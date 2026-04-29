import 'package:flutter/foundation.dart';
import '../models/teacher_model.dart';
import '../data/student_data.dart';

class MockDataService {
  // Static list to persist data during app session
  static final List<Teacher> _teachers = [
    Teacher(
      id: 'teacher-1',
      username: 'doctor',
      password: 'password',
      courses: [
        Course(name: 'تكنولوجيا التعليم', level: 'الفرقة الثانية', department: 'إعلام تربوي'),
      ],
    ),
  ];

  static final List<Map<String, dynamic>> _mockStudents = [
    ...mediaLevel2Students.values.map((s) => {
      'studentCode': s.code,
      'fullName': s.name,
      'department': s.department,
      'level': s.level,
      'status': s.status,
      'allowedAccess': true,
    }),
    ...homeEconomicsLevel2Students.values.map((s) => {
      'studentCode': s.code,
      'fullName': s.name,
      'department': s.department,
      'level': s.level,
      'status': s.status,
      'allowedAccess': true,
    }),
  ];

  static final List<Map<String, dynamic>> _mockAnnouncements = [
    {
      'id': 'ann-1',
      'title': 'ترحيب بالطلاب الجدد',
      'content': 'نرحب بجميع الطلاب الجدد في كليتنا ونتمنى لكم عاماً دراسياً موفقاً.',
      'date': '2024-05-10',
      'priority': 'عادي',
      'readByStudentIds': [],
      'imageUrl': '',
    },
    {
      'id': 'ann-2',
      'title': 'تنبيه هام بخصوص الامتحانات',
      'content': 'يرجى العلم أن امتحانات الفصل الدراسي الثاني ستبدأ في منتصف شهر يونيو.',
      'date': '2024-05-12',
      'priority': 'هام جداً',
      'readByStudentIds': [],
      'imageUrl': '',
    },
  ];

  static final List<Map<String, dynamic>> _mockSchedules = [
    {
      'id': 'sch-1',
      'subject': 'برمجة الموبايل',
      'day': 'الأحد',
      'date': '2024-05-19',
      'time': '10:00 AM - 12:00 PM',
      'location': 'قاعة 1',
      'department': 'تكنولوجيا التعليم',
      'level': 'الفرقة الرابعة',
      'isExam': false,
    },
    {
      'id': 'sch-2',
      'subject': 'تحليل نظم',
      'day': 'الإثنين',
      'date': '2024-05-20',
      'time': '12:00 PM - 02:00 PM',
      'location': 'معمل 3',
      'department': 'الحاسب الآلي',
      'level': 'الفرقة الثالثة',
      'isExam': false,
    },
  ];

  static final List<Map<String, dynamic>> _mockExams = [
    {
      'id': 'exam-1',
      'subject': 'مقدمة في تكنولوجيا التعليم',
      'department': 'إعلام تربوي',
      'level': 'الفرقة الثانية',
      'tfCount': 5,
      'mcqCount': 5,
      'createdAt': '2024-05-01',
      'questions': [
        {'type': 'tf', 'question': 'هل تكنولوجيا التعليم تقتصر على الأجهزة فقط؟', 'answer': false},
        {'type': 'mcq', 'question': 'من أول من استخدم مصطلح تكنولوجيا التعليم؟', 'options': ['فلان', 'علان', 'ترتان'], 'answer': 0},
      ]
    }
  ];

  static final List<Map<String, dynamic>> _mockMaterials = [
    {
      'id': 'mat-1',
      'originalName': 'محاضرة 1.pdf',
      'url': 'https://example.com/lecture1.pdf',
      'department': 'إعلام تربوي',
      'level': 'الفرقة الثانية',
      'subject': 'تكنولوجيا التعليم',
      'teacherName': 'د. أحمد محمد',
      'uploadedAt': '2024-05-01',
    }
  ];

  static final List<Map<String, dynamic>> _mockAttendanceRecords = [];

  static final List<Map<String, dynamic>> _mockExamResults = [];

  static final List<Map<String, dynamic>> _mockNotifications = [];

  static final List<Map<String, dynamic>> _mockAssignments = [];

  static final List<Map<String, dynamic>> _mockSubmissions = [];

  static final List<Map<String, dynamic>> _mockLibraryBooks = [];

  static final List<Map<String, dynamic>> _mockQuestionBank = [
    {
      'id': 'qb-1',
      'department': 'إعلام تربوي',
      'level': 'الفرقة الثانية',
      'subject': 'تكنولوجيا التعليم',
      'type': 'tf',
      'question': 'هل تكنولوجيا التعليم تعني الأجهزة فقط؟',
      'answer': false,
    },
    {
      'id': 'qb-2',
      'department': 'إعلام تربوي',
      'level': 'الفرقة الثانية',
      'subject': 'تكنولوجيا التعليم',
      'type': 'mcq',
      'question': 'من العالم الذي ارتبط اسمه بمخروط الخبرة؟',
      'options': ['إدجار ديل', 'سكينر', 'بياجيه', 'بلوم'],
      'answer': 0,
    }
  ];

  // Getters
  static List<Teacher> get teachers => List.unmodifiable(_teachers);
  static List<Map<String, dynamic>> get announcements => _mockAnnouncements;
  static List<Map<String, dynamic>> get schedules => _mockSchedules;
  static List<Map<String, dynamic>> get exams => _mockExams;
  static List<Map<String, dynamic>> get materials => _mockMaterials;
  static List<Map<String, dynamic>> get students => _mockStudents;
  static List<Map<String, dynamic>> get attendanceRecords => _mockAttendanceRecords;
  static List<Map<String, dynamic>> get examResults => _mockExamResults;
  static List<Map<String, dynamic>> get questionBank => _mockQuestionBank;
  static List<Map<String, dynamic>> get notifications => _mockNotifications;
  static List<Map<String, dynamic>> get assignments => _mockAssignments;
  static List<Map<String, dynamic>> get submissions => _mockSubmissions;
  static List<Map<String, dynamic>> get libraryBooks => _mockLibraryBooks;

  // Library Methods
  static List<Map<String, dynamic>> getLibraryBooks() {
    return _mockLibraryBooks;
  }

  static void deleteLibraryBook(String id) {
    _mockLibraryBooks.removeWhere((b) => b['id'] == id);
  }

  // Assignment Methods
  static void addAssignment(Map<String, dynamic> assignment) {
    _mockAssignments.insert(0, {
      ...assignment,
      'id': 'assign-${DateTime.now().millisecondsSinceEpoch}',
    });
  }

  static List<Map<String, dynamic>> getAssignments(String department, String level) {
    return _mockAssignments.where((a) => a['department'] == department && a['level'] == level).toList();
  }

  static void submitAssignment(Map<String, dynamic> submission) {
    _mockSubmissions.insert(0, {
      ...submission,
      'id': 'sub-${DateTime.now().millisecondsSinceEpoch}',
    });
  }

  static List<Map<String, dynamic>> getSubmissions(String assignmentId) {
    return _mockSubmissions.where((s) => s['assignmentId'] == assignmentId).toList();
  }

  static Map<String, dynamic>? getStudentSubmission(String assignmentId, String studentCode) {
    try {
      return _mockSubmissions.firstWhere((s) => s['assignmentId'] == assignmentId && s['studentCode'] == studentCode);
    } catch (_) {
      return null;
    }
  }

  static void gradeSubmission(String submissionId, double grade, String feedback) {
    final idx = _mockSubmissions.indexWhere((s) => s['id'] == submissionId);
    if (idx != -1) {
      _mockSubmissions[idx]['grade'] = grade;
      _mockSubmissions[idx]['feedback'] = feedback;
    }
  }

  // Notification Methods
  static void addNotification({
    required String title,
    required String message,
    required String levelId,
  }) {
    _mockNotifications.insert(0, {
      'id': 'notif-${DateTime.now().millisecondsSinceEpoch}',
      'title': title,
      'message': message,
      'timestamp': DateTime.now().toIso8601String(),
      'levelId': levelId,
      'isRead': false,
    });
  }

  static List<Map<String, dynamic>> getNotifications(String levelId) {
    return _mockNotifications
        .where((n) => n['levelId'] == levelId || n['levelId'] == '')
        .toList();
  }

  static void markNotificationsAsRead(String levelId) {
    for (var n in _mockNotifications) {
      if (n['levelId'] == levelId || n['levelId'] == '') {
        n['isRead'] = true;
      }
    }
  }

  // Question Bank Methods
  static void addQuestionToBank(Map<String, dynamic> question) {
    _mockQuestionBank.add({
      ...question,
      'id': 'qb-${DateTime.now().millisecondsSinceEpoch}',
    });
  }

  static List<Map<String, dynamic>> getQuestionsFromBank({
    required String department,
    required String level,
    required String subject,
    String? type,
  }) {
    return _mockQuestionBank.where((q) {
      bool match = q['department'] == department &&
          q['level'] == level &&
          q['subject'] == subject;
      if (type != null && type.isNotEmpty) {
        match = match && q['type'] == type;
      }
      return match;
    }).toList();
  }

  static void deleteQuestionFromBank(String id) {
    _mockQuestionBank.removeWhere((q) => q['id'] == id);
  }

  // Exam Results Methods
  static void addExamResult(Map<String, dynamic> result) {
    _mockExamResults.add({
      ...result,
      'id': 'res-${DateTime.now().millisecondsSinceEpoch}',
      'submittedAt': DateTime.now().toIso8601String(),
    });
  }

  static Map<String, dynamic>? getLatestExamResult(String studentCode) {
    final results = _mockExamResults
        .where((r) => r['studentCode'] == studentCode)
        .toList();
    if (results.isEmpty) return null;
    results.sort((a, b) => (b['submittedAt'] as String).compareTo(a['submittedAt'] as String));
    return results.first;
  }

  // Attendance Methods
  static void addAttendanceRecord(Map<String, dynamic> record) {
    _mockAttendanceRecords.add({
      ...record,
      'timestamp': DateTime.now().toIso8601String(),
    });
  }

  static List<Map<String, dynamic>> getAttendanceForStudent(String studentCode) {
    return _mockAttendanceRecords.where((r) => r['studentCode'] == studentCode).toList();
  }

  static void processAbsentees({
    required String levelId,
    required String subjectId,
    required String lectureId,
    required List<String> presentStudentCodes,
    required String teacherId,
  }) {
    final parts = levelId.split('__');
    if (parts.length < 2) return;
    final dept = parts[0];
    final level = parts[1];

    final allStudentsInLevel = _mockStudents.where((s) => 
      s['department'] == dept && s['level'] == level
    ).toList();

    for (var student in allStudentsInLevel) {
      final code = student['studentCode'].toString();
      if (!presentStudentCodes.contains(code)) {
        _mockAttendanceRecords.add({
          'studentCode': code,
          'studentName': student['fullName'],
          'levelId': levelId,
          'subjectId': subjectId,
          'lectureId': lectureId,
          'teacherId': teacherId,
          'status': 'Absent',
          'timestamp': DateTime.now().toIso8601String(),
        });
      }
    }
  }

  static List<Map<String, dynamic>> getCumulativeAttendance(String levelId) {
    final parts = levelId.split('__');
    if (parts.length < 2) return [];
    final dept = parts[0];
    final level = parts[1];

    final studentsInLevel = _mockStudents.where((s) => 
      s['department'] == dept && s['level'] == level
    ).toList();

    // Get total lectures for this level from attendance records (unique lectureIds)
    final totalLectures = _mockAttendanceRecords
        .where((r) => r['levelId'] == levelId)
        .map((r) => r['lectureId'])
        .toSet()
        .length;

    return studentsInLevel.map((s) {
      final code = s['studentCode'].toString();
      final presentCount = _mockAttendanceRecords.where((r) => 
        r['studentCode'] == code && r['levelId'] == levelId && r['status'] == 'Present'
      ).length;

      return {
        'studentCode': code,
        'studentName': s['fullName'],
        'totalLectures': totalLectures,
        'presentCount': presentCount,
        'percentage': totalLectures > 0 ? (presentCount / totalLectures * 100) : 0.0,
      };
    }).toList();
  }

  // Student Methods
  static void addStudent(Map<String, dynamic> student) {
    _mockStudents.add({
      ...student,
      'allowedAccess': student['allowedAccess'] ?? true,
    });
  }

  static void updateStudent(String code, Map<String, dynamic> payload) {
    final index = _mockStudents.indexWhere((s) => s['studentCode'] == code);
    if (index != -1) {
      _mockStudents[index] = {
        ..._mockStudents[index],
        ...payload,
      };
    }
  }

  static void deleteStudent(String code) {
    _mockStudents.removeWhere((s) => s['studentCode'] == code);
  }

  static void setStudentAccess(String code, bool allowed) {
    final index = _mockStudents.indexWhere((s) => s['studentCode'] == code);
    if (index != -1) {
      _mockStudents[index]['allowedAccess'] = allowed;
    }
  }

  // Teacher Methods
  static void addTeacher(Teacher teacher) {
    _teachers.add(teacher);
    if (kDebugMode) {
      print('Teacher added: ${teacher.username} with password: ${teacher.password}');
    }
  }

  static void updateTeacher(String id, Teacher updatedTeacher) {
    final index = _teachers.indexWhere((t) => t.id == id);
    if (index != -1) {
      _teachers[index] = updatedTeacher;
    }
  }

  static void deleteTeacher(String id) {
    _teachers.removeWhere((t) => t.id == id);
  }

  static Teacher? authenticateTeacher(String username, String password) {
    try {
      return _teachers.firstWhere(
        (t) => t.username == username && t.password == password,
      );
    } catch (_) {
      return null;
    }
  }

  // Messaging Methods
  static final Map<String, int> _unreadCountsForStudents = {}; // Key: levelId|teacherId
  static final Map<String, int> _unreadCountsForTeacher = {};   // Key: levelId|teacherId

  static final List<Map<String, dynamic>> _mockMessages = [
    {
      'id': 'msg-1',
      'levelId': 'إعلام تربوي__الفرقة الثانية',
      'teacherId': 'teacher-1',
      'senderName': 'doctor',
      'role': 'teacher',
      'content': 'أهلاً بكم، اكتبوا أسئلتكم هنا بخصوص الفرقة.',
      'timestamp': 1715600000000,
    },
    {
      'id': 'msg-2',
      'levelId': 'إعلام تربوي__الفرقة الثانية',
      'teacherId': 'teacher-1',
      'senderName': 'طالب',
      'role': 'student',
      'content': 'حضرتك، هل الامتحان هيبقى اختيار من متعدد فقط؟',
      'timestamp': 1715600300000,
    },
  ];

  static List<Map<String, dynamic>> getMessagesByLevel(String levelId, {String? teacherId}) {
    final items = _mockMessages.where((m) {
      bool match = m['levelId'] == levelId;
      if (teacherId != null) {
        match = match && m['teacherId'] == teacherId;
      }
      return match;
    }).toList();
    items.sort((a, b) => ((a['timestamp'] ?? 0) as int).compareTo(((b['timestamp'] ?? 0) as int)));
    return List.unmodifiable(items);
  }

  static Map<String, dynamic> addMessage(String levelId, String teacherId, String senderName, String role, String content) {
    final message = <String, dynamic>{
      'id': 'msg-${DateTime.now().microsecondsSinceEpoch}',
      'levelId': levelId,
      'teacherId': teacherId,
      'senderName': senderName,
      'role': role,
      'content': content,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    };
    _mockMessages.add(message);

    // Update unread counts
    final key = '$levelId|$teacherId';
    if (role == 'teacher') {
      _unreadCountsForStudents[key] = (_unreadCountsForStudents[key] ?? 0) + 1;
    } else {
      _unreadCountsForTeacher[key] = (_unreadCountsForTeacher[key] ?? 0) + 1;
    }
    
    return message;
  }

  static int getUnreadCountForStudent(String levelId, String teacherId) {
    return _unreadCountsForStudents['$levelId|$teacherId'] ?? 0;
  }

  static int getUnreadCountForTeacher(String levelId, String teacherId) {
    return _unreadCountsForTeacher['$levelId|$teacherId'] ?? 0;
  }

  static void markAsRead(String levelId, String teacherId, String role) {
    final key = '$levelId|$teacherId';
    if (role == 'teacher') {
      _unreadCountsForTeacher[key] = 0;
    } else {
      _unreadCountsForStudents[key] = 0;
    }
  }

  static int getTotalUnreadForStudent(String levelId) {
    int total = 0;
    _unreadCountsForStudents.forEach((key, count) {
      if (key.startsWith('$levelId|')) {
        total += count;
      }
    });
    return total;
  }

  static int getTotalUnreadForTeacher(String teacherId) {
    int total = 0;
    _unreadCountsForTeacher.forEach((key, count) {
      if (key.endsWith('|$teacherId')) {
        total += count;
      }
    });
    return total;
  }
}
