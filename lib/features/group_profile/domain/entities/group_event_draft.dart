import 'dart:io';

/// Name and description of an event in one language.
class GroupEventDraftMetadata {
  final String language;
  final String name;
  final String description;

  const GroupEventDraftMetadata({
    required this.language,
    this.name = '',
    this.description = '',
  });

  bool get hasName => name.trim().isNotEmpty;

  GroupEventDraftMetadata copyWith({String? name, String? description}) {
    return GroupEventDraftMetadata(
      language: language,
      name: name ?? this.name,
      description: description ?? this.description,
    );
  }
}

/// Where the cover image comes from; a file is uploaded on submit.
sealed class GroupEventCover {
  const GroupEventCover();
}

class GroupEventCoverFile extends GroupEventCover {
  final File file;

  const GroupEventCoverFile(this.file);
}

class GroupEventCoverUrl extends GroupEventCover {
  final String url;

  const GroupEventCoverUrl(this.url);
}

/// What the composer has collected so far, carried across its steps.
class GroupEventDraft {
  /// Ordered as the language list from the API.
  final List<GroupEventDraftMetadata> metadata;
  final GroupEventCover? cover;

  const GroupEventDraft({this.metadata = const [], this.cover});

  List<String> get languages => [for (final m in metadata) m.language];

  /// Languages without a name are dropped before sending.
  bool get hasName => metadata.any((m) => m.hasName);

  bool get hasContent =>
      cover != null ||
      metadata.any((m) => m.hasName || m.description.trim().isNotEmpty);

  GroupEventDraftMetadata? metadataFor(String language) =>
      metadata.where((m) => m.language == language).firstOrNull;

  GroupEventDraft copyWith({
    List<GroupEventDraftMetadata>? metadata,
    GroupEventCover? cover,
    bool clearCover = false,
  }) {
    return GroupEventDraft(
      metadata: metadata ?? this.metadata,
      cover: clearCover ? null : (cover ?? this.cover),
    );
  }
}
