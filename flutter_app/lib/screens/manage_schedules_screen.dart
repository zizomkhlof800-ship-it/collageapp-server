import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:convert';
import '../constants/theme.dart';
import '../services/data_service.dart';
import '../constants/api.dart';

class ManageSchedulesScreen extends StatefulWidget {
  final bool isExam; // true for Exam Schedule, false for Academic Schedule

  const ManageSchedulesScreen({super.key, required this.isExam});

  @override
  State<ManageSchedulesScreen> createState() => _ManageSchedulesScreenState();
}

class _ManageSchedulesScreenState extends State<ManageSchedulesScreen> {
  final DataService _dataService = DataService();
  
  // Controllers for adding new schedule
  final _subjectController = TextEditingController();
  final _dayDateController = TextEditingController(); // Functions as Day for Academic, Date for Exam
  final _timeController = TextEditingController();
  final _locationController = TextEditingController();
  final _departmentController = TextEditingController(text: 'إعلام تربوي');
  final _levelController = TextEditingController(text: 'الفرقة الثانية');
  final _imageUrlController = TextEditingController();
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
  void initState() {
    super.initState();
    _dataService.addListener(_onDataChanged);
  }

  @override
  void dispose() {
    _dataService.removeListener(_onDataChanged);
    _subjectController.dispose();
    _dayDateController.dispose();
    _timeController.dispose();
    _locationController.dispose();
    _departmentController.dispose();
    _levelController.dispose();
    _imageUrlController.dispose();
    super.dispose();
  }

  void _onDataChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  void _addSchedule() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          widget.isExam ? 'إضافة امتحان' : 'إضافة محاضرة',
          style: GoogleFonts.cairo(fontWeight: FontWeight.bold),
          textDirection: TextDirection.rtl,
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildTextField(_subjectController, 'المادة'),
              const SizedBox(height: 8),
              _buildTextField(_dayDateController, widget.isExam ? 'التاريخ (YYYY-MM-DD)' : 'اليوم (السبت، الأحد...)'),
              const SizedBox(height: 8),
              _buildTextField(_timeController, 'الوقت (من - إلى)'),
              const SizedBox(height: 8),
              _buildTextField(_locationController, 'المكان/القاعة'),
              const SizedBox(height: 8),
              _buildDropdown('القسم', _departments, _departmentController),
              const SizedBox(height: 8),
              _buildDropdown('الفرقة', _levels, _levelController),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('إلغاء', style: GoogleFonts.cairo(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () {
              if (_subjectController.text.isNotEmpty && 
                  _dayDateController.text.isNotEmpty &&
                  _timeController.text.isNotEmpty) {
                
                final newItem = ScheduleItem(
                  id: DateTime.now().millisecondsSinceEpoch.toString(),
                  subject: _subjectController.text,
                  day: widget.isExam ? '' : _dayDateController.text,
                  date: widget.isExam ? _dayDateController.text : '',
                  time: _timeController.text,
                  location: _locationController.text,
                  department: _departmentController.text,
                  level: _levelController.text,
                  imageUrl: '',
                  isExam: widget.isExam,
                );

                try {
                  _dataService.addSchedule(newItem);
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('تمت الإضافة بنجاح', style: GoogleFonts.cairo())),
                  );
                } catch (_) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('فشل إضافة البند', style: GoogleFonts.cairo())),
                  );
                }

                // Clear controllers
                _subjectController.clear();
                _dayDateController.clear();
                _timeController.clear();
                _locationController.clear();

                
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: Text('إضافة', style: GoogleFonts.cairo(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _addScheduleImage() {
    _imageUrlController.clear();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          widget.isExam ? 'إضافة صورة جدول الامتحانات' : 'إضافة صورة الجدول الدراسي',
          style: GoogleFonts.cairo(fontWeight: FontWeight.bold),
          textDirection: TextDirection.rtl,
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDropdown('القسم', _departments, _departmentController),
              const SizedBox(height: 8),
              _buildDropdown('الفرقة', _levels, _levelController),
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  onPressed: () async {
                    final result = await FilePicker.platform.pickFiles(
                      type: FileType.image,
                      withData: true,
                    );
                    if (result != null && result.files.isNotEmpty) {
                      final file = result.files.first;
                      final bytes = file.bytes;
                      if (bytes != null) {
                        final ext = (file.extension ?? 'png').toLowerCase();
                        final mime = ext == 'jpg' || ext == 'jpeg' ? 'image/jpeg' : 'image/$ext';
                        final base64Data = base64Encode(bytes);
                        final dataUrl = 'data:$mime;base64,$base64Data';
                        _imageUrlController.text = dataUrl;
                        setState(() {}); // reflect any preview if needed
                      }
                    }
                  },
                  icon: const Icon(LucideIcons.image, size: 16),
                  label: Text('اختيار صورة من الجهاز', style: GoogleFonts.cairo()),
                  style: TextButton.styleFrom(foregroundColor: AppColors.primary),
                ),
              ),
              if (_imageUrlController.text.isNotEmpty) ...[
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: _buildImage(_imageUrlController.text),
                ),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('إلغاء', style: GoogleFonts.cairo(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () {
              if (_imageUrlController.text.isNotEmpty) {
                final newItem = ScheduleItem(
                  id: DateTime.now().millisecondsSinceEpoch.toString(),
                  subject: 'صورة الجدول',
                  day: '',
                  date: '',
                  time: '',
                  location: '',
                  department: _departmentController.text,
                  level: _levelController.text,
                  imageUrl: _imageUrlController.text,
                  isExam: widget.isExam,
                );
                try {
                  _dataService.addSchedule(newItem);
                  _imageUrlController.clear();
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('تمت إضافة الصورة بنجاح', style: GoogleFonts.cairo())),
                  );
                } catch (_) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('فشل إضافة الصورة', style: GoogleFonts.cairo())),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: Text('إضافة الصورة', style: GoogleFonts.cairo(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _deleteSchedule(ScheduleItem item) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('تأكيد الحذف', style: GoogleFonts.cairo(fontWeight: FontWeight.bold), textDirection: TextDirection.rtl),
        content: Text('هل أنت متأكد من حذف ${item.subject}؟', style: GoogleFonts.cairo(), textDirection: TextDirection.rtl),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('إلغاء', style: GoogleFonts.cairo(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () {
              _dataService.deleteSchedule(item.id, widget.isExam, item.department, item.level);
              Navigator.pop(context);
            },
            child: Text('حذف', style: GoogleFonts.cairo(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label) {
    return TextField(
      controller: controller,
      textDirection: TextDirection.rtl,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: GoogleFonts.cairo(fontSize: 14),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
    );
  }
  
  Widget _buildDropdown(String label, List<String> items, TextEditingController controller) {
    final currentValue = controller.text.isNotEmpty ? controller.text : (items.isNotEmpty ? items.first : '');
    if (controller.text.isEmpty && items.isNotEmpty) controller.text = items.first;
    return DropdownButtonFormField<String>(
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
        labelText: label,
        labelStyle: GoogleFonts.cairo(fontSize: 14),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final schedules = widget.isExam ? _dataService.examSchedules : _dataService.academicSchedules;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            widget.isExam ? 'إدارة جدول الامتحانات' : 'إدارة الجدول الدراسي',
            style: GoogleFonts.cairo(fontWeight: FontWeight.bold, color: AppColors.text),
          ),
          backgroundColor: Colors.white,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(LucideIcons.arrowRight, color: AppColors.primary),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        floatingActionButton: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            FloatingActionButton.extended(
              onPressed: _addSchedule,
              backgroundColor: AppColors.primary,
              icon: const Icon(LucideIcons.plus, color: Colors.white),
              label: Text('إضافة بند', style: GoogleFonts.cairo(color: Colors.white)),
            ),
            const SizedBox(height: 12),
            FloatingActionButton.extended(
              onPressed: _addScheduleImage,
              backgroundColor: Colors.orange,
              icon: const Icon(LucideIcons.image, color: Colors.white),
              label: Text('إضافة صورة الجدول', style: GoogleFonts.cairo(color: Colors.white)),
            ),
          ],
        ),
        body: schedules.isEmpty
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(LucideIcons.calendarX, size: 64, color: Colors.grey[300]),
                    const SizedBox(height: 16),
                    Text(
                      'لا توجد بيانات مضافة حالياً',
                      style: GoogleFonts.cairo(color: Colors.grey, fontSize: 16),
                    ),
                  ],
                ),
              )
            : ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: schedules.length,
                itemBuilder: (context, index) {
                  final item = schedules[index];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 2,
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: widget.isExam ? Colors.orange.withOpacity(0.1) : Colors.blue.withOpacity(0.1),
                        child: Icon(
                          widget.isExam ? LucideIcons.fileClock : LucideIcons.calendar,
                          color: widget.isExam ? Colors.orange : Colors.blue,
                          size: 20,
                        ),
                      ),
                      title: Text(
                        item.subject,
                        style: GoogleFonts.cairo(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 4),
                          if ((widget.isExam ? item.date : item.day).isNotEmpty || item.time.isNotEmpty)
                            Row(
                              children: [
                                Icon(LucideIcons.clock, size: 14, color: Colors.grey[600]),
                                const SizedBox(width: 4),
                                Text(
                                  [
                                    if ((widget.isExam ? item.date : item.day).isNotEmpty) (widget.isExam ? item.date : item.day),
                                    if (item.time.isNotEmpty) item.time,
                                  ].join(' | '),
                                  style: GoogleFonts.cairo(fontSize: 12),
                                ),
                              ],
                            ),
                          const SizedBox(height: 2),
                          if (item.location.isNotEmpty)
                            Row(
                              children: [
                                Icon(LucideIcons.mapPin, size: 14, color: Colors.grey[600]),
                                const SizedBox(width: 4),
                                Text(item.location, style: GoogleFonts.cairo(fontSize: 12)),
                              ],
                            ),
                          const SizedBox(height: 4),
                          Text('${item.department} | ${item.level}', style: GoogleFonts.cairo(fontSize: 12, color: Colors.grey[700])),
                          if (item.imageUrl.isNotEmpty) ...[
                            const SizedBox(height: 8),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: _buildImage(item.imageUrl),
                            ),
                          ],
                        ],
                    ),
                      trailing: IconButton(
                        icon: const Icon(LucideIcons.trash2, color: Colors.red, size: 20),
                        onPressed: () => _deleteSchedule(item),
                      ),
                      onTap: () {
                        _openEditDialog(item);
                      },
                    ),
                  );
                },
              ),
      ),
    );
  }

  void _openEditDialog(ScheduleItem item) {
    final subject = TextEditingController(text: item.subject);
    final day = TextEditingController(text: item.day);
    final date = TextEditingController(text: item.date);
    final time = TextEditingController(text: item.time);
    final location = TextEditingController(text: item.location);
    final department = TextEditingController(text: item.department);
    final level = TextEditingController(text: item.level);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('تعديل البند', style: GoogleFonts.cairo(fontWeight: FontWeight.bold), textDirection: TextDirection.rtl),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildTextField(subject, 'المادة'),
              const SizedBox(height: 8),
              _buildTextField(widget.isExam ? date : day, widget.isExam ? 'التاريخ (YYYY-MM-DD)' : 'اليوم'),
              const SizedBox(height: 8),
              _buildTextField(time, 'الوقت (من - إلى)'),
              const SizedBox(height: 8),
              _buildTextField(location, 'المكان/القاعة'),
              const SizedBox(height: 8),
              _buildTextField(department, 'القسم'),
              const SizedBox(height: 8),
              _buildTextField(level, 'الفرقة'),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text('إلغاء', style: GoogleFonts.cairo(color: Colors.grey))),
          ElevatedButton(
            onPressed: () async {
              final messenger = ScaffoldMessenger.of(context);
              final nav = Navigator.of(context);
              try {
                await _dataService.updateScheduleItem(
                  item.id,
                  {
                    'subject': subject.text,
                    'day': widget.isExam ? null : day.text,
                    'date': widget.isExam ? date.text : null,
                    'time': time.text,
                    'location': location.text,
                    'department': department.text,
                    'level': level.text,
                    'isExam': item.isExam,
                  },
                  department.text,
                  level.text,
                );
                nav.pop();
                messenger.showSnackBar(SnackBar(content: Text('تم الحفظ', style: GoogleFonts.cairo())));
              } catch (_) {
                messenger.showSnackBar(SnackBar(content: Text('تعذر الحفظ', style: GoogleFonts.cairo()), backgroundColor: Colors.red));
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
            child: Text('حفظ', style: GoogleFonts.cairo(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _buildImage(String url) {
    if (url.startsWith('data:')) {
      try {
        final base64Part = url.split(',').last;
        final bytes = base64Decode(base64Part);
        return Image.memory(
          bytes,
          height: 140,
          width: double.infinity,
          fit: BoxFit.cover,
        );
      } catch (_) {
        return Container(
          height: 140,
          alignment: Alignment.center,
          color: Colors.grey[200],
          child: Text('تعذر قراءة الصورة', style: GoogleFonts.cairo(color: Colors.grey[600])),
        );
      }
    } else {
      final u = url.startsWith('http') ? url : '$baseUrl$url';
      return Image.network(
        u,
        height: 140,
        width: double.infinity,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => Container(
          height: 140,
          alignment: Alignment.center,
          color: Colors.grey[200],
          child: Text('تعذر تحميل الصورة', style: GoogleFonts.cairo(color: Colors.grey[600])),
        ),
      );
    }
  }
}
