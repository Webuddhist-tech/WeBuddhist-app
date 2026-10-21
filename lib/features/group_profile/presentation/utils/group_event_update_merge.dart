import 'dart:convert';

import 'package:flutter_pecha/features/group_profile/data/models/group_event_request_model.dart';
import 'package:flutter_pecha/features/group_profile/presentation/utils/group_event_draft_mapper.dart';

/// Merges the user's edits into the rows the server already holds.
///
/// The draft only models one live link and plain videos, and picks a count
/// mode per accumulation. Rebuilding those lists from the draft alone would
/// drop studio data the app does not load (extra links, link languages and
/// labels, or a format the app never pairs with a count mode). So when the
/// user changed one of these lists, the server's rows are kept and only the
/// changed entries are replaced.
class GroupEventUpdateMerge {
  GroupEventUpdateMerge._();

  /// [next] and [original] are built from the edited and the loaded draft.
  static CreateGroupEventRequest apply(
    CreateGroupEventRequest next, {
    required CreateGroupEventRequest original,
    required GroupEventEditSource source,
  }) {
    final linksChanged =
        _encode(next.links.map((e) => e.toJson())) !=
        _encode(original.links.map((e) => e.toJson()));
    final youtubeChanged =
        _encode(next.youtube.map((e) => e.toJson())) !=
        _encode(original.youtube.map((e) => e.toJson()));
    final accumulationsChanged =
        _encode(next.accumulations.map((e) => e.toJson())) !=
        _encode(original.accumulations.map((e) => e.toJson()));
    if (!linksChanged && !youtubeChanged && !accumulationsChanged) {
      return next;
    }

    var merged = next;
    if (linksChanged || youtubeChanged) {
      final (links, youtube) = _mergeLinks(next, original, source);
      // Only the list the user changed is replaced; the other stays equal to
      // the original, so the update leaves it out.
      merged = merged.copyWith(
        links: linksChanged ? links : null,
        youtube: youtubeChanged ? youtube : null,
      );
    }
    if (accumulationsChanged) {
      merged = merged.copyWith(
        accumulations: _mergeAccumulations(next, original, source),
      );
    }
    return merged;
  }

  static (List<GroupEventLinkRequest>, List<GroupEventYoutubeRequest>)
  _mergeLinks(
    CreateGroupEventRequest next,
    CreateGroupEventRequest original,
    GroupEventEditSource source,
  ) {
    final fallbackLanguage =
        next.metadata.isNotEmpty ? next.metadata.first.language : 'EN';
    final youtube = <GroupEventYoutubeRequest>[
      for (final (i, row) in source.serverYoutube.indexed)
        if (_url(row).isNotEmpty)
          GroupEventYoutubeRequest(
            url: _url(row),
            label: row['label'] as String?,
            language: (row['language'] as String?) ?? fallbackLanguage,
            displayOrder: (row['display_order'] as num?)?.toInt() ?? i + 1,
          ),
    ];
    final links = <GroupEventLinkRequest>[
      for (final (i, row) in source.serverLinks.indexed)
        if (_url(row).isNotEmpty)
          GroupEventLinkRequest(
            type: (row['type'] as String? ?? '').trim(),
            url: _url(row),
            label: row['label'] as String?,
            language: (row['language'] as String?) ?? fallbackLanguage,
            displayOrder: (row['display_order'] as num?)?.toInt() ?? i + 1,
          ),
    ];

    // The live link: the draft holds the first YouTube row, else the first
    // non-video link (see GroupEventDraftMapper).
    final nextLive = _liveOf(next);
    final originalLive = _liveOf(original);
    if (_urlOf(nextLive) != _urlOf(originalLive)) {
      String? language;
      int? order;
      var wasYoutube = false;
      if (youtube.isNotEmpty) {
        final old = youtube.removeAt(0);
        language = old.language;
        order = old.displayOrder;
        wasYoutube = true;
      } else {
        final index = links.indexWhere((link) => !_isVideo(link.type));
        if (index >= 0) {
          final old = links.removeAt(index);
          language = old.language;
          order = old.displayOrder;
        }
      }
      final added = nextLive;
      if (added is GroupEventYoutubeRequest) {
        youtube.insert(
          0,
          GroupEventYoutubeRequest(
            url: added.url,
            label: added.label,
            language: language ?? added.language,
            displayOrder:
                wasYoutube ? (order ?? added.displayOrder) : added.displayOrder,
          ),
        );
      } else if (added is GroupEventLinkRequest) {
        links.insert(
          0,
          GroupEventLinkRequest(
            type: added.type,
            url: added.url,
            label: added.label,
            language: language ?? added.language,
            displayOrder:
                wasYoutube ? added.displayOrder : (order ?? added.displayOrder),
          ),
        );
      }
    }

    // Videos: keep the saved rows still in the draft, drop removed ones,
    // and append new ones.
    final nextVideos = next.links.where((link) => _isVideo(link.type));
    final originalVideos = original.links.where((link) => _isVideo(link.type));
    if (_encode(nextVideos.map((e) => e.toJson())) !=
        _encode(originalVideos.map((e) => e.toJson()))) {
      final keep = {for (final video in nextVideos) video.url};
      links.removeWhere(
        (link) => _isVideo(link.type) && !keep.contains(link.url),
      );
      final saved = {
        for (final link in links)
          if (_isVideo(link.type)) link.url,
      };
      var order = links.fold<int>(
        0,
        (max, link) => link.displayOrder > max ? link.displayOrder : max,
      );
      for (final video in nextVideos) {
        if (saved.contains(video.url)) continue;
        links.add(
          GroupEventLinkRequest(
            type: video.type,
            url: video.url,
            label: video.label,
            language: video.language,
            displayOrder: ++order,
          ),
        );
      }
    }
    return (links, youtube);
  }

  /// Rows whose count mode the user left alone keep the saved format and
  /// mode; the rest take the draft's.
  static List<GroupEventAccumulationRequest> _mergeAccumulations(
    CreateGroupEventRequest next,
    CreateGroupEventRequest original,
    GroupEventEditSource source,
  ) {
    final before = {
      for (final item in original.accumulations) item.groupAccumulatorId: item,
    };
    final saved = <String, Map<String, dynamic>>{};
    for (final row in source.serverAccumulations) {
      final ref = row['group_accumulator'];
      final id =
          (ref is Map<String, dynamic> ? ref['id'] as String? : null) ??
          row['group_accumulator_id'] as String?;
      if (id != null && id.isNotEmpty) saved.putIfAbsent(id, () => row);
    }
    return [
      for (final item in next.accumulations)
        _keepSaved(
          item,
          before[item.groupAccumulatorId],
          saved[item.groupAccumulatorId],
        ),
    ];
  }

  static GroupEventAccumulationRequest _keepSaved(
    GroupEventAccumulationRequest item,
    GroupEventAccumulationRequest? before,
    Map<String, dynamic>? row,
  ) {
    final untouched =
        before != null &&
        before.countMode == item.countMode &&
        before.eventFormat == item.eventFormat;
    if (!untouched || row == null) return item;
    final format = row['event_format'];
    final mode = row['count_mode'];
    return GroupEventAccumulationRequest(
      groupAccumulatorId: item.groupAccumulatorId,
      eventFormat:
          format is String && format.isNotEmpty ? format : item.eventFormat,
      displayOrder: item.displayOrder,
      countMode: mode is String && mode.isNotEmpty ? mode : item.countMode,
    );
  }

  /// The request entry that carries the live link, if any.
  static Object? _liveOf(CreateGroupEventRequest request) {
    if (request.youtube.isNotEmpty) return request.youtube.first;
    for (final link in request.links) {
      if (!_isVideo(link.type)) return link;
    }
    return null;
  }

  static bool _isVideo(String type) => type.trim().toLowerCase() == 'video';

  static String _url(Map<String, dynamic> row) =>
      (row['url'] as String? ?? '').trim();

  static String? _urlOf(Object? live) => switch (live) {
    GroupEventYoutubeRequest(:final url) => url,
    GroupEventLinkRequest(:final url) => url,
    _ => null,
  };

  static String _encode(Iterable<Map<String, dynamic>> rows) =>
      jsonEncode(rows.toList());
}
