import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:file_picker/file_picker.dart';
import '../services/data_service.dart';
import '../constants/theme.dart';
import 'pdf_viewer_screen.dart';

const int _maxSubmissionFileBytes = 8 * 1024 * 1024;

class StudentAssignmentsScreen extends StatefulWidget {
  final String department;
  final String level;
  final String studentCode;
  final String studentName;

  const StudentAssignmentsScreen({
    super.key,
    required this.department,
    required this.level,
    required this.studentCode,
    required this.studentName,
  });

  @override
  State<StudentAssignmentsScreen> createState() =>
      _StudentAssignmentsScreenState();
}

class _StudentAssignmentsScreenState extends State<StudentAssignmentsScreen> {
  final DataService _dataService = DataService();
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _dataService.addListener(_onDataChanged);
    _loadData();
  }

  @override
  void dispose() {
    _dataService.removeListener(_onDataChanged);
    super.dispose();
  }

  void _onDataChanged() {
    if (mounted) setState(() {});
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    await _dataService.fetchAssignments(
      department: widget.department,
      level: widget.level,
    );
    if (mounted) setState(() => _isLoading = false);
  }

  void _showSubmissionDialog(Assignment assignment) {
    final contentController = TextEditingController();
    PlatformFile? selectedFile;
    bool isSubmitting = false;
    double uploadProgress = 0;
    bool isUploading = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => Directionality(
          textDirection: TextDirection.rtl,
          child: AlertDialog(
            title: Text(
              'تسليم التكليف: ${assignment.title}',
              style: GoogleFonts.cairo(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: contentController,
                    maxLines: 4,
                    enabled: !isSubmitting && !isUploading,
                    decoration: InputDecoration(
                      labelText: 'اكتب ملاحظاتك أو النص هنا (اختياري)',
                      labelStyle: GoogleFonts.cairo(fontSize: 12),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      alignLabelWithHint: true,
                    ),
                  ),
                  const SizedBox(height: 16),
                  // PDF File Picker with Pre-upload simulation
                  InkWell(
                    onTap: (isSubmitting || isUploading)
                        ? null
                        : () async {
                            final result = await FilePicker.platform.pickFiles(
                              type: FileType.custom,
                              allowedExtensions: ['pdf'],
                              withData: true,
                            );
                            if (result != null) {
                              final file = result.files.first;
                              if (file.size > _maxSubmissionFileBytes) {
                                if (!context.mounted) return;
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      'حجم الملف كبير. أقصى حجم مسموح 8 ميجابايت.',
                                      style: GoogleFonts.cairo(),
                                    ),
                                    backgroundColor: Colors.orange,
                                  ),
                                );
                                return;
                              }
                              setDialogState(() {
                                selectedFile = file;
                                isUploading = true;
                                uploadProgress = 0;
                              });

                              // Simulate Pre-upload progress
                              for (int i = 0; i <= 10; i++) {
                                await Future.delayed(
                                  const Duration(milliseconds: 100),
                                );
                                if (!context.mounted) return;
                                setDialogState(() => uploadProgress = i / 10);
                              }

                              setDialogState(() => isUploading = false);
                            }
                          },
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey[300]!),
                        borderRadius: BorderRadius.circular(12),
                        color: Colors.grey[50],
                      ),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Icon(
                                selectedFile != null
                                    ? LucideIcons.checkCircle
                                    : LucideIcons.filePlus,
                                color: selectedFile != null
                                    ? Colors.green
                                    : Colors.grey,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  selectedFile != null
                                      ? selectedFile!.name
                                      : 'اضغط لاختيار ملف الحل (PDF)',
                                  style: GoogleFonts.cairo(
                                    color: selectedFile != null
                                        ? Colors.black
                                        : Colors.grey,
                                    fontSize: 13,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (selectedFile != null &&
                                  !isUploading &&
                                  !isSubmitting)
                                IconButton(
                                  icon: const Icon(
                                    LucideIcons.x,
                                    size: 16,
                                    color: Colors.red,
                                  ),
                                  onPressed: () => setDialogState(() {
                                    selectedFile = null;
                                    uploadProgress = 0;
                                  }),
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(),
                                ),
                            ],
                          ),
                          if (isUploading) ...[
                            const SizedBox(height: 8),
                            LinearProgressIndicator(
                              value: uploadProgress,
                              backgroundColor: Colors.grey[200],
                              valueColor: const AlwaysStoppedAnimation<Color>(
                                AppColors.primary,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'جاري رفع الملف... ${(uploadProgress * 100).toInt()}%',
                              style: GoogleFonts.cairo(
                                fontSize: 10,
                                color: AppColors.primary,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'تأكد من إرفاق الملف الصحيح قبل الضغط على تسليم.',
                    style: GoogleFonts.cairo(fontSize: 11, color: Colors.grey),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: (isSubmitting || isUploading)
                    ? null
                    : () => Navigator.pop(context),
                child: Text('إلغاء', style: GoogleFonts.cairo()),
              ),
              ElevatedButton(
                onPressed: (isSubmitting || isUploading || selectedFile == null)
                    ? null
                    : () async {
                        setDialogState(() => isSubmitting = true);

                        try {
                          await _dataService.submitAssignment(
                            assignmentId: assignment.id,
                            studentCode: widget.studentCode,
                            studentName: widget.studentName,
                            fileUrl:
                                'mock_submission_url_${selectedFile!.name}',
                            contentText: contentController.text.trim(),
                            fileBytes: selectedFile!.bytes,
                          );

                          if (!context.mounted) return;

                          Navigator.pop(context);
                          _loadData(); // Refresh list
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                'تم تسليم التكليف بنجاح',
                                style: GoogleFonts.cairo(),
                              ),
                              backgroundColor: Colors.green,
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        } catch (e) {
                          if (!context.mounted) return;
                          setDialogState(() => isSubmitting = false);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                'حدث خطأ أثناء التسليم: $e',
                                style: GoogleFonts.cairo(),
                              ),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: isSubmitting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : Text(
                        'تسليم الآن',
                        style: GoogleFonts.cairo(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final assignments = _dataService.assignments;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            'التكليفات المطلوبة',
            style: GoogleFonts.cairo(fontWeight: FontWeight.bold),
          ),
          leading: IconButton(
            icon: const Icon(LucideIcons.arrowRight),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : assignments.isEmpty
            ? _buildEmptyState()
            : ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: assignments.length,
                itemBuilder: (context, index) {
                  final assignment = assignments[index];
                  return FutureBuilder<AssignmentSubmission?>(
                    future: _dataService.fetchStudentSubmission(
                      assignment.id,
                      widget.studentCode,
                    ),
                    builder: (context, snapshot) {
                      final submission = snapshot.data;
                      return _buildAssignmentCard(assignment, submission);
                    },
                  );
                },
              ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            LucideIcons.clipboardList,
            size: 64,
            color: Colors.grey.withValues(alpha: 0.5),
          ),
          const SizedBox(height: 16),
          Text(
            'لا توجد تكليفات مضافة حالياً',
            style: GoogleFonts.cairo(color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildAssignmentCard(
    Assignment assignment,
    AssignmentSubmission? submission,
  ) {
    final isSubmitted = submission != null;
    final isGraded = submission?.grade != null;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      elevation: 2,
      child: ExpansionTile(
        title: Row(
          children: [
            Expanded(
              child: Text(
                assignment.title,
                style: GoogleFonts.cairo(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                  color: AppColors.primary,
                ),
              ),
            ),
            _buildStatusBadge(isSubmitted, isGraded),
          ],
        ),
        subtitle: Text(
          'المادة: ${assignment.subject} • الموعد: ${_formatDate(assignment.deadline)}',
          style: GoogleFonts.cairo(fontSize: 11, color: Colors.grey),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'المتطلبات:',
                  style: GoogleFonts.cairo(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  assignment.description,
                  style: GoogleFonts.cairo(
                    fontSize: 13,
                    color: Colors.grey[700],
                  ),
                ),
                const SizedBox(height: 16),
                if (assignment.pdfUrl != null &&
                    assignment.pdfUrl!.isNotEmpty) ...[
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => PDFViewerScreen(
                              title: 'ملف التكليف: ${assignment.title}',
                              url: assignment.pdfUrl,
                            ),
                          ),
                        );
                      },
                      icon: const Icon(LucideIcons.fileText, size: 18),
                      label: Text(
                        'عرض ملف التكليف (PDF)',
                        style: GoogleFonts.cairo(),
                      ),
                      style: OutlinedButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
                if (isSubmitted) ...[
                  const Divider(),
                  const SizedBox(height: 8),
                  Text(
                    'حالة التسليم:',
                    style: GoogleFonts.cairo(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: Colors.green,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(
                        LucideIcons.checkCircle,
                        color: Colors.green,
                        size: 16,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'تم التسليم بتاريخ: ${_formatDate(submission.submittedAt)}',
                        style: GoogleFonts.cairo(fontSize: 12),
                      ),
                    ],
                  ),
                  if (isGraded) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.green.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: Colors.green.withValues(alpha: 0.2),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'الدرجة النهائية:',
                                style: GoogleFonts.cairo(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green,
                                ),
                              ),
                              Text(
                                '${submission.grade}%',
                                style: GoogleFonts.cairo(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                  color: Colors.green,
                                ),
                              ),
                            ],
                          ),
                          if (submission.feedback != null &&
                              submission.feedback!.isNotEmpty) ...[
                            const SizedBox(height: 8),
                            Text(
                              'ملاحظات المعلم:',
                              style: GoogleFonts.cairo(
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                            Text(
                              submission.feedback!,
                              style: GoogleFonts.cairo(
                                fontSize: 12,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ] else
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () => _showSubmissionDialog(assignment),
                      icon: const Icon(
                        LucideIcons.upload,
                        size: 18,
                        color: Colors.white,
                      ),
                      label: Text(
                        'رفع ملف البحث الآن',
                        style: GoogleFonts.cairo(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(bool isSubmitted, bool isGraded) {
    if (isGraded) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.orange.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          'تم التصحيح',
          style: GoogleFonts.cairo(
            fontSize: 10,
            color: Colors.orange,
            fontWeight: FontWeight.bold,
          ),
        ),
      );
    }
    if (isSubmitted) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.green.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          'تم التسليم',
          style: GoogleFonts.cairo(
            fontSize: 10,
            color: Colors.green,
            fontWeight: FontWeight.bold,
          ),
        ),
      );
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.red.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        'لم يتم التسليم',
        style: GoogleFonts.cairo(
          fontSize: 10,
          color: Colors.red,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  String _formatDate(String dateStr) {
    try {
      final dt = DateTime.parse(dateStr);
      return '${dt.day}/${dt.month}/${dt.year}';
    } catch (_) {
      return dateStr;
    }
  }
}
