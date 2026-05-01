import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../constants/theme.dart';
import '../models/teacher_model.dart';
import '../services/api_service.dart';

class ManageTeachersScreen extends StatefulWidget {
  const ManageTeachersScreen({super.key});

  @override
  State<ManageTeachersScreen> createState() => _ManageTeachersScreenState();
}

class _ManageTeachersScreenState extends State<ManageTeachersScreen> {
  List<Teacher> _teachers = [];
  bool _isLoading = true;
  final TextEditingController _searchController = TextEditingController();
  List<Teacher> _filteredTeachers = [];

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
    _loadTeachers();
  }

  Future<void> _loadTeachers() async {
    if (mounted) setState(() => _isLoading = true);
    try {
      final data = await ApiService.getTeachers();
      if (mounted) {
        setState(() {
          _teachers = data.map((t) => Teacher.fromMap(t)).toList();
          _filterTeachers();
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
      _showErrorSnackBar('تعذر تحميل بيانات المعلمين');
    }
  }

  void _filterTeachers() {
    final query = _searchController.text.toLowerCase();
    if (mounted) {
      setState(() {
        if (query.isEmpty) {
          _filteredTeachers = List.from(_teachers);
        } else {
          _filteredTeachers = _teachers.where((t) {
            return t.username.toLowerCase().contains(query);
          }).toList();
        }
      });
    }
  }

  void _showErrorSnackBar(String message) {
    if (!mounted) return;
    final theme = Theme.of(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: GoogleFonts.cairo(color: theme.colorScheme.onError),
        ),
        backgroundColor: theme.colorScheme.error,
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: GoogleFonts.cairo(color: Colors.white)),
        backgroundColor: const Color(0xFF1E8E3E),
      ),
    );
  }

  Future<void> _deleteTeacher(Teacher teacher) async {
    final theme = Theme.of(context);
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: theme.colorScheme.surface,
        title: Text(
          'تأكيد الحذف',
          style: GoogleFonts.cairo(
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.onSurface,
          ),
        ),
        content: Text(
          'هل أنت متأكد من حذف حساب المعلم ${teacher.username}؟',
          style: GoogleFonts.cairo(color: theme.colorScheme.onSurface),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              'إلغاء',
              style: GoogleFonts.cairo(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context, true);
              try {
                await ApiService.deleteTeacher(teacher.id);
                _loadTeachers();
                _showSuccessSnackBar('تم حذف حساب المعلم بنجاح');
              } catch (e) {
                _showErrorSnackBar('تعذر حذف حساب المعلم');
              }
            },
            child: Text(
              'حذف',
              style: GoogleFonts.cairo(
                color: Colors.red,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _addOrEditTeacher([Teacher? teacher]) async {
    final isEdit = teacher != null;
    final usernameController = TextEditingController(
      text: teacher?.username ?? '',
    );
    final passwordController = TextEditingController(
      text: teacher?.password ?? '',
    );
    List<Course> selectedCourses = isEdit ? List.from(teacher.courses) : [];
    final theme = Theme.of(context);

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: theme.colorScheme.surface,
          title: Text(
            isEdit ? 'تعديل بيانات معلم' : 'إضافة معلم جديد',
            style: GoogleFonts.cairo(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.onSurface,
            ),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: usernameController,
                  style: GoogleFonts.cairo(color: theme.colorScheme.onSurface),
                  decoration: InputDecoration(
                    labelText: 'اسم المستخدم',
                    labelStyle: GoogleFonts.cairo(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    border: const OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: passwordController,
                  style: GoogleFonts.cairo(color: theme.colorScheme.onSurface),
                  decoration: InputDecoration(
                    labelText: 'كلمة المرور',
                    labelStyle: GoogleFonts.cairo(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    border: const OutlineInputBorder(),
                  ),
                  obscureText: true,
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'المواد والفرق الدراسية:',
                      style: GoogleFonts.cairo(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                    IconButton(
                      icon: Icon(
                        LucideIcons.plusCircle,
                        color: theme.colorScheme.primary,
                      ),
                      onPressed: () async {
                        final newCourse = await _showAddCourseDialog();
                        if (newCourse != null) {
                          setDialogState(() => selectedCourses.add(newCourse));
                        }
                      },
                    ),
                  ],
                ),
                Divider(color: theme.dividerColor),
                ...selectedCourses.asMap().entries.map((entry) {
                  final idx = entry.key;
                  final course = entry.value;
                  return ListTile(
                    dense: true,
                    title: Text(
                      course.name,
                      style: GoogleFonts.cairo(
                        fontSize: 14,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                    subtitle: Text(
                      '${course.department} - ${course.level}',
                      style: GoogleFonts.cairo(
                        fontSize: 12,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    trailing: IconButton(
                      icon: Icon(
                        LucideIcons.trash2,
                        size: 18,
                        color: theme.colorScheme.error,
                      ),
                      onPressed: () =>
                          setDialogState(() => selectedCourses.removeAt(idx)),
                    ),
                  );
                }),
                if (selectedCourses.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: Text(
                      'لا توجد مواد مضافة',
                      style: GoogleFonts.cairo(
                        color: theme.colorScheme.onSurfaceVariant,
                        fontSize: 12,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'إلغاء',
                style: GoogleFonts.cairo(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.colorScheme.primary,
              ),
              onPressed: () async {
                final messenger = ScaffoldMessenger.of(context);
                if (usernameController.text.isEmpty ||
                    passwordController.text.isEmpty) {
                  messenger.showSnackBar(
                    SnackBar(
                      content: Text(
                        'يرجى ملء كافة الحقول الإجبارية',
                        style: GoogleFonts.cairo(
                          color: theme.colorScheme.onError,
                        ),
                      ),
                      backgroundColor: theme.colorScheme.error,
                    ),
                  );
                  return;
                }

                final teacherData = Teacher(
                  id: isEdit
                      ? teacher.id
                      : 'teacher-${DateTime.now().millisecondsSinceEpoch}',
                  username: usernameController.text.trim(),
                  password: passwordController.text.trim(),
                  courses: selectedCourses,
                );

                try {
                  if (isEdit) {
                    await ApiService.updateTeacher(
                      teacher!.id,
                      teacherData.toJson(),
                    );
                  } else {
                    await ApiService.addTeacher(teacherData.toJson());
                  }
                  if (mounted) {
                    Navigator.pop(context);
                    _loadTeachers();
                    _showSuccessSnackBar(
                      isEdit
                          ? 'تم تحديث بيانات المعلم'
                          : 'تم إضافة المعلم بنجاح',
                    );
                  }
                } catch (e) {
                  _showErrorSnackBar('تعذر حفظ بيانات المعلم: $e');
                }
              },
              child: Text(
                'حفظ',
                style: GoogleFonts.cairo(color: theme.colorScheme.onPrimary),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<Course?> _showAddCourseDialog() async {
    final nameController = TextEditingController();
    String selectedDept = _departments.first;
    String selectedLevel = _levels.first;
    final theme = Theme.of(context);

    return showDialog<Course>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setSheetState) => AlertDialog(
          backgroundColor: theme.colorScheme.surface,
          title: Text(
            'إضافة مادة',
            style: GoogleFonts.cairo(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.onSurface,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                style: GoogleFonts.cairo(color: theme.colorScheme.onSurface),
                decoration: InputDecoration(
                  labelText: 'اسم المادة',
                  labelStyle: GoogleFonts.cairo(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  border: const OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: selectedDept,
                dropdownColor: theme.colorScheme.surface,
                items: _departments
                    .map(
                      (e) => DropdownMenuItem(
                        value: e,
                        child: Text(
                          e,
                          style: GoogleFonts.cairo(
                            color: theme.colorScheme.onSurface,
                          ),
                        ),
                      ),
                    )
                    .toList(),
                onChanged: (v) => setSheetState(() => selectedDept = v!),
                decoration: InputDecoration(
                  labelText: 'القسم',
                  labelStyle: GoogleFonts.cairo(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  border: const OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: selectedLevel,
                dropdownColor: theme.colorScheme.surface,
                items: _levels
                    .map(
                      (e) => DropdownMenuItem(
                        value: e,
                        child: Text(
                          e,
                          style: GoogleFonts.cairo(
                            color: theme.colorScheme.onSurface,
                          ),
                        ),
                      ),
                    )
                    .toList(),
                onChanged: (v) => setSheetState(() => selectedLevel = v!),
                decoration: InputDecoration(
                  labelText: 'الفرقة',
                  labelStyle: GoogleFonts.cairo(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  border: const OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'إلغاء',
                style: GoogleFonts.cairo(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.colorScheme.primary,
              ),
              onPressed: () {
                if (nameController.text.isEmpty) return;
                Navigator.pop(
                  context,
                  Course(
                    name: nameController.text,
                    level: selectedLevel,
                    department: selectedDept,
                  ),
                );
              },
              child: Text(
                'إضافة',
                style: GoogleFonts.cairo(color: theme.colorScheme.onPrimary),
              ),
            ),
          ],
        ),
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
          title: Text(
            'إدارة المعلمين',
            style: GoogleFonts.cairo(fontWeight: FontWeight.bold),
          ),
          backgroundColor: theme.colorScheme.surface,
          elevation: 0,
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () => _addOrEditTeacher(),
          backgroundColor: theme.colorScheme.primary,
          child: Icon(LucideIcons.plus, color: theme.colorScheme.onPrimary),
        ),
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: TextField(
                controller: _searchController,
                onChanged: (_) => _filterTeachers(),
                style: GoogleFonts.cairo(
                  color: theme.textTheme.bodyLarge?.color,
                ),
                decoration: InputDecoration(
                  hintText: 'بحث باسم المستخدم...',
                  hintStyle: GoogleFonts.cairo(
                    color: theme.textTheme.bodySmall?.color,
                  ),
                  prefixIcon: Icon(
                    LucideIcons.search,
                    color: theme.textTheme.bodySmall?.color,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: theme.dividerColor),
                  ),
                  filled: true,
                  fillColor: theme.colorScheme.surface,
                ),
              ),
            ),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _filteredTeachers.isEmpty
                  ? _buildEmptyState()
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _filteredTeachers.length,
                      itemBuilder: (context, index) {
                        final teacher = _filteredTeachers[index];
                        return _buildTeacherCard(teacher);
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTeacherCard(Teacher teacher) {
    final theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: theme.colorScheme.surface,
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.1),
          child: Icon(LucideIcons.user, color: theme.colorScheme.primary),
        ),
        title: Text(
          teacher.username,
          style: GoogleFonts.cairo(
            fontWeight: FontWeight.bold,
            color: theme.textTheme.bodyLarge?.color,
          ),
        ),
        subtitle: Text(
          'عدد المواد: ${teacher.courses.length}',
          style: GoogleFonts.cairo(color: theme.textTheme.bodySmall?.color),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: Icon(LucideIcons.edit, color: theme.colorScheme.primary),
              onPressed: () => _addOrEditTeacher(teacher),
            ),
            IconButton(
              icon: Icon(LucideIcons.trash2, color: theme.colorScheme.error),
              onPressed: () => _deleteTeacher(teacher),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    final theme = Theme.of(context);
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            LucideIcons.users,
            size: 64,
            color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.3),
          ),
          const SizedBox(height: 16),
          Text(
            'لا يوجد معلمون مضافون بعد',
            style: GoogleFonts.cairo(
              color: theme.textTheme.bodySmall?.color,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }
}
