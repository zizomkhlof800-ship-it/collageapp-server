import 'package:flutter/material.dart';
import 'dart:io'; // Added for File
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:file_picker/file_picker.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';
import 'dart:typed_data';
import '../services/api_service.dart';
import '../constants/theme.dart';

class QuestionBankScreen extends StatefulWidget {
  final String department;
  final String level;
  final String subject;

  const QuestionBankScreen({
    super.key,
    required this.department,
    required this.level,
    required this.subject,
  });

  @override
  State<QuestionBankScreen> createState() => _QuestionBankScreenState();
}

class _QuestionBankScreenState extends State<QuestionBankScreen> {
  bool _loading = true;
  bool _isParsing = false;
  List<Map<String, dynamic>> _questions = [];
  List<Map<String, dynamic>> _parsedQuestions = [];

  @override
  void initState() {
    super.initState();
    _loadQuestions();
  }

  Future<void> _loadQuestions() async {
    setState(() => _loading = true);
    try {
      final tf = await ApiService.getQuestionsFromBank(
        department: widget.department,
        level: widget.level,
        subject: widget.subject,
        type: 'tf',
      );
      final mcq = await ApiService.getQuestionsFromBank(
        department: widget.department,
        level: widget.level,
        subject: widget.subject,
        type: 'mcq',
      );
      if (mounted) {
        setState(() {
          _questions = [...(tf ?? []), ...(mcq ?? [])];
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _importFromPDF() async {
    final messenger = ScaffoldMessenger.of(context);
    
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
        withData: true, // Crucial for reading bytes directly
      );

      if (result == null || result.files.isEmpty) return;

      setState(() => _isParsing = true);

      final file = result.files.first;
      Uint8List? bytes = file.bytes;
      
      // If bytes are null (common on some Android versions/configurations), try reading from path
      if (bytes == null && file.path != null) {
        try {
          final ioFile = File(file.path!);
          if (await ioFile.exists()) {
            bytes = await ioFile.readAsBytes();
          }
        } catch (e) {
          debugPrint('Error reading file from path: $e');
        }
      }
      
      if (bytes == null) {
        throw Exception("لا يمكن قراءة الملف. يرجى المحاولة مرة أخرى.");
      }

      // 1. Load PDF
      final PdfDocument document = PdfDocument(inputBytes: bytes);
      
      // 2. Extract Text
      String text = PdfTextExtractor(document).extractText();
      document.dispose();

      if (text.trim().isEmpty) {
        throw Exception("الملف فارغ أو لا يحتوي على نص قابل للقراءة");
      }

      // 3. Parse Questions
      final questions = _parseTextToQuestions(text);
      
      if (questions.isEmpty) {
        throw Exception("لم يتم العثور على أسئلة بالتنسيق المطلوب (أ، ب، ج، د) أو (صح، خطأ)");
      }

      setState(() {
        _parsedQuestions = questions;
        _isParsing = false;
      });

      // Show review UI
      _showReviewDialog();

    } catch (e) {
      setState(() => _isParsing = false);
      messenger.showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceAll('Exception: ', ''), style: GoogleFonts.cairo()),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  List<Map<String, dynamic>> _parseTextToQuestions(String text) {
    final List<Map<String, dynamic>> questions = [];
    final lines = text.split('\n');
    
    Map<String, dynamic>? currentQuestion;
    List<String> currentOptions = [];
    int? correctAnswerIndex;
    bool? correctTFAnswer;

    for (var line in lines) {
      line = line.trim();
      if (line.isEmpty) continue;

      // Question detection: Ends with ? or ؟
      if (line.endsWith('?') || line.endsWith('؟')) {
        // Save previous question if exists
        if (currentQuestion != null) {
          _finalizeQuestion(questions, currentQuestion, currentOptions, correctAnswerIndex, correctTFAnswer);
        }
        
        // Start new question
        currentQuestion = {
          'department': widget.department,
          'level': widget.level,
          'subject': widget.subject,
          'question': line,
        };
        currentOptions = [];
        correctAnswerIndex = null;
        correctTFAnswer = null;
      } 
      // Option detection: Starts with أ، ب، ج، د or A, B, C, D
      else if (RegExp(r'^([أبجدABCD]|[أ-د])[\.\-\)]\s*').hasMatch(line)) {
        currentOptions.add(line.replaceFirst(RegExp(r'^([أبجدABCD]|[أ-د])[\.\-\)]\s*'), '').trim());
      }
      // True/False detection: contains صح، خطأ or ✔️، ❌
      else if (line.contains('صح') || line.contains('خطأ') || line.contains('✔️') || line.contains('❌')) {
        if (currentQuestion != null) {
          currentQuestion['type'] = 'tf';
          if (line.contains('صح') || line.contains('✔️')) {
            // This might be the answer line or just an option indicator
          }
        }
      }
      // Correct answer detection: Starts with الإجابة: or الجواب:
      if (line.startsWith('الإجابة:') || line.startsWith('الجواب:') || line.startsWith('Answer:')) {
        final answerPart = line.split(':').last.trim();
        
        // Check if it's MCQ answer (أ، ب، ج، د or A, B, C, D)
        if (RegExp(r'^[أبجدABCD]').hasMatch(answerPart)) {
          final char = answerPart[0];
          if (char == 'أ' || char == 'A') correctAnswerIndex = 0;
          else if (char == 'ب' || char == 'B') correctAnswerIndex = 1;
          else if (char == 'ج' || char == 'C') correctAnswerIndex = 2;
          else if (char == 'د' || char == 'D') correctAnswerIndex = 3;
        } 
        // Check if it's TF answer
        else if (answerPart.contains('صح') || answerPart.contains('✔️') || answerPart.contains('True')) {
          correctTFAnswer = true;
        } else if (answerPart.contains('خطأ') || answerPart.contains('❌') || answerPart.contains('False')) {
          correctTFAnswer = false;
        }
      }
    }

    // Finalize last question
    if (currentQuestion != null) {
      _finalizeQuestion(questions, currentQuestion, currentOptions, correctAnswerIndex, correctTFAnswer);
    }

    return questions;
  }

  void _finalizeQuestion(List<Map<String, dynamic>> questions, Map<String, dynamic> q, List<String> options, int? mcqAns, bool? tfAns) {
    if (options.isNotEmpty) {
      q['type'] = 'mcq';
      q['options'] = options;
      q['answer'] = mcqAns ?? 0; // Default to first if not found
      questions.add(q);
    } else {
      q['type'] = 'tf';
      q['answer'] = tfAns ?? true; // Default to true if not found
      questions.add(q);
    }
  }

  void _showReviewDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          title: Row(
            children: [
              const Icon(LucideIcons.clipboardCheck, color: Colors.green),
              const SizedBox(width: 8),
              Text('مراجعة الأسئلة المستخرجة', style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 16)),
            ],
          ),
          content: SizedBox(
            width: double.maxFinite,
            height: 400,
            child: ListView.separated(
              itemCount: _parsedQuestions.length,
              separatorBuilder: (context, index) => const Divider(),
              itemBuilder: (context, index) {
                final q = _parsedQuestions[index];
                return ListTile(
                  title: Text(q['question'], style: GoogleFonts.cairo(fontSize: 13, fontWeight: FontWeight.bold)),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(q['type'] == 'mcq' ? 'نوع: اختيار متعدد' : 'نوع: صح / خطأ', style: GoogleFonts.cairo(fontSize: 11, color: Colors.blue)),
                      if (q['type'] == 'mcq')
                        ... (q['options'] as List).map((opt) => Text('• $opt', style: GoogleFonts.cairo(fontSize: 11))),
                      Text('الإجابة: ${q['type'] == 'mcq' ? (q['options'] as List)[q['answer']] : (q['answer'] ? 'صح' : 'خطأ')}', 
                        style: GoogleFonts.cairo(fontSize: 11, color: Colors.green, fontWeight: FontWeight.bold)),
                    ],
                  ),
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                setState(() => _parsedQuestions = []);
                Navigator.pop(context);
              }, 
              child: Text('إلغاء', style: GoogleFonts.cairo(color: Colors.red))
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(context);
                setState(() => _loading = true);
                for (var q in _parsedQuestions) {
                  await ApiService.addQuestionToBank(q);
                }
                setState(() {
                  _parsedQuestions = [];
                  _loading = false;
                });
                _loadQuestions();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('تم حفظ جميع الأسئلة بنجاح', style: GoogleFonts.cairo()), backgroundColor: Colors.green),
                );
              },
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
              child: Text('تأكيد وحفظ بنك الأسئلة', style: GoogleFonts.cairo(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  void _addNewQuestion() {
    // Logic to show a dialog and add a manual question
    showDialog(
      context: context,
      builder: (context) => _AddQuestionDialog(
        department: widget.department,
        level: widget.level,
        subject: widget.subject,
        onAdded: _loadQuestions,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        appBar: AppBar(
          backgroundColor: theme.colorScheme.surface,
          elevation: 0,
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('بنك الأسئلة', style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 16)),
              Text(widget.subject, style: GoogleFonts.cairo(fontSize: 12, color: theme.colorScheme.primary)),
            ],
          ),
          leading: IconButton(
            icon: Icon(LucideIcons.arrowRight, color: theme.colorScheme.onSurface),
            onPressed: () => Navigator.pop(context),
          ),
          actions: [
            IconButton(
              icon: const Icon(LucideIcons.fileUp),
              tooltip: 'استيراد من PDF',
              onPressed: _importFromPDF,
            ),
          ],
        ),
        body: _loading || _isParsing
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const CircularProgressIndicator(),
                    if (_isParsing) ...[
                      const SizedBox(height: 16),
                      Text('جاري تحليل ملف الـ PDF واستخراج الأسئلة...', style: GoogleFonts.cairo(fontSize: 14)),
                    ],
                  ],
                ),
              )
            : _questions.isEmpty
                ? _buildEmptyState()
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _questions.length,
                    itemBuilder: (context, index) {
                      final q = _questions[index];
                      return _buildQuestionCard(q, theme);
                    },
                  ),
        floatingActionButton: FloatingActionButton(
          onPressed: _addNewQuestion,
          backgroundColor: theme.colorScheme.primary,
          child: const Icon(LucideIcons.plus, color: Colors.white),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(LucideIcons.database, size: 64, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text('لا توجد أسئلة في البنك لهذه المادة', style: GoogleFonts.cairo(color: Colors.grey)),
          const SizedBox(height: 8),
          Text('يمكنك إضافة أسئلة يدوياً أو استيرادها من ملف PDF', style: GoogleFonts.cairo(fontSize: 12, color: Colors.grey)),
        ],
      ),
    );
  }

  Widget _buildQuestionCard(Map<String, dynamic> q, ThemeData theme) {
    final isTF = q['type'] == 'tf';
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    isTF ? 'صح / خطأ' : 'اختيار متعدد',
                    style: GoogleFonts.cairo(fontSize: 10, color: theme.colorScheme.primary, fontWeight: FontWeight.bold),
                  ),
                ),
                IconButton(
                  icon: const Icon(LucideIcons.trash2, size: 18, color: Colors.red),
                  onPressed: () async {
                    await ApiService.deleteQuestionFromBank(q['id']);
                    _loadQuestions();
                  },
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(q['question'] ?? '', style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 14)),
            const SizedBox(height: 12),
            if (isTF)
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.green.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.green.withValues(alpha: 0.2)),
                ),
                child: Row(
                  children: [
                    const Icon(LucideIcons.checkCircle2, size: 16, color: Colors.green),
                    const SizedBox(width: 8),
                    Text('الإجابة الصحيحة: ${q['answer'] == true ? 'صح' : 'خطأ'}', style: GoogleFonts.cairo(color: Colors.green, fontSize: 12, fontWeight: FontWeight.bold)),
                  ],
                ),
              )
            else
              ...[
                ...(q['options'] as List).asMap().entries.map((e) {
                  final isCorrect = e.key == q['answer'];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Row(
                      children: [
                        Icon(isCorrect ? LucideIcons.checkCircle2 : LucideIcons.circle, size: 14, color: isCorrect ? Colors.green : Colors.grey),
                        const SizedBox(width: 8),
                        Expanded(child: Text(e.value.toString(), style: GoogleFonts.cairo(fontSize: 13, color: isCorrect ? Colors.green : null, fontWeight: isCorrect ? FontWeight.bold : null))),
                      ],
                    ),
                  );
                }),
              ],
          ],
        ),
      ),
    );
  }
}

class _AddQuestionDialog extends StatefulWidget {
  final String department;
  final String level;
  final String subject;
  final VoidCallback onAdded;

  const _AddQuestionDialog({
    required this.department,
    required this.level,
    required this.subject,
    required this.onAdded,
  });

  @override
  State<_AddQuestionDialog> createState() => _AddQuestionDialogState();
}

class _AddQuestionDialogState extends State<_AddQuestionDialog> {
  final _questionController = TextEditingController();
  final _optionControllers = List.generate(4, (_) => TextEditingController());
  String _type = 'mcq';
  int _correctIdx = 0;
  bool _tfCorrect = true;

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: AlertDialog(
        title: Text('إضافة سؤال جديد', style: GoogleFonts.cairo(fontWeight: FontWeight.bold)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                initialValue: _type,
                items: [
                  DropdownMenuItem(value: 'mcq', child: Text('اختيار متعدد', style: GoogleFonts.cairo())),
                  DropdownMenuItem(value: 'tf', child: Text('صح / خطأ', style: GoogleFonts.cairo())),
                ],
                onChanged: (v) => setState(() => _type = v!),
                decoration: const InputDecoration(labelText: 'نوع السؤال'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _questionController,
                decoration: const InputDecoration(labelText: 'نص السؤال'),
                maxLines: 2,
              ),
              const SizedBox(height: 12),
              if (_type == 'mcq') ...[
                ...List.generate(4, (i) => Row(
                  children: [
                    Expanded(child: TextField(controller: _optionControllers[i], decoration: InputDecoration(labelText: 'اختيار ${i + 1}'))),
                    Radio<int>(value: i, groupValue: _correctIdx, onChanged: (v) => setState(() => _correctIdx = v!)),
                  ],
                )),
              ] else ...[
                Row(
                  children: [
                    Expanded(
                      child: RadioListTile<bool>(
                        title: Text('صح', style: GoogleFonts.cairo()),
                        value: true,
                        groupValue: _tfCorrect,
                        onChanged: (v) => setState(() => _tfCorrect = v!),
                      ),
                    ),
                    Expanded(
                      child: RadioListTile<bool>(
                        title: Text('خطأ', style: GoogleFonts.cairo()),
                        value: false,
                        groupValue: _tfCorrect,
                        onChanged: (v) => setState(() => _tfCorrect = v!),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text('إلغاء', style: GoogleFonts.cairo())),
          ElevatedButton(
            onPressed: () async {
              if (_questionController.text.isEmpty) return;
              final question = {
                'department': widget.department,
                'level': widget.level,
                'subject': widget.subject,
                'type': _type,
                'question': _questionController.text,
                'options': _type == 'mcq' ? _optionControllers.map((c) => c.text).toList() : null,
                'answer': _type == 'mcq' ? _correctIdx : _tfCorrect,
              };
              await ApiService.addQuestionToBank(question);
              widget.onAdded();
              if (mounted) Navigator.pop(context);
            },
            child: Text('إضافة', style: GoogleFonts.cairo()),
          ),
        ],
      ),
    );
  }
}