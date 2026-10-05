import 'package:equatable/equatable.dart';

class VerseOfDay extends Equatable {
  final String id;
  final String verse;
  final String imageUrl;
  final String date;
  final String source;

  const VerseOfDay({
    required this.id,
    required this.verse,
    required this.imageUrl,
    required this.date,
    this.source = '',
  });

  @override
  List<Object?> get props => [id, verse, imageUrl, date, source];
}
