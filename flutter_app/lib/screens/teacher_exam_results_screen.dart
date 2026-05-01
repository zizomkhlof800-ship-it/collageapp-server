import 'package:flutter/material.dart';
import 'dart:typed_data';
import 'package:excel/excel.dart' as xls;
import 'package:file_picker/file_picker.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../constants/theme.dart';
import '../services/api_service.dart';

class TeacherExamResultsScreen extends StatefulWidget {
  const TeacherExamResultsScreen({super.key});

  @override
  State<TeacherExamResultsScreen> createState() =>
      _TeacherExamResultsScreenState();
}

class _TeacherExamResultsScreenState extends State<TeacherExamResultsScreen> {
  List<Map<String, dynamic>> _exams = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadExams();
  }

  Future<void> _loadExams() async {
    try {
      final rows = await ApiService.getExams();
      setState(() {
        _exams = rows;
        _loading = false;
      });
    } catch (_) {
      setState(() {
        _exams = [];
        _loading = false;
      });
    }
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
          title: Text(
            'نتائج الاختبارات',
            style: GoogleFonts.cairo(
              color: context.appText,
              fontWeight: FontWeight.bold,
            ),
          ),
          leading: IconButton(
            icon: const Icon(LucideIcons.arrowRight, color: AppColors.primary),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: _loading
            ? const Center(child: CircularProgressIndicator())
            : ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: _exams.isEmpty ? 1 : _exams.length,
                itemBuilder: (context, index) {
                  if (_exams.isEmpty) {
                    return Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: context.appSurface,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(
                              alpha: context.isDarkMode ? 0.18 : 0.03,
                            ),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Center(
                        child: Text(
                          'لا توجد اختبارات حالياً',
                          style: GoogleFonts.cairo(color: context.appTextLight),
                        ),
                      ),
                    );
                  }
                  final e = _exams[index];
                  final subject = (e['subject'] ?? '').toString();
                  final department = (e['department'] ?? '').toString();
                  final level = (e['level'] ?? '').toString();
                  final tf = int.tryParse((e['tfCount'] ?? 0).toString()) ?? 0;
                  final mcq =
                      int.tryParse((e['mcqCount'] ?? 0).toString()) ?? 0;
                  final createdAt = (e['createdAt'] ?? '').toString();
                  return InkWell(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ExamResultsDetailsScreen(
                            examId: (e['id'] ?? e['_id'] ?? '').toString(),
                            subject: subject,
                            department: department,
                            level: level,
                          ),
                        ),
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: context.appSurface,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(
                              alpha: context.isDarkMode ? 0.18 : 0.03,
                            ),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: Colors.blue.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              LucideIcons.fileCheck,
                              color: Colors.blue,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  subject.isEmpty ? 'اختبار' : subject,
                                  style: GoogleFonts.cairo(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '$department • $level',
                                  style: GoogleFonts.cairo(
                                    color: Colors.grey[600],
                                    fontSize: 12,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'أسئلة: ${tf + mcq} (صح/خطأ: $tf • اختيار: $mcq)',
                                  style: GoogleFonts.cairo(
                                    color: Colors.grey[600],
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            createdAt.isNotEmpty
                                ? createdAt.split('T').first
                                : '',
                            style: GoogleFonts.cairo(
                              color: Colors.grey[600],
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
      ),
    );
  }
}

class ExamResultsDetailsScreen extends StatefulWidget {
  final String examId;
  final String subject;
  final String department;
  final String level;
  const ExamResultsDetailsScreen({
    super.key,
    required this.examId,
    required this.subject,
    required this.department,
    required this.level,
  });

  @override
  State<ExamResultsDetailsScreen> createState() =>
      _ExamResultsDetailsScreenState();
}

class _ExamResultsDetailsScreenState extends State<ExamResultsDetailsScreen> {
  bool _loading = true;
  final List<Map<String, dynamic>> _rows = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final students = await ApiService.getStudents(
        department: widget.department,
        level: widget.level,
      );
      final results = await ApiService.getExamResults(widget.examId);
      for (final s in students) {
        final code = (s['studentCode'] ?? s['code'] ?? '').toString();
        if (code.isEmpty) continue;
        try {
          final latest = results.firstWhere(
            (row) => (row['studentCode'] ?? '').toString() == code,
            orElse: () => <String, dynamic>{},
          );
          if (latest.isEmpty) continue;
          final examId = (latest['examId'] ?? '').toString();
          if (examId == widget.examId) {
            _rows.add({
              'code': code,
              'name': (s['fullName'] ?? s['name'] ?? '').toString(),
              'score':
                  double.tryParse((latest['score'] ?? 0).toString()) ?? 0.0,
              'correct': int.tryParse((latest['correct'] ?? 0).toString()) ?? 0,
              'wrong': int.tryParse((latest['wrong'] ?? 0).toString()) ?? 0,
              'total': int.tryParse((latest['total'] ?? 0).toString()) ?? 0,
              'submittedAt': (latest['submittedAt'] ?? '').toString(),
            });
          }
        } catch (_) {}
      }
    } catch (_) {}
    setState(() {
      _loading = false;
    });
  }

  Future<void> _exportResults() async {
    final excel = xls.Excel.createExcel();
    final sheet = excel['Results'];
    sheet.appendRow([
      xls.TextCellValue('كود الطالب'),
      xls.TextCellValue('اسم الطالب'),
      xls.TextCellValue('الدرجة %'),
      xls.TextCellValue('صحيح'),
      xls.TextCellValue('خطأ'),
      xls.TextCellValue('الإجمالي'),
      xls.TextCellValue('وقت التسليم'),
    ]);
    for (final row in _rows) {
      sheet.appendRow([
        xls.TextCellValue((row['code'] ?? '').toString()),
        xls.TextCellValue((row['name'] ?? '').toString()),
        xls.DoubleCellValue(
          double.tryParse((row['score'] ?? 0).toString()) ?? 0,
        ),
        xls.IntCellValue(int.tryParse((row['correct'] ?? 0).toString()) ?? 0),
        xls.IntCellValue(int.tryParse((row['wrong'] ?? 0).toString()) ?? 0),
        xls.IntCellValue(int.tryParse((row['total'] ?? 0).toString()) ?? 0),
        xls.TextCellValue((row['submittedAt'] ?? '').toString()),
      ]);
    }
    final bytes = excel.encode();
    if (bytes == null) return;
    await FilePicker.platform.saveFile(
      dialogTitle: 'حفظ نتائج الامتحان',
      fileName: 'exam-results-${widget.examId}.xlsx',
      bytes: Uint8List.fromList(bytes),
    );
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('تم تجهيز ملف Excel', style: GoogleFonts.cairo()),
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
          title: Text(
            'نتائج: ${widget.subject}',
            style: GoogleFonts.cairo(
              color: context.appText,
              fontWeight: FontWeight.bold,
            ),
          ),
          leading: IconButton(
            icon: const Icon(LucideIcons.arrowRight, color: AppColors.primary),
            onPressed: () => Navigator.pop(context),
          ),
          actions: [
            IconButton(
              tooltip: 'تصدير Excel',
              icon: const Icon(LucideIcons.fileSpreadsheet),
              onPressed: _rows.isEmpty ? null : _exportResults,
            ),
          ],
        ),
        body: _loading
            ? const Center(child: CircularProgressIndicator())
            : ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: _rows.isEmpty ? 1 : _rows.length,
                itemBuilder: (context, index) {
                  if (_rows.isEmpty) {
                    return Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: context.appSurface,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(
                              alpha: context.isDarkMode ? 0.18 : 0.03,
                            ),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Center(
                        child: Text(
                          'لا توجد نتائج مسجلة لهذا الاختبار',
                          style: GoogleFonts.cairo(color: context.appTextLight),
                        ),
                      ),
                    );
                  }
                  final r = _rows[index];
                  return Container(
                    padding: const EdgeInsets.all(16),
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: context.appSurface,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(
                            alpha: context.isDarkMode ? 0.18 : 0.03,
                          ),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: Colors.green.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(
                                LucideIcons.user,
                                color: Colors.green,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    (r['name'] ?? '').toString(),
                                    style: GoogleFonts.cairo(
                                      fontWeight: FontWeight.bold,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    (r['code'] ?? '').toString(),
                                    style: GoogleFonts.cairo(
                                      color: Colors.grey[600],
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'النتيجة: ${((r['score'] ?? 0.0) as double).toStringAsFixed(2)}%',
                          textAlign: TextAlign.right,
                          style: GoogleFonts.cairo(color: context.appText),
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          alignment: WrapAlignment.spaceBetween,
                          runSpacing: 8,
                          spacing: 8,
                          children: [
                            _badge(
                              'صحيح',
                              (r['correct'] ?? 0).toString(),
                              Colors.green,
                            ),
                            _badge(
                              'خطأ',
                              (r['wrong'] ?? 0).toString(),
                              Colors.red,
                            ),
                            _badge(
                              'إجمالي',
                              (r['total'] ?? 0).toString(),
                              Colors.blue,
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              ),
      ),
    );
  }

  Widget _badge(String title, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Text(
            '$title: $value',
            style: GoogleFonts.cairo(color: color, fontSize: 12),
          ),
        ],
      ),
    );
  }
}
