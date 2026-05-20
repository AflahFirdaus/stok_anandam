class Announcement {
  final int? id;
  final String title;
  final String subtitle;
  final DateTime? startDate;
  final DateTime? expiredDate;

  const Announcement({
    this.id,
    required this.title,
    required this.subtitle,
    this.startDate,
    this.expiredDate,
  });

  factory Announcement.fromJson(Map<String, dynamic> json) {
    return Announcement(
      id: json['id'] as int?,
      title: json['title']?.toString() ?? '',
      subtitle: json['subtitle']?.toString() ?? '',
      startDate: json['startDate'] != null
          ? DateTime.tryParse(json['startDate'].toString())
          : null,
      expiredDate: json['expiredDate'] != null
          ? DateTime.tryParse(json['expiredDate'].toString())
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'title': title,
      'subtitle': subtitle,
      if (startDate != null) 'startDate': startDate!.toIso8601String(),
      if (expiredDate != null) 'expiredDate': expiredDate!.toIso8601String(),
    };
  }
}
