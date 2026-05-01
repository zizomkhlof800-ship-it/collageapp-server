import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../constants/theme.dart';
import 'student_take_exam_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/data_service.dart';
import '../services/api_service.dart';

class StudentElectronicExamsScreen extends StatefulWidget {
  final String department;
  final String level;
  final String studentCode;
  const StudentElectronicExamsScreen({
    super.key,
    required this.department,
    required this.level,
    required this.studentCode,
  });

  @override
  State<StudentElectronicExamsScreen> createState() =>
      _StudentElectronicExamsScreenState();
}

class _StudentElectronicExamsScreenState
    extends State<StudentElectronicExamsScreen> {
  final DataService _dataService = DataService();
  String? _lastCompletedExamId;
  Map<String, dynamic>? _latestResult;

  @override
  void initState() {
    super.initState();
    _dataService.addListener(_onDataChanged);
    _dataService.fetchExams();
    _loadLastCompleted();
    _fetchLatestResult();
  }

  @override
  void dispose() {
    _dataService.removeListener(_onDataChanged);
    super.dispose();
  }

  void _onDataChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _loadLastCompleted() async {
    final prefs = await SharedPreferences.getInstance();
    _lastCompletedExamId = prefs.getString('last_exam_completed_id');
    if (mounted) setState(() {});
  }

  Future<void> _setLastCompleted(String id) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('last_exam_completed_id', id);
    _lastCompletedExamId = id;
    if (mounted) setState(() {});
  }

  Future<void> _fetchLatestResult() async {
    try {
      final res = await ApiService.getLatestExamResult(widget.studentCode);
      _latestResult = res;
      if (mounted) setState(() {});
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final exams = _dataService.exams
        .where(
          (e) => e.department == widget.department && e.level == widget.level,
        )
        .toList();
    final lastExam = _lastCompletedExamId == null
        ? null
        : exams.firstWhere(
            (e) => e.id == _lastCompletedExamId,
            orElse: () => exams.isNotEmpty
                ? exams.first
                : ExamItem(
                    id: '',
                    subject: '',
                    department: '',
                    level: '',
                    tfCount: 0,
                    mcqCount: 0,
                    createdAt: '',
                  ),
          );

    // Check if result should be shown (after endTime)
    bool showResultDetails = false;
    if (lastExam != null && lastExam.endTime != null) {
      final end = DateTime.tryParse(lastExam.endTime!);
      if (end != null && DateTime.now().isAfter(end)) {
        showResultDetails = true;
      }
    } else if (lastExam != null) {
      // If no end time specified, show it anyway or default to true
      showResultDetails = true;
    }

    final showStats = lastExam != null && lastExam.id.isNotEmpty;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: context.appBackground,
        appBar: AppBar(
          backgroundColor: context.appSurface,
          elevation: 0,
          centerTitle: false,
          leading: IconButton(
            icon: Icon(LucideIcons.arrowRight, color: context.appText),
            onPressed: () => Navigator.pop(context),
          ),
          title: Text(
            'الاختبارات الالكترونية',
            style: GoogleFonts.cairo(
              color: context.appText,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (showStats)
                _buildStatsCard(lastExam, showResultDetails)
              else
                _buildStatsCard(null, false),
              const SizedBox(height: 16),
              Text(
                'اختبارات مضافة من قبل أعضاء التدريس',
                style: GoogleFonts.cairo(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: context.appText,
                ),
              ),
              const SizedBox(height: 12),
              if (exams.isEmpty)
                _buildEmptyPlaceholder()
              else
                ...exams.map((e) => _buildExamCard(e)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatsCard(ExamItem? exam, bool showDetails) {
    if (exam == null) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: context.appSurface,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(
                alpha: context.isDarkMode ? 0.18 : 0.05,
              ),
              blurRadius: 6,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            const Icon(LucideIcons.barChart3, color: AppColors.primary),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'لا توجد إحصائيات متاحة بعد',
                style: GoogleFonts.cairo(color: context.appTextLight),
              ),
            ),
          ],
        ),
      );
    }

    if (!showDetails && _latestResult != null) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: context.appSurface,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(
                alpha: context.isDarkMode ? 0.18 : 0.05,
              ),
              blurRadius: 6,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          children: [
            Row(
              children: [
                const Icon(LucideIcons.checkCircle, color: Colors.green),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'تم تسليم اختبار (${exam.subject}) بنجاح.',
                    style: GoogleFonts.cairo(
                      fontWeight: FontWeight.bold,
                      color: context.appText,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'سيتم عرض النتيجة والمراجعة فور انتهاء وقت الامتحان الكلي.',
              style: GoogleFonts.cairo(
                fontSize: 12,
                color: context.appTextLight,
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.appSurface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(
              alpha: context.isDarkMode ? 0.18 : 0.05,
            ),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Icon(LucideIcons.barChart3, color: AppColors.primary),
              const SizedBox(width: 8),
              Text(
                'إحصائيات الاختبار الأخير',
                style: GoogleFonts.cairo(
                  fontWeight: FontWeight.bold,
                  color: context.appText,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildStatItem('اسم المادة', exam.subject, LucideIcons.bookOpen),
              _buildStatItem(
                'عدد الأسئلة',
                (exam.tfCount + exam.mcqCount).toString(),
                LucideIcons.listChecks,
              ),
              _buildStatItem(
                'النتيجة',
                _latestResult == null
                    ? '-'
                    : '${(_latestResult?['score'] ?? 0).toString()}%',
                LucideIcons.badgeCheck,
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (_latestResult != null)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildStatItem(
                  'صحيح',
                  (_latestResult?['correct'] ?? 0).toString(),
                  LucideIcons.check,
                ),
                _buildStatItem(
                  'خطأ',
                  (_latestResult?['wrong'] ?? 0).toString(),
                  LucideIcons.x,
                ),
                _buildStatItem(
                  'تم الإنهاء',
                  (_latestResult?['submittedAt'] ?? '').toString(),
                  LucideIcons.calendarClock,
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String title, String value, IconData icon) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: context.appBackground,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(icon, color: AppColors.primary, size: 18),
                const SizedBox(width: 6),
                Text(
                  title,
                  style: GoogleFonts.cairo(
                    fontSize: 12,
                    color: context.appTextLight,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              value,
              style: GoogleFonts.cairo(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: context.appText,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExamCard(ExamItem exam) {
    return InkWell(
      onTap: () async {
        final now = DateTime.now();
        final existingResult = await ApiService.getExamResult(
          widget.studentCode,
          exam.id,
        );
        if (existingResult != null) {
          await _setLastCompleted(exam.id);
          _latestResult = existingResult;
          if (mounted) setState(() {});
          final end = exam.endTime == null
              ? null
              : DateTime.tryParse(exam.endTime!);
          final canShowScore = end == null || now.isAfter(end);
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                canShowScore
                    ? 'تم تسليم هذا الامتحان من قبل. نتيجتك: ${existingResult['score'] ?? 0}%'
                    : 'تم تسليم هذا الامتحان من قبل. ستظهر النتيجة بعد انتهاء الوقت.',
                style: GoogleFonts.cairo(),
              ),
            ),
          );
          return;
        }
        if (!mounted) return;
        if (exam.startTime != null) {
          final start = DateTime.tryParse(exam.startTime!);
          if (start != null && now.isBefore(start)) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'عذراً، هذا الاختبار لم يبدأ بعد.',
                  style: GoogleFonts.cairo(),
                ),
              ),
            );
            return;
          }
        }
        if (exam.endTime != null) {
          final end = DateTime.tryParse(exam.endTime!);
          if (end != null && now.isAfter(end)) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'عذراً، انتهى وقت هذا الاختبار.',
                  style: GoogleFonts.cairo(),
                ),
              ),
            );
            return;
          }
        }

        final result = await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => StudentTakeExamScreen(
              exam: exam,
              studentCode: widget.studentCode,
            ),
          ),
        );
        if (result is Map &&
            result['completed'] == true &&
            result['examId'] == exam.id) {
          await _setLastCompleted(exam.id);
          await _fetchLatestResult();
        }
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: context.appSurface,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(
                alpha: context.isDarkMode ? 0.18 : 0.05,
              ),
              blurRadius: 6,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                const Icon(LucideIcons.fileQuestion, color: AppColors.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    exam.subject,
                    style: GoogleFonts.cairo(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: context.appText,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(
                  LucideIcons.graduationCap,
                  size: 14,
                  color: context.appTextLight,
                ),
                const SizedBox(width: 6),
                Text(
                  '${exam.level} - ${exam.department}',
                  style: GoogleFonts.cairo(
                    fontSize: 12,
                    color: context.appTextLight,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                Icon(
                  LucideIcons.checkCheck,
                  size: 14,
                  color: context.appTextLight,
                ),
                const SizedBox(width: 6),
                Text(
                  'صح/خطأ: ${exam.tfCount}',
                  style: GoogleFonts.cairo(
                    fontSize: 12,
                    color: context.appTextLight,
                  ),
                ),
                const SizedBox(width: 12),
                Icon(
                  LucideIcons.listChecks,
                  size: 14,
                  color: context.appTextLight,
                ),
                const SizedBox(width: 6),
                Text(
                  'اختيار متعدد: ${exam.mcqCount}',
                  style: GoogleFonts.cairo(
                    fontSize: 12,
                    color: context.appTextLight,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyPlaceholder() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: context.appSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.appBorder),
      ),
      child: Column(
        children: [
          Icon(LucideIcons.fileQuestion, size: 48, color: context.appTextLight),
          const SizedBox(height: 8),
          Text(
            'لا توجد اختبارات مضافة بعد',
            style: GoogleFonts.cairo(color: context.appTextLight),
          ),
        ],
      ),
    );
  }
}
