class PatientModel {
  final String id;
  final String name;
  final int age;
  final DateTime date;
  final String mobile;
  final DateTime createdAt;

  PatientModel({
    required this.id,
    required this.name,
    required this.age,
    required this.date,
    required this.mobile,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'age': age,
      'date': date.toIso8601String(),
      'mobile': mobile,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory PatientModel.fromMap(Map<String, dynamic> map) {
    return PatientModel(
      id: map['id'],
      name: map['name'],
      age: map['age'],
      date: DateTime.parse(map['date']),
      mobile: map['mobile'],
      createdAt: DateTime.parse(map['createdAt']),
    );
  }
}