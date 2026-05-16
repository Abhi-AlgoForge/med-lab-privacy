class MedicationReminder {
  final String id;
  final String medicineName;
  final MedicationTiming timing;
  final bool beforeEating;
  final bool isActive;
  final List<int> notificationIds;

  MedicationReminder({
    required this.id,
    required this.medicineName,
    required this.timing,
    required this.beforeEating,
    this.isActive = true,
    this.notificationIds = const [],
  });

  MedicationReminder copyWith({
    String? id,
    String? medicineName,
    MedicationTiming? timing,
    bool? beforeEating,
    bool? isActive,
    List<int>? notificationIds,
  }) {
    return MedicationReminder(
      id: id ?? this.id,
      medicineName: medicineName ?? this.medicineName,
      timing: timing ?? this.timing,
      beforeEating: beforeEating ?? this.beforeEating,
      isActive: isActive ?? this.isActive,
      notificationIds: notificationIds ?? this.notificationIds,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'medicineName': medicineName,
      'timing': timing.toString(),
      'beforeEating': beforeEating,
      'isActive': isActive,
      'notificationIds': notificationIds,
    };
  }

  factory MedicationReminder.fromJson(Map<String, dynamic> json) {
    return MedicationReminder(
      id: json['id'] as String,
      medicineName: json['medicineName'] as String,
      timing: MedicationTiming.values.firstWhere(
        (e) => e.toString() == json['timing'],
        orElse: () => MedicationTiming.morning,
      ),
      beforeEating: json['beforeEating'] as bool? ?? true,
      isActive: json['isActive'] as bool? ?? true,
      notificationIds: (json['notificationIds'] as List<dynamic>?)
              ?.map((e) => e as int)
              .toList() ??
          [],
    );
  }
}

enum MedicationTiming {
  morning,
  afternoon,
  night;

  String get displayName {
    switch (this) {
      case MedicationTiming.morning:
        return 'Morning';
      case MedicationTiming.afternoon:
        return 'Afternoon';
      case MedicationTiming.night:
        return 'Night';
    }
  }
}
