class UserProfile {
  final String name;
  final int age;
  final double weight;
  final double height;
  final TimeOfDay breakfastTime;
  final TimeOfDay lunchTime;
  final TimeOfDay dinnerTime;

  UserProfile({
    required this.name,
    required this.age,
    required this.weight,
    required this.height,
    required this.breakfastTime,
    required this.lunchTime,
    required this.dinnerTime,
  });

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'age': age,
      'weight': weight,
      'height': height,
      'breakfastTime': '${breakfastTime.hour}:${breakfastTime.minute}',
      'lunchTime': '${lunchTime.hour}:${lunchTime.minute}',
      'dinnerTime': '${dinnerTime.hour}:${dinnerTime.minute}',
    };
  }

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      name: (json['name'] as String?)?.trim().isNotEmpty == true
          ? json['name'] as String
          : 'User',
      age: _readInt(json['age'], fallback: 30),
      weight: _readDouble(json['weight'], fallback: 60.0),
      height: _readDouble(json['height'], fallback: 165.0),
      breakfastTime: _parseTime(json['breakfastTime'], fallbackHour: 8),
      lunchTime: _parseTime(json['lunchTime'], fallbackHour: 13),
      dinnerTime: _parseTime(json['dinnerTime'], fallbackHour: 20),
    );
  }

  static int _readInt(dynamic value, {required int fallback}) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value) ?? fallback;
    return fallback;
  }

  static double _readDouble(dynamic value, {required double fallback}) {
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? fallback;
    return fallback;
  }

  static TimeOfDay _parseTime(dynamic value, {required int fallbackHour}) {
    if (value is String && value.contains(':')) {
      final parts = value.split(':');
      final h = int.tryParse(parts[0]);
      final m = parts.length > 1 ? int.tryParse(parts[1]) : 0;
      if (h != null && h >= 0 && h < 24 && m != null && m >= 0 && m < 60) {
        return TimeOfDay(hour: h, minute: m);
      }
    }
    return TimeOfDay(hour: fallbackHour, minute: 0);
  }
}

class TimeOfDay {
  final int hour;
  final int minute;

  TimeOfDay({required this.hour, required this.minute});

  @override
  String toString() {
    final h = hour.toString().padLeft(2, '0');
    final m = minute.toString().padLeft(2, '0');
    return '$h:$m';
  }
}
