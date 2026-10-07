import 'package:flutter_pecha/features/group_profile/domain/entities/group_report.dart';

class GroupReportsPage {
  final List<GroupReport> reports;

  final int skip;
  final int limit;
  final int total;
  final int? _received;

  /// How many reports the page held on the wire, including any of a kind this
  /// client dropped. What the next page must be asked to skip, since
  /// [reports] alone would ask for the dropped ones again.
  int get received => _received ?? reports.length;

  const GroupReportsPage({
    required this.reports,
    required this.skip,
    required this.limit,
    required this.total,
    int? received,
  }) : _received = received;
}
