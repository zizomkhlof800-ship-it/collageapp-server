import '../constants/api.dart';

class AttendanceService {
  // Singleton pattern
  static final AttendanceService _instance = AttendanceService._internal();
  static AttendanceService get instance => _instance;

  AttendanceService._internal();

  String? _currentCode;
  DateTime? _sessionExpiry;
  final List<Map<String, String>> _presentStudents = [];
  String? _currentLectureId;
  String? _currentQrPayload;
  String? _currentLevelId;
  String? _currentSubjectId;
  String? _currentTeacherId;
  int _qrNonce = 0;

  String? get currentCode => _currentCode;
  List<Map<String, String>> get presentStudents => _presentStudents;
  String? get currentLectureId => _currentLectureId;
  String? get currentQrPayload => _currentQrPayload;
  String? get currentLevelId => _currentLevelId;
  String? get currentSubjectId => _currentSubjectId;
  String? get currentTeacherId => _currentTeacherId;

  bool get isSessionActive {
    if (_currentCode == null || _sessionExpiry == null) return false;
    return DateTime.now().isBefore(_sessionExpiry!);
  }

  void setSession({
    required String code,
    required int expiresAtMs,
    required String lectureId,
    required String levelId,
    required String subjectId,
    required String teacherId,
  }) {
    _currentCode = code;
    _currentLectureId = lectureId;
    _currentLevelId = levelId;
    _currentSubjectId = subjectId;
    _currentTeacherId = teacherId;
    _sessionExpiry = DateTime.fromMillisecondsSinceEpoch(expiresAtMs);
    _presentStudents.clear();
    _qrNonce = 0;
    refreshQrPayload();
  }

  void refreshQrPayload() {
    if (_currentLectureId == null) return;
    _qrNonce++;
    final ts = DateTime.now().millisecondsSinceEpoch;
    _currentQrPayload =
        '$baseUrl/mark-attendance?lectureId=$_currentLectureId&timestamp=$ts&nonce=$_qrNonce';
  }

  void endSession() {
    _currentCode = null;
    _sessionExpiry = null;
    _currentLectureId = null;
    _currentQrPayload = null;
    _currentLevelId = null;
    _currentSubjectId = null;
    _currentTeacherId = null;
    _qrNonce = 0;
  }

  // Validate the entered code
  bool validateCode(String code) {
    if (!isSessionActive) return false;
    return code == _currentCode;
  }

  // Register a student
  bool registerStudent({
    required String name,
    required String code,
    required String department,
    required String level,
    required String status,
  }) {
    if (!isSessionActive) return false;

    // Check if student is already registered
    final isAlreadyRegistered = _presentStudents.any((s) => s['code'] == code);
    if (isAlreadyRegistered) {
      return true; // Already registered, treat as success
    }

    _presentStudents.add({
      'name': name,
      'code': code,
      'department': department,
      'level': level,
      'status': status,
      'time': DateTime.now().toString(),
    });

    return true;
  }

  // Get formatted expiry time
  String get remainingTime {
    if (_sessionExpiry == null) return '00:00';
    final remaining = _sessionExpiry!.difference(DateTime.now());
    if (remaining.isNegative) return '00:00';

    final minutes = remaining.inMinutes.toString().padLeft(2, '0');
    final seconds = (remaining.inSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }
}
