import 'package:flutter_pecha/features/group_profile/domain/entities/group_report.dart';

class GroupReportsPage {
  final List<GroupReport> reports;
  final int skip;
  final int limit;
  final int total;

  const GroupReportsPage({
    required this.reports,
    required this.skip,
    required this.limit,
    required this.total,
  });
}
