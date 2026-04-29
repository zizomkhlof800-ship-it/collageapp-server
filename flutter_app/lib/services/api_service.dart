import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../constants/api.dart';
import '../models/teacher_model.dart';
import 'mock_data_service.dart';

class ApiService {
  static final StreamController<void> _changes =
      StreamController<void>.broadcast();
  static final Map<String, Map<String, dynamic>> _activeSessions = {};
  static bool _changeQueued = false;

  static Future<bool> testConnection() async {
    if (!offlineMode && baseUrl.isNotEmpty) {
      try {
        final response = await http
            .get(Uri.parse('$baseUrl/health'))
            .timeout(const Duration(seconds: 4));
        return response.statusCode >= 200 && response.statusCode < 300;
      } catch (_) {
        return false;
      }
    }
    await _OfflineStore.ensureReady();
    return true;
  }

  static Future<int?> dbHealthState() async {
    await _OfflineStore.ensureReady();
    return 1;
  }

  static void _emitChange() {
    if (_changeQueued || _changes.isClosed) return;
    _changeQueued = true;
    scheduleMicrotask(() {
      _changeQueued = false;
      if (!_changes.isClosed) _changes.add(null);
    });
  }

  static String _newId(String prefix) =>
      '$prefix-${DateTime.now().microsecondsSinceEpoch}';

  static String _nowIso() => DateTime.now().toIso8601String();

  static String _today() => DateTime.now().toIso8601String().split('T').first;

  static String _levelId(String department, String level) =>
      '${department}__$level';

  static int _compareDesc(
    Map<String, dynamic> a,
    Map<String, dynamic> b,
    String field,
  ) {
    final av = (a[field] ?? '').toString();
    final bv = (b[field] ?? '').toString();
    return bv.compareTo(av);
  }

  static Map<String, dynamic> _mapOf(Map<dynamic, dynamic> map) {
    return map.map((key, value) => MapEntry(key.toString(), _jsonSafe(value)));
  }

  static List<Map<String, dynamic>> _rowsOf(
    Iterable<Map<dynamic, dynamic>> rows,
  ) {
    return rows.map(_mapOf).toList();
  }

  static dynamic _jsonSafe(dynamic value) {
    if (value is Uint8List) return base64Encode(value);
    if (value is DateTime) return value.toIso8601String();
    if (value is Map) {
      return value.map(
        (key, item) => MapEntry(key.toString(), _jsonSafe(item)),
      );
    }
    if (value is Iterable) return value.map(_jsonSafe).toList();
    return value;
  }

  static List<String> _stringList(dynamic value) {
    if (value is List) return value.map((item) => item.toString()).toList();
    return <String>[];
  }

  static String _mimeForFile(
    String fileName, {
    String fallback = 'application/octet-stream',
  }) {
    final lower = fileName.toLowerCase();
    if (lower.endsWith('.pdf')) return 'application/pdf';
    if (lower.endsWith('.png')) return 'image/png';
    if (lower.endsWith('.jpg') || lower.endsWith('.jpeg')) return 'image/jpeg';
    if (lower.endsWith('.gif')) return 'image/gif';
    if (lower.endsWith('.webp')) return 'image/webp';
    if (lower.endsWith('.mp4')) return 'video/mp4';
    if (lower.endsWith('.mov')) return 'video/quicktime';
    return fallback;
  }

  static String _offlineUrlFromBytes(
    dynamic bytes, {
    required String fileName,
    String fallback = '',
  }) {
    final mime = _mimeForFile(fileName);
    if (bytes is Uint8List && bytes.isNotEmpty) {
      return 'data:$mime;base64,${base64Encode(bytes)}';
    }
    if (bytes is List<int> && bytes.isNotEmpty) {
      return 'data:$mime;base64,${base64Encode(bytes)}';
    }
    return fallback;
  }

  static String _offlineUrlFromBase64(
    dynamic value, {
    required String fileName,
    String fallback = '',
  }) {
    final raw = (value ?? '').toString().trim();
    if (raw.isEmpty) return fallback;
    if (raw.startsWith('data:')) return raw;
    return 'data:${_mimeForFile(fileName)};base64,$raw';
  }

  static bool _matchesLevel(Map<String, dynamic> row, String? levelId) {
    if (levelId == null || levelId.isEmpty) return true;
    final rowLevelId = (row['levelId'] ?? '').toString();
    if (rowLevelId.isEmpty) return true;
    return rowLevelId == levelId;
  }

  static Future<List<Map<String, dynamic>>> _students() {
    return _OfflineStore.list('students', () {
      return _rowsOf(MockDataService.students.map(_normalizeStudent));
    });
  }

  static Future<List<Map<String, dynamic>>> _teachers() {
    return _OfflineStore.list('teachers', () {
      return MockDataService.teachers
          .map((teacher) => teacher.toMap())
          .toList();
    });
  }

  static Future<List<Map<String, dynamic>>> _announcements() {
    return _OfflineStore.list('announcements', () {
      return _rowsOf(
        MockDataService.announcements.map((row) {
          return {
            ...row,
            'likes': row['likes'] ?? <String>[],
            'comments': row['comments'] ?? <Map<String, dynamic>>[],
            'levelId': row['levelId'] ?? '',
          };
        }),
      );
    });
  }

  static Future<List<Map<String, dynamic>>> _schedules() {
    return _OfflineStore.list(
      'schedules',
      () => _rowsOf(MockDataService.schedules),
    );
  }

  static Future<List<Map<String, dynamic>>> _exams() {
    return _OfflineStore.list('exams', () => _rowsOf(MockDataService.exams));
  }

  static Future<List<Map<String, dynamic>>> _materials() {
    return _OfflineStore.list(
      'materials',
      () => _rowsOf(MockDataService.materials),
    );
  }

  static Future<List<Map<String, dynamic>>> _attendance() {
    return _OfflineStore.list(
      'attendance',
      () => _rowsOf(MockDataService.attendanceRecords),
    );
  }

  static Future<List<Map<String, dynamic>>> _examResults() {
    return _OfflineStore.list(
      'exam_results',
      () => _rowsOf(MockDataService.examResults),
    );
  }

  static Future<List<Map<String, dynamic>>> _questionBank() {
    return _OfflineStore.list(
      'question_bank',
      () => _rowsOf(MockDataService.questionBank),
    );
  }

  static Future<List<Map<String, dynamic>>> _notifications() {
    return _OfflineStore.list(
      'notifications',
      () => _rowsOf(MockDataService.notifications),
    );
  }

  static Future<List<Map<String, dynamic>>> _assignments() {
    return _OfflineStore.list(
      'assignments',
      () => _rowsOf(MockDataService.assignments),
    );
  }

  static Future<List<Map<String, dynamic>>> _submissions() {
    return _OfflineStore.list(
      'submissions',
      () => _rowsOf(MockDataService.submissions),
    );
  }

  static Future<List<Map<String, dynamic>>> _libraryBooks() {
    return _OfflineStore.list(
      'library',
      () => _rowsOf(MockDataService.libraryBooks),
    );
  }

  static Future<List<Map<String, dynamic>>> _messages() {
    return _OfflineStore.list('messages', () => <Map<String, dynamic>>[]);
  }

  static Future<void> _save(String key, List<Map<String, dynamic>> rows) async {
    await _OfflineStore.save(key, rows);
    _emitChange();
  }

  static Map<String, dynamic> _normalizeStudent(Map<dynamic, dynamic> raw) {
    final code = (raw['studentCode'] ?? raw['code'] ?? raw['id'] ?? '')
        .toString();
    final name = (raw['fullName'] ?? raw['name'] ?? '').toString();
    return _mapOf({
      ...raw,
      'id': code,
      'studentCode': code,
      'code': code,
      'fullName': name,
      'name': name,
      'allowedAccess': raw['allowedAccess'] ?? true,
    });
  }

  static Map<String, dynamic> _normalizeTeacher(Map<dynamic, dynamic> raw) {
    final id = (raw['id'] ?? raw['_id'] ?? _newId('teacher')).toString();
    return _mapOf({
      ...raw,
      'id': id,
      'courses': (raw['courses'] as List? ?? const []).map((course) {
        return course is Course ? course.toMap() : _mapOf(course as Map);
      }).toList(),
    });
  }

  static Stream<List<Map<String, dynamic>>> _watchList(
    Future<List<Map<String, dynamic>>> Function() loader,
  ) async* {
    yield await loader();
    await for (final _ in _changes.stream) {
      yield await loader();
    }
  }

  static Stream<int> _watchInt(Future<int> Function() loader) async* {
    yield await loader();
    await for (final _ in _changes.stream) {
      yield await loader();
    }
  }

  static Future<Map<String, dynamic>> resolveSession(String code) async {
    final raw = code.trim();
    final uri = Uri.tryParse(raw);
    final lectureIdFromUrl = uri?.queryParameters['lectureId'];
    if (lectureIdFromUrl != null && lectureIdFromUrl.isNotEmpty) {
      return {
        'lectureId': lectureIdFromUrl,
        'subjectId': uri?.queryParameters['subjectId'] ?? 'offline-subject',
        'teacherId': uri?.queryParameters['teacherId'] ?? 'teacher-1',
      };
    }

    final now = DateTime.now().millisecondsSinceEpoch;
    for (final session in _activeSessions.values) {
      final sessionCode = (session['code'] ?? '').toString();
      final expiresAt =
          int.tryParse((session['expiresAt'] ?? 0).toString()) ?? 0;
      if (sessionCode == raw && expiresAt > now) {
        return Map<String, dynamic>.from(session);
      }
    }

    return {
      'lectureId': 'lecture-$raw',
      'subjectId': 'offline-subject',
      'teacherId': 'teacher-1',
    };
  }

  static Future<void> markAttendance({
    required String lectureId,
    required String studentId,
    required String name,
    required String department,
    required String level,
    required String status,
    required String levelId,
    required String subjectId,
    required String teacherId,
  }) async {
    final rows = await _attendance();
    final existing = rows.indexWhere((row) {
      return row['lectureId'] == lectureId &&
          row['studentCode'].toString() == studentId;
    });
    final record = {
      'id': existing == -1 ? _newId('attendance') : rows[existing]['id'],
      'studentCode': studentId,
      'studentName': name,
      'name': name,
      'department': department,
      'level': level,
      'lectureId': lectureId,
      'levelId': levelId,
      'subjectId': subjectId,
      'teacherId': teacherId,
      'status': 'Present',
      'timestamp': _nowIso(),
    };
    if (existing == -1) {
      rows.add(record);
    } else {
      rows[existing] = record;
    }
    await _save('attendance', rows);
  }

  static Future<List<Map<String, dynamic>>> getCumulativeAttendance(
    String levelId,
  ) async {
    final rows = await _attendance();
    final students = await getStudents(
      department: levelId.contains('__') ? levelId.split('__').first : null,
      level: levelId.contains('__') ? levelId.split('__').last : null,
    );
    final levelRows = rows.where((row) => row['levelId'] == levelId).toList();
    final totalLectures = levelRows
        .map((row) => row['lectureId'])
        .toSet()
        .length;

    return students.map((student) {
      final code = (student['studentCode'] ?? student['code'] ?? '').toString();
      final presentCount = levelRows.where((row) {
        return row['studentCode'].toString() == code &&
            row['status'] == 'Present';
      }).length;
      return {
        'studentCode': code,
        'studentName': student['fullName'] ?? student['name'] ?? '',
        'totalLectures': totalLectures,
        'presentCount': presentCount,
        'percentage': totalLectures > 0
            ? (presentCount / totalLectures * 100)
            : 0.0,
      };
    }).toList();
  }

  static Future<List<Map<String, dynamic>>> getAttendanceByLecture(
    String lectureId,
  ) async {
    final rows = await _attendance();
    return rows.where((row) {
      return row['lectureId'] == lectureId &&
          (row['status'] ?? '') == 'Present';
    }).toList();
  }

  static Future<void> clearAttendanceByLecture(String lectureId) async {
    final rows = await _attendance();
    rows.removeWhere((row) => row['lectureId'] == lectureId);
    await _save('attendance', rows);
  }

  static Future<void> deleteAttendanceStudent(
    String lectureId,
    String studentCode,
  ) async {
    final rows = await _attendance();
    rows.removeWhere((row) {
      return row['lectureId'] == lectureId &&
          row['studentCode'].toString() == studentCode;
    });
    await _save('attendance', rows);
  }

  static Future<void> clearAllAttendance() async {
    await _save('attendance', <Map<String, dynamic>>[]);
  }

  static Future<Map<String, dynamic>> getExamById(String id) async {
    final exams = await _exams();
    return exams.firstWhere(
      (exam) => (exam['id'] ?? exam['_id'] ?? '').toString() == id,
      orElse: () => <String, dynamic>{},
    );
  }

  static Future<List<Map<String, dynamic>>> getAnnouncements({
    String? levelId,
  }) async {
    final rows = await _announcements();
    final filtered = rows.where((row) => _matchesLevel(row, levelId)).toList();
    filtered.sort((a, b) => _compareDesc(a, b, 'date'));
    return filtered;
  }

  static Future<Map<String, dynamic>> getAnnouncementById(String id) async {
    final rows = await _announcements();
    return rows.firstWhere(
      (row) => (row['id'] ?? row['_id'] ?? '').toString() == id,
      orElse: () => <String, dynamic>{},
    );
  }

  static Future<Map<String, dynamic>> likeAnnouncement(
    String id,
    String userId,
  ) async {
    final rows = await _announcements();
    final index = rows.indexWhere(
      (row) => (row['id'] ?? row['_id'] ?? '').toString() == id,
    );
    if (index == -1) return {'success': false};

    final likes = _stringList(rows[index]['likes']);
    likes.contains(userId) ? likes.remove(userId) : likes.add(userId);
    rows[index]['likes'] = likes;
    await _save('announcements', rows);
    return {'success': true, 'likes': likes};
  }

  static Future<Map<String, dynamic>> commentOnAnnouncement({
    required String id,
    required String userId,
    required String userType,
    required String name,
    required String text,
  }) async {
    final rows = await _announcements();
    final index = rows.indexWhere(
      (row) => (row['id'] ?? row['_id'] ?? '').toString() == id,
    );
    if (index == -1) return {'success': false};

    final comments = List<Map<String, dynamic>>.from(
      rows[index]['comments'] ?? const [],
    );
    final comment = {
      'id': _newId('comment'),
      'userId': userId,
      'userType': userType,
      'name': name,
      'text': text,
      'createdAt': _nowIso(),
    };
    comments.add(comment);
    rows[index]['comments'] = comments;
    await _save('announcements', rows);
    return {'success': true, 'comment': comment};
  }

  static Future<void> editAnnouncementComment({
    required String id,
    required String commentId,
    required String userId,
    required String userType,
    required String text,
  }) async {
    final rows = await _announcements();
    final annIndex = rows.indexWhere(
      (row) => (row['id'] ?? row['_id'] ?? '').toString() == id,
    );
    if (annIndex == -1) return;

    final comments = List<Map<String, dynamic>>.from(
      rows[annIndex]['comments'] ?? const [],
    );
    final commentIndex = comments.indexWhere(
      (comment) => (comment['id'] ?? '').toString() == commentId,
    );
    if (commentIndex == -1) return;
    final owner = (comments[commentIndex]['userId'] ?? '').toString();
    if (userType != 'admin' && userType != 'teacher' && owner != userId) return;

    comments[commentIndex] = {
      ...comments[commentIndex],
      'text': text,
      'updatedAt': _nowIso(),
    };
    rows[annIndex]['comments'] = comments;
    await _save('announcements', rows);
  }

  static Future<void> deleteAnnouncementComment({
    required String id,
    required String commentId,
    required String userId,
    required String userType,
  }) async {
    final rows = await _announcements();
    final annIndex = rows.indexWhere(
      (row) => (row['id'] ?? row['_id'] ?? '').toString() == id,
    );
    if (annIndex == -1) return;

    final comments = List<Map<String, dynamic>>.from(
      rows[annIndex]['comments'] ?? const [],
    );
    comments.removeWhere((comment) {
      final owner = (comment['userId'] ?? '').toString();
      final canDelete =
          userType == 'admin' || userType == 'teacher' || owner == userId;
      return canDelete && (comment['id'] ?? '').toString() == commentId;
    });
    rows[annIndex]['comments'] = comments;
    await _save('announcements', rows);
  }

  static Future<String?> resolveStudentCodeFromScan(String value) async {
    final clean = value.trim();
    if (RegExp(r'^\d{6,}$').hasMatch(clean)) return clean;
    final match = RegExp(r'([0-9]{6,})').firstMatch(clean);
    return match?.group(1);
  }

  static Future<void> markNotificationsAsRead(String levelId) async {
    final rows = await _notifications();
    for (final row in rows) {
      if ((row['levelId'] ?? '').toString().isEmpty ||
          row['levelId'] == levelId) {
        row['isRead'] = true;
      }
    }
    await _save('notifications', rows);
  }

  static Future<List<Map<String, dynamic>>> getNotifications({
    required String levelId,
  }) async {
    final rows = await _notifications();
    final filtered = rows.where((row) {
      final rowLevel = (row['levelId'] ?? '').toString();
      return rowLevel.isEmpty || rowLevel == levelId;
    }).toList();
    filtered.sort((a, b) => _compareDesc(a, b, 'timestamp'));
    return filtered.take(50).toList();
  }

  static Future<void> addNotification({
    required String title,
    required String message,
    required String levelId,
  }) async {
    final rows = await _notifications();
    rows.insert(0, {
      'id': _newId('notification'),
      'title': title,
      'message': message,
      'levelId': levelId,
      'timestamp': _nowIso(),
      'isRead': false,
    });
    await _save('notifications', rows);
  }

  static Future<void> addAssignment(Map<String, dynamic> payload) async {
    final rows = await _assignments();
    final fileName = (payload['fileName'] ?? 'assignment.pdf').toString();
    final pdfUrl = _offlineUrlFromBytes(
      payload['fileBytes'],
      fileName: fileName,
      fallback: (payload['pdfUrl'] ?? '').toString(),
    );
    rows.insert(0, {
      ..._mapOf(payload),
      'id': _newId('assignment'),
      'pdfUrl': pdfUrl,
      'fileBytes': null,
      'fileName': fileName,
      'createdAt': payload['createdAt'] ?? _nowIso(),
    });
    await _save('assignments', rows);
    await addNotification(
      title: 'New assignment: ${payload['title'] ?? ''}',
      message: '${payload['subject'] ?? ''} - ${payload['deadline'] ?? ''}',
      levelId: _levelId(
        (payload['department'] ?? '').toString(),
        (payload['level'] ?? '').toString(),
      ),
    );
  }

  static Future<List<Map<String, dynamic>>> getAssignments({
    required String department,
    required String level,
  }) async {
    final rows = await _assignments();
    final filtered = rows.where((row) {
      return row['department'] == department && row['level'] == level;
    }).toList();
    filtered.sort((a, b) => _compareDesc(a, b, 'createdAt'));
    return filtered;
  }

  static Future<void> submitAssignment(Map<String, dynamic> payload) async {
    final rows = await _submissions();
    final fileName =
        (payload['fileName'] ?? 'submission_${payload['studentCode']}.pdf')
            .toString();
    final fileUrl = _offlineUrlFromBytes(
      payload['fileBytes'],
      fileName: fileName,
      fallback: (payload['fileUrl'] ?? '').toString(),
    );
    rows.insert(0, {
      ..._mapOf(payload),
      'id': _newId('submission'),
      'fileUrl': fileUrl,
      'fileBytes': null,
      'submittedAt': payload['submittedAt'] ?? _nowIso(),
    });
    await _save('submissions', rows);
  }

  static Future<List<Map<String, dynamic>>> getSubmissions(
    String assignmentId,
  ) async {
    final rows = await _submissions();
    final filtered = rows
        .where((row) => row['assignmentId'] == assignmentId)
        .toList();
    filtered.sort((a, b) => _compareDesc(a, b, 'submittedAt'));
    return filtered;
  }

  static Future<Map<String, dynamic>?> getStudentSubmission(
    String assignmentId,
    String studentCode,
  ) async {
    final rows = await _submissions();
    try {
      return rows.firstWhere((row) {
        return row['assignmentId'] == assignmentId &&
            row['studentCode'].toString() == studentCode;
      });
    } catch (_) {
      return null;
    }
  }

  static Future<void> gradeSubmission(
    String submissionId,
    double grade,
    String feedback,
  ) async {
    final rows = await _submissions();
    final index = rows.indexWhere(
      (row) => (row['id'] ?? '').toString() == submissionId,
    );
    if (index == -1) return;
    rows[index]['grade'] = grade;
    rows[index]['feedback'] = feedback;
    await _save('submissions', rows);
  }

  static Future<List<Map<String, dynamic>>> getLibraryBooks() async {
    final rows = await _libraryBooks();
    rows.sort((a, b) => _compareDesc(a, b, 'createdAt'));
    return rows;
  }

  static Future<void> addLibraryBook(Map<String, dynamic> book) async {
    final rows = await _libraryBooks();
    final fileName = (book['fileName'] ?? book['title'] ?? 'library-file')
        .toString();
    final url = _offlineUrlFromBytes(
      book['fileBytes'],
      fileName: fileName,
      fallback: (book['url'] ?? '').toString(),
    );
    rows.insert(0, {
      ..._mapOf(book),
      'id': _newId('library'),
      'url': url,
      'fileBytes': null,
      'fileName': fileName,
      'createdAt': book['createdAt'] ?? _nowIso(),
    });
    await _save('library', rows);
    await addNotification(
      title: 'New library item',
      message: (book['title'] ?? '').toString(),
      levelId: '',
    );
  }

  static Future<void> deleteLibraryBook(String id) async {
    final rows = await _libraryBooks();
    rows.removeWhere((row) => (row['id'] ?? row['_id'] ?? '').toString() == id);
    await _save('library', rows);
  }

  static Future<Map<String, dynamic>> addAnnouncement(
    Map<String, dynamic> payload,
  ) async {
    final rows = await _announcements();
    final id = _newId('announcement');
    final imageUrl = _offlineUrlFromBase64(
      payload['imageBase64'],
      fileName: (payload['imageName'] ?? 'announcement.png').toString(),
      fallback: (payload['imageUrl'] ?? '').toString(),
    );
    final row = {
      ..._mapOf(payload),
      'id': id,
      'imageUrl': imageUrl,
      'imageBase64': null,
      'date': payload['date'] ?? _today(),
      'readByStudentIds': payload['readByStudentIds'] ?? <String>[],
      'likes': payload['likes'] ?? <String>[],
      'comments': payload['comments'] ?? <Map<String, dynamic>>[],
      'createdAt': _nowIso(),
    };
    rows.insert(0, row);
    await _save('announcements', rows);
    await addNotification(
      title: 'New announcement: ${payload['title'] ?? ''}',
      message: (payload['content'] ?? '').toString(),
      levelId: (payload['levelId'] ?? '').toString(),
    );
    return {'id': id, 'imageUrl': imageUrl};
  }

  static Future<void> deleteAnnouncement(String id) async {
    final rows = await _announcements();
    rows.removeWhere((row) => (row['id'] ?? row['_id'] ?? '').toString() == id);
    await _save('announcements', rows);
  }

  static Future<void> markAnnouncementRead(String id, String studentId) async {
    final rows = await _announcements();
    final index = rows.indexWhere(
      (row) => (row['id'] ?? row['_id'] ?? '').toString() == id,
    );
    if (index == -1) return;
    final readBy = _stringList(rows[index]['readByStudentIds']);
    if (!readBy.contains(studentId)) readBy.add(studentId);
    rows[index]['readByStudentIds'] = readBy;
    await _save('announcements', rows);
  }

  static Future<List<Map<String, dynamic>>> getSchedules(
    String department,
    String level,
  ) async {
    final rows = await _schedules();
    return rows
        .where(
          (row) => row['department'] == department && row['level'] == level,
        )
        .toList();
  }

  static Future<void> addSchedule(Map<String, dynamic> payload) async {
    final rows = await _schedules();
    rows.insert(0, {
      ..._mapOf(payload),
      'id': (payload['id'] ?? _newId('schedule')).toString(),
      'uploadedAt': payload['uploadedAt'] ?? _nowIso(),
    });
    await _save('schedules', rows);
  }

  static Future<void> addScheduleImage(
    String department,
    String level,
    String imageName,
    String imageBase64,
  ) async {
    await addSchedule({
      'subject': imageName,
      'imageName': imageName,
      'imageUrl': _offlineUrlFromBase64(
        imageBase64,
        fileName: imageName,
        fallback: imageBase64,
      ),
      'department': department,
      'level': level,
      'time': '',
      'location': '',
      'isExam': false,
    });
  }

  static Future<void> deleteSchedule(String id) async {
    final rows = await _schedules();
    rows.removeWhere((row) => (row['id'] ?? row['_id'] ?? '').toString() == id);
    await _save('schedules', rows);
  }

  static Future<void> updateSchedule(
    String id,
    Map<String, dynamic> payload,
  ) async {
    final rows = await _schedules();
    final index = rows.indexWhere(
      (row) => (row['id'] ?? row['_id'] ?? '').toString() == id,
    );
    if (index == -1) return;
    rows[index] = {...rows[index], ..._mapOf(payload), 'id': id};
    await _save('schedules', rows);
  }

  static Future<List<Map<String, dynamic>>> getMaterials({
    String department = '',
    String level = '',
    String subject = '',
  }) async {
    final rows = await _materials();
    return rows.where((row) {
      if (department.isNotEmpty && row['department'] != department) {
        return false;
      }
      if (level.isNotEmpty && row['level'] != level) return false;
      if (subject.isNotEmpty && row['subject'] != subject) return false;
      return true;
    }).toList();
  }

  static Future<String> addMaterialPdf({
    required String department,
    required String level,
    required String subject,
    required String teacherName,
    required String fileName,
    required String fileBase64,
  }) async {
    final rows = await _materials();
    final id = _newId('material');
    rows.insert(0, {
      'id': id,
      'url': _offlineUrlFromBase64(fileBase64, fileName: fileName),
      'originalName': fileName,
      'department': department,
      'level': level,
      'subject': subject,
      'teacherName': teacherName,
      'uploadedAt': _nowIso(),
    });
    await _save('materials', rows);
    return id;
  }

  static Future<void> deleteMaterial(String id) async {
    final rows = await _materials();
    rows.removeWhere((row) => (row['id'] ?? row['_id'] ?? '').toString() == id);
    await _save('materials', rows);
  }

  static Future<Map<String, dynamic>> loginStudent(String studentCode) async {
    final code = studentCode.trim();
    final rows = await _students();
    final student = rows.firstWhere(
      (row) => (row['studentCode'] ?? row['code'] ?? '').toString() == code,
      orElse: () => <String, dynamic>{},
    );
    if (student.isEmpty || student['allowedAccess'] == false) {
      throw Exception('invalid_student');
    }
    return _normalizeStudent(student);
  }

  static Future<Map<String, dynamic>> loginWithUsername(
    String username,
    String password,
  ) async {
    if (username == 'admin' && password == 'admin') {
      return {'id': 'admin', 'username': 'admin', 'role': 'admin'};
    }

    final rows = await _teachers();
    final teacher = rows.firstWhere(
      (row) =>
          row['username'] == username &&
          (row['password'] ?? '').toString() == password,
      orElse: () => <String, dynamic>{},
    );
    if (teacher.isEmpty) throw Exception('invalid_credentials');
    return {...teacher, 'role': 'teacher'};
  }

  static Stream<List<Map<String, dynamic>>> getLevelMessagesStream(
    String levelId, {
    String? teacherId,
  }) {
    return _watchList(() => getLevelMessages(levelId, teacherId: teacherId));
  }

  static Stream<List<Map<String, dynamic>>> getNotificationsStream(
    String levelId,
  ) {
    return _watchList(() => getNotifications(levelId: levelId));
  }

  static Stream<int> getTotalUnreadCountStream(String id, String role) {
    return _watchInt(() => getTotalUnreadCount(id, role));
  }

  static Future<Map<String, dynamic>> sendLevelMessage(
    String levelId,
    String teacherId,
    String senderName,
    String role,
    String content,
  ) async {
    final rows = await _messages();
    final message = {
      'id': _newId('message'),
      'levelId': levelId,
      'teacherId': teacherId,
      'senderName': senderName,
      'role': role,
      'content': content,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
      'studentRead': role == 'student',
      'teacherRead': role == 'teacher',
    };
    rows.add(message);
    await _save('messages', rows);
    return message;
  }

  static Future<int> getUnreadCount(
    String levelId,
    String teacherId,
    String role,
  ) async {
    final rows = await _messages();
    return rows.where((row) {
      if (row['levelId'] != levelId || row['teacherId'] != teacherId) {
        return false;
      }
      if (role == 'teacher') {
        return row['role'] != 'teacher' && row['teacherRead'] != true;
      }
      return row['role'] != 'student' && row['studentRead'] != true;
    }).length;
  }

  static Future<void> markMessagesAsRead(
    String levelId,
    String teacherId,
    String role,
  ) async {
    final rows = await _messages();
    for (final row in rows) {
      if (row['levelId'] == levelId && row['teacherId'] == teacherId) {
        if (role == 'teacher') {
          row['teacherRead'] = true;
        } else {
          row['studentRead'] = true;
        }
      }
    }
    await _save('messages', rows);
  }

  static Future<int> getTotalUnreadCount(String id, String role) async {
    final rows = await _messages();
    return rows.where((row) {
      if (role == 'teacher') {
        return row['teacherId'] == id &&
            row['role'] != 'teacher' &&
            row['teacherRead'] != true;
      }
      return row['levelId'] == id &&
          row['role'] != 'student' &&
          row['studentRead'] != true;
    }).length;
  }

  static Future<List<Map<String, dynamic>>> getTeachers() async {
    final rows = await _teachers();
    return rows.map(_normalizeTeacher).toList();
  }

  static Future<void> addTeacher(Map<String, dynamic> teacher) async {
    final rows = await _teachers();
    rows.add(_normalizeTeacher(teacher));
    await _save('teachers', rows);
  }

  static Future<void> updateTeacher(
    String id,
    Map<String, dynamic> teacher,
  ) async {
    final rows = await _teachers();
    final index = rows.indexWhere(
      (row) => (row['id'] ?? row['_id'] ?? '').toString() == id,
    );
    if (index == -1) return;
    rows[index] = _normalizeTeacher({...rows[index], ...teacher, 'id': id});
    await _save('teachers', rows);
  }

  static Future<void> deleteTeacher(String id) async {
    final rows = await _teachers();
    rows.removeWhere((row) => (row['id'] ?? row['_id'] ?? '').toString() == id);
    await _save('teachers', rows);
  }

  static Future<Map<String, dynamic>?> getUser(String id) async {
    if (id == 'admin') {
      return {'id': 'admin', 'username': 'admin', 'role': 'admin'};
    }

    final teachers = await _teachers();
    for (final teacher in teachers) {
      if ((teacher['id'] ?? '').toString() == id) {
        return {...teacher, 'role': 'teacher'};
      }
    }

    final students = await _students();
    for (final student in students) {
      if ((student['studentCode'] ?? '').toString() == id) {
        return {...student, 'role': 'student'};
      }
    }
    return null;
  }

  static Future<Map<String, dynamic>> updateUser(
    String id,
    Map<String, dynamic> payload,
  ) async {
    final teachers = await _teachers();
    final teacherIndex = teachers.indexWhere(
      (row) => (row['id'] ?? '').toString() == id,
    );
    if (teacherIndex != -1) {
      teachers[teacherIndex] = _normalizeTeacher({
        ...teachers[teacherIndex],
        ...payload,
        'id': id,
      });
      await _save('teachers', teachers);
      return teachers[teacherIndex];
    }

    final students = await _students();
    final studentIndex = students.indexWhere(
      (row) => (row['studentCode'] ?? '').toString() == id,
    );
    if (studentIndex != -1) {
      students[studentIndex] = _normalizeStudent({
        ...students[studentIndex],
        ...payload,
      });
      await _save('students', students);
      return students[studentIndex];
    }
    return payload;
  }

  static Future<void> importStudentsBulk(
    List<Map<String, dynamic>> students,
  ) async {
    final rows = await _students();
    for (final item in students) {
      final student = _normalizeStudent(item);
      final code = (student['studentCode'] ?? '').toString();
      if (code.isEmpty) continue;
      final index = rows.indexWhere(
        (row) => (row['studentCode'] ?? '').toString() == code,
      );
      if (index == -1) {
        rows.add(student);
      } else {
        rows[index] = _normalizeStudent({...rows[index], ...student});
      }
    }
    await _save('students', rows);
  }

  static Future<List<Map<String, dynamic>>> getStudents({
    String? department,
    String? level,
  }) async {
    final rows = await _students();
    return rows
        .where((row) {
          if (department != null &&
              department.isNotEmpty &&
              row['department'] != department) {
            return false;
          }
          if (level != null && level.isNotEmpty && row['level'] != level) {
            return false;
          }
          return true;
        })
        .map(_normalizeStudent)
        .toList();
  }

  static Future<void> deleteStudent(String studentCode) async {
    final rows = await _students();
    rows.removeWhere(
      (row) =>
          (row['studentCode'] ?? row['code'] ?? '').toString() == studentCode,
    );
    await _save('students', rows);
  }

  static Future<void> updateStudent(
    String studentCode,
    Map<String, dynamic> student,
  ) async {
    final rows = await _students();
    final index = rows.indexWhere(
      (row) =>
          (row['studentCode'] ?? row['code'] ?? '').toString() == studentCode,
    );
    if (index == -1) return;
    rows[index] = _normalizeStudent({
      ...rows[index],
      ...student,
      'studentCode': studentCode,
    });
    await _save('students', rows);
  }

  static Future<void> setStudentAccess(String studentCode, bool allowed) async {
    final rows = await _students();
    final index = rows.indexWhere(
      (row) =>
          (row['studentCode'] ?? row['code'] ?? '').toString() == studentCode,
    );
    if (index == -1) return;
    rows[index]['allowedAccess'] = allowed;
    await _save('students', rows);
  }

  static Future<void> addExamResult(Map<String, dynamic> payload) async {
    final rows = await _examResults();
    rows.insert(0, {
      ..._mapOf(payload),
      'id': _newId('exam-result'),
      'submittedAt': payload['submittedAt'] ?? _nowIso(),
    });
    await _save('exam_results', rows);
  }

  static Future<Map<String, dynamic>?> getLatestExamResult(
    String studentCode,
  ) async {
    final rows = await _examResults();
    final filtered = rows
        .where((row) => row['studentCode'].toString() == studentCode)
        .toList();
    filtered.sort((a, b) => _compareDesc(a, b, 'submittedAt'));
    return filtered.isEmpty ? null : filtered.first;
  }

  static Future<void> addStudent(Map<String, dynamic> student) async {
    final rows = await _students();
    final normalized = _normalizeStudent(student);
    rows.add(normalized);
    await _save('students', rows);
  }

  static Future<List<Map<String, dynamic>>> getExams() async {
    final rows = await _exams();
    rows.sort((a, b) => _compareDesc(a, b, 'createdAt'));
    return rows;
  }

  static Future<String> addExam(Map<String, dynamic> payload) async {
    final rows = await _exams();
    final id = _newId('exam');
    rows.insert(0, {..._mapOf(payload), 'id': id, 'createdAt': _nowIso()});
    await _save('exams', rows);
    await addNotification(
      title: 'New exam: ${payload['subject'] ?? ''}',
      message: (payload['subject'] ?? '').toString(),
      levelId: _levelId(
        (payload['department'] ?? '').toString(),
        (payload['level'] ?? '').toString(),
      ),
    );
    return id;
  }

  static Future<void> deleteExam(String id) async {
    final rows = await _exams();
    rows.removeWhere((row) => (row['id'] ?? row['_id'] ?? '').toString() == id);
    await _save('exams', rows);
  }

  static Future<void> updateExam(
    String id,
    Map<String, dynamic> payload,
  ) async {
    final rows = await _exams();
    final index = rows.indexWhere(
      (row) => (row['id'] ?? row['_id'] ?? '').toString() == id,
    );
    if (index == -1) return;
    rows[index] = {...rows[index], ..._mapOf(payload), 'id': id};
    await _save('exams', rows);
  }

  static Future<void> addQuestionToBank(Map<String, dynamic> question) async {
    final rows = await _questionBank();
    rows.add({
      ..._mapOf(question),
      'id': (question['id'] ?? _newId('question')).toString(),
    });
    await _save('question_bank', rows);
  }

  static Future<List<Map<String, dynamic>>> getQuestionsFromBank({
    String? subject,
    String? department,
    String? level,
    String? type,
  }) async {
    final rows = await _questionBank();
    return rows.where((row) {
      if (subject != null && subject.isNotEmpty && row['subject'] != subject) {
        return false;
      }
      if (department != null &&
          department.isNotEmpty &&
          row['department'] != department) {
        return false;
      }
      if (level != null && level.isNotEmpty && row['level'] != level) {
        return false;
      }
      if (type != null && type.isNotEmpty && row['type'] != type) {
        return false;
      }
      return true;
    }).toList();
  }

  static Future<List<Map<String, dynamic>>> getLevelMessages(
    String levelId, {
    String? teacherId,
  }) async {
    final rows = await _messages();
    final filtered = rows.where((row) {
      if (row['levelId'] != levelId) {
        return false;
      }
      if (teacherId != null &&
          teacherId.isNotEmpty &&
          row['teacherId'] != teacherId) {
        return false;
      }
      return true;
    }).toList();
    filtered.sort((a, b) {
      final av = int.tryParse((a['timestamp'] ?? 0).toString()) ?? 0;
      final bv = int.tryParse((b['timestamp'] ?? 0).toString()) ?? 0;
      return av.compareTo(bv);
    });
    return filtered;
  }

  static Future<void> deleteQuestionFromBank(String id) async {
    final rows = await _questionBank();
    rows.removeWhere((row) => (row['id'] ?? row['_id'] ?? '').toString() == id);
    await _save('question_bank', rows);
  }

  static Future<Map<String, dynamic>> importExamFromFile({
    required String fileName,
    required String fileBase64,
    required String department,
    required String level,
    String? subject,
  }) async {
    final id = await addExam({
      'subject': subject ?? fileName,
      'department': department,
      'level': level,
      'questions': <Map<String, dynamic>>[],
      'tfCount': 0,
      'mcqCount': 0,
      'sourceFileName': fileName,
    });
    return {'id': id, 'subject': subject ?? fileName};
  }

  static Future<Map<String, dynamic>> startSession({
    required String userId,
    required String levelId,
    required String subjectId,
    int durationMinutes = 15,
    String lectureId = '',
  }) async {
    final session = {
      'code': (1000 + (DateTime.now().millisecondsSinceEpoch % 9000))
          .toString(),
      'expiresAt': DateTime.now()
          .add(Duration(minutes: durationMinutes))
          .millisecondsSinceEpoch,
      'lectureId': lectureId.isEmpty ? _newId('lecture') : lectureId,
      'levelId': levelId,
      'subjectId': subjectId,
      'teacherId': userId,
    };
    _activeSessions[userId] = session;
    return session;
  }

  static Future<void> endSession({
    required String lectureId,
    required String levelId,
    required String subjectId,
    required List<String> presentStudentCodes,
    required String teacherId,
  }) async {
    final parts = levelId.split('__');
    final department = parts.isNotEmpty ? parts.first : '';
    final level = parts.length > 1 ? parts.sublist(1).join('__') : '';
    final students = await getStudents(department: department, level: level);
    final rows = await _attendance();

    for (final student in students) {
      final code = (student['studentCode'] ?? student['code'] ?? '').toString();
      if (code.isEmpty || presentStudentCodes.contains(code)) continue;
      final exists = rows.any((row) {
        return row['lectureId'] == lectureId &&
            row['studentCode'].toString() == code;
      });
      if (exists) continue;
      rows.add({
        'id': _newId('attendance'),
        'studentCode': code,
        'studentName': student['fullName'] ?? student['name'] ?? '',
        'name': student['fullName'] ?? student['name'] ?? '',
        'department': department,
        'level': level,
        'lectureId': lectureId,
        'levelId': levelId,
        'subjectId': subjectId,
        'teacherId': teacherId,
        'status': 'Absent',
        'timestamp': _nowIso(),
      });
    }

    _activeSessions.removeWhere((_, session) {
      return session['lectureId'] == lectureId ||
          session['teacherId'] == teacherId;
    });
    await _save('attendance', rows);
  }

  static Future<Map<String, dynamic>?> getActiveSession(String userId) async {
    final session = _activeSessions[userId];
    if (session == null) return null;
    final expiresAt = int.tryParse((session['expiresAt'] ?? 0).toString()) ?? 0;
    if (expiresAt <= DateTime.now().millisecondsSinceEpoch) {
      _activeSessions.remove(userId);
      return null;
    }
    return session;
  }
}

class _OfflineStore {
  static SharedPreferences? _prefs;
  static final Map<String, List<Map<String, dynamic>>> _cache = {};
  static final Map<String, String> _encodedCache = {};

  static Future<void> ensureReady() async {
    _prefs ??= await SharedPreferences.getInstance();
  }

  static Future<List<Map<String, dynamic>>> list(
    String name,
    List<Map<String, dynamic>> Function() seed,
  ) async {
    await ensureReady();
    if (!offlineMode && baseUrl.isNotEmpty) {
      try {
        final remoteRows = await _BackendStore.list(name);
        if (remoteRows.isNotEmpty) return remoteRows;

        final seeded = seed()
            .map((row) => Map<String, dynamic>.from(row))
            .toList();
        if (seeded.isNotEmpty) {
          await _BackendStore.save(name, seeded);
          return seeded;
        }
        return remoteRows;
      } catch (error) {
        debugPrint(
          'Backend read failed for $name; using offline cache: $error',
        );
      }
    }

    final cached = _cache[name];
    if (cached != null) {
      return cached.map((row) => Map<String, dynamic>.from(row)).toList();
    }

    final key = _key(name);
    final raw = _prefs!.getString(key);
    if (raw == null) {
      final seeded = seed()
          .map((row) => Map<String, dynamic>.from(row))
          .toList();
      await save(name, seeded);
      return seeded;
    }

    try {
      final decoded = jsonDecode(raw);
      if (decoded is List) {
        final rows = decoded
            .whereType<Map>()
            .map(
              (row) => row.map((key, value) => MapEntry(key.toString(), value)),
            )
            .toList();
        _cache[name] = rows;
        _encodedCache[name] = raw;
        return rows.map((row) => Map<String, dynamic>.from(row)).toList();
      }
    } catch (error) {
      debugPrint('Offline store read failed for $name: $error');
    }

    final seeded = seed().map((row) => Map<String, dynamic>.from(row)).toList();
    await save(name, seeded);
    return seeded;
  }

  static Future<void> save(String name, List<Map<String, dynamic>> rows) async {
    await ensureReady();
    final normalized = rows
        .map((row) => Map<String, dynamic>.from(row))
        .toList();
    if (!offlineMode && baseUrl.isNotEmpty) {
      try {
        await _BackendStore.save(name, normalized);
        _cache[name] = normalized;
        _encodedCache[name] = jsonEncode(normalized);
        return;
      } catch (error) {
        debugPrint('Backend save failed for $name; saving offline: $error');
      }
    }

    final encoded = jsonEncode(normalized);
    if (_encodedCache[name] == encoded) {
      _cache[name] = normalized;
      return;
    }
    _cache[name] = normalized;
    _encodedCache[name] = encoded;
    try {
      await _prefs!.setString(_key(name), encoded);
    } catch (error) {
      debugPrint(
        'Offline save exceeded browser storage for $name; saving lightweight metadata: $error',
      );
      final lightweight = _toLightweightRows(normalized);
      final lightweightEncoded = jsonEncode(lightweight);
      _encodedCache[name] = lightweightEncoded;
      try {
        await _prefs!.remove(_key(name));
        await _prefs!.setString(_key(name), lightweightEncoded);
      } catch (fallbackError) {
        debugPrint(
          'Lightweight offline save failed for $name; keeping data in memory only: $fallbackError',
        );
      }
    }
  }

  static String _key(String name) => 'offline_api_$name';

  static List<Map<String, dynamic>> _toLightweightRows(
    List<Map<String, dynamic>> rows,
  ) {
    return rows.map((row) {
      final cleaned = Map<String, dynamic>.from(row);
      for (final key in const [
        'pdfUrl',
        'fileUrl',
        'url',
        'imageUrl',
        'thumbnail',
        'imageBase64',
        'fileBytes',
      ]) {
        final value = cleaned[key];
        if (value is String && _isLargeEmbeddedFile(value)) {
          cleaned[key] = '';
          cleaned['attachmentStoredLocallyOnly'] = true;
        } else if (value is List && value.length > 64 * 1024) {
          cleaned[key] = null;
          cleaned['attachmentStoredLocallyOnly'] = true;
        }
      }
      return cleaned;
    }).toList();
  }

  static bool _isLargeEmbeddedFile(String value) {
    return value.startsWith('data:') && value.length > 128 * 1024;
  }
}

class _BackendStore {
  static const Duration _timeout = Duration(seconds: 8);

  static Future<List<Map<String, dynamic>>> list(String name) async {
    final response = await http
        .get(Uri.parse('$baseUrl/api/$name'))
        .timeout(_timeout);
    _throwIfBad(response);
    final decoded = jsonDecode(response.body);
    final items = decoded is Map ? decoded['items'] : decoded;
    if (items is! List) return <Map<String, dynamic>>[];
    return items
        .whereType<Map>()
        .map((row) => row.map((key, value) => MapEntry(key.toString(), value)))
        .toList();
  }

  static Future<void> save(String name, List<Map<String, dynamic>> rows) async {
    final response = await http
        .put(
          Uri.parse('$baseUrl/api/$name/bulk'),
          headers: const {'Content-Type': 'application/json'},
          body: jsonEncode({'items': rows}),
        )
        .timeout(_timeout);
    _throwIfBad(response);
  }

  static void _throwIfBad(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) return;
    throw Exception('HTTP ${response.statusCode}: ${response.body}');
  }
}
