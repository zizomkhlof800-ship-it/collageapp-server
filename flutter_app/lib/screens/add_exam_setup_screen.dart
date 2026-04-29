import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../constants/theme.dart';
import 'add_exam_questions_screen.dart';
import 'question_bank_screen.dart';
// تم إزالة الاستيراد الخاص بالاستيراد من ملفات خارجية

class AddExamSetupScreen extends StatefulWidget {
  final String? initialSubject;
  final String? initialDepartment;
  final String? initialLevel;

  const AddExamSetupScreen({
    super.key,
    this.initialSubject,
    this.initialDepartment,
    this.initialLevel,
  });

  @override
  State<AddExamSetupScreen> createState() => _AddExamSetupScreenState();
}

class _AddExamSetupScreenState extends State<AddExamSetupScreen> {
  late final TextEditingController _tfCountController = TextEditingController(text: '0');
  late final TextEditingController _mcqCountController = TextEditingController(text: '0');
  late final TextEditingController _subjectController = TextEditingController(text: widget.initialSubject ?? '');
  late final TextEditingController _departmentController = TextEditingController(text: widget.initialDepartment ?? 'إعلام تربوي');
  late final TextEditingController _levelController = TextEditingController(text: widget.initialLevel ?? 'الفرقة الثانية');
  late final TextEditingController _durationController = TextEditingController(text: '30');
  DateTime? _startDate;
  TimeOfDay? _startTime;
  DateTime? _endDate;
  TimeOfDay? _endTime;
  bool _isFromBank = false;
  
  final List<String> _departments = const [
    'تكنولوجيا التعليم',
    'الحاسب الآلي',
    'إعلام تربوي',
    'اقتصاد منزلي',
    'تربية فنية',
    'تربية موسيقية',
  ];
  final List<String> _levels = const [
    'الفرقة الأولى',
    'الفرقة الثانية',
    'الفرقة الثالثة',
    'الفرقة الرابعة',
  ];

  @override
  void dispose() {
    _tfCountController.dispose();
    _mcqCountController.dispose();
    _subjectController.dispose();
    _departmentController.dispose();
    _levelController.dispose();
    _durationController.dispose();
    super.dispose();
  }

  Future<void> _pickStartTime() async {
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: Theme.of(context).colorScheme.copyWith(primary: AppColors.primary),
        ),
        child: child!,
      ),
    );
    if (date != null) {
      if (!mounted) return;
      final time = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.now(),
      );
      if (time != null) {
        setState(() {
          _startDate = date;
          _startTime = time;
        });
      }
    }
  }

  Future<void> _pickEndTime() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _startDate ?? DateTime.now(),
      firstDate: _startDate ?? DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: Theme.of(context).colorScheme.copyWith(primary: AppColors.primary),
        ),
        child: child!,
      ),
    );
    if (date != null) {
      if (!mounted) return;
      final time = await showTimePicker(
        context: context,
        initialTime: _startTime ?? TimeOfDay.now(),
      );
      if (time != null) {
        setState(() {
          _endDate = date;
          _endTime = time;
        });
      }
    }
  }

  void _proceed() {
    final tf = int.tryParse(_tfCountController.text.trim()) ?? 0;
    final mcq = int.tryParse(_mcqCountController.text.trim()) ?? 0;
    final duration = int.tryParse(_durationController.text.trim()) ?? 0;
    final messenger = ScaffoldMessenger.of(context);

    if (tf <= 0 && mcq <= 0) {
      messenger.showSnackBar(
        SnackBar(content: Text('اختر عدد الأسئلة لأي نوع على الأقل', style: GoogleFonts.cairo())),
      );
      return;
    }

    if (_startDate == null || _startTime == null || _endDate == null || _endTime == null) {
      messenger.showSnackBar(
        SnackBar(content: Text('يرجى تحديد وقت البدء ووقت الانتهاء', style: GoogleFonts.cairo())),
      );
      return;
    }

    final start = DateTime(_startDate!.year, _startDate!.month, _startDate!.day, _startTime!.hour, _startTime!.minute);
    final end = DateTime(_endDate!.year, _endDate!.month, _endDate!.day, _endTime!.hour, _endTime!.minute);

    if (end.isBefore(start)) {
      messenger.showSnackBar(
        SnackBar(content: Text('وقت الانتهاء يجب أن يكون بعد وقت البدء', style: GoogleFonts.cairo())),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => AddExamQuestionsScreen(
        tfCount: tf,
        mcqCount: mcq,
        subject: _subjectController.text.trim(),
        department: _departmentController.text.trim(),
        level: _levelController.text.trim(),
        startTime: start.toIso8601String(),
        endTime: end.toIso8601String(),
        durationMinutes: duration,
        isFromBank: _isFromBank,
      )),
    );
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
          title: Text('إعداد الاختبار', style: GoogleFonts.cairo(fontWeight: FontWeight.bold, color: AppColors.text)),
          leading: IconButton(
            icon: const Icon(LucideIcons.arrowRight, color: AppColors.text),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildInfoCard(),
              const SizedBox(height: 16),
              _buildTextField(_subjectController, 'اسم المادة', LucideIcons.book),
              const SizedBox(height: 12),
              _buildDropdown('القسم', LucideIcons.graduationCap, _departments, _departmentController),
              const SizedBox(height: 12),
              _buildDropdown('الفرقة الدراسية', LucideIcons.layers, _levels, _levelController),
              const SizedBox(height: 16),
              _buildSectionTitle('التوقيت والمدة'),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: _buildDateTimePicker(
                      label: 'وقت البدء',
                      value: _startDate == null ? 'اختر الوقت' : '${_startDate!.day}/${_startDate!.month} - ${_startTime!.format(context)}',
                      icon: LucideIcons.calendar,
                      onTap: _pickStartTime,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildDateTimePicker(
                      label: 'وقت الانتهاء',
                      value: _endDate == null ? 'اختر الوقت' : '${_endDate!.day}/${_endDate!.month} - ${_endTime!.format(context)}',
                      icon: LucideIcons.calendarCheck,
                      onTap: _pickEndTime,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _buildNumberField(_durationController, 'مدة الامتحان (بالدقائق)', LucideIcons.timer),
              const SizedBox(height: 16),
              _buildSectionTitle('الأسئلة وبنك الأسئلة'),
              const SizedBox(height: 8),
              _buildNumberField(_tfCountController, 'عدد أسئلة صح/خطأ', LucideIcons.checkCircle),
              const SizedBox(height: 12),
              _buildNumberField(_mcqCountController, 'عدد أسئلة اختيار من متعدد', LucideIcons.listChecks),
              const SizedBox(height: 16),
              _buildBankSwitch(),
              const SizedBox(height: 16),
              _buildBankButton(),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _proceed,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Text('التالي', style: GoogleFonts.cairo(fontWeight: FontWeight.bold, color: Colors.white)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: GoogleFonts.cairo(fontWeight: FontWeight.bold, color: AppColors.primary, fontSize: 16),
    );
  }

  Widget _buildDateTimePicker({required String label, required String value, required IconData icon, required VoidCallback onTap}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: GoogleFonts.cairo(fontWeight: FontWeight.bold, color: AppColors.text, fontSize: 14)),
        const SizedBox(height: 8),
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.inputBorder),
            ),
            child: Row(
              children: [
                Icon(icon, color: AppColors.textLight, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    value,
                    style: GoogleFonts.cairo(color: _startDate == null ? AppColors.textLight : AppColors.text, fontSize: 13),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBankSwitch() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
      ),
      child: SwitchListTile(
        title: Text('سحب الأسئلة عشوائياً من البنك', style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 14)),
        subtitle: Text('سيتم اختيار الأسئلة تلقائياً من الأسئلة المخزنة مسبقاً', style: GoogleFonts.cairo(fontSize: 12)),
        value: _isFromBank,
        onChanged: (v) => setState(() => _isFromBank = v),
      ),
    );
  }

  Widget _buildBankButton() {
    return OutlinedButton.icon(
      onPressed: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => QuestionBankScreen(
              department: _departmentController.text,
              level: _levelController.text,
              subject: _subjectController.text,
            ),
          ),
        );
      },
      icon: const Icon(LucideIcons.database),
      label: Text('فتح بنك الأسئلة للمراجعة/الإضافة', style: GoogleFonts.cairo(fontWeight: FontWeight.bold)),
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.primary,
        side: const BorderSide(color: AppColors.primary),
        padding: const EdgeInsets.symmetric(vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Widget _buildInfoCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          const Icon(LucideIcons.info, color: AppColors.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'اختر أنواع الأسئلة وعددها، ثم انتقل لإدخال نصوص الأسئلة وتحديد الإجابات الصحيحة.',
              style: GoogleFonts.cairo(fontSize: 12, color: AppColors.textLight),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label, IconData icon) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: GoogleFonts.cairo(fontWeight: FontWeight.bold, color: AppColors.text)),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          decoration: InputDecoration(
            prefixIcon: Icon(icon, color: AppColors.textLight, size: 20),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.inputBorder),
            ),
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),
        ),
      ],
    );
  }

  Widget _buildNumberField(TextEditingController controller, String label, IconData icon) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: GoogleFonts.cairo(fontWeight: FontWeight.bold, color: AppColors.text)),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            prefixIcon: Icon(icon, color: AppColors.textLight, size: 20),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.inputBorder),
            ),
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),
        ),
      ],
    );
  }

  Widget _buildDropdown(String label, IconData icon, List<String> items, TextEditingController controller) {
    final currentValue = controller.text.isNotEmpty ? controller.text : (items.isNotEmpty ? items.first : '');
    if (controller.text.isEmpty && items.isNotEmpty) controller.text = items.first;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: GoogleFonts.cairo(fontWeight: FontWeight.bold, color: AppColors.text)),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          initialValue: currentValue,
          items: items
              .map((e) => DropdownMenuItem<String>(
                    value: e,
                    child: Align(alignment: Alignment.centerRight, child: Text(e, style: GoogleFonts.cairo())),
                  ))
              .toList(),
          onChanged: (v) {
            if (v != null) controller.text = v;
            setState(() {});
          },
          decoration: InputDecoration(
            prefixIcon: Icon(icon, color: AppColors.textLight, size: 20),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.inputBorder),
            ),
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),
        ),
      ],
    );
  }
}
