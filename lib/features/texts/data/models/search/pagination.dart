class Pagination {
  final int total;
  final int skip;
  final int limit;

  Pagination({required this.total, required this.skip, required this.limit});

  factory Pagination.fromJson(Map<String, dynamic> json) {
    return Pagination(
      total: json['total'] ?? 0,
      skip: json['skip'] ?? 0,
      limit: json['limit'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {'total': total, 'skip': skip, 'limit': limit};
  }

  @override
  String toString() {
    return 'Pagination(total: $total, skip: $skip, limit: $limit)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Pagination &&
        other.total == total &&
        other.skip == skip &&
        other.limit == limit;
  }

  @override
  int get hashCode {
    return total.hashCode ^ skip.hashCode ^ limit.hashCode;
  }
}

