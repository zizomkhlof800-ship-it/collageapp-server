import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../constants/theme.dart';
import '../data/student_data.dart';

class AddStudentScreen extends StatefulWidget {
  const AddStudentScreen({super.key});

  @override
  State<AddStudentScreen> createState() => _AddStudentScreenState();
}

class _AddStudentScreenState extends State<AddStudentScreen> {
  final _nameController = TextEditingController();
  final _codeController = TextEditingController(); // acts as ID and Code
  final _departmentController = TextEditingController(text: 'إعلام تربوي'); // Default
  final _levelController = TextEditingController(text: 'الفرقة الثانية'); // Default
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
  // We can add more if needed, but StudentInfo needs: name, code, status, department, level.
  // Status defaults to 'مستجد' for new students?

  @override
  void dispose() {
    _nameController.dispose();
    _codeController.dispose();
    _departmentController.dispose();
    _levelController.dispose();
    super.dispose();
  }

  void _saveStudent() {
    final messenger = ScaffoldMessenger.of(context);
    if (_nameController.text.isEmpty || _codeController.text.isEmpty) {
      messenger.showSnackBar(
        SnackBar(content: Text('يرجى ملء جميع الحقول المطلوبة', style: GoogleFonts.cairo())),
      );
      return;
    }

    final newStudent = StudentInfo(
      name: _nameController.text,
      code: _codeController.text,
      status: 'مستجد', // Default status
      department: _departmentController.text,
      level: _levelController.text,
    );

    Navigator.pop(context, newStudent);
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: AppColors.white,
          elevation: 0,
          title: Text(
            'إضافة طالب جديد',
            style: GoogleFonts.cairo(
              color: AppColors.text,
              fontWeight: FontWeight.bold,
            ),
          ),
          leading: IconButton(
            icon: const Icon(LucideIcons.arrowRight, color: AppColors.text),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              // Profile Image Placeholder
              Center(
                child: Stack(
                  children: [
                    Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        color: AppColors.white,
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColors.inputBorder),
                      ),
                      child: const Icon(LucideIcons.user, size: 40, color: AppColors.textLight),
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: const BoxDecoration(
                          color: AppColors.primary,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(LucideIcons.camera, size: 16, color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              _buildTextField(
                controller: _nameController,
                label: 'اسم الطالب',
                icon: LucideIcons.user,
              ),
              const SizedBox(height: 16),
              _buildTextField(
                controller: _codeController,
                label: 'الكود الجامعي',
                icon: LucideIcons.hash,
                isNumber: false,
              ),
              const SizedBox(height: 16),
              _buildDropdown('القسم', LucideIcons.graduationCap, _departments, _departmentController),
              const SizedBox(height: 16),
              _buildDropdown('الفرقة الدراسية', LucideIcons.layers, _levels, _levelController),
              const SizedBox(height: 32),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _saveStudent,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    'حفظ البيانات',
                    style: GoogleFonts.cairo(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool isNumber = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.cairo(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: AppColors.text,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          keyboardType: isNumber ? TextInputType.number : TextInputType.text,
          decoration: InputDecoration(
            prefixIcon: Icon(icon, color: AppColors.textLight, size: 20),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.inputBorder),
            ),
            filled: true,
            fillColor: AppColors.white,
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
        Text(
          label,
          style: GoogleFonts.cairo(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: AppColors.text,
          ),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          initialValue: currentValue,
          items: items
              .map((e) => DropdownMenuItem<String>(
                    value: e,
                    child: Align(
                      alignment: Alignment.centerRight,
                      child: Text(e, style: GoogleFonts.cairo()),
                    ),
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
            fillColor: AppColors.white,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),
        ),
      ],
    );
  }
}
