import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:file_picker/file_picker.dart';
import '../services/data_service.dart';
import '../constants/theme.dart';
import 'pdf_viewer_screen.dart';

const int _maxAssignmentFileBytes = 8 * 1024 * 1024;

class TeacherAssignmentsScreen extends StatefulWidget {
  final String department;
  final String level;
  final String subject;
  final String teacherName;

  const TeacherAssignmentsScreen({
    super.key,
    required this.department,
    required this.level,
    required this.subject,
    required this.teacherName,
  });

  @override
  State<TeacherAssignmentsScreen> createState() =>
      _TeacherAssignmentsScreenState();
}

class _TeacherAssignmentsScreenState extends State<TeacherAssignmentsScreen> {
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

  void _showAddAssignmentDialog() {
    final titleController = TextEditingController();
    final descController = TextEditingController();
    DateTime? selectedDeadline;
    PlatformFile? pickedFile;
    bool isSaving = false;
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
              'إضافة تكليف جديد',
              style: GoogleFonts.cairo(fontWeight: FontWeight.bold),
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: titleController,
                    enabled: !isSaving && !isUploading,
                    decoration: InputDecoration(
                      labelText: 'عنوان التكليف',
                      labelStyle: GoogleFonts.cairo(),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: descController,
                    maxLines: 3,
                    enabled: !isSaving && !isUploading,
                    decoration: InputDecoration(
                      labelText: 'وصف المتطلبات',
                      labelStyle: GoogleFonts.cairo(),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  // PDF File Picker with Pre-upload simulation
                  InkWell(
                    onTap: (isSaving || isUploading)
                        ? null
                        : () async {
                            final result = await FilePicker.platform.pickFiles(
                              type: FileType.custom,
                              allowedExtensions: ['pdf'],
                              withData: true,
                            );
                            if (result != null) {
                              final file = result.files.first;
                              if (file.size > _maxAssignmentFileBytes) {
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
                                pickedFile = file;
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
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 12,
                      ),
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
                                pickedFile != null
                                    ? LucideIcons.checkCircle
                                    : LucideIcons.fileText,
                                color: pickedFile != null
                                    ? Colors.green
                                    : Colors.grey,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  pickedFile != null
                                      ? pickedFile!.name
                                      : 'إرفاق ملف PDF (اختياري)',
                                  style: GoogleFonts.cairo(
                                    color: pickedFile != null
                                        ? Colors.black
                                        : Colors.grey,
                                    fontSize: 13,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (pickedFile != null &&
                                  !isUploading &&
                                  !isSaving)
                                IconButton(
                                  icon: const Icon(
                                    LucideIcons.x,
                                    size: 16,
                                    color: Colors.red,
                                  ),
                                  onPressed: () => setDialogState(() {
                                    pickedFile = null;
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
                              'جاري الرفع... ${(uploadProgress * 100).toInt()}%',
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
                  ListTile(
                    title: Text(
                      selectedDeadline == null
                          ? 'اختر موعد التسليم'
                          : 'الموعد: ${selectedDeadline!.day}/${selectedDeadline!.month}/${selectedDeadline!.year}',
                      style: GoogleFonts.cairo(),
                    ),
                    trailing: const Icon(LucideIcons.calendar),
                    onTap: (isSaving || isUploading)
                        ? null
                        : () async {
                            final date = await showDatePicker(
                              context: context,
                              initialDate: DateTime.now().add(
                                const Duration(days: 7),
                              ),
                              firstDate: DateTime.now(),
                              lastDate: DateTime.now().add(
                                const Duration(days: 365),
                              ),
                            );
                            if (date != null) {
                              setDialogState(() => selectedDeadline = date);
                            }
                          },
                    shape: RoundedRectangleBorder(
                      side: BorderSide(color: Colors.grey[300]!),
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: (isSaving || isUploading)
                    ? null
                    : () => Navigator.pop(context),
                child: Text('إلغاء', style: GoogleFonts.cairo()),
              ),
              ElevatedButton(
                onPressed: (isSaving || isUploading)
                    ? null
                    : () async {
                        final title = titleController.text.trim();
                        final desc = descController.text.trim();

                        // Validation
                        if (title.isEmpty ||
                            desc.isEmpty ||
                            selectedDeadline == null) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                'يرجى ملء جميع الحقول (العنوان، الوصف، التاريخ)',
                                style: GoogleFonts.cairo(),
                              ),
                              backgroundColor: Colors.orange,
                            ),
                          );
                          return;
                        }

                        setDialogState(() => isSaving = true);

                        try {
                          await _dataService.addAssignment(
                            title: title,
                            description: desc,
                            deadline: selectedDeadline!.toIso8601String(),
                            department: widget.department,
                            level: widget.level,
                            subject: widget.subject,
                            teacherName: widget.teacherName,
                            fileBytes: pickedFile?.bytes,
                            fileName: pickedFile?.name,
                          );

                          if (!context.mounted) return;

                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                'تمت إضافة التكليف بنجاح',
                                style: GoogleFonts.cairo(),
                              ),
                              backgroundColor: Colors.green,
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        } catch (e) {
                          if (!context.mounted) return;
                          setDialogState(() => isSaving = false);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                'حدث خطأ أثناء الإضافة: $e',
                                style: GoogleFonts.cairo(),
                              ),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  minimumSize: const Size(100, 45),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: isSaving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : Text(
                        'إضافة التكليف',
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
    final assignments = _dataService.assignments
        .where((a) => a.subject == widget.subject)
        .toList();

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            'التكليفات - ${widget.subject}',
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
                  return _buildAssignmentCard(assignment);
                },
              ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: _showAddAssignmentDialog,
          backgroundColor: AppColors.primary,
          icon: const Icon(LucideIcons.plus, color: Colors.white),
          label: Text(
            'تكليف جديد',
            style: GoogleFonts.cairo(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
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

  Widget _buildAssignmentCard(Assignment assignment) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    assignment.title,
                    style: GoogleFonts.cairo(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: AppColors.primary,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'الموعد: ${_formatDate(assignment.deadline)}',
                    style: GoogleFonts.cairo(
                      fontSize: 10,
                      color: Colors.red,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              assignment.description,
              style: GoogleFonts.cairo(fontSize: 13, color: Colors.grey[700]),
            ),
            const SizedBox(height: 16),
            const Divider(),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton.icon(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          SubmissionsReviewScreen(assignment: assignment),
                    ),
                  ),
                  icon: const Icon(LucideIcons.users, size: 18),
                  label: Text(
                    'عرض التسليمات',
                    style: GoogleFonts.cairo(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ],
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

class SubmissionsReviewScreen extends StatefulWidget {
  final Assignment assignment;
  const SubmissionsReviewScreen({super.key, required this.assignment});

  @override
  State<SubmissionsReviewScreen> createState() =>
      _SubmissionsReviewScreenState();
}

class _SubmissionsReviewScreenState extends State<SubmissionsReviewScreen> {
  final DataService _dataService = DataService();
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _dataService.addListener(_onDataChanged);
    _loadSubmissions();
  }

  @override
  void dispose() {
    _dataService.removeListener(_onDataChanged);
    super.dispose();
  }

  void _onDataChanged() {
    if (mounted) setState(() {});
  }

  Future<void> _loadSubmissions() async {
    setState(() => _isLoading = true);
    await _dataService.fetchSubmissions(widget.assignment.id);
    if (mounted) setState(() => _isLoading = false);
  }

  void _showGradeDialog(AssignmentSubmission submission) {
    final gradeController = TextEditingController(
      text: submission.grade?.toString() ?? '',
    );
    final feedbackController = TextEditingController(
      text: submission.feedback ?? '',
    );

    showDialog(
      context: context,
      builder: (context) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          title: Text(
            'تصحيح التكليف: ${submission.studentName}',
            style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: gradeController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'الدرجة (من 100)',
                  labelStyle: GoogleFonts.cairo(),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: feedbackController,
                maxLines: 3,
                decoration: InputDecoration(
                  labelText: 'ملاحظات المعلم',
                  labelStyle: GoogleFonts.cairo(),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('إلغاء', style: GoogleFonts.cairo()),
            ),
            ElevatedButton(
              onPressed: () async {
                final grade = double.tryParse(gradeController.text) ?? 0;
                await _dataService.gradeSubmission(
                  submissionId: submission.id,
                  grade: grade,
                  feedback: feedbackController.text,
                );
                await _loadSubmissions();
                if (context.mounted) Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
              child: Text(
                'رصد الدرجة',
                style: GoogleFonts.cairo(color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final submissions = _dataService.submissions;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            'تسليمات: ${widget.assignment.title}',
            style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 16),
          ),
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : submissions.isEmpty
            ? Center(
                child: Text(
                  'لا توجد تسليمات بعد',
                  style: GoogleFonts.cairo(color: Colors.grey),
                ),
              )
            : ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: submissions.length,
                itemBuilder: (context, index) {
                  final sub = submissions[index];
                  final isGraded = sub.grade != null;
                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: ExpansionTile(
                      leading: CircleAvatar(
                        backgroundColor: isGraded
                            ? Colors.green.withValues(alpha: 0.1)
                            : Colors.orange.withValues(alpha: 0.1),
                        child: Icon(
                          isGraded
                              ? LucideIcons.checkCircle
                              : LucideIcons.clock,
                          color: isGraded ? Colors.green : Colors.orange,
                          size: 20,
                        ),
                      ),
                      title: Text(
                        sub.studentName,
                        style: GoogleFonts.cairo(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text(
                        'كود: ${sub.studentCode} • ${sub.submittedAt.split('T')[0]}',
                        style: GoogleFonts.cairo(fontSize: 11),
                      ),
                      trailing: isGraded
                          ? Text(
                              '${sub.grade}%',
                              style: GoogleFonts.cairo(
                                color: Colors.green,
                                fontWeight: FontWeight.bold,
                              ),
                            )
                          : Text(
                              'بانتظار التصحيح',
                              style: GoogleFonts.cairo(
                                color: Colors.orange,
                                fontSize: 10,
                              ),
                            ),
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (sub.contentText != null &&
                                  sub.contentText!.isNotEmpty) ...[
                                Text(
                                  'ملاحظات الطالب:',
                                  style: GoogleFonts.cairo(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Colors.grey[50],
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(
                                      color: Colors.grey[200]!,
                                    ),
                                  ),
                                  child: Text(
                                    sub.contentText!,
                                    style: GoogleFonts.cairo(
                                      fontSize: 12,
                                      color: Colors.black87,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 16),
                              ],
                              Row(
                                children: [
                                  Expanded(
                                    child: ElevatedButton.icon(
                                      onPressed: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) => PDFViewerScreen(
                                              title:
                                                  'حل الطالب: ${sub.studentName}',
                                              url: sub.fileUrl,
                                            ),
                                          ),
                                        );
                                      },
                                      icon: const Icon(
                                        LucideIcons.fileText,
                                        size: 18,
                                        color: Colors.white,
                                      ),
                                      label: Text(
                                        'عرض ملف الحل (PDF)',
                                        style: GoogleFonts.cairo(
                                          color: Colors.white,
                                        ),
                                      ),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: AppColors.primary,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            10,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  OutlinedButton.icon(
                                    onPressed: () => _showGradeDialog(sub),
                                    icon: const Icon(
                                      LucideIcons.edit3,
                                      size: 18,
                                    ),
                                    label: Text(
                                      isGraded ? 'تعديل الدرجة' : 'رصد الدرجة',
                                      style: GoogleFonts.cairo(),
                                    ),
                                    style: OutlinedButton.styleFrom(
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              if (sub.feedback != null) ...[
                                const SizedBox(height: 12),
                                Text(
                                  'ملاحظات المعلم: ${sub.feedback}',
                                  style: GoogleFonts.cairo(
                                    fontSize: 11,
                                    color: AppColors.primary,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
      ),
    );
  }
}
