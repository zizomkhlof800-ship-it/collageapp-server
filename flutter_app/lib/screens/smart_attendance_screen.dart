import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../constants/theme.dart';
import '../services/attendance_service.dart';
import '../services/api_service.dart';

import 'dart:convert';

class SmartAttendanceScreen extends StatefulWidget {
  final String teacherId;
  final String? levelId;
  final String? subjectId;
  const SmartAttendanceScreen({
    super.key,
    required this.teacherId,
    this.levelId,
    this.subjectId,
  });

  @override
  State<SmartAttendanceScreen> createState() => _SmartAttendanceScreenState();
}

class _SmartAttendanceScreenState extends State<SmartAttendanceScreen> {
  Timer? _timer;
  bool _isGenerating = false;
  bool _isEnding = false;
  final TextEditingController _lectureIdController = TextEditingController();
  List<Map<String, String>> _attendees = [];

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          _attendees = List.from(AttendanceService.instance.presentStudents);
        });
      }
    });
    _loadActiveSession();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _lectureIdController.dispose();
    super.dispose();
  }

  Future<void> _loadActiveSession() async {
    final tid = widget.teacherId.isNotEmpty ? widget.teacherId : 'admin';
    try {
      final data = await ApiService.getActiveSession(tid);
      if (data != null) {
        final code = (data['code'] ?? '').toString();
        final expiresAt =
            int.tryParse((data['expiresAt'] ?? 0).toString()) ?? 0;
        final lectureId = (data['lectureId'] ?? '').toString();
        final levelId = (data['levelId'] ?? '').toString();
        final subjectId = (data['subjectId'] ?? '').toString();
        if (code.isNotEmpty && expiresAt > 0) {
          AttendanceService.instance.setSession(
            code: code,
            expiresAtMs: expiresAt,
            lectureId: lectureId,
            levelId: levelId,
            subjectId: subjectId,
            teacherId: tid,
          );
          if (mounted) setState(() {});
        }
      }
    } catch (_) {}
  }

  void _generateQRCode() async {
    final messenger = ScaffoldMessenger.of(context);
    if (AttendanceService.instance.isSessionActive) {
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            'الجلسة الحالية لا تزال سارية',
            style: GoogleFonts.cairo(),
          ),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    if (widget.levelId == null || widget.subjectId == null) {
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            'يرجى اختيار مادة وفرقة أولاً من لوحة التحكم',
            style: GoogleFonts.cairo(),
          ),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final lectureId = 'LECTURE-${DateTime.now().millisecondsSinceEpoch}';
    _lectureIdController.text = lectureId;
    setState(() => _isGenerating = true);
    try {
      final tid = widget.teacherId.isNotEmpty ? widget.teacherId : 'admin';
      final data = await ApiService.startSession(
        userId: tid,
        levelId: widget.levelId!,
        subjectId: widget.subjectId!,
        durationMinutes: 15,
        lectureId: lectureId,
      );
      final code = (data['code'] ?? '').toString();
      final expiresAt = int.tryParse((data['expiresAt'] ?? 0).toString()) ?? 0;
      AttendanceService.instance.setSession(
        code: code,
        expiresAtMs: expiresAt,
        lectureId: lectureId,
        levelId: widget.levelId!,
        subjectId: widget.subjectId!,
        teacherId: tid,
      );
    } catch (_) {
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            'تعذر إنشاء جلسة. تحقق من اتصال السيرفر',
            style: GoogleFonts.cairo(),
          ),
          backgroundColor: Colors.red,
        ),
      );
    }
    if (mounted) setState(() => _isGenerating = false);
  }

  void _endPreparation() async {
    if (!AttendanceService.instance.isSessionActive) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'إنهاء التحضير',
          style: GoogleFonts.cairo(fontWeight: FontWeight.bold),
        ),
        content: Text(
          'هل أنت متأكد من إنهاء عملية التحضير الآن؟ سيتم تسجيل باقي الطلاب كغائبين.',
          style: GoogleFonts.cairo(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('إلغاء', style: GoogleFonts.cairo()),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              'تأكيد الإنهاء',
              style: GoogleFonts.cairo(color: Colors.red),
            ),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _isEnding = true);
    final messenger = ScaffoldMessenger.of(context);
    try {
      final lectureId = AttendanceService.instance.currentLectureId!;
      final levelId = AttendanceService.instance.currentLevelId!;
      final subjectId = AttendanceService.instance.currentSubjectId!;
      final presentCodes = AttendanceService.instance.presentStudents
          .map((s) => s['code']!)
          .toList();
      final tid = widget.teacherId.isNotEmpty ? widget.teacherId : 'admin';

      await ApiService.endSession(
        lectureId: lectureId,
        levelId: levelId,
        subjectId: subjectId,
        presentStudentCodes: presentCodes,
        teacherId: tid,
      );

      AttendanceService.instance.endSession();
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            'تم إنهاء التحضير ومعالجة الغياب بنجاح',
            style: GoogleFonts.cairo(),
          ),
          backgroundColor: Colors.green,
        ),
      );
    } catch (_) {
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            'حدث خطأ أثناء إنهاء الجلسة',
            style: GoogleFonts.cairo(),
          ),
          backgroundColor: Colors.red,
        ),
      );
    }
    if (mounted) setState(() => _isEnding = false);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.colorScheme.surface,
        elevation: 0,
        title: Text(
          'الحضور الذكي',
          style: GoogleFonts.cairo(
            color: theme.colorScheme.onSurface,
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: IconButton(
          icon: Icon(
            LucideIcons.arrowRight,
            color: theme.colorScheme.onSurface,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          if (AttendanceService.instance.isSessionActive)
            TextButton.icon(
              onPressed: _isEnding ? null : _endPreparation,
              icon: const Icon(
                LucideIcons.stopCircle,
                color: Colors.red,
                size: 18,
              ),
              label: Text(
                'إنهاء الآن',
                style: GoogleFonts.cairo(
                  color: Colors.red,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          const SizedBox(width: 8),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
                border: Border.all(color: theme.dividerColor),
              ),
              child: Column(
                children: [
                  Text(
                    'رمز الحضور (QR)',
                    style: GoogleFonts.cairo(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: theme.textTheme.bodyLarge?.color,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'قم بعرض هذا الرمز للطلاب لتسجيل حضورهم',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.cairo(
                      fontSize: 14,
                      color: theme.textTheme.bodySmall?.color,
                    ),
                  ),
                  const SizedBox(height: 32),

                  Container(
                    height: 250,
                    width: 250,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerHighest
                          .withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: theme.dividerColor),
                    ),
                    child: Center(
                      child: !AttendanceService.instance.isSessionActive
                          ? Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  LucideIcons.qrCode,
                                  size: 64,
                                  color: theme.textTheme.bodySmall?.color,
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'اضغط توليد لإنشاء الرمز',
                                  style: GoogleFonts.cairo(
                                    color: theme.textTheme.bodySmall?.color,
                                  ),
                                ),
                              ],
                            )
                          : QrImageView(
                              data:
                                  AttendanceService.instance.currentQrPayload ??
                                  AttendanceService.instance.currentCode!,
                              version: QrVersions.auto,
                              size: 200.0,
                              eyeStyle: QrEyeStyle(
                                eyeShape: QrEyeShape.square,
                                color: theme.colorScheme.primary,
                              ),
                              dataModuleStyle: QrDataModuleStyle(
                                dataModuleShape: QrDataModuleShape.square,
                                color: theme.colorScheme.primary,
                              ),
                            ),
                    ),
                  ),

                  if (AttendanceService.instance.isSessionActive)
                    Padding(
                      padding: const EdgeInsets.only(top: 24),
                      child: Column(
                        children: [
                          Text(
                            'رمز الجلسة اليدوي',
                            style: GoogleFonts.cairo(
                              fontSize: 14,
                              color: theme.textTheme.bodySmall?.color,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.surfaceContainerHighest
                                  .withValues(alpha: 0.3),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: theme.colorScheme.primary.withValues(
                                  alpha: 0.3,
                                ),
                              ),
                            ),
                            child: Text(
                              AttendanceService.instance.currentCode ?? '',
                              style: GoogleFonts.cairo(
                                fontSize: 32,
                                fontWeight: FontWeight.bold,
                                color: theme.colorScheme.primary,
                                letterSpacing: 8,
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'ينتهي خلال: ${AttendanceService.instance.remainingTime}',
                            style: GoogleFonts.cairo(
                              fontSize: 14,
                              color: Colors.red,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),

                  const SizedBox(height: 32),

                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isGenerating ? null : _generateQRCode,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: theme.colorScheme.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: _isGenerating
                          ? const SizedBox(
                              height: 24,
                              width: 24,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(LucideIcons.refreshCw, size: 20),
                                const SizedBox(width: 8),
                                Text(
                                  'توليد رمز جديد',
                                  style: GoogleFonts.cairo(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            if (AttendanceService.instance.isSessionActive)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'الطلاب الحاضرون (${_attendees.length})',
                    style: GoogleFonts.cairo(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (_attendees.isEmpty)
                    Center(
                      child: Text(
                        'لا يوجد طلاب مسجلون حالياً',
                        style: GoogleFonts.cairo(
                          color: theme.textTheme.bodySmall?.color,
                        ),
                      ),
                    )
                  else
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _attendees.length,
                      itemBuilder: (context, index) {
                        final student = _attendees[index];
                        return Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: theme.colorScheme.primary
                                  .withValues(alpha: 0.1),
                              child: Text(
                                student['name']?[0] ?? 'S',
                                style: TextStyle(
                                  color: theme.colorScheme.primary,
                                ),
                              ),
                            ),
                            title: Text(
                              student['name'] ?? '',
                              style: GoogleFonts.cairo(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            subtitle: Text(
                              student['code'] ?? '',
                              style: GoogleFonts.cairo(fontSize: 12),
                            ),
                            trailing: Text(
                              DateTime.parse(student['time']!)
                                  .toLocal()
                                  .toString()
                                  .split(' ')[1]
                                  .substring(0, 5),
                              style: GoogleFonts.cairo(
                                fontSize: 12,
                                color: theme.textTheme.bodySmall?.color,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
