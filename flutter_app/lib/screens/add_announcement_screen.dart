import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../constants/theme.dart';
import '../services/data_service.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:convert';
import 'dart:typed_data';

class AddAnnouncementScreen extends StatefulWidget {
  const AddAnnouncementScreen({super.key});

  @override
  State<AddAnnouncementScreen> createState() => _AddAnnouncementScreenState();
}

class _AddAnnouncementScreenState extends State<AddAnnouncementScreen> {
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  String _selectedPriority = 'عادي'; // normal, urgent
  DateTime? _selectedDate;
  String _selectedDepartment = 'إعلام تربوي';
  String _selectedLevel = 'الفرقة الثانية';
  String _imageName = '';
  Uint8List? _imageBytes;
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

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2101),
    );
    if (picked != null && picked != _selectedDate) {
      final TimeOfDay? timePicked = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.now(),
      );
      if (timePicked != null) {
        setState(() {
          _selectedDate = DateTime(
            picked.year,
            picked.month,
            picked.day,
            timePicked.hour,
            timePicked.minute,
          );
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.appBackground,
      appBar: AppBar(
        backgroundColor: context.appSurface,
        elevation: 0,
        title: Text(
          'إضافة إعلان جديد',
          style: GoogleFonts.cairo(
            color: context.appText,
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: IconButton(
          icon: Icon(LucideIcons.arrowRight, color: context.appText),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'عنوان الإعلان',
              style: GoogleFonts.cairo(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: context.appText,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _titleController,
              decoration: InputDecoration(
                hintText: 'مثال: تغيير موعد محاضرة البرمجة',
                hintStyle: GoogleFonts.cairo(color: context.appTextLight),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.inputBorder),
                ),
                filled: true,
                fillColor: context.appSurface,
              ),
            ),
            const SizedBox(height: 24),

            Text(
              'مستوى الأهمية',
              style: GoogleFonts.cairo(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: context.appText,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _buildPriorityOption('عادي', AppColors.primary),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildPriorityOption(
                    'هام جداً',
                    AppColors.cardRedIcon,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            Text(
              'القسم',
              style: GoogleFonts.cairo(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: context.appText,
              ),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              initialValue: _selectedDepartment,
              items: _departments
                  .map(
                    (e) => DropdownMenuItem<String>(
                      value: e,
                      child: Align(
                        alignment: Alignment.centerRight,
                        child: Text(e, style: GoogleFonts.cairo()),
                      ),
                    ),
                  )
                  .toList(),
              onChanged: (v) => setState(
                () => _selectedDepartment = v ?? _selectedDepartment,
              ),
              decoration: InputDecoration(
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'الفرقة',
              style: GoogleFonts.cairo(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: context.appText,
              ),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              initialValue: _selectedLevel,
              items: _levels
                  .map(
                    (e) => DropdownMenuItem<String>(
                      value: e,
                      child: Align(
                        alignment: Alignment.centerRight,
                        child: Text(e, style: GoogleFonts.cairo()),
                      ),
                    ),
                  )
                  .toList(),
              onChanged: (v) =>
                  setState(() => _selectedLevel = v ?? _selectedLevel),
              decoration: InputDecoration(
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
              ),
            ),
            const SizedBox(height: 24),

            Text(
              'صورة مرفقة (اختياري)',
              style: GoogleFonts.cairo(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: context.appText,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                ElevatedButton.icon(
                  onPressed: () async {
                    final result = await FilePicker.platform.pickFiles(
                      type: FileType.custom,
                      allowedExtensions: ['png', 'jpg', 'jpeg', 'webp'],
                      withData: true,
                    );
                    if (result == null || result.files.isEmpty) return;
                    final f = result.files.first;
                    if (f.bytes == null) return;
                    setState(() {
                      _imageName = f.name;
                      _imageBytes = f.bytes!;
                    });
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey[100],
                    foregroundColor: context.appText,
                    elevation: 0,
                  ),
                  icon: const Icon(LucideIcons.image),
                  label: Text(
                    _imageName.isEmpty ? 'اختيار صورة' : 'تغيير الصورة',
                    style: GoogleFonts.cairo(),
                  ),
                ),
                const SizedBox(width: 12),
                if (_imageName.isNotEmpty)
                  Expanded(
                    child: Text(
                      _imageName,
                      style: GoogleFonts.cairo(
                        fontSize: 12,
                        color: context.appTextLight,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            if (_imageBytes != null)
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(color: Colors.grey[300]!),
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.all(8),
                child: Image.memory(
                  _imageBytes!,
                  height: 140,
                  fit: BoxFit.contain,
                ),
              ),
            const SizedBox(height: 24),

            Text(
              'وقت النشر',
              style: GoogleFonts.cairo(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: context.appText,
              ),
            ),
            const SizedBox(height: 8),
            InkWell(
              onTap: () => _selectDate(context),
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 16,
                ),
                decoration: BoxDecoration(
                  color: context.appSurface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: context.appBorder),
                ),
                child: Row(
                  children: [
                    Icon(LucideIcons.calendar, color: context.appTextLight),
                    const SizedBox(width: 12),
                    Text(
                      _selectedDate == null
                          ? 'اختر وقت النشر'
                          : '${_selectedDate!.year}-${_selectedDate!.month}-${_selectedDate!.day} ${_selectedDate!.hour}:${_selectedDate!.minute.toString().padLeft(2, '0')}',
                      style: GoogleFonts.cairo(
                        color: _selectedDate == null
                            ? context.appTextLight
                            : context.appText,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            Text(
              'نص الإعلان',
              style: GoogleFonts.cairo(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: context.appText,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _contentController,
              maxLines: 6,
              decoration: InputDecoration(
                hintText: 'اكتب تفاصيل الإعلان هنا...',
                hintStyle: GoogleFonts.cairo(color: context.appTextLight),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.inputBorder),
                ),
                filled: true,
                fillColor: context.appSurface,
              ),
            ),
            const SizedBox(height: 32),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  final messenger = ScaffoldMessenger.of(context);
                  if (_titleController.text.isEmpty ||
                      _contentController.text.isEmpty) {
                    messenger.showSnackBar(
                      SnackBar(
                        content: Text(
                          'يرجى ملء جميع الحقول',
                          style: GoogleFonts.cairo(),
                        ),
                        backgroundColor: Colors.red,
                      ),
                    );
                    return;
                  }

                  final titleText =
                      '$_selectedDepartment - $_selectedLevel | ${_titleController.text}';
                  final newAnnouncement = Announcement(
                    id: DateTime.now().millisecondsSinceEpoch.toString(),
                    title: titleText,
                    content: _contentController.text,
                    priority: _selectedPriority,
                    date: _selectedDate == null
                        ? 'الآن'
                        : '${_selectedDate!.year}-${_selectedDate!.month}-${_selectedDate!.day} ${_selectedDate!.hour}:${_selectedDate!.minute.toString().padLeft(2, '0')}',
                    imageName: _imageName,
                    imageBase64: _imageBytes == null
                        ? ''
                        : (() {
                            final lower = _imageName.toLowerCase();
                            String mime = 'image/png';
                            if (lower.endsWith('.jpg') ||
                                lower.endsWith('.jpeg'))
                              mime = 'image/jpeg';
                            if (lower.endsWith('.webp')) mime = 'image/webp';
                            return 'data:$mime;base64,${base64Encode(_imageBytes!)}';
                          })(),
                  );

                  messenger.showSnackBar(
                    SnackBar(
                      content: Text(
                        'تم نشر الإعلان بنجاح',
                        style: GoogleFonts.cairo(),
                      ),
                      backgroundColor: AppColors.cardGreenIcon,
                    ),
                  );
                  Navigator.pop(context, newAnnouncement);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  'نشر الإعلان',
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
    );
  }

  Widget _buildPriorityOption(String label, Color color) {
    final isSelected = _selectedPriority == label;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedPriority = label;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? color.withValues(alpha: 0.1) : context.appSurface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? color : AppColors.inputBorder,
            width: 2,
          ),
        ),
        child: Center(
          child: Text(
            label,
            style: GoogleFonts.cairo(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: isSelected ? color : context.appTextLight,
            ),
          ),
        ),
      ),
    );
  }
}
