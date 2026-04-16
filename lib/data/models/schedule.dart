class Schedule {
  final String id;
  final String name;
  final DateTime time;
  final String icon;
  final bool isEnabled;
  final String? type; // e.g., 'Medicine', 'Commute'
  final String? dosage;

  Schedule({
    required this.id,
    required this.name,
    required this.time,
    required this.icon,
    this.isEnabled = true,
    this.type,
    this.dosage,
  });

  Map<String, dynamic> toMap() {
    return {
      '_id': id,
      'name': name,
      'time': time.toIso8601String(),
      'icon': icon,
      'isEnabled': isEnabled,
      'type': type,
      'dosage': dosage,
    };
  }

  factory Schedule.fromMap(Map<String, dynamic> map) {
    return Schedule(
      id: map['_id'].toString(),
      name: map['name'],
      time: DateTime.parse(map['time']),
      icon: map['icon'],
      isEnabled: map['isEnabled'] ?? true,
      type: map['type'],
      dosage: map['dosage'],
    );
  }
}
