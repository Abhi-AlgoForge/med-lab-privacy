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
    final breakfastParts = (json['breakfastTime'] as String).split(':');
    final lunchParts = (json['lunchTime'] as String).split(':');
    final dinnerParts = (json['dinnerTime'] as String).split(':');

    return UserProfile(
      name: json['name'] as String,
      age: json['age'] as int,
      weight: (json['weight'] as num).toDouble(),
      height: (json['height'] as num).toDouble(),
      breakfastTime: TimeOfDay(
        hour: int.parse(breakfastParts[0]),
        minute: int.parse(breakfastParts[1]),
      ),
      lunchTime: TimeOfDay(
        hour: int.parse(lunchParts[0]),
        minute: int.parse(lunchParts[1]),
      ),
      dinnerTime: TimeOfDay(
        hour: int.parse(dinnerParts[0]),
        minute: int.parse(dinnerParts[1]),
      ),
    );
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
