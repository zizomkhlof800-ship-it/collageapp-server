import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../constants/theme.dart';
import '../services/api_service.dart';

class TeacherExamResultsScreen extends StatefulWidget {
  const TeacherExamResultsScreen({super.key});

  @override
  State<TeacherExamResultsScreen> createState() => _TeacherExamResultsScreenState();
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
        backgroundColor: const Color(0xFFF8F9FA),
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          title: Text('نتائج الاختبارات', style: GoogleFonts.cairo(color: AppColors.text, fontWeight: FontWeight.bold)),
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
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4))],
                      ),
                      child: Center(child: Text('لا توجد اختبارات حالياً', style: GoogleFonts.cairo(color: AppColors.textLight))),
                    );
                  }
                  final e = _exams[index];
                  final subject = (e['subject'] ?? '').toString();
                  final department = (e['department'] ?? '').toString();
                  final level = (e['level'] ?? '').toString();
                  final tf = int.tryParse((e['tfCount'] ?? 0).toString()) ?? 0;
                  final mcq = int.tryParse((e['mcqCount'] ?? 0).toString()) ?? 0;
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
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4))],
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: Colors.blue.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(LucideIcons.fileCheck, color: Colors.blue),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(subject.isEmpty ? 'اختبار' : subject, style: GoogleFonts.cairo(fontWeight: FontWeight.bold)),
                                const SizedBox(height: 4),
                                Text('$department • $level', style: GoogleFonts.cairo(color: Colors.grey[600], fontSize: 12)),
                                const SizedBox(height: 4),
                                Text('أسئلة: ${tf + mcq} (صح/خطأ: $tf • اختيار: $mcq)', style: GoogleFonts.cairo(color: Colors.grey[600], fontSize: 12)),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(createdAt.isNotEmpty ? createdAt.split('T').first : '', style: GoogleFonts.cairo(color: Colors.grey[600], fontSize: 12)),
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
  const ExamResultsDetailsScreen({super.key, required this.examId, required this.subject, required this.department, required this.level});

  @override
  State<ExamResultsDetailsScreen> createState() => _ExamResultsDetailsScreenState();
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
      final students = await ApiService.getStudents(department: widget.department, level: widget.level);
      for (final s in students) {
        final code = (s['studentCode'] ?? s['code'] ?? '').toString();
        if (code.isEmpty) continue;
        try {
          final latest = await ApiService.getLatestExamResult(code);
          if (latest == null) continue;
          final examId = (latest['examId'] ?? '').toString();
          if (examId == widget.examId) {
            _rows.add({
              'code': code,
              'name': (s['fullName'] ?? s['name'] ?? '').toString(),
              'score': double.tryParse((latest['score'] ?? 0).toString()) ?? 0.0,
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

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFFF8F9FA),
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          title: Text('نتائج: ${widget.subject}', style: GoogleFonts.cairo(color: AppColors.text, fontWeight: FontWeight.bold)),
          leading: IconButton(
            icon: const Icon(LucideIcons.arrowRight, color: AppColors.primary),
            onPressed: () => Navigator.pop(context),
          ),
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
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4))],
                      ),
                      child: Center(child: Text('لا توجد نتائج مسجلة لهذا الاختبار', style: GoogleFonts.cairo(color: AppColors.textLight))),
                    );
                  }
                  final r = _rows[index];
                  return Container(
                    padding: const EdgeInsets.all(16),
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4))],
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
                                color: Colors.green.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(LucideIcons.user, color: Colors.green),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    (r['name'] ?? '').toString(),
                                    style: GoogleFonts.cairo(fontWeight: FontWeight.bold),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    (r['code'] ?? '').toString(),
                                    style: GoogleFonts.cairo(color: Colors.grey[600], fontSize: 12),
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
                          style: GoogleFonts.cairo(color: AppColors.text),
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          alignment: WrapAlignment.spaceBetween,
                          runSpacing: 8,
                          spacing: 8,
                          children: [
                            _badge('صحيح', (r['correct'] ?? 0).toString(), Colors.green),
                            _badge('خطأ', (r['wrong'] ?? 0).toString(), Colors.red),
                            _badge('إجمالي', (r['total'] ?? 0).toString(), Colors.blue),
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
      decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
      child: Row(
        children: [
          Container(width: 6, height: 6, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
          const SizedBox(width: 6),
          Text('$title: $value', style: GoogleFonts.cairo(color: color, fontSize: 12)),
        ],
      ),
    );
  }
}
