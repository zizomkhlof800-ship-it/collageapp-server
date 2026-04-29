import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:convert';
import '../data/student_data.dart';
import '../services/api_service.dart';
import 'add_student_screen.dart';
import 'package:excel/excel.dart';

class ManageStudentsScreen extends StatefulWidget {
  const ManageStudentsScreen({super.key});

  @override
  State<ManageStudentsScreen> createState() => _ManageStudentsScreenState();
}

class _ManageStudentsScreenState extends State<ManageStudentsScreen> {
  // Combine all students into a list for display
  List<StudentInfo> _allStudents = [];
  List<StudentInfo> _filteredStudents = [];
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _defaultDeptController = TextEditingController(text: 'إعلام تربوي');
  final TextEditingController _defaultLevelController = TextEditingController(text: 'الفرقة الثانية');
  bool _overwriteExcelDeptLevel = true;
  final Map<String, bool> _accessMap = {};
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
    _init();
  }

  Future<void> _init() async {
    await _loadStudents();
  }

  bool _isLoading = false;

  Future<void> _loadStudents() async {
    if (mounted) setState(() => _isLoading = true);
    try {
      final list = await ApiService.getStudents();
      if (mounted) {
        setState(() {
          _allStudents = list.map((m) {
            final name = (m['fullName'] ?? m['name'] ?? '').toString();
            final code = (m['studentCode'] ?? m['code'] ?? '').toString();
            final status = (m['status'] ?? '').toString();
            final department = (m['department'] ?? '').toString();
            final level = (m['level'] ?? '').toString();
            final s = StudentInfo(name: name, code: code, status: status, department: department, level: level);
            if (code.isNotEmpty) _accessMap[code] = status.contains('مصرح');
            return s;
          }).toList();
          
          if (_allStudents.isEmpty) {
            _handleSeedData();
          } else {
            _filterStudents();
            _isLoading = false;
          }
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _allStudents = [];
          _filterStudents();
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _handleSeedData() async {
    final seed = <Map<String, dynamic>>[];
    seed.addAll(mediaLevel2Students.values.map((s) => {
      'code': s.code,
      'name': s.name,
      'department': s.department,
      'level': s.level,
      'status': s.status,
    }));
    seed.addAll(homeEconomicsLevel2Students.values.map((s) => {
      'code': s.code,
      'name': s.name,
      'department': s.department,
      'level': s.level,
      'status': s.status,
    }));

    if (seed.isNotEmpty) {
      try {
        await ApiService.importStudentsBulk(seed);
        final restored = await ApiService.getStudents();
        if (mounted) {
          setState(() {
            _allStudents = restored.map((m) {
              final name = (m['fullName'] ?? m['name'] ?? '').toString();
              final code = (m['studentCode'] ?? m['code'] ?? '').toString();
              final status = (m['status'] ?? '').toString();
              final department = (m['department'] ?? '').toString();
              final level = (m['level'] ?? '').toString();
              final s = StudentInfo(name: name, code: code, status: status, department: department, level: level);
              if (code.isNotEmpty) _accessMap[code] = status.contains('مصرح');
              return s;
            }).toList();
            _filterStudents();
            _isLoading = false;
          });
        }
      } catch (_) {
        if (mounted) setState(() => _isLoading = false);
      }
    } else {
      if (mounted) {
        setState(() {
          _filterStudents();
          _isLoading = false;
        });
      }
    }
  }

  void _filterStudents() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      if (query.isEmpty) {
        _filteredStudents = List.from(_allStudents);
      } else {
        _filteredStudents = _allStudents.where((student) {
          return student.name.toLowerCase().contains(query) ||
              student.code.toLowerCase().contains(query);
        }).toList();
      }
    });
  }

  Future<void> _addStudent() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const AddStudentScreen()),
    );

    if (result != null && result is StudentInfo) {
      final theme = Theme.of(context);
      final messenger = ScaffoldMessenger.of(context);
      try {
        await ApiService.addStudent({
          'studentCode': result.code,
          'fullName': result.name,
          'status': result.status,
          'department': result.department,
          'level': result.level,
        });
        await _loadStudents();
      } catch (_) {
        try {
          final state = await ApiService.dbHealthState();
          final msg = (state == null || state != 1)
              ? 'تعذر حفظ الطالب: قاعدة البيانات غير جاهزة'
              : 'تعذر حفظ الطالب على الخادم';
          messenger.showSnackBar(
            SnackBar(
              content: Text(msg, style: GoogleFonts.cairo(color: theme.colorScheme.onError)),
              backgroundColor: theme.colorScheme.error,
            ),
          );
        } catch (_) {
          messenger.showSnackBar(
            SnackBar(
              content: Text('تعذر حفظ الطالب على الخادم', style: GoogleFonts.cairo(color: theme.colorScheme.onError)),
              backgroundColor: theme.colorScheme.error,
            ),
          );
        }
        return;
      }
      messenger.showSnackBar(
        SnackBar(
          content: Text('تم إضافة الطالب بنجاح', style: GoogleFonts.cairo(color: Colors.white)),
          backgroundColor: const Color(0xFF1E8E3E),
        ),
      );
    }
  }

  Future<Map<String, dynamic>?> _askImportSettings() async {
    final theme = Theme.of(context);
    return showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setSheetState) => AlertDialog(
          backgroundColor: theme.colorScheme.surface,
          title: Text('إعدادات الاستيراد', style: GoogleFonts.cairo(fontWeight: FontWeight.bold, color: theme.colorScheme.onSurface)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              DropdownButtonFormField<String>(
                initialValue: _defaultDeptController.text.isNotEmpty
                    ? _defaultDeptController.text
                    : (_departments.isNotEmpty ? _departments.first : null),
                dropdownColor: theme.colorScheme.surface,
                items: _departments
                    .map((e) => DropdownMenuItem<String>(
                          value: e,
                          child: Align(alignment: Alignment.centerRight, child: Text(e, style: GoogleFonts.cairo(color: theme.colorScheme.onSurface))),
                        ))
                    .toList(),
                onChanged: (v) {
                  if (v != null) setSheetState(() => _defaultDeptController.text = v);
                },
                decoration: InputDecoration(
                  labelText: 'القسم الافتراضي',
                  labelStyle: GoogleFonts.cairo(color: theme.colorScheme.onSurfaceVariant),
                  border: const OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: _defaultLevelController.text.isNotEmpty
                    ? _defaultLevelController.text
                    : (_levels.isNotEmpty ? _levels.first : null),
                dropdownColor: theme.colorScheme.surface,
                items: _levels
                    .map((e) => DropdownMenuItem<String>(
                          value: e,
                          child: Align(alignment: Alignment.centerRight, child: Text(e, style: GoogleFonts.cairo(color: theme.colorScheme.onSurface))),
                        ))
                    .toList(),
                onChanged: (v) {
                  if (v != null) setSheetState(() => _defaultLevelController.text = v);
                },
                decoration: InputDecoration(
                  labelText: 'الفرقة الافتراضية',
                  labelStyle: GoogleFonts.cairo(color: theme.colorScheme.onSurfaceVariant),
                  border: const OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text('تطبيق على الكل', style: GoogleFonts.cairo(color: theme.colorScheme.onSurface)),
                  const SizedBox(width: 8),
                  Checkbox(
                    value: _overwriteExcelDeptLevel,
                    onChanged: (v) => setSheetState(() => _overwriteExcelDeptLevel = v ?? true),
                    activeColor: theme.colorScheme.primary,
                  ),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('إلغاء', style: GoogleFonts.cairo(color: theme.colorScheme.onSurfaceVariant)),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context, {
                  'department': _defaultDeptController.text.trim(),
                  'level': _defaultLevelController.text.trim(),
                  'overwrite': _overwriteExcelDeptLevel,
                });
              },
              child: Text('بدء الاستيراد', style: GoogleFonts.cairo(color: theme.colorScheme.primary, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _importFromExcel() async {
    try {
      final settings = await _askImportSettings();
      if (settings == null) return;
      final defaultDept = (settings['department'] ?? '').toString();
      final defaultLevel = (settings['level'] ?? '').toString();
      final overwrite = settings['overwrite'] == true;

      final result = await FilePicker.platform.pickFiles(
        withData: true,
        type: FileType.custom,
        allowedExtensions: ['xlsx', 'xls', 'csv'],
      );
      if (result == null || result.files.isEmpty) return;
      
      final theme = Theme.of(context);
      final messenger = ScaffoldMessenger.of(context);
      
      final file = result.files.first;
      final bytes = file.bytes;
      final ext = (file.extension ?? '').toLowerCase();
      if (bytes == null) {
        messenger.showSnackBar(
          SnackBar(content: Text('تعذر قراءة الملف', style: GoogleFonts.cairo(color: theme.colorScheme.onError)), backgroundColor: theme.colorScheme.error),
        );
        return;
      }
      final students = <Map<String, dynamic>>[];
      if (ext == 'csv') {
        final content = utf8.decode(bytes);
        final lines = content.split(RegExp(r'\r?\n')).where((l) => l.trim().isNotEmpty).toList();
        if (lines.isEmpty) throw Exception('empty_csv');
        final header = lines.first.split(',').map((h) => h.trim().toLowerCase()).toList();
        int idxName = header.indexWhere((h) => h == 'name' || h == 'fullname' || h == 'الاسم');
        int idxCode = header.indexWhere((h) => h == 'code' || h == 'studentcode' || h == 'الكود');
        int idxDept = header.indexWhere((h) => h == 'department' || h == 'القسم');
        int idxLevel = header.indexWhere((h) => h == 'level' || h == 'الفرقة');
        int idxStatus = header.indexWhere((h) => h == 'status' || h == 'الحالة');
        for (int i = 1; i < lines.length; i++) {
          final cols = lines[i].split(',');
          String name = idxName >= 0 && idxName < cols.length ? cols[idxName].trim() : '';
          String code = idxCode >= 0 && idxCode < cols.length ? cols[idxCode].trim() : '';
          String department = idxDept >= 0 && idxDept < cols.length ? cols[idxDept].trim() : '';
          String level = idxLevel >= 0 && idxLevel < cols.length ? cols[idxLevel].trim() : '';
          String status = idxStatus >= 0 && idxStatus < cols.length ? cols[idxStatus].trim() : '';
          if (code.isEmpty || name.isEmpty) continue;
          if (overwrite || department.isEmpty) department = defaultDept;
          if (overwrite || level.isEmpty) level = defaultLevel;
          students.add({'code': code, 'name': name, 'department': department, 'level': level, 'status': status});
        }
      } else {
        final excel = Excel.decodeBytes(bytes);
        if (excel.tables.isEmpty) throw Exception('empty_excel');
        final sheetName = excel.tables.keys.first;
        final table = excel.tables[sheetName]!;
        if (table.rows.isEmpty) throw Exception('empty_sheet');
        final headerRow = table.rows.first.map((cell) => (cell?.value?.toString() ?? '').trim().toLowerCase()).toList();
        int idxName = headerRow.indexWhere((h) => h == 'name' || h == 'fullname' || h == 'الاسم');
        int idxCode = headerRow.indexWhere((h) => h == 'code' || h == 'studentcode' || h == 'الكود');
        int idxDept = headerRow.indexWhere((h) => h == 'department' || h == 'القسم');
        int idxLevel = headerRow.indexWhere((h) => h == 'level' || h == 'الفرقة');
        int idxStatus = headerRow.indexWhere((h) => h == 'status' || h == 'الحالة');
        for (int i = 1; i < table.rows.length; i++) {
          final row = table.rows[i];
          String name = idxName >= 0 && idxName < row.length ? (row[idxName]?.value?.toString() ?? '').trim() : '';
          String code = idxCode >= 0 && idxCode < row.length ? (row[idxCode]?.value?.toString() ?? '').trim() : '';
          String department = idxDept >= 0 && idxDept < row.length ? (row[idxDept]?.value?.toString() ?? '').trim() : '';
          String level = idxLevel >= 0 && idxLevel < row.length ? (row[idxLevel]?.value?.toString() ?? '').trim() : '';
          String status = idxStatus >= 0 && idxStatus < row.length ? (row[idxStatus]?.value?.toString() ?? '').trim() : '';
          if (code.isEmpty || name.isEmpty) continue;
          if (overwrite || department.isEmpty) department = defaultDept;
          if (overwrite || level.isEmpty) level = defaultLevel;
          students.add({'code': code, 'name': name, 'department': department, 'level': level, 'status': status});
        }
      }
      if (students.isEmpty) {
        messenger.showSnackBar(
          SnackBar(content: Text('لم يتم العثور على سجلات صالحة', style: GoogleFonts.cairo(color: Colors.white)), backgroundColor: Colors.orange),
        );
        return;
      }
      await ApiService.importStudentsBulk(students);
      await _loadStudents();
      messenger.showSnackBar(
        SnackBar(content: Text('تم استيراد ${students.length} طالبًا', style: GoogleFonts.cairo(color: Colors.white)), backgroundColor: const Color(0xFF1E8E3E)),
      );
    } catch (_) {
      if (!mounted) return;
      final theme = Theme.of(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('تعذر الاستيراد من الملف', style: GoogleFonts.cairo(color: theme.colorScheme.onError)), backgroundColor: theme.colorScheme.error),
      );
    }
  }
  
  Future<void> _editStudent(StudentInfo student) async {
    final nameController = TextEditingController(text: student.name);
    final deptController = TextEditingController(text: student.department);
    final levelController = TextEditingController(text: student.level);
    final statusController = TextEditingController(text: student.status);
    final theme = Theme.of(context);
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: theme.colorScheme.surface,
        title: Text('تعديل بيانات الطالب', style: GoogleFonts.cairo(fontWeight: FontWeight.bold, color: theme.colorScheme.onSurface)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                style: GoogleFonts.cairo(color: theme.colorScheme.onSurface),
                decoration: InputDecoration(
                  labelText: 'اسم الطالب', 
                  labelStyle: GoogleFonts.cairo(color: theme.colorScheme.onSurfaceVariant),
                  border: const OutlineInputBorder()
                ),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                initialValue: deptController.text.isNotEmpty ? deptController.text : (_departments.isNotEmpty ? _departments.first : null),
                dropdownColor: theme.colorScheme.surface,
                items: _departments
                    .map((e) => DropdownMenuItem<String>(
                          value: e,
                          child: Align(alignment: Alignment.centerRight, child: Text(e, style: GoogleFonts.cairo(color: theme.colorScheme.onSurface))),
                        ))
                    .toList(),
                onChanged: (v) {
                  if (v != null) deptController.text = v;
                },
                decoration: InputDecoration(
                  labelText: 'القسم', 
                  labelStyle: GoogleFonts.cairo(color: theme.colorScheme.onSurfaceVariant),
                  border: const OutlineInputBorder()
                ),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                initialValue: levelController.text.isNotEmpty ? levelController.text : (_levels.isNotEmpty ? _levels.first : null),
                dropdownColor: theme.colorScheme.surface,
                items: _levels
                    .map((e) => DropdownMenuItem<String>(
                          value: e,
                          child: Align(alignment: Alignment.centerRight, child: Text(e, style: GoogleFonts.cairo(color: theme.colorScheme.onSurface))),
                        ))
                    .toList(),
                onChanged: (v) {
                  if (v != null) levelController.text = v;
                },
                decoration: InputDecoration(
                  labelText: 'الفرقة', 
                  labelStyle: GoogleFonts.cairo(color: theme.colorScheme.onSurfaceVariant),
                  border: const OutlineInputBorder()
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: statusController,
                style: GoogleFonts.cairo(color: theme.colorScheme.onSurface),
                decoration: InputDecoration(
                  labelText: 'الحالة', 
                  labelStyle: GoogleFonts.cairo(color: theme.colorScheme.onSurfaceVariant),
                  border: const OutlineInputBorder()
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('إلغاء', style: GoogleFonts.cairo(color: theme.colorScheme.onSurfaceVariant)),
          ),
          TextButton(
            onPressed: () async {
              final theme = Theme.of(context);
              final messenger = ScaffoldMessenger.of(context);
              final nav = Navigator.of(context);
              try {
                await ApiService.updateStudent(
                  student.code,
                  {
                    'fullName': nameController.text.trim(),
                    'department': deptController.text.trim(),
                    'level': levelController.text.trim(),
                    'status': statusController.text.trim(),
                  },
                );
                await _loadStudents();
                nav.pop();
                messenger.showSnackBar(
                  SnackBar(content: Text('تم تحديث بيانات الطالب', style: GoogleFonts.cairo(color: Colors.white)), backgroundColor: const Color(0xFF1E8E3E)),
                );
              } catch (_) {
                messenger.showSnackBar(
                  SnackBar(content: Text('تعذر تحديث بيانات الطالب', style: GoogleFonts.cairo(color: theme.colorScheme.onError)), backgroundColor: theme.colorScheme.error),
                );
              }
            },
            child: Text('حفظ', style: GoogleFonts.cairo(color: theme.colorScheme.primary, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
    nameController.dispose();
    deptController.dispose();
    levelController.dispose();
    statusController.dispose();
  }
  void _deleteStudent(StudentInfo student) {
    final theme = Theme.of(context);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: theme.colorScheme.surface,
        title: Text('حذف طالب', style: GoogleFonts.cairo(fontWeight: FontWeight.bold, color: theme.colorScheme.onSurface)),
        content: Text('هل أنت متأكد من حذف الطالب ${student.name}؟', style: GoogleFonts.cairo(color: theme.colorScheme.onSurface)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('إلغاء', style: GoogleFonts.cairo(color: theme.colorScheme.onSurfaceVariant)),
          ),
          TextButton(
            onPressed: () async {
              final theme = Theme.of(context);
              final messenger = ScaffoldMessenger.of(context);
              final nav = Navigator.of(context);
              try {
                await ApiService.deleteStudent(student.code);
                await _loadStudents();
              } catch (_) {}
              nav.pop();
              messenger.showSnackBar(
                SnackBar(
                  content: Text('تم حذف الطالب بنجاح', style: GoogleFonts.cairo(color: theme.colorScheme.onError)),
                  backgroundColor: theme.colorScheme.error,
                ),
              );
            },
            child: Text('حذف', style: GoogleFonts.cairo(color: theme.colorScheme.error, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        appBar: AppBar(
          backgroundColor: theme.colorScheme.surface,
          elevation: 0,
          title: Text(
            'إدارة الطلاب',
            style: GoogleFonts.cairo(
              color: theme.textTheme.bodyLarge?.color,
              fontWeight: FontWeight.bold,
            ),
          ),
          leading: IconButton(
            icon: Icon(LucideIcons.arrowRight, color: theme.colorScheme.onSurface),
            onPressed: () => Navigator.pop(context),
          ),
        actions: [
          TextButton.icon(
            onPressed: _importFromExcel,
            icon: const Icon(LucideIcons.upload, size: 16),
            label: Text('استيراد من اكسيل', style: GoogleFonts.cairo(fontWeight: FontWeight.bold)),
            style: TextButton.styleFrom(foregroundColor: theme.colorScheme.primary),
          ),
          const SizedBox(width: 8),
        ],
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: _addStudent,
          backgroundColor: theme.colorScheme.primary,
          child: Icon(LucideIcons.plus, color: theme.colorScheme.onPrimary),
        ),
        body: Column(
          children: [
            // Search Bar
            Container(
              padding: const EdgeInsets.all(16),
              color: theme.colorScheme.surface,
              child: TextField(
                controller: _searchController,
                onChanged: (value) => _filterStudents(),
                style: GoogleFonts.cairo(color: theme.textTheme.bodyLarge?.color),
                decoration: InputDecoration(
                  hintText: 'بحث بالاسم أو الكود...',
                  hintStyle: GoogleFonts.cairo(color: theme.textTheme.bodySmall?.color),
                  prefixIcon: Icon(LucideIcons.search, color: theme.textTheme.bodySmall?.color),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: theme.dividerColor),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: theme.dividerColor),
                  ),
                  filled: true,
                  fillColor: theme.colorScheme.surface,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                ),
              ),
            ),
            
            // List
            Expanded(
              child: _filteredStudents.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(LucideIcons.users, size: 64, color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.3)),
                          const SizedBox(height: 16),
                          Text(
                            'لا يوجد طلاب',
                            style: GoogleFonts.cairo(
                              color: theme.textTheme.bodySmall?.color,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemCount: _filteredStudents.length,
                      separatorBuilder: (context, index) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final student = _filteredStudents[index];
                        return GestureDetector(
                          onTap: () => _editStudent(student),
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.surface,
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        student.name,
                                        textAlign: TextAlign.right,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        style: GoogleFonts.cairo(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                          color: theme.textTheme.bodyLarge?.color,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    CircleAvatar(
                                      backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.1),
                                      child: Text(
                                        student.name.isNotEmpty ? student.name.substring(0, 1) : 'S',
                                        style: GoogleFonts.cairo(
                                          fontWeight: FontWeight.bold,
                                          color: theme.colorScheme.primary,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  '${student.level} • ${student.department}',
                                  textAlign: TextAlign.right,
                                  style: GoogleFonts.cairo(
                                    fontSize: 13,
                                    color: theme.textTheme.bodySmall?.color,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'الكود: ${student.code}',
                                  textAlign: TextAlign.right,
                                  style: GoogleFonts.cairo(
                                    fontSize: 13,
                                    color: theme.colorScheme.primary,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    IconButton(
                                      icon: const Icon(LucideIcons.trash2, color: Colors.red, size: 20),
                                      onPressed: () => _deleteStudent(student),
                                    ),
                                    Row(
                                      children: [
                                        Text('سماح', style: GoogleFonts.cairo(fontSize: 13, color: theme.textTheme.bodyLarge?.color)),
                                        const SizedBox(width: 6),
                                        Checkbox(
                                          value: _accessMap[student.code] ?? student.status.contains('مصرح'),
                                          onChanged: (v) async {
                                            final next = v ?? false;
                                            final theme = Theme.of(context);
                                            final messenger = ScaffoldMessenger.of(context);
                                            setState(() {
                                              _accessMap[student.code] = next;
                                            });
                                            try {
                                              await ApiService.setStudentAccess(student.code, next);
                                              await _loadStudents();
                                              messenger.showSnackBar(
                                                SnackBar(content: Text(next ? 'تم السماح بالوصول' : 'تم الحجب من الوصول', style: GoogleFonts.cairo(color: Colors.white)), backgroundColor: const Color(0xFF1E8E3E)),
                                              );
                                            } catch (_) {
                                              setState(() {
                                                _accessMap[student.code] = !next;
                                              });
                                              messenger.showSnackBar(
                                                SnackBar(content: Text('تعذر تحديث الصلاحية', style: GoogleFonts.cairo(color: theme.colorScheme.onError)), backgroundColor: theme.colorScheme.error),
                                              );
                                            }
                                          },
                                        ),
                                      ],
                                    ),
                                    IconButton(
                                      icon: Icon(LucideIcons.edit, color: theme.colorScheme.primary, size: 20),
                                      onPressed: () => _editStudent(student),
                                      tooltip: 'تعديل',
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
