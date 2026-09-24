import 'package:equatable/equatable.dart';
import 'package:flutter_pecha/features/reader/domain/layout/reader_layout_context.dart';

/// Which dual-layout settings a reader uses: one text in one
/// [ReaderLayoutContext].
///
/// The same text opened from an event and from the library keeps two
/// separate sets of picks, so an event's transliteration and translation
/// never leak into library reading.
class ReaderSettingsScope extends Equatable {
  const ReaderSettingsScope({required this.textId, required this.context});

  /// The edition the reader was opened with.
  final String textId;

  final ReaderLayoutContext context;

  @override
  List<Object?> get props => [textId, context];

  @override
  String toString() => 'ReaderSettingsScope($textId, ${context.name})';
}
