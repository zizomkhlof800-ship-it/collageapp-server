import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../constants/api.dart';
import '../constants/theme.dart';
import '../services/api_service.dart';

class LiveLectureScreen extends StatefulWidget {
  final String channelName;
  final String userName;
  final bool isTeacher;
  final String? levelId;
  final String? subjectId;
  final String? userId;

  const LiveLectureScreen({
    super.key,
    required this.channelName,
    required this.userName,
    required this.isTeacher,
    this.levelId,
    this.subjectId,
    this.userId,
  });

  @override
  State<LiveLectureScreen> createState() => _LiveLectureScreenState();
}

class _LiveLectureScreenState extends State<LiveLectureScreen> {
  Map<String, dynamic>? _session;
  bool _loading = true;
  bool _joining = false;
  String? _error;
  Timer? _timer;

  String get _levelId => widget.levelId ?? '';
  String get _subjectId => widget.subjectId ?? widget.channelName;
  String get _userId => (widget.userId ?? widget.userName).trim();

  @override
  void initState() {
    super.initState();
    _loadSession();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted && _session != null) setState(() {});
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _loadSession() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    if (offlineMode) {
      setState(() {
        _loading = false;
        _error = 'التطبيق يعمل الآن في وضع الأوفلاين.';
      });
      return;
    }

    final online = await ApiService.testConnection();
    if (!online) {
      setState(() {
        _loading = false;
        _error = 'تعذر الاتصال بالسيرفر. تأكد من الإنترنت ثم حاول مرة أخرى.';
      });
      return;
    }

    try {
      final session = widget.isTeacher
          ? await ApiService.startSession(
              userId: _userId.isEmpty ? 'teacher' : _userId,
              levelId: _levelId,
              subjectId: _subjectId,
              durationMinutes: 90,
            )
          : await ApiService.getActiveSessionForLecture(
              levelId: _levelId,
              subjectId: _subjectId,
            );

      if (!mounted) return;
      setState(() {
        _session = session;
        _loading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'حدث خطأ أثناء فتح المحاضرة: $error';
      });
    }
  }

  Future<void> _joinLecture() async {
    final session = _session;
    if (session == null || _joining) return;

    setState(() => _joining = true);
    try {
      final parts = _levelId.split('__');
      final department = parts.isNotEmpty ? parts.first : '';
      final level = parts.length > 1 ? parts.sublist(1).join('__') : '';
      await ApiService.markAttendance(
        lectureId: (session['lectureId'] ?? '').toString(),
        studentId: _userId,
        name: widget.userName,
        department: department,
        level: level,
        status: 'Present',
        levelId: _levelId,
        subjectId: _subjectId,
        teacherId: (session['teacherId'] ?? '').toString(),
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'تم تسجيل حضورك في المحاضرة',
            style: GoogleFonts.cairo(),
          ),
        ),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'تعذر تسجيل الحضور: $error',
            style: GoogleFonts.cairo(),
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => _joining = false);
    }
  }

  Future<void> _endLecture() async {
    final session = _session;
    if (session == null) return;
    await ApiService.endSession(
      lectureId: (session['lectureId'] ?? '').toString(),
      levelId: _levelId,
      subjectId: _subjectId,
      presentStudentCodes: const [],
      teacherId: _userId,
    );
    if (!mounted) return;
    Navigator.pop(context);
  }

  String _remainingTime() {
    final session = _session;
    if (session == null) return '--:--';
    final expiresAt = int.tryParse((session['expiresAt'] ?? 0).toString()) ?? 0;
    final remaining = DateTime.fromMillisecondsSinceEpoch(
      expiresAt,
    ).difference(DateTime.now());
    if (remaining.isNegative) return '00:00';
    final hours = remaining.inHours;
    final minutes = (remaining.inMinutes % 60).toString().padLeft(2, '0');
    final seconds = (remaining.inSeconds % 60).toString().padLeft(2, '0');
    return hours > 0 ? '$hours:$minutes:$seconds' : '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        appBar: AppBar(
          title: Text(
            widget.channelName,
            style: GoogleFonts.cairo(fontWeight: FontWeight.bold),
          ),
          leading: IconButton(
            icon: const Icon(LucideIcons.arrowRight),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: _loading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
            ? _buildMessage(
                icon: LucideIcons.wifiOff,
                title: 'تعذر فتح المحاضرة',
                message: _error!,
                actionText: 'إعادة المحاولة',
                onAction: _loadSession,
              )
            : widget.isTeacher
            ? _buildTeacherView()
            : _buildStudentView(),
      ),
    );
  }

  Widget _buildTeacherView() {
    final session = _session;
    if (session == null) {
      return _buildMessage(
        icon: LucideIcons.videoOff,
        title: 'لم تبدأ المحاضرة',
        message: 'اضغط إعادة المحاولة لبدء جلسة جديدة على السيرفر.',
        actionText: 'إعادة المحاولة',
        onAction: _loadSession,
      );
    }

    final code = (session['code'] ?? '').toString();
    final lectureId = (session['lectureId'] ?? '').toString();
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        _statusHeader('المحاضرة تعمل الآن أونلاين', LucideIcons.radio),
        const SizedBox(height: 18),
        _infoTile('كود الانضمام', code, LucideIcons.keyRound),
        _infoTile('معرف المحاضرة', lectureId, LucideIcons.hash),
        _infoTile('الوقت المتبقي', _remainingTime(), LucideIcons.clock),
        const SizedBox(height: 20),
        Center(
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.black12),
            ),
            child: QrImageView(data: code, version: QrVersions.auto, size: 190),
          ),
        ),
        const SizedBox(height: 24),
        FilledButton.icon(
          onPressed: _endLecture,
          icon: const Icon(LucideIcons.square),
          label: Text(
            'إنهاء المحاضرة',
            style: GoogleFonts.cairo(fontWeight: FontWeight.bold),
          ),
          style: FilledButton.styleFrom(
            backgroundColor: Colors.red[600],
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 14),
          ),
        ),
      ],
    );
  }

  Widget _buildStudentView() {
    final session = _session;
    if (session == null) {
      return _buildMessage(
        icon: LucideIcons.videoOff,
        title: 'لا توجد محاضرة نشطة الآن',
        message: 'اطلب من المعلم بدء المحاضرة ثم اضغط تحديث.',
        actionText: 'تحديث',
        onAction: _loadSession,
      );
    }

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        _statusHeader('تم العثور على محاضرة أونلاين', LucideIcons.video),
        const SizedBox(height: 18),
        _infoTile('المادة', widget.channelName, LucideIcons.bookOpen),
        _infoTile(
          'كود المحاضرة',
          (session['code'] ?? '').toString(),
          LucideIcons.keyRound,
        ),
        _infoTile('الوقت المتبقي', _remainingTime(), LucideIcons.clock),
        const SizedBox(height: 24),
        FilledButton.icon(
          onPressed: _joining ? null : _joinLecture,
          icon: _joining
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(LucideIcons.checkCircle),
          label: Text(
            _joining ? 'جاري التسجيل...' : 'تسجيل الحضور والانضمام',
            style: GoogleFonts.cairo(fontWeight: FontWeight.bold),
          ),
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 14),
          ),
        ),
      ],
    );
  }

  Widget _statusHeader(String title, IconData icon) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.22)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: AppColors.primary,
            child: Icon(icon, color: Colors.white),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              title,
              style: GoogleFonts.cairo(
                fontSize: 17,
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.onSurface,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoTile(String title, String value, IconData icon) {
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.dividerColor.withValues(alpha: 0.45)),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppColors.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.cairo(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value.isEmpty ? '-' : value,
                  style: GoogleFonts.cairo(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessage({
    required IconData icon,
    required String title,
    required String message,
    required String actionText,
    required VoidCallback onAction,
  }) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 88,
              height: 88,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 42, color: AppColors.primary),
            ),
            const SizedBox(height: 20),
            Text(
              title,
              textAlign: TextAlign.center,
              style: GoogleFonts.cairo(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: GoogleFonts.cairo(
                fontSize: 14,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 18),
            OutlinedButton.icon(
              onPressed: onAction,
              icon: const Icon(LucideIcons.refreshCw),
              label: Text(actionText, style: GoogleFonts.cairo()),
            ),
          ],
        ),
      ),
    );
  }
}
