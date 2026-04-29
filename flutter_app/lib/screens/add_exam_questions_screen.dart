import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../constants/theme.dart';
import '../services/data_service.dart';

class AddExamQuestionsScreen extends StatefulWidget {
  final int tfCount;
  final int mcqCount;
  final String subject;
  final String department;
  final String level;
  final String? examId;
  final List<Map<String, dynamic>>? initialQuestions;
  final String? startTime;
  final String? endTime;
  final int? durationMinutes;
  final bool isFromBank;

  const AddExamQuestionsScreen({
    super.key,
    required this.tfCount,
    required this.mcqCount,
    required this.subject,
    required this.department,
    required this.level,
    this.examId,
    this.initialQuestions,
    this.startTime,
    this.endTime,
    this.durationMinutes,
    this.isFromBank = false,
  });

  @override
  State<AddExamQuestionsScreen> createState() => _AddExamQuestionsScreenState();
}

class _AddExamQuestionsScreenState extends State<AddExamQuestionsScreen> {
  late final List<TextEditingController> _tfQuestionControllers;
  late final List<bool> _tfCorrectIsTrue;

  late final List<TextEditingController> _mcqQuestionControllers;
  late final List<List<TextEditingController>> _mcqOptionControllers; // 4 options each
  late final List<int> _mcqCorrectIndex; // 0..3

  @override
  void initState() {
    super.initState();
    _tfQuestionControllers = List.generate(widget.tfCount, (_) => TextEditingController());
    _tfCorrectIsTrue = List.generate(widget.tfCount, (_) => true);
    _mcqQuestionControllers = List.generate(widget.mcqCount, (_) => TextEditingController());
    _mcqOptionControllers = List.generate(widget.mcqCount, (_) => List.generate(4, (_) => TextEditingController()));
    _mcqCorrectIndex = List.generate(widget.mcqCount, (_) => 0);

    if (widget.isFromBank) {
      _loadFromBank();
    } else if (widget.initialQuestions != null && widget.initialQuestions!.isNotEmpty) {
      _fillQuestions(widget.initialQuestions!);
    }
  }

  Future<void> _loadFromBank() async {
    try {
      final tf = await DataService().getQuestionsFromBank(
        department: widget.department,
        level: widget.level,
        subject: widget.subject,
        type: 'tf',
      );
      final mcq = await DataService().getQuestionsFromBank(
        department: widget.department,
        level: widget.level,
        subject: widget.subject,
        type: 'mcq',
      );
      
      // Shuffle and take required count
      tf.shuffle();
      mcq.shuffle();
      
      final selectedTf = tf.take(widget.tfCount).toList();
      final selectedMcq = mcq.take(widget.mcqCount).toList();
      
      if (mounted) {
        setState(() {
          _fillQuestions([...selectedTf, ...selectedMcq]);
        });
      }
    } catch (_) {}
  }

  void _fillQuestions(List<Map<String, dynamic>> questions) {
    int tfI = 0;
    int mcqI = 0;
    for (final q in questions) {
      final type = (q['type'] ?? '').toString();
      if (type == 'tf' && tfI < _tfQuestionControllers.length) {
        _tfQuestionControllers[tfI].text = (q['question'] ?? '').toString();
        final corr = (q['correct'] ?? 'true').toString().toLowerCase() == 'true' || q['answer'] == true;
        _tfCorrectIsTrue[tfI] = corr;
        tfI++;
      } else if (type == 'mcq' && mcqI < _mcqQuestionControllers.length) {
        _mcqQuestionControllers[mcqI].text = (q['question'] ?? '').toString();
        final options = (q['options'] as List?)?.map((e) => e.toString()).toList() ?? const [];
        for (int k = 0; k < _mcqOptionControllers[mcqI].length && k < options.length; k++) {
          _mcqOptionControllers[mcqI][k].text = options[k];
        }
        final ci = int.tryParse((q['correctIndex'] ?? q['answer'] ?? 0).toString()) ?? 0;
        _mcqCorrectIndex[mcqI] = ci;
        mcqI++;
      }
    }
  }

  @override
  void dispose() {
    for (final c in _tfQuestionControllers) {
      c.dispose();
    }
    for (final list in _mcqOptionControllers) {
      for (final c in list) {
        c.dispose();
      }
    }
    for (final c in _mcqQuestionControllers) {
      c.dispose();
    }
    super.dispose();
  }

  void _saveExam() async {
    // Collect data and save via DataService
    final tfQuestions = List.generate(widget.tfCount, (i) => {
      'type': 'tf',
      'question': _tfQuestionControllers[i].text.trim(),
      'correct': _tfCorrectIsTrue[i] ? 'true' : 'false',
    }).where((q) => (q['question'] as String).isNotEmpty).toList();
    final mcqQuestions = List.generate(widget.mcqCount, (i) => {
      'type': 'mcq',
      'question': _mcqQuestionControllers[i].text.trim(),
      'options': _mcqOptionControllers[i].map((c) => c.text.trim()).toList(),
      'correctIndex': _mcqCorrectIndex[i],
    }).where((q) => (q['question'] as String).isNotEmpty).toList();

    final messenger = ScaffoldMessenger.of(context);
    if (tfQuestions.isEmpty && mcqQuestions.isEmpty) {
      messenger.showSnackBar(
        SnackBar(content: Text('أدخل أسئلة قبل الحفظ', style: GoogleFonts.cairo())),
      );
      return;
    }

    final questions = <Map<String, dynamic>>[];
    questions.addAll(tfQuestions);
    questions.addAll(mcqQuestions);
    final ds = DataService();
    final nav = Navigator.of(context);
    try {
      if (widget.examId != null && widget.examId!.isNotEmpty) {
        await ds.updateExam(
          id: widget.examId!,
          subject: widget.subject,
          department: widget.department,
          level: widget.level,
          questions: questions,
          tfCount: widget.tfCount,
          mcqCount: widget.mcqCount,
          startTime: widget.startTime,
          endTime: widget.endTime,
          durationMinutes: widget.durationMinutes,
          isFromBank: widget.isFromBank,
        );
      } else {
        await ds.addExam(
          subject: widget.subject,
          department: widget.department,
          level: widget.level,
          questions: questions,
          tfCount: widget.tfCount,
          mcqCount: widget.mcqCount,
          startTime: widget.startTime,
          endTime: widget.endTime,
          durationMinutes: widget.durationMinutes,
          isFromBank: widget.isFromBank,
        );
      }
      messenger.showSnackBar(
        SnackBar(content: Text('تم حفظ الاختبار', style: GoogleFonts.cairo()), backgroundColor: AppColors.cardGreenIcon),
      );
      nav.pop();
      nav.pop();
    } catch (_) {
      messenger.showSnackBar(
        SnackBar(content: Text('تعذر حفظ الاختبار على الخادم', style: GoogleFonts.cairo())),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          title: Text('إنشاء أسئلة الاختبار', style: GoogleFonts.cairo(fontWeight: FontWeight.bold, color: AppColors.text)),
          leading: IconButton(
            icon: const Icon(LucideIcons.arrowRight, color: AppColors.text),
            onPressed: () => Navigator.pop(context),
          ),
          actions: [
            TextButton(
              onPressed: _saveExam,
              child: Text('حفظ', style: GoogleFonts.cairo(color: AppColors.primary, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
        body: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            if (widget.tfCount > 0) ...[
              Text('أسئلة صح/خطأ', style: GoogleFonts.cairo(fontWeight: FontWeight.bold, color: AppColors.text)),
              const SizedBox(height: 8),
              ...List.generate(widget.tfCount, (i) => _buildTFCard(i)),
              const SizedBox(height: 16),
            ],
            if (widget.mcqCount > 0) ...[
              Text('أسئلة اختيار من متعدد', style: GoogleFonts.cairo(fontWeight: FontWeight.bold, color: AppColors.text)),
              const SizedBox(height: 8),
              ...List.generate(widget.mcqCount, (i) => _buildMCQCard(i)),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTFCard(int index) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _tfQuestionControllers[index],
              decoration: InputDecoration(
                labelText: 'نص السؤال',
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: RadioListTile<bool>(
                    value: true,
                    groupValue: _tfCorrectIsTrue[index],
                    onChanged: (v) => setState(() => _tfCorrectIsTrue[index] = v ?? true),
                    title: Text('صح', style: GoogleFonts.cairo()),
                  ),
                ),
                Expanded(
                  child: RadioListTile<bool>(
                    value: false,
                    groupValue: _tfCorrectIsTrue[index],
                    onChanged: (v) => setState(() => _tfCorrectIsTrue[index] = v ?? false),
                    title: Text('خطأ', style: GoogleFonts.cairo()),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMCQCard(int index) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _mcqQuestionControllers[index],
              decoration: InputDecoration(
                labelText: 'نص السؤال',
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 8),
            ...List.generate(4, (opt) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _mcqOptionControllers[index][opt],
                        decoration: InputDecoration(
                          labelText: 'اختيار ${opt + 1}',
                          border: const OutlineInputBorder(),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Radio<int>(
                      value: opt,
                      groupValue: _mcqCorrectIndex[index],
                      onChanged: (v) => setState(() => _mcqCorrectIndex[index] = v ?? 0),
                    ),
                    Text('صح', style: GoogleFonts.cairo()),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}
