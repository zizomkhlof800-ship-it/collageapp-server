import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../constants/theme.dart';
import '../services/api_service.dart';
import '../services/data_service.dart';
import 'student_dashboard_screen.dart';

class StudentTakeExamScreen extends StatefulWidget {
  final ExamItem exam;
  final String studentCode;
  const StudentTakeExamScreen({
    super.key,
    required this.exam,
    required this.studentCode,
  });

  @override
  State<StudentTakeExamScreen> createState() => _StudentTakeExamScreenState();
}

class _StudentTakeExamScreenState extends State<StudentTakeExamScreen>
    with WidgetsBindingObserver {
  List<Map<String, dynamic>> _questions = [];
  final Map<int, dynamic> _answers = {};
  Timer? _timer;
  int _secondsRemaining = 0;
  int _cheatWarnings = 0;
  bool _isSubmitted = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _secondsRemaining = _calculateInitialSeconds();
    _fetchQuestions();
    _startTimer();
  }

  int _calculateInitialSeconds() {
    final now = DateTime.now();
    final durationSeconds = (widget.exam.durationMinutes ?? 30) * 60;
    final endTime = widget.exam.endTime == null
        ? null
        : DateTime.tryParse(widget.exam.endTime!);
    if (endTime == null) return durationSeconds;
    final endRemaining = endTime.difference(now).inSeconds;
    if (endRemaining <= 0) return 0;
    return endRemaining < durationSeconds ? endRemaining : durationSeconds;
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _timer?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (_isSubmitted) return;
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      _handleCheatDetection();
    }
  }

  void _handleCheatDetection() {
    _cheatWarnings++;
    if (_cheatWarnings == 1) {
      _showCheatWarning();
    } else if (_cheatWarnings >= 2) {
      _autoSubmitForCheating();
    }
  }

  void _showCheatWarning() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          title: Text(
            'تحذير غش!',
            style: GoogleFonts.cairo(
              color: Colors.red,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Text(
            'لقد غادرت شاشة الامتحان. هذا هو الإنذار الأول. في المرة القادمة سيتم سحب الورقة وتصفير الدرجة تلقائياً.',
            style: GoogleFonts.cairo(),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'فهمت، سأكمل الامتحان',
                style: GoogleFonts.cairo(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _autoSubmitForCheating() async {
    if (_isSubmitted) return;
    _isSubmitted = true;
    _timer?.cancel();

    // Score 0 due to cheating
    try {
      await ApiService.addExamResult({
        'studentCode': widget.studentCode,
        'examId': widget.exam.id,
        'department': widget.exam.department,
        'level': widget.exam.level,
        'correct': 0,
        'wrong': _questions.length,
        'total': _questions.length,
        'score': 0.0,
        'submittedAt': DateTime.now().toIso8601String(),
      });
    } catch (_) {}

    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          title: Text(
            'تم سحب الورقة!',
            style: GoogleFonts.cairo(
              color: Colors.red,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Text(
            'لقد تكررت محاولة مغادرة التطبيق، تم إلغاء امتحانك وتسجيل درجة (صفر).',
            style: GoogleFonts.cairo(),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context); // Close dialog
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(
                    builder: (context) => StudentDashboardScreen(
                      studentCode: widget.studentCode,
                      department: widget.exam.department,
                      level: widget.exam.level,
                    ),
                  ),
                  (route) => false,
                );
              },
              child: Text(
                'العودة للرئيسية',
                style: GoogleFonts.cairo(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _startTimer() {
    if (_secondsRemaining <= 0) {
      scheduleMicrotask(() => _submitExam(isAutoSubmit: true));
      return;
    }
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsRemaining > 0) {
        setState(() {
          _secondsRemaining--;
        });
      } else {
        _timer?.cancel();
        _submitExam(isAutoSubmit: true);
      }
    });
  }

  String _formatTime(int seconds) {
    final mins = seconds ~/ 60;
    final secs = seconds % 60;
    return '${mins.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  Future<void> _fetchQuestions() async {
    try {
      final exam = await ApiService.getExamById(widget.exam.id);
      List<Map<String, dynamic>> qs = List<Map<String, dynamic>>.from(
        (exam['questions'] ?? []).map((e) => Map<String, dynamic>.from(e)),
      );
      if (qs.isEmpty) {
        qs = [
          ...List.generate(
            widget.exam.tfCount,
            (i) => {
              'type': 'tf',
              'question': 'سؤال صح/خطأ ${i + 1}',
              'correct': 'true',
            },
          ),
          ...List.generate(
            widget.exam.mcqCount,
            (i) => {
              'type': 'mcq',
              'question': 'سؤال اختيار من متعدد ${i + 1}',
              'options': ['اختيار 1', 'اختيار 2', 'اختيار 3', 'اختيار 4'],
              'correctIndex': 0,
            },
          ),
        ];
      }

      // Shuffle questions
      qs.shuffle();

      // For each MCQ, shuffle options while maintaining correct answer
      for (var q in qs) {
        if (q['type'] == 'mcq') {
          final options = List<String>.from(q['options'] ?? []);
          final correctIdx =
              int.tryParse((q['correctIndex'] ?? 0).toString()) ?? 0;
          final correctText = options[correctIdx];

          options.shuffle();
          q['options'] = options;
          q['correctIndex'] = options.indexOf(correctText);
        }
      }

      if (mounted) {
        setState(() {
          _questions = qs;
        });
      }
    } catch (_) {}
  }

  void _submitExam({bool isAutoSubmit = false}) async {
    if (_isSubmitted) return;

    if (!isAutoSubmit) {
      final allAnswered = _answers.length == _questions.length;
      if (!allAnswered) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'أكمل جميع الأسئلة قبل الإنهاء',
              style: GoogleFonts.cairo(),
            ),
          ),
        );
        return;
      }
    }

    _isSubmitted = true;
    _timer?.cancel();

    int correct = 0;
    int wrong = 0;
    final total = _questions.length;
    for (int i = 0; i < _questions.length; i++) {
      final q = _questions[i];
      final type = (q['type'] ?? '').toString();
      if (type == 'tf') {
        final ans = (_answers[i] as bool?);
        if (ans == null) {
          wrong++;
          continue;
        }
        final correctStr = (q['correct'] ?? '').toString().toLowerCase();
        final corr = correctStr == 'true' || q['answer'] == true;
        if (ans == corr) {
          correct++;
        } else {
          wrong++;
        }
      } else {
        final ans = (_answers[i] as int?);
        if (ans == null) {
          wrong++;
          continue;
        }
        final corrIdx =
            int.tryParse((q['correctIndex'] ?? q['answer'] ?? -1).toString()) ??
            -1;
        if (ans == corrIdx) {
          correct++;
        } else {
          wrong++;
        }
      }
    }

    final score = total > 0 ? (correct * 100.0 / total) : 0.0;

    try {
      await ApiService.addExamResult({
        'studentCode': widget.studentCode,
        'examId': widget.exam.id,
        'department': widget.exam.department,
        'level': widget.exam.level,
        'correct': correct,
        'wrong': wrong,
        'total': total,
        'score': double.parse(score.toStringAsFixed(2)),
        'submittedAt': DateTime.now().toIso8601String(),
      });
    } catch (_) {}

    if (!mounted) return;

    // Clear stack and go to dashboard
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (context) => StudentDashboardScreen(
          studentCode: widget.studentCode,
          department: widget.exam.department,
          level: widget.exam.level,
        ),
      ),
      (route) => false,
    );

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('تم تسليم الامتحان بنجاح', style: GoogleFonts.cairo()),
        backgroundColor: Colors.green,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: context.appBackground,
        appBar: AppBar(
          backgroundColor: context.appSurface,
          elevation: 0,
          leading: IconButton(
            icon: Icon(LucideIcons.arrowRight, color: context.appText),
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => Directionality(
                  textDirection: TextDirection.rtl,
                  child: AlertDialog(
                    title: Text(
                      'تنبيه',
                      style: GoogleFonts.cairo(fontWeight: FontWeight.bold),
                    ),
                    content: Text(
                      'هل أنت متأكد من الخروج؟ سيتم تسليم إجاباتك الحالية.',
                      style: GoogleFonts.cairo(),
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: Text('إلغاء', style: GoogleFonts.cairo()),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.pop(context);
                          _submitExam();
                        },
                        child: Text(
                          'خروج وتسليم',
                          style: GoogleFonts.cairo(color: Colors.red),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.exam.subject,
                style: GoogleFonts.cairo(
                  color: context.appText,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              Text(
                'المؤقت: ${_formatTime(_secondsRemaining)}',
                style: GoogleFonts.cairo(
                  color: _secondsRemaining < 60
                      ? Colors.red
                      : AppColors.primary,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          actions: [
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Center(
                child: Text(
                  '${_answers.length} / ${_questions.length}',
                  style: GoogleFonts.cairo(
                    color: AppColors.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
        body: Column(
          children: [
            LinearProgressIndicator(
              value: _questions.isEmpty
                  ? 0
                  : _answers.length / _questions.length,
              backgroundColor: AppColors.primary.withValues(alpha: 0.1),
              valueColor: const AlwaysStoppedAnimation<Color>(
                AppColors.primary,
              ),
            ),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: _questions.length,
                itemBuilder: (context, i) {
                  final q = _questions[i];
                  final type = (q['type'] ?? '').toString();
                  final title = (q['question'] ?? 'سؤال').toString();
                  final options = List<String>.from(
                    (q['options'] ?? []).map((e) => e.toString()),
                  );
                  return Card(
                    margin: const EdgeInsets.only(bottom: 16),
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              CircleAvatar(
                                radius: 12,
                                backgroundColor: AppColors.primary,
                                child: Text(
                                  '${i + 1}',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  title,
                                  style: GoogleFonts.cairo(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          if (type == 'tf')
                            _buildTFOptions(i)
                          else
                            _buildMCQOptions(i, options),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _submitExam,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 4,
                  ),
                  child: Text(
                    'إنهاء وتسليم الاختبار',
                    style: GoogleFonts.cairo(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTFOptions(int index) {
    return Column(
      children: [
        _buildOptionTile(
          title: 'صح',
          value: true,
          groupValue: _answers[index],
          onChanged: (v) => setState(() => _answers[index] = v),
        ),
        const SizedBox(height: 8),
        _buildOptionTile(
          title: 'خطأ',
          value: false,
          groupValue: _answers[index],
          onChanged: (v) => setState(() => _answers[index] = v),
        ),
      ],
    );
  }

  Widget _buildMCQOptions(int index, List<String> options) {
    return Column(
      children: List.generate(options.length, (optIdx) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: _buildOptionTile(
            title: options[optIdx],
            value: optIdx,
            groupValue: _answers[index],
            onChanged: (v) => setState(() => _answers[index] = v),
          ),
        );
      }),
    );
  }

  Widget _buildOptionTile({
    required String title,
    required dynamic value,
    required dynamic groupValue,
    required ValueChanged<dynamic> onChanged,
  }) {
    final isSelected = value == groupValue;
    return InkWell(
      onTap: () => onChanged(value),
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary.withValues(alpha: 0.05)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.inputBorder,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected ? AppColors.primary : context.appTextLight,
                  width: 2,
                ),
              ),
              child: isSelected
                  ? Center(
                      child: Container(
                        width: 10,
                        height: 10,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.primary,
                        ),
                      ),
                    )
                  : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: GoogleFonts.cairo(
                  color: isSelected ? AppColors.primary : context.appText,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
