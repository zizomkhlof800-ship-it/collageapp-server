import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../constants/theme.dart';
import '../services/attendance_service.dart';
import '../services/api_service.dart';

class StudentsListScreen extends StatefulWidget {
  final String? department;
  final String? level;

  const StudentsListScreen({super.key, this.department, this.level});

  @override
  State<StudentsListScreen> createState() => _StudentsListScreenState();
}

class _StudentsListScreenState extends State<StudentsListScreen> {
  Timer? _timer;
  final TextEditingController _lectureIdController = TextEditingController(
    text: 'LECTURE-123',
  );
  List<Map<String, dynamic>> _attended = [];
  final Set<String> _hiddenCodes = {};

  String _codeOf(Map<String, dynamic> s) {
    return (s['studentCode'] ?? s['code'] ?? '').toString();
  }

  @override
  void initState() {
    super.initState();
    _fetchAttendees();
    _timer = Timer.periodic(const Duration(seconds: 3), (timer) {
      _fetchAttendees();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _lectureIdController.dispose();
    super.dispose();
  }

  Future<void> _fetchAttendees() async {
    try {
      final lectureId =
          AttendanceService.instance.currentLectureId ??
          _lectureIdController.text.trim();
      if (lectureId.isEmpty) {
        setState(() => _attended = []);
        return;
      }
      final rows = await ApiService.getAttendanceByLecture(lectureId);
      setState(() {
        _attended = rows.where((s) {
          final map = Map<String, dynamic>.from(s);
          if (_hiddenCodes.contains(_codeOf(map))) return false;

          // Filter by department and level if provided
          if (widget.department != null && widget.department!.isNotEmpty) {
            if (map['department'] != widget.department) return false;
          }
          if (widget.level != null && widget.level!.isNotEmpty) {
            if (map['level'] != widget.level) return false;
          }
          return true;
        }).toList();
      });
    } catch (_) {
      // keep previous list
    }
  }

  Future<void> _deleteStudent(Map<String, dynamic> student) async {
    final lectureId =
        AttendanceService.instance.currentLectureId ??
        _lectureIdController.text.trim();
    final code = _codeOf(student);
    if (lectureId.isEmpty || code.isEmpty) return;
    final messenger = ScaffoldMessenger.of(context);
    try {
      await ApiService.deleteAttendanceStudent(lectureId, code);
      if (mounted) {
        setState(() {
          _hiddenCodes.add(code);
          _attended.removeWhere(
            (s) => _codeOf(Map<String, dynamic>.from(s)) == code,
          );
        });
      }
      messenger.showSnackBar(
        SnackBar(
          content: Text('تم حذف الطالب من السجل', style: GoogleFonts.cairo()),
        ),
      );
    } catch (_) {
      // Remove locally even if server fails to avoid stuck UI
      if (mounted) {
        setState(() {
          _hiddenCodes.add(code);
          _attended.removeWhere(
            (s) => _codeOf(Map<String, dynamic>.from(s)) == code,
          );
        });
      }
    }
  }

  void _resetAttendance() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'بدء محاضرة جديدة',
          style: GoogleFonts.cairo(fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'هل أنت متأكد من مسح سجل الحضور الحالي لبدء محاضرة جديدة؟',
              style: GoogleFonts.cairo(),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _lectureIdController,
              textAlign: TextAlign.right,
              decoration: InputDecoration(
                labelText: 'معرف المحاضرة (lectureId)',
                labelStyle: GoogleFonts.cairo(),
                border: const OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('إلغاء', style: GoogleFonts.cairo(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () {
              final lectureId = _lectureIdController.text.trim();
              Navigator.pop(context);
              if (lectureId.isNotEmpty) {
                ApiService.clearAttendanceByLecture(
                  lectureId,
                ).catchError((_) {});
              }
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    'تم تجهيز محاضرة جديدة، افتح شاشة QR لبدء الجلسة',
                    style: GoogleFonts.cairo(),
                  ),
                  backgroundColor: AppColors.primary,
                ),
              );
              setState(() {
                _hiddenCodes.clear();
                _attended = [];
              });
            },
            child: Text(
              'نعم، مسح',
              style: GoogleFonts.cairo(
                color: Colors.red,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final attendedStudents = _attended;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: context.appBackground,
      appBar: AppBar(
        backgroundColor: context.appSurface,
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'سجل الحضور الذكي',
              style: GoogleFonts.cairo(
                color: context.appText,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
            Text(
              '${attendedStudents.length} طالب حاضر',
              style: GoogleFonts.cairo(
                color: context.appTextLight,
                fontSize: 12,
              ),
            ),
          ],
        ),
        leading: IconButton(
          icon: Icon(LucideIcons.arrowRight, color: context.appText),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: Text(
                    'مسح كل سجلات الحضور',
                    style: GoogleFonts.cairo(fontWeight: FontWeight.bold),
                  ),
                  content: Text(
                    'سيتم حذف كل سجلات الحضور من الخادم. هل أنت متأكد؟',
                    style: GoogleFonts.cairo(),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text(
                        'إلغاء',
                        style: GoogleFonts.cairo(color: Colors.grey),
                      ),
                    ),
                    TextButton(
                      onPressed: () async {
                        Navigator.pop(context);
                        try {
                          await ApiService.clearAllAttendance();
                        } catch (_) {}
                        setState(() {
                          _hiddenCodes.clear();
                          _attended = [];
                        });
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'تم مسح كل سجلات الحضور',
                              style: GoogleFonts.cairo(),
                            ),
                          ),
                        );
                      },
                      child: Text(
                        'مسح الكل',
                        style: GoogleFonts.cairo(
                          color: Colors.red,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
            icon: const Icon(LucideIcons.refreshCw, color: AppColors.primary),
            tooltip: 'مسح كل السجلات',
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: attendedStudents.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(LucideIcons.users, size: 64, color: Colors.grey[300]),
                  const SizedBox(height: 16),
                  Text(
                    'لا يوجد حضور مسجل حالياً',
                    style: GoogleFonts.cairo(
                      color: Colors.grey[400],
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'سيظهر الطلاب هنا عند مسح رمز QR',
                    style: GoogleFonts.cairo(
                      color: Colors.grey[400],
                      fontSize: 12,
                    ),
                  ),
                  if (AttendanceService.instance.isSessionActive)
                    Padding(
                      padding: const EdgeInsets.only(top: 16),
                      child: Text(
                        'المحاضرة: ${AttendanceService.instance.currentLectureId ?? '-'} | الكود: ${AttendanceService.instance.currentCode ?? '-'}',
                        style: GoogleFonts.cairo(
                          color: AppColors.primary,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                ],
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: attendedStudents.length,
              separatorBuilder: (context, index) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final student = attendedStudents[index];
                return Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: context.appSurface,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(
                          alpha: isDark ? 0.18 : 0.05,
                        ),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Expanded(
                            child: Text(
                              (student['studentName'] ?? '').toString(),
                              textAlign: TextAlign.right,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.cairo(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: context.appText,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Container(
                            width: 42,
                            height: 42,
                            decoration: BoxDecoration(
                              color: AppColors.cardGreenBg,
                              shape: BoxShape.circle,
                            ),
                            child: Center(
                              child: Icon(
                                LucideIcons.check,
                                color: AppColors.cardGreenIcon,
                                size: 20,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Icon(
                            LucideIcons.graduationCap,
                            size: 14,
                            color: context.appTextLight,
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              '${(student['level'] ?? '').toString()} - ${(student['department'] ?? '').toString()}',
                              textAlign: TextAlign.right,
                              style: GoogleFonts.cairo(
                                fontSize: 12,
                                color: context.appTextLight,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            LucideIcons.clock,
                            size: 14,
                            color: context.appTextLight,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            _formatTime(student['time']),
                            style: GoogleFonts.cairo(
                              fontSize: 12,
                              color: context.appTextLight,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          IconButton(
                            onPressed: () => _deleteStudent(student),
                            icon: const Icon(
                              LucideIcons.trash2,
                              color: Colors.red,
                            ),
                            tooltip: 'حذف من السجل',
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: context.appSurfaceVariant,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              (student['studentCode'] ?? '').toString(),
                              style: GoogleFonts.cairo(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: context.appText,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }

  String _formatTime(dynamic t) {
    if (t == null) return '';
    final millis = int.tryParse(t.toString());
    if (millis != null) {
      final dt = DateTime.fromMillisecondsSinceEpoch(millis);
      final hh = dt.hour.toString().padLeft(2, '0');
      final mm = dt.minute.toString().padLeft(2, '0');
      return '$hh:$mm';
    }
    final s = t.toString();
    if (s.contains(' ')) {
      try {
        return s.split(' ')[1].substring(0, 5);
      } catch (_) {}
    }
    return s;
  }
}
