class DoseRecord {
  final String reminderId;
  final String medicineName;
  final String scheduledDate; // yyyy-MM-dd
  final DateTime? takenAt;
  final bool taken;

  DoseRecord({
    required this.reminderId,
    required this.medicineName,
    required this.scheduledDate,
    this.takenAt,
    this.taken = false,
  });

  Map<String, dynamic> toJson() {
    return {
      'reminderId': reminderId,
      'medicineName': medicineName,
      'scheduledDate': scheduledDate,
      'takenAt': takenAt?.toIso8601String(),
      'taken': taken,
    };
  }

  factory DoseRecord.fromJson(Map<String, dynamic> json) {
    return DoseRecord(
      reminderId: json['reminderId'] as String? ?? '',
      medicineName: json['medicineName'] as String? ?? '',
      scheduledDate: json['scheduledDate'] as String? ?? '',
      takenAt: json['takenAt'] != null
          ? DateTime.tryParse(json['takenAt'] as String)
          : null,
      taken: json['taken'] as bool? ?? false,
    );
  }
}
