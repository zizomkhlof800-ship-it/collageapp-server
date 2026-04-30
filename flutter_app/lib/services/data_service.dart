import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:typed_data';
import '../constants/api.dart';
import 'api_service.dart';

enum LibraryMediaType { BOOK, VIDEO_FILE, VIDEO_LINK }

class LibraryBook {
  final String id;
  final String title;
  final String author; // Teacher Name
  final String category; // Default is textbooks
  final String url;
  final String thumbnail;
  final String size;
  final String description;
  final LibraryMediaType mediaType;
  final String? teacherId; // To manage their own books
  final String createdAt;

  LibraryBook({
    required this.id,
    required this.title,
    required this.author,
    this.category = 'textbooks',
    required this.url,
    required this.thumbnail,
    required this.size,
    required this.description,
    this.mediaType = LibraryMediaType.BOOK,
    this.teacherId,
    required this.createdAt,
  });

  factory LibraryBook.fromMap(Map<String, dynamic> map) {
    return LibraryBook(
      id: map['id'] ?? '',
      title: map['title'] ?? '',
      author: map['author'] ?? map['teacherName'] ?? '',
      category: map['category'] ?? 'textbooks',
      url: map['url'] ?? '',
      thumbnail: map['thumbnail'] ?? '',
      size: map['size'] ?? '',
      description: map['description'] ?? '',
      mediaType: _parseMediaType(map['mediaType']),
      teacherId: map['teacherId'],
      createdAt: map['createdAt'] ?? DateTime.now().toIso8601String(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'author': author,
      'category': category,
      'url': url,
      'thumbnail': thumbnail,
      'size': size,
      'description': description,
      'mediaType': mediaType.name,
      'teacherId': teacherId,
      'createdAt': createdAt,
    };
  }

  static LibraryMediaType _parseMediaType(String? type) {
    switch (type) {
      case 'VIDEO_FILE':
        return LibraryMediaType.VIDEO_FILE;
      case 'VIDEO_LINK':
        return LibraryMediaType.VIDEO_LINK;
      case 'BOOK':
      default:
        return LibraryMediaType.BOOK;
    }
  }
}

class Assignment {
  final String id;
  final String title;
  final String description;
  final String deadline;
  final String? pdfUrl;
  final String department;
  final String level;
  final String subject;
  final String teacherName;
  final String createdAt;

  Assignment({
    required this.id,
    required this.title,
    required this.description,
    required this.deadline,
    this.pdfUrl,
    required this.department,
    required this.level,
    required this.subject,
    required this.teacherName,
    required this.createdAt,
  });

  factory Assignment.fromMap(Map<String, dynamic> map) {
    return Assignment(
      id: map['id'] ?? '',
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      deadline: map['deadline'] ?? '',
      pdfUrl: map['pdfUrl'],
      department: map['department'] ?? '',
      level: map['level'] ?? '',
      subject: map['subject'] ?? '',
      teacherName: map['teacherName'] ?? '',
      createdAt: map['createdAt'] ?? '',
    );
  }
}

class AssignmentSubmission {
  final String id;
  final String assignmentId;
  final String studentCode;
  final String studentName;
  final String fileUrl;
  final String? contentText;
  final String submittedAt;
  final double? grade;
  final String? feedback;

  AssignmentSubmission({
    required this.id,
    required this.assignmentId,
    required this.studentCode,
    required this.studentName,
    required this.fileUrl,
    this.contentText,
    required this.submittedAt,
    this.grade,
    this.feedback,
  });

  factory AssignmentSubmission.fromMap(Map<String, dynamic> map) {
    return AssignmentSubmission(
      id: map['id'] ?? '',
      assignmentId: map['assignmentId'] ?? '',
      studentCode: map['studentCode'] ?? '',
      studentName: map['studentName'] ?? '',
      fileUrl: map['fileUrl'] ?? '',
      contentText: map['contentText'],
      submittedAt: map['submittedAt'] ?? '',
      grade: map['grade'] != null
          ? double.tryParse(map['grade'].toString())
          : null,
      feedback: map['feedback'],
    );
  }
}

class AppNotification {
  final String id;
  final String title;
  final String message;
  final String timestamp;
  final String levelId;
  final bool isRead;

  AppNotification({
    required this.id,
    required this.title,
    required this.message,
    required this.timestamp,
    required this.levelId,
    this.isRead = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'message': message,
      'timestamp': timestamp,
      'levelId': levelId,
      'isRead': isRead,
    };
  }

  factory AppNotification.fromMap(Map<String, dynamic> map) {
    return AppNotification(
      id: map['id'] ?? '',
      title: map['title'] ?? '',
      message: map['message'] ?? '',
      timestamp: map['timestamp'] ?? '',
      levelId: map['levelId'] ?? '',
      isRead: map['isRead'] ?? false,
    );
  }

  AppNotification copyWith({
    String? id,
    String? title,
    String? message,
    String? timestamp,
    String? levelId,
    bool? isRead,
  }) {
    return AppNotification(
      id: id ?? this.id,
      title: title ?? this.title,
      message: message ?? this.message,
      timestamp: timestamp ?? this.timestamp,
      levelId: levelId ?? this.levelId,
      isRead: isRead ?? this.isRead,
    );
  }
}

class Announcement {
  final String id;
  final String title;
  final String content;
  final String date;
  final String priority;
  final List<String> readByStudentIds;
  final String imageUrl;
  final String imageName; // for upload only
  final String imageBase64; // for upload only
  final String levelId; // Target level

  Announcement({
    required this.id,
    required this.title,
    required this.content,
    required this.date,
    required this.priority,
    this.readByStudentIds = const [],
    this.imageUrl = '',
    this.imageName = '',
    this.imageBase64 = '',
    this.levelId = '',
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'content': content,
      'date': date,
      'priority': priority,
      'readByStudentIds': readByStudentIds,
      'levelId': levelId,
      if (imageName.isNotEmpty) 'imageName': imageName,
      if (imageBase64.isNotEmpty) 'imageBase64': imageBase64,
    };
  }

  factory Announcement.fromMap(Map<String, dynamic> map) {
    return Announcement(
      id: map['id'] ?? DateTime.now().toString(),
      title: map['title'] ?? '',
      content: map['content'] ?? '',
      date: map['date'] ?? '',
      priority: map['priority'] ?? 'عادي',
      readByStudentIds: List<String>.from(map['readByStudentIds'] ?? []),
      imageUrl: (map['imageUrl'] ?? '').toString(),
      levelId: (map['levelId'] ?? '').toString(),
    );
  }

  Announcement copyWith({
    String? id,
    String? title,
    String? content,
    String? date,
    String? priority,
    List<String>? readByStudentIds,
    String? imageUrl,
    String? imageName,
    String? imageBase64,
    String? levelId,
  }) {
    return Announcement(
      id: id ?? this.id,
      title: title ?? this.title,
      content: content ?? this.content,
      date: date ?? this.date,
      priority: priority ?? this.priority,
      readByStudentIds: readByStudentIds ?? this.readByStudentIds,
      imageUrl: imageUrl ?? this.imageUrl,
      imageName: imageName ?? this.imageName,
      imageBase64: imageBase64 ?? this.imageBase64,
      levelId: levelId ?? this.levelId,
    );
  }
}

class ScheduleItem {
  final String id;
  final String subject;
  final String day; // e.g., "الأحد"
  final String date; // e.g., "2024-05-20"
  final String time; // e.g., "10:00 AM - 12:00 PM"
  final String location; // e.g., "قاعة 1"
  final String department;
  final String level;
  final String imageUrl;
  final bool isExam;

  ScheduleItem({
    required this.id,
    required this.subject,
    this.day = '',
    this.date = '',
    required this.time,
    required this.location,
    required this.department,
    required this.level,
    this.imageUrl = '',
    required this.isExam,
  });
}

class DataService {
  // Singleton pattern
  static final DataService _instance = DataService._internal();
  factory DataService() => _instance;
  DataService._internal();

  // In-memory storage
  final List<Announcement> _announcements = [];
  final List<ScheduleItem> _academicSchedules = [];
  final List<ScheduleItem> _examSchedules = [];
  final List<ExamItem> _exams = [];
  final List<MaterialItem> _materials = [];
  final List<AppNotification> _notifications = [];
  final List<Assignment> _assignments = [];
  final List<AssignmentSubmission> _submissions = [];
  final List<LibraryBook> _libraryBooks = [];

  // Observable for UI updates (simple callback mechanism)
  final List<VoidCallback> _listeners = [];
  Timer? _announcementsTimer;
  Timer? _assignmentsTimer;
  Timer? _libraryTimer;
  Timer? _unreadCountsTimer;
  int _announcementsAutoRefCount = 0;
  int _assignmentsAutoRefCount = 0;
  int _libraryAutoRefCount = 0;

  // Stream Subscriptions
  StreamSubscription? _notificationsSubscription;
  StreamSubscription? _unreadCountsSubscription;
  int _totalUnreadCount = 0;
  int get totalUnreadCount => _totalUnreadCount;

  int _unreadNotificationsCount = 0;
  int get unreadNotificationsCount => _unreadNotificationsCount;

  void addListener(VoidCallback listener) {
    if (_listeners.contains(listener)) return;
    _listeners.add(listener);
  }

  void removeListener(VoidCallback listener) {
    _listeners.remove(listener);
  }

  void _notifyListeners() {
    for (var listener in List<VoidCallback>.from(_listeners)) {
      listener();
    }
  }

  void startLibraryAutoRefresh({
    Duration interval = const Duration(minutes: 5),
  }) {
    _libraryAutoRefCount += 1;
    if (offlineMode) {
      fetchLibraryBooks();
      return;
    }
    if (_libraryTimer != null) return;
    _libraryTimer = Timer.periodic(interval, (_) {
      fetchLibraryBooks();
    });
  }

  void stopLibraryAutoRefresh() {
    _libraryAutoRefCount = (_libraryAutoRefCount - 1).clamp(0, 1 << 30);
    if (_libraryAutoRefCount == 0) {
      _libraryTimer?.cancel();
      _libraryTimer = null;
    }
  }

  Future<void> fetchLibraryBooks() async {
    try {
      final rows = await ApiService.getLibraryBooks();
      _libraryBooks
        ..clear()
        ..addAll(rows.map((m) => LibraryBook.fromMap(m)));
      _notifyListeners();
    } catch (_) {}
  }

  List<LibraryBook> get libraryBooks => List.unmodifiable(_libraryBooks);

  void startNotificationsStream(String levelId) {
    _notificationsSubscription?.cancel();
    _notificationsSubscription = ApiService.getNotificationsStream(levelId)
        .listen((rows) {
          _notifications
            ..clear()
            ..addAll(rows.map((m) => AppNotification.fromMap(m)));
          _unreadNotificationsCount = _notifications
              .where((n) => !n.isRead)
              .length;
          _notifyListeners();
        });
  }

  void stopNotificationsStream() {
    _notificationsSubscription?.cancel();
    _notificationsSubscription = null;
  }

  void startAssignmentsAutoRefresh(
    String department,
    String level, {
    Duration interval = const Duration(seconds: 30),
  }) {
    _assignmentsAutoRefCount += 1;
    if (offlineMode) {
      fetchAssignments(department: department, level: level);
      return;
    }
    if (_assignmentsTimer != null) return;
    _assignmentsTimer = Timer.periodic(interval, (_) {
      fetchAssignments(department: department, level: level);
    });
  }

  void stopAssignmentsAutoRefresh() {
    _assignmentsAutoRefCount = (_assignmentsAutoRefCount - 1).clamp(0, 1 << 30);
    if (_assignmentsAutoRefCount == 0) {
      _assignmentsTimer?.cancel();
      _assignmentsTimer = null;
    }
  }

  Future<void> fetchAssignments({
    required String department,
    required String level,
  }) async {
    try {
      final rows = await ApiService.getAssignments(
        department: department,
        level: level,
      );
      _assignments
        ..clear()
        ..addAll(rows.map((m) => Assignment.fromMap(m)));
      _notifyListeners();
    } catch (_) {}
  }

  Future<void> fetchSubmissions(String assignmentId) async {
    try {
      final rows = await ApiService.getSubmissions(assignmentId);
      _submissions
        ..clear()
        ..addAll(rows.map((m) => AssignmentSubmission.fromMap(m)));
      _notifyListeners();
    } catch (_) {}
  }

  Future<AssignmentSubmission?> fetchStudentSubmission(
    String assignmentId,
    String studentCode,
  ) async {
    try {
      final data = await ApiService.getStudentSubmission(
        assignmentId,
        studentCode,
      );
      if (data != null) {
        return AssignmentSubmission.fromMap(data);
      }
    } catch (_) {}
    return null;
  }

  Future<void> addAssignment({
    required String title,
    required String description,
    required String deadline,
    required String department,
    required String level,
    required String subject,
    required String teacherName,
    String? pdfUrl,
    Uint8List? fileBytes,
    String? fileName,
  }) async {
    final payload = {
      'title': title,
      'description': description,
      'deadline': deadline,
      'department': department,
      'level': level,
      'subject': subject,
      'teacherName': teacherName,
      'pdfUrl': pdfUrl,
      'fileBytes': fileBytes,
      'fileName': fileName,
      'createdAt': DateTime.now().toIso8601String(),
    };
    await ApiService.addAssignment(payload);
    unawaited(fetchAssignments(department: department, level: level));
  }

  Future<void> submitAssignment({
    required String assignmentId,
    required String studentCode,
    required String studentName,
    required String fileUrl,
    String? contentText,
    Uint8List? fileBytes,
  }) async {
    final payload = {
      'assignmentId': assignmentId,
      'studentCode': studentCode,
      'studentName': studentName,
      'fileUrl': fileUrl,
      'contentText': contentText,
      'fileBytes': fileBytes, // Pass bytes to API
      'submittedAt': DateTime.now().toIso8601String(),
    };
    await ApiService.submitAssignment(payload);
  }

  Future<void> gradeSubmission({
    required String submissionId,
    required double grade,
    required String feedback,
  }) async {
    await ApiService.gradeSubmission(submissionId, grade, feedback);
  }

  List<Assignment> get assignments => List.unmodifiable(_assignments);
  List<AssignmentSubmission> get submissions => List.unmodifiable(_submissions);

  Future<void> fetchNotifications({required String levelId}) async {
    try {
      final rows = await ApiService.getNotifications(levelId: levelId);
      _notifications
        ..clear()
        ..addAll(rows.map((m) => AppNotification.fromMap(m)));

      _unreadNotificationsCount = _notifications.where((n) => !n.isRead).length;
      _notifyListeners();
    } catch (_) {}
  }

  Future<void> markNotificationsAsRead(String levelId) async {
    try {
      await ApiService.markNotificationsAsRead(levelId);
      for (int i = 0; i < _notifications.length; i++) {
        _notifications[i] = _notifications[i].copyWith(isRead: true);
      }
      _unreadNotificationsCount = 0;
      _notifyListeners();
    } catch (_) {}
  }

  List<AppNotification> get notifications => List.unmodifiable(_notifications);

  void startAnnouncementsAutoRefresh({
    Duration interval = const Duration(seconds: 20),
  }) {
    _announcementsAutoRefCount += 1;
    if (offlineMode) {
      fetchAnnouncements();
      return;
    }
    if (_announcementsTimer != null) return;
    _announcementsTimer = Timer.periodic(interval, (_) {
      fetchAnnouncements();
    });
  }

  void stopAnnouncementsAutoRefresh() {
    _announcementsAutoRefCount = (_announcementsAutoRefCount - 1).clamp(
      0,
      1 << 30,
    );
    if (_announcementsAutoRefCount == 0) {
      _announcementsTimer?.cancel();
      _announcementsTimer = null;
    }
  }

  Future<void> fetchTotalUnreadCount(String id, String role) async {
    try {
      final count = await ApiService.getTotalUnreadCount(id, role);
      if (_totalUnreadCount != count) {
        _totalUnreadCount = count;
        _notifyListeners();
      }
    } catch (_) {}
  }

  void startUnreadCountsAutoRefresh(
    String id,
    String role, {
    Duration interval = const Duration(seconds: 30),
  }) {
    if (offlineMode) {
      fetchTotalUnreadCount(id, role);
      return;
    }
    _unreadCountsTimer?.cancel();
    _unreadCountsTimer = Timer.periodic(interval, (_) {
      fetchTotalUnreadCount(id, role);
    });
  }

  void stopUnreadCountsAutoRefresh() {
    _unreadCountsTimer?.cancel();
    _unreadCountsTimer = null;
  }

  void startUnreadCountsStream(String id, String role) {
    _unreadCountsSubscription?.cancel();
    _unreadCountsSubscription = ApiService.getTotalUnreadCountStream(id, role)
        .listen((count) {
          if (_totalUnreadCount != count) {
            _totalUnreadCount = count;
            _notifyListeners();
          }
        });
  }

  void stopUnreadCountsStream() {
    _unreadCountsSubscription?.cancel();
    _unreadCountsSubscription = null;
  }

  Stream<List<Map<String, dynamic>>> getChatStream(
    String levelId, {
    String? teacherId,
  }) {
    return ApiService.getLevelMessagesStream(levelId, teacherId: teacherId);
  }

  Future<void> fetchAnnouncements({String? levelId}) async {
    try {
      final rows = await ApiService.getAnnouncements(levelId: levelId);
      _announcements
        ..clear()
        ..addAll(
          rows.map(
            (m) => Announcement.fromMap({
              'id': (m['_id'] ?? m['id'] ?? '').toString(),
              'title': m['title'] ?? '',
              'content': m['content'] ?? '',
              'date': m['date'] ?? '',
              'priority': m['priority'] ?? 'عادي',
              'readByStudentIds': (m['readByStudentIds'] ?? const []),
              'imageUrl': (m['imageUrl'] ?? '').toString(),
              'levelId': (m['levelId'] ?? '').toString(),
            }),
          ),
        );
      _notifyListeners();
    } catch (_) {}
  }

  // Exams
  List<ExamItem> get exams => List.unmodifiable(_exams);

  Future<void> fetchExams() async {
    try {
      final rows = await ApiService.getExams();
      _exams
        ..clear()
        ..addAll(rows.map((m) => ExamItem.fromMap(m)));
      _notifyListeners();
    } catch (_) {}
  }

  Future<void> addExam({
    required String subject,
    required String department,
    required String level,
    required List<Map<String, dynamic>> questions,
    required int tfCount,
    required int mcqCount,
    String? startTime,
    String? endTime,
    int? durationMinutes,
    bool isFromBank = false,
  }) async {
    final payload = {
      'subject': subject,
      'department': department,
      'level': level,
      'questions': questions,
      'tfCount': tfCount,
      'mcqCount': mcqCount,
      'startTime': startTime,
      'endTime': endTime,
      'durationMinutes': durationMinutes,
      'isFromBank': isFromBank,
    };
    final id = await ApiService.addExam(payload);
    _exams.insert(
      0,
      ExamItem(
        id: id,
        subject: subject,
        department: department,
        level: level,
        tfCount: tfCount,
        mcqCount: mcqCount,
        createdAt: DateTime.now().toIso8601String(),
        startTime: startTime,
        endTime: endTime,
        durationMinutes: durationMinutes,
        isFromBank: isFromBank,
      ),
    );
    _notifyListeners();
  }

  Future<void> updateExam({
    required String id,
    required String subject,
    required String department,
    required String level,
    required List<Map<String, dynamic>> questions,
    required int tfCount,
    required int mcqCount,
    String? startTime,
    String? endTime,
    int? durationMinutes,
    bool isFromBank = false,
  }) async {
    await ApiService.updateExam(id, {
      'subject': subject,
      'department': department,
      'level': level,
      'questions': questions,
      'tfCount': tfCount,
      'mcqCount': mcqCount,
      'startTime': startTime,
      'endTime': endTime,
      'durationMinutes': durationMinutes,
      'isFromBank': isFromBank,
    });
    final idx = _exams.indexWhere((e) => e.id == id);
    if (idx != -1) {
      _exams[idx] = ExamItem(
        id: id,
        subject: subject,
        department: department,
        level: level,
        tfCount: tfCount,
        mcqCount: mcqCount,
        createdAt: _exams[idx].createdAt,
        startTime: startTime,
        endTime: endTime,
        durationMinutes: durationMinutes,
        isFromBank: isFromBank,
      );
      _notifyListeners();
    } else {
      await fetchExams();
    }
  }

  Future<void> deleteExam(String id) async {
    await ApiService.deleteExam(id);
    _exams.removeWhere((e) => e.id == id);
    _notifyListeners();
  }

  // Announcement Methods
  List<Announcement> get announcements => List.unmodifiable(_announcements);

  Future<void> addAnnouncement(Announcement announcement) async {
    final resp = await ApiService.addAnnouncement(announcement.toMap());
    final id = (resp['id'] ?? '').toString();
    final imageUrl = (resp['imageUrl'] ?? '').toString();
    _announcements.insert(0, announcement.copyWith(id: id, imageUrl: imageUrl));
    _notifyListeners();
  }

  Future<void> deleteAnnouncement(String id) async {
    await ApiService.deleteAnnouncement(id);
    _announcements.removeWhere((a) => a.id == id);
    _notifyListeners();
  }

  Future<void> markAnnouncementAsRead(
    String announcementId,
    String studentId,
  ) async {
    await ApiService.markAnnouncementRead(announcementId, studentId);
    final index = _announcements.indexWhere((a) => a.id == announcementId);
    if (index != -1) {
      final announcement = _announcements[index];
      if (!announcement.readByStudentIds.contains(studentId)) {
        final updatedReadList = List<String>.from(announcement.readByStudentIds)
          ..add(studentId);
        _announcements[index] = announcement.copyWith(
          readByStudentIds: updatedReadList,
        );
        _notifyListeners();
      }
    }
  }

  bool isAnnouncementRead(String announcementId, String studentId) {
    final announcement = _announcements.firstWhere(
      (a) => a.id == announcementId,
      orElse: () =>
          Announcement(id: '', title: '', content: '', date: '', priority: ''),
    );
    if (announcement.id.isEmpty) return false;
    return announcement.readByStudentIds.contains(studentId);
  }

  // Schedule Methods
  List<ScheduleItem> get academicSchedules =>
      List.unmodifiable(_academicSchedules);
  List<ScheduleItem> get examSchedules => List.unmodifiable(_examSchedules);

  Future<void> addSchedule(ScheduleItem item) async {
    try {
      await ApiService.addSchedule({
        'id': item.id,
        'subject': item.subject,
        'day': item.day,
        'date': item.date,
        'time': item.time,
        'location': item.location,
        'department': item.department,
        'level': item.level,
        'imageUrl': item.imageUrl,
        'isExam': item.isExam,
      });
      await fetchSchedules(department: item.department, level: item.level);
    } catch (e) {
      debugPrint("Error adding schedule: $e");
    }
  }

  Future<void> deleteSchedule(
    String id,
    bool isExam,
    String department,
    String level,
  ) async {
    await ApiService.deleteSchedule(id);
    await fetchSchedules(department: department, level: level);
  }

  Future<void> updateScheduleItem(
    String id,
    Map<String, dynamic> payload,
    String department,
    String level,
  ) async {
    try {
      await ApiService.updateSchedule(id, payload);
      await fetchSchedules(department: department, level: level);
    } catch (e) {
      debugPrint("Error updating schedule item: $e");
    }
  }

  Future<void> fetchSchedules({
    required String department,
    required String level,
  }) async {
    try {
      final rows = await ApiService.getSchedules(department, level);
      final items = rows.map(
        (m) => ScheduleItem(
          id: (m['id'] ?? '').toString(),
          subject: (m['subject'] ?? m['imageName'] ?? '').toString(),
          day: (m['day'] ?? '').toString(),
          date: (m['date'] ?? '').toString(),
          time: (m['time'] ?? '').toString(),
          location: (m['location'] ?? '').toString(),
          department: (m['department'] ?? '').toString(),
          level: (m['level'] ?? '').toString(),
          imageUrl: (m['imageUrl'] ?? '').toString(),
          isExam: (m['isExam'] ?? false),
        ),
      );
      _academicSchedules
        ..clear()
        ..addAll(items.where((i) => !i.isExam));
      _examSchedules
        ..clear()
        ..addAll(items.where((i) => i.isExam));
      _notifyListeners();
    } catch (_) {}
  }

  // Materials Methods
  List<MaterialItem> get materials => List.unmodifiable(_materials);

  Future<void> fetchMaterials({
    String department = '',
    String level = '',
    String subject = '',
  }) async {
    try {
      final rows = await ApiService.getMaterials(
        department: department,
        level: level,
        subject: subject,
      );
      _materials
        ..clear()
        ..addAll(
          rows.map(
            (m) => MaterialItem(
              id: (m['_id'] ?? m['id'] ?? '').toString(),
              url: (m['url'] ?? '').toString(),
              originalName: (m['originalName'] ?? '').toString(),
              department: (m['department'] ?? '').toString(),
              level: (m['level'] ?? '').toString(),
              subject: (m['subject'] ?? '').toString(),
              teacherName: (m['teacherName'] ?? '').toString(),
              uploadedAt: (m['uploadedAt'] ?? '').toString(),
            ),
          ),
        );
      _notifyListeners();
    } catch (_) {}
  }

  Future<void> addMaterial({
    required String department,
    required String level,
    required String subject,
    required String teacherName,
    required String fileName,
    required String fileBase64,
  }) async {
    await ApiService.addMaterialPdf(
      department: department,
      level: level,
      subject: subject,
      teacherName: teacherName,
      fileName: fileName,
      fileBase64: fileBase64,
    );
    unawaited(
      fetchMaterials(department: department, level: level, subject: subject),
    );
  }

  Future<void> deleteMaterial(String id) async {
    await ApiService.deleteMaterial(id);
    _materials.removeWhere((m) => m.id == id);
    _notifyListeners();
  }

  Future<void> addExamResult({
    required String studentCode,
    required String examId,
    required String department,
    required String level,
    required int correct,
    required int wrong,
    required int total,
    required double score,
    required String submittedAt,
  }) async {
    await ApiService.addExamResult({
      'studentCode': studentCode,
      'examId': examId,
      'department': department,
      'level': level,
      'correct': correct,
      'wrong': wrong,
      'total': total,
      'score': score,
      'submittedAt': submittedAt,
    });
  }

  Future<List<Map<String, dynamic>>> getQuestionsFromBank({
    required String department,
    required String level,
    required String subject,
    String? type,
  }) async {
    return await ApiService.getQuestionsFromBank(
      department: department,
      level: level,
      subject: subject,
      type: type,
    );
  }

  Future<void> addQuestionToBank(Map<String, dynamic> question) async {
    await ApiService.addQuestionToBank(question);
  }

  Future<void> deleteQuestionFromBank(String id) async {
    await ApiService.deleteQuestionFromBank(id);
  }
}

class MaterialItem {
  final String id;
  final String url;
  final String originalName;
  final String department;
  final String level;
  final String subject;
  final String teacherName;
  final String uploadedAt;

  MaterialItem({
    required this.id,
    required this.url,
    required this.originalName,
    required this.department,
    required this.level,
    required this.subject,
    required this.teacherName,
    required this.uploadedAt,
  });
}

class ExamItem {
  final String id;
  final String subject;
  final String department;
  final String level;
  final int tfCount;
  final int mcqCount;
  final String createdAt;
  final List<Map<String, dynamic>> questions;
  final String? startTime;
  final String? endTime;
  final int? durationMinutes;
  final bool isFromBank;

  ExamItem({
    required this.id,
    required this.subject,
    required this.department,
    required this.level,
    required this.tfCount,
    required this.mcqCount,
    required this.createdAt,
    this.questions = const [],
    this.startTime,
    this.endTime,
    this.durationMinutes,
    this.isFromBank = false,
  });

  factory ExamItem.fromMap(Map<String, dynamic> map) {
    return ExamItem(
      id: (map['id'] ?? map['_id'] ?? '').toString(),
      subject: map['subject'] ?? '',
      department: map['department'] ?? '',
      level: map['level'] ?? '',
      tfCount: int.tryParse((map['tfCount'] ?? 0).toString()) ?? 0,
      mcqCount: int.tryParse((map['mcqCount'] ?? 0).toString()) ?? 0,
      createdAt: map['createdAt'] ?? '',
      questions: List<Map<String, dynamic>>.from(map['questions'] ?? []),
      startTime: map['startTime'],
      endTime: map['endTime'],
      durationMinutes: map['durationMinutes'] != null
          ? int.tryParse(map['durationMinutes'].toString())
          : null,
      isFromBank: (map['isFromBank'] ?? false) == true,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'subject': subject,
      'department': department,
      'level': level,
      'tfCount': tfCount,
      'mcqCount': mcqCount,
      'createdAt': createdAt,
      'questions': questions,
      'startTime': startTime,
      'endTime': endTime,
      'durationMinutes': durationMinutes,
      'isFromBank': isFromBank,
    };
  }

  ExamItem copyWith({
    String? id,
    String? subject,
    String? department,
    String? level,
    int? tfCount,
    int? mcqCount,
    String? createdAt,
    List<Map<String, dynamic>>? questions,
    String? startTime,
    String? endTime,
    int? durationMinutes,
    bool? isFromBank,
  }) {
    return ExamItem(
      id: id ?? this.id,
      subject: subject ?? this.subject,
      department: department ?? this.department,
      level: level ?? this.level,
      tfCount: tfCount ?? this.tfCount,
      mcqCount: mcqCount ?? this.mcqCount,
      createdAt: createdAt ?? this.createdAt,
      questions: questions ?? this.questions,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      isFromBank: isFromBank ?? this.isFromBank,
    );
  }
}
