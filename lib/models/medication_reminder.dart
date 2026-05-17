class MedicationReminder {
  final String id;
  final String medicineName;
  final MedicationTiming timing;
  final bool beforeEating;
  final bool isActive;

  // Stable 31-bit integer ID for the OS notification slot.
  // Required because hashCode of strings can collide, silently cancelling
  // unrelated reminders.
  final int notificationId;

  MedicationReminder({
    required this.id,
    required this.medicineName,
    required this.timing,
    required this.beforeEating,
    this.isActive = true,
    int? notificationId,
  }) : notificationId = notificationId ?? _generateNotificationId();

  static int _nextSeq = 0;
  static int _generateNotificationId() {
    final base = DateTime.now().microsecondsSinceEpoch & 0x7FFFFFFF;
    _nextSeq = (_nextSeq + 1) & 0x7FFF;
    return (base ^ _nextSeq) & 0x7FFFFFFF;
  }

  MedicationReminder copyWith({
    String? id,
    String? medicineName,
    MedicationTiming? timing,
    bool? beforeEating,
    bool? isActive,
    int? notificationId,
  }) {
    return MedicationReminder(
      id: id ?? this.id,
      medicineName: medicineName ?? this.medicineName,
      timing: timing ?? this.timing,
      beforeEating: beforeEating ?? this.beforeEating,
      isActive: isActive ?? this.isActive,
      notificationId: notificationId ?? this.notificationId,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'medicineName': medicineName,
      'timing': timing.toString(),
      'beforeEating': beforeEating,
      'isActive': isActive,
      'notificationId': notificationId,
    };
  }

  factory MedicationReminder.fromJson(Map<String, dynamic> json) {
    final id = (json['id'] as String?) ??
        DateTime.now().millisecondsSinceEpoch.toString();
    final storedNotifId = json['notificationId'];
    final notifId = storedNotifId is int
        ? storedNotifId
        : (id.hashCode & 0x7FFFFFFF);
    return MedicationReminder(
      id: id,
      medicineName: (json['medicineName'] as String?) ?? 'Unknown medicine',
      timing: MedicationTiming.values.firstWhere(
        (e) => e.toString() == json['timing'],
        orElse: () => MedicationTiming.morning,
      ),
      beforeEating: json['beforeEating'] as bool? ?? true,
      isActive: json['isActive'] as bool? ?? true,
      notificationId: notifId,
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
