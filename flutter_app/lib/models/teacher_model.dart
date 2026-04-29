
class Course {
  final String name;
  final String level;
  final String department;

  Course({
    required this.name,
    required this.level,
    required this.department,
  });

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'level': level,
      'department': department,
    };
  }

  Map<String, dynamic> toJson() => toMap();

  factory Course.fromMap(Map<String, dynamic> map) {
    return Course(
      name: map['name'] ?? '',
      level: map['level'] ?? '',
      department: map['department'] ?? '',
    );
  }
}

class Teacher {
  final String id;
  final String username;
  final String? password; // Only used when creating/updating
  final List<Course> courses;

  Teacher({
    required this.id,
    required this.username,
    this.password,
    required this.courses,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'username': username,
      if (password != null) 'password': password,
      'courses': courses.map((c) => c.toMap()).toList(),
    };
  }

  Map<String, dynamic> toJson() => toMap();

  factory Teacher.fromMap(Map<String, dynamic> map) {
    return Teacher(
      id: map['id']?.toString() ?? '',
      username: map['username']?.toString() ?? '',
      password: map['password']?.toString(),
      courses: (map['courses'] as List? ?? [])
          .map((c) => Course.fromMap(c as Map<String, dynamic>))
          .toList(),
    );
  }
}
