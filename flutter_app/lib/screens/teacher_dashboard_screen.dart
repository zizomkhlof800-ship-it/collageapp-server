import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'dart:convert';
import 'package:file_picker/file_picker.dart';
import 'package:provider/provider.dart';
import '../constants/theme.dart';
import '../providers/theme_provider.dart';
import '../services/data_service.dart';
import 'add_announcement_screen.dart';
import 'announcement_detail_screen.dart';
import 'add_exam_questions_screen.dart';
import '../services/api_service.dart';
import 'students_list_screen.dart';
import 'login_screen.dart';
import 'smart_attendance_screen.dart';
import 'add_exam_setup_screen.dart';
import 'teacher_assignments_screen.dart';
import 'teacher_exam_results_screen.dart';
import 'cumulative_attendance_report_screen.dart';
import 'question_bank_screen.dart';
import '../models/teacher_model.dart';
import '../widgets/offline_image.dart';
import 'subject_forum_screen.dart';
import 'digital_library_screen.dart';

import 'live_lecture_screen.dart';

class TeacherDashboardScreen extends StatefulWidget {
  final String teacherId;
  final Teacher? initialTeacherProfile;

  const TeacherDashboardScreen({
    super.key,
    required this.teacherId,
    this.initialTeacherProfile,
  });

  @override
  State<TeacherDashboardScreen> createState() => _TeacherDashboardScreenState();
}

class _TeacherDashboardScreenState extends State<TeacherDashboardScreen> {
  final DataService _dataService = DataService();
  bool _isDeleteMode = false;
  final GlobalKey _materialsKey = GlobalKey();
  final GlobalKey _examsKey = GlobalKey();

  Teacher? _teacherProfile;
  Course? _selectedCourse;
  bool _courseSelectionQueued = false;
  bool _courseSelectionOpen = false;

  @override
  void initState() {
    super.initState();
    final initialProfile = widget.initialTeacherProfile;
    if (initialProfile != null) {
      _applyTeacherProfile(initialProfile);
    }
    _loadTeacherProfile();
    _dataService.addListener(_onDataChanged);
    _dataService.fetchAnnouncements();
    _dataService.fetchSchedules(department: 'all', level: 'all');
    _dataService.fetchExams();
    _dataService.fetchMaterials();
    _dataService.startAnnouncementsAutoRefresh();
    _dataService.startUnreadCountsStream(widget.teacherId, 'teacher');
  }

  Future<void> _loadTeacherProfile() async {
    try {
      Teacher? profile;
      if (widget.teacherId == 'admin') {
        profile = Teacher(
          id: 'admin',
          username: 'المدير العام',
          courses: [
            Course(
              name: 'كل المواد',
              level: 'جميع الفرق',
              department: 'جميع الأقسام',
            ),
          ],
        );
      } else {
        final data = await ApiService.getUser(widget.teacherId);
        if (data != null) {
          profile = Teacher.fromMap(data);
        }
      }

      if (mounted && profile != null) {
        setState(() => _applyTeacherProfile(profile!));
      }
    } catch (e) {
      // fallback
    } finally {
      if (mounted) setState(() {});
    }
  }

  void _applyTeacherProfile(Teacher profile) {
    _teacherProfile = profile;
    final courses = profile.courses;
    if (courses.isEmpty) {
      _selectedCourse = null;
      return;
    }

    final selectedCourse = _selectedCourse;
    if (selectedCourse != null && !_containsCourse(courses, selectedCourse)) {
      _selectedCourse = null;
    }

    if (_selectedCourse == null && courses.length == 1) {
      _selectedCourse = courses.first;
    }

    if (_selectedCourse == null && courses.length > 1) {
      _queueCourseSelectionDialog();
    }
  }

  bool _containsCourse(List<Course> courses, Course target) {
    return courses.any(
      (course) =>
          course.name == target.name &&
          course.department == target.department &&
          course.level == target.level,
    );
  }

  void _queueCourseSelectionDialog() {
    if (_courseSelectionQueued || _courseSelectionOpen || !mounted) return;
    _courseSelectionQueued = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _courseSelectionQueued = false;
      if (!mounted || _selectedCourse != null) return;
      if ((_teacherProfile?.courses.length ?? 0) > 1) {
        _showCourseSelectionDialog();
      }
    });
  }

  Future<Course?> _ensureCourseSelected() async {
    final selectedCourse = _selectedCourse;
    if (selectedCourse != null) return selectedCourse;

    final courses = _teacherProfile?.courses ?? const <Course>[];
    if (courses.isEmpty) return null;

    if (courses.length == 1) {
      final course = courses.first;
      if (mounted) {
        setState(() => _selectedCourse = course);
      } else {
        _selectedCourse = course;
      }
      return course;
    }

    return _showCourseSelectionDialog();
  }

  Future<Course?> _showCourseSelectionDialog() async {
    if (!mounted || _courseSelectionOpen) return _selectedCourse;
    final courses = _teacherProfile?.courses ?? const <Course>[];
    if (courses.isEmpty) return null;

    String? action;
    _courseSelectionOpen = true;
    final selected = await showDialog<Course>(
      context: context,
      barrierDismissible: _selectedCourse != null,
      builder: (context) => PopScope(
        canPop: _selectedCourse != null,
        child: AlertDialog(
          title: Text(
            'اختر المادة والفرقة',
            style: GoogleFonts.cairo(fontWeight: FontWeight.bold),
          ),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: courses.length,
              itemBuilder: (context, index) {
                final course = courses[index];
                return ListTile(
                  title: Text(
                    course.name,
                    style: GoogleFonts.cairo(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    '${course.department} - ${course.level}',
                    style: GoogleFonts.cairo(),
                  ),
                  trailing: PopupMenuButton<String>(
                    icon: const Icon(LucideIcons.moreVertical),
                    onSelected: (value) {
                      action = value;
                      Navigator.pop(context, course);
                    },
                    itemBuilder: (context) => [
                      PopupMenuItem(
                        value: 'select',
                        child: Text(
                          'اختيار المادة',
                          style: GoogleFonts.cairo(),
                        ),
                      ),
                      PopupMenuItem(
                        value: 'forum',
                        child: Text(
                          'فتح المنتدى',
                          style: GoogleFonts.cairo(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                  onTap: () {
                    Navigator.pop(context, course);
                  },
                );
              },
            ),
          ),
        ),
      ),
    );

    _courseSelectionOpen = false;
    if (!mounted) return selected;
    if (selected != null) {
      setState(() => _selectedCourse = selected);
      if (action == 'forum') {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) _openForumForLevel(selected);
        });
      }
    }
    return selected;
  }

  void _openForumForLevel(Course course) {
    final levelId = '${course.department}__${course.level}';
    final levelName = '${course.department} - ${course.level}';
    final userName = (_teacherProfile?.username ?? widget.teacherId).toString();
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => LevelForumScreen(
          levelId: levelId,
          levelName: levelName,
          userName: userName,
          userRole: 'teacher',
          teacherId: widget.teacherId,
          teacherName: userName,
        ),
      ),
    ).then(
      (_) => _dataService.fetchTotalUnreadCount(widget.teacherId, 'teacher'),
    );
  }

  @override
  void dispose() {
    _dataService.removeListener(_onDataChanged);
    _dataService.stopAnnouncementsAutoRefresh();
    _dataService.stopUnreadCountsStream();
    super.dispose();
  }

  void _onDataChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _navigateToAddAnnouncement() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const AddAnnouncementScreen()),
    );
    if (result != null && result is Announcement) {
      _dataService.addAnnouncement(result);
    }
  }

  void _showSendNotificationDialog() {
    final titleController = TextEditingController();
    final bodyController = TextEditingController();
    final theme = Theme.of(context);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: theme.colorScheme.surface,
        title: Text(
          'إرسال تنبيه للطلاب',
          style: GoogleFonts.cairo(
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.onSurface,
          ),
          textAlign: TextAlign.right,
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleController,
              textAlign: TextAlign.right,
              style: GoogleFonts.cairo(color: theme.colorScheme.onSurface),
              decoration: InputDecoration(
                labelText: 'عنوان التنبيه',
                labelStyle: GoogleFonts.cairo(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                hintText: 'مثلاً: موعد الامتحان',
                hintStyle: GoogleFonts.cairo(
                  color: theme.colorScheme.onSurfaceVariant.withValues(
                    alpha: 0.5,
                  ),
                ),
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: bodyController,
              textAlign: TextAlign.right,
              maxLines: 3,
              style: GoogleFonts.cairo(color: theme.colorScheme.onSurface),
              decoration: InputDecoration(
                labelText: 'نص التنبيه',
                labelStyle: GoogleFonts.cairo(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                hintText: 'مثلاً: يرجى العلم أن امتحان غداً سيبدأ في...',
                hintStyle: GoogleFonts.cairo(
                  color: theme.colorScheme.onSurfaceVariant.withValues(
                    alpha: 0.5,
                  ),
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
            onPressed: () async {
              if (titleController.text.trim().isEmpty ||
                  bodyController.text.trim().isEmpty) {
                return;
              }

              final levelId = _selectedCourse != null
                  ? '${_selectedCourse!.department}__${_selectedCourse!.level}'
                  : '';

              final newAnnouncement = Announcement(
                id: '', // Will be set by API
                title: titleController.text.trim(),
                content: bodyController.text.trim(),
                date: DateTime.now().toString().split(' ')[0],
                priority: 'هام',
                levelId: levelId,
              );

              await _dataService.addAnnouncement(newAnnouncement);

              if (kDebugMode) {
                print('--- Send Notification ---');
                print('Title: ${titleController.text}');
                print('Body: ${bodyController.text}');
                print('LevelId: $levelId');
                print('------------------------------');
              }

              if (!context.mounted) return;
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    'تم إرسال التنبيه بنجاح للفرقة المختارة',
                    style: GoogleFonts.cairo(color: Colors.white),
                  ),
                  backgroundColor: const Color(0xFF1E8E3E),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: theme.colorScheme.primary,
            ),
            child: Text(
              'إرسال',
              style: GoogleFonts.cairo(color: theme.colorScheme.onPrimary),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        drawer: _buildSideMenu(context), // Right side drawer (RTL)
        appBar: AppBar(
          elevation: 0,
          centerTitle: false,
          leading: Builder(
            builder: (context) => IconButton(
              icon: const Icon(LucideIcons.menu),
              onPressed: () =>
                  Scaffold.of(context).openDrawer(), // Open drawer from right
            ),
          ),
          actions: [
            if (_selectedCourse != null)
              IconButton(
                icon: const Icon(LucideIcons.messagesSquare),
                tooltip: 'فتح المنتدى',
                onPressed: () => _openForumForLevel(_selectedCourse!),
              ),
            IconButton(
              icon: const Icon(LucideIcons.bellPlus),
              tooltip: 'إرسال تنبيه للطلاب',
              onPressed: _showSendNotificationDialog,
            ),
            Consumer<ThemeProvider>(
              builder: (context, themeProvider, child) {
                return IconButton(
                  icon: Icon(
                    themeProvider.isDarkMode
                        ? LucideIcons.sun
                        : LucideIcons.moon,
                  ),
                  onPressed: () =>
                      themeProvider.toggleTheme(!themeProvider.isDarkMode),
                );
              },
            ),
            const SizedBox(width: 8),
          ],
          title: Row(
            children: [
              Consumer<ThemeProvider>(
                builder: (context, themeProvider, _) => ColorFiltered(
                  colorFilter: themeProvider.isDarkMode
                      ? const ColorFilter.matrix([
                          -1,
                          0,
                          0,
                          0,
                          255,
                          0,
                          -1,
                          0,
                          0,
                          255,
                          0,
                          0,
                          -1,
                          0,
                          255,
                          0,
                          0,
                          0,
                          1,
                          0,
                        ])
                      : const ColorFilter.mode(
                          Colors.transparent,
                          BlendMode.dst,
                        ),
                  child: Icon(
                    LucideIcons.graduationCap,
                    color: theme.colorScheme.primary,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Consumer<ThemeProvider>(
                builder: (context, themeProvider, _) => Text(
                  'EduPorta',
                  style: GoogleFonts.cairo(
                    color: themeProvider.isDarkMode
                        ? Colors.white
                        : theme.colorScheme.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 1. Welcome Card
              _buildWelcomeCard(),
              const SizedBox(height: 16),

              // 2. Announcements Card
              _buildSectionCard(
                title: 'الإعلانات',
                icon: LucideIcons.megaphone,
                action: Row(
                  children: [
                    // Delete Button
                    IconButton(
                      onPressed: () {
                        setState(() {
                          _isDeleteMode = !_isDeleteMode;
                        });
                      },
                      icon: Icon(
                        _isDeleteMode ? LucideIcons.x : LucideIcons.trash2,
                        size: 20,
                        color: _isDeleteMode
                            ? Colors.red
                            : theme.textTheme.bodySmall?.color,
                      ),
                      tooltip: _isDeleteMode ? 'إلغاء الحذف' : 'حذف إعلان',
                    ),
                    const SizedBox(width: 8),
                    // Add Button
                    TextButton.icon(
                      onPressed: _navigateToAddAnnouncement,
                      icon: const Icon(LucideIcons.plus, size: 16),
                      label: Text(
                        'إضافة',
                        style: GoogleFonts.cairo(fontWeight: FontWeight.bold),
                      ),
                      style: TextButton.styleFrom(
                        foregroundColor: theme.colorScheme.primary,
                      ),
                    ),
                  ],
                ),
                child: _dataService.announcements.isEmpty
                    ? _buildEmptyState('لا توجد إعلانات')
                    : Column(
                        children: _dataService.announcements.map((
                          announcement,
                        ) {
                          return Stack(
                            children: [
                              InkWell(
                                onTap: _isDeleteMode
                                    ? null
                                    : () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) =>
                                                AnnouncementDetailScreen(
                                                  announcementId:
                                                      announcement.id,
                                                ),
                                          ),
                                        );
                                      },
                                child: Container(
                                  margin: const EdgeInsets.only(bottom: 12),
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: theme
                                        .colorScheme
                                        .surfaceContainerHighest
                                        .withValues(alpha: 0.3),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: theme.dividerColor,
                                    ),
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Expanded(
                                            child: Text(
                                              announcement.title,
                                              style: GoogleFonts.cairo(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 14,
                                                color: theme
                                                    .textTheme
                                                    .bodyLarge
                                                    ?.color,
                                              ),
                                            ),
                                          ),
                                          if (announcement.priority ==
                                              'هام جداً')
                                            Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 8,
                                                    vertical: 4,
                                                  ),
                                              decoration: BoxDecoration(
                                                color: Colors.red.withValues(
                                                  alpha: 0.1,
                                                ),
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                              ),
                                              child: Text(
                                                'هام',
                                                style: GoogleFonts.cairo(
                                                  fontSize: 10,
                                                  fontWeight: FontWeight.bold,
                                                  color: Colors.red,
                                                ),
                                              ),
                                            ),
                                        ],
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        announcement.content,
                                        style: GoogleFonts.cairo(
                                          fontSize: 12,
                                          color:
                                              theme.textTheme.bodySmall?.color,
                                        ),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      if (announcement.imageUrl.isNotEmpty) ...[
                                        const SizedBox(height: 8),
                                        ClipRRect(
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                          child: OfflineImage(
                                            url: announcement.imageUrl,
                                            height: 120,
                                            width: double.infinity,
                                            fit: BoxFit.cover,
                                          ),
                                        ),
                                      ],
                                      const SizedBox(height: 8),
                                      Row(
                                        children: [
                                          const Icon(
                                            LucideIcons.clock,
                                            size: 12,
                                            color: Colors.grey,
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            announcement.date,
                                            style: GoogleFonts.cairo(
                                              fontSize: 10,
                                              color: Colors.grey,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              if (_isDeleteMode)
                                Positioned(
                                  left: 0,
                                  top: 0,
                                  bottom: 12, // match margin bottom
                                  child: Center(
                                    child: Container(
                                      margin: const EdgeInsets.only(left: 8),
                                      child: IconButton(
                                        icon: const Icon(
                                          LucideIcons.trash2,
                                          color: Colors.red,
                                        ),
                                        onPressed: () {
                                          _dataService.deleteAnnouncement(
                                            announcement.id,
                                          );
                                          if (_dataService
                                              .announcements
                                              .isEmpty) {
                                            setState(() {
                                              _isDeleteMode = false;
                                            });
                                          }
                                        },
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          );
                        }).toList(),
                      ),
              ),
              const SizedBox(height: 16),

              // 3. Quick Actions (Blue Card)
              _buildQuickActionsCard(context),
              const SizedBox(height: 16),

              // 5. Recent Exams Card
              _buildSectionCard(
                title: 'الاختبارات الأخيرة',
                icon: LucideIcons.fileCheck,
                sectionKey: _examsKey,
                action: TextButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => AddExamSetupScreen(
                          initialSubject: _selectedCourse?.name,
                          initialDepartment: _selectedCourse?.department,
                          initialLevel: _selectedCourse?.level,
                        ),
                      ),
                    );
                  },
                  icon: const Icon(LucideIcons.plus, size: 16),
                  label: Text(
                    'إضافة',
                    style: GoogleFonts.cairo(fontWeight: FontWeight.bold),
                  ),
                  style: TextButton.styleFrom(
                    foregroundColor: theme.colorScheme.primary,
                  ),
                ),
                child:
                    _dataService.exams.where((e) {
                      if (_selectedCourse == null) return true;
                      // Filter by department and level
                      return e.department == _selectedCourse!.department &&
                          e.level == _selectedCourse!.level;
                    }).isEmpty
                    ? _buildEmptyState(
                        'لا توجد اختبارات لهذه الفرقة حالياً',
                        icon: LucideIcons.clipboardList,
                      )
                    : Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        children: _dataService.exams
                            .where((e) {
                              if (_selectedCourse == null) return true;
                              return e.department ==
                                      _selectedCourse!.department &&
                                  e.level == _selectedCourse!.level;
                            })
                            .map((e) {
                              return Container(
                                width: 260,
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: theme
                                      .colorScheme
                                      .surfaceContainerHighest
                                      .withValues(alpha: 0.3),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: theme.dividerColor),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Icon(
                                          LucideIcons.fileCheck,
                                          size: 16,
                                          color:
                                              theme.textTheme.bodyLarge?.color,
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            e.subject,
                                            style: GoogleFonts.cairo(
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      '${e.level} - ${e.department}',
                                      style: GoogleFonts.cairo(
                                        color: theme.textTheme.bodySmall?.color,
                                        fontSize: 12,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Row(
                                      children: [
                                        const Icon(
                                          LucideIcons.checkCircle,
                                          size: 14,
                                          color: Colors.green,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          'صح/خطأ: ${e.tfCount}',
                                          style: GoogleFonts.cairo(
                                            fontSize: 12,
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        const Icon(
                                          LucideIcons.listChecks,
                                          size: 14,
                                          color: Colors.blue,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          'اختيار: ${e.mcqCount}',
                                          style: GoogleFonts.cairo(
                                            fontSize: 12,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.end,
                                      children: [
                                        TextButton.icon(
                                          onPressed: () async {
                                            try {
                                              final exam =
                                                  await ApiService.getExamById(
                                                    e.id,
                                                  );
                                              final questions =
                                                  List<
                                                    Map<String, dynamic>
                                                  >.from(
                                                    exam['questions'] ??
                                                        const [],
                                                  );
                                              final tf =
                                                  int.tryParse(
                                                    (exam['tfCount'] ??
                                                            e.tfCount)
                                                        .toString(),
                                                  ) ??
                                                  e.tfCount;
                                              final mcq =
                                                  int.tryParse(
                                                    (exam['mcqCount'] ??
                                                            e.mcqCount)
                                                        .toString(),
                                                  ) ??
                                                  e.mcqCount;
                                              if (!context.mounted) return;
                                              Navigator.push(
                                                context,
                                                MaterialPageRoute(
                                                  builder: (context) =>
                                                      AddExamQuestionsScreen(
                                                        tfCount: tf,
                                                        mcqCount: mcq,
                                                        subject: e.subject,
                                                        department:
                                                            e.department,
                                                        level: e.level,
                                                        examId: e.id,
                                                        initialQuestions:
                                                            questions,
                                                      ),
                                                ),
                                              );
                                            } catch (_) {}
                                          },
                                          icon: const Icon(
                                            LucideIcons.edit,
                                            size: 14,
                                          ),
                                          label: Text(
                                            'تعديل',
                                            style: GoogleFonts.cairo(),
                                          ),
                                          style: TextButton.styleFrom(
                                            foregroundColor:
                                                theme.colorScheme.primary,
                                          ),
                                        ),
                                        TextButton.icon(
                                          onPressed: () =>
                                              _dataService.deleteExam(e.id),
                                          icon: const Icon(
                                            LucideIcons.trash2,
                                            size: 14,
                                          ),
                                          label: Text(
                                            'حذف',
                                            style: GoogleFonts.cairo(),
                                          ),
                                          style: TextButton.styleFrom(
                                            foregroundColor: Colors.red,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              );
                            })
                            .toList(),
                      ),
              ),
              const SizedBox(height: 16),
              // 6. Course Materials (PDF)
              _buildSectionCard(
                title: 'مواد المقرر (PDF)',
                icon: LucideIcons.fileText,
                sectionKey: _materialsKey,
                action: Row(
                  children: [
                    IconButton(
                      onPressed: () {
                        setState(() {
                          _isDeleteMode = !_isDeleteMode;
                        });
                      },
                      icon: Icon(
                        _isDeleteMode ? LucideIcons.x : LucideIcons.trash2,
                        size: 20,
                        color: _isDeleteMode
                            ? Colors.red
                            : theme.textTheme.bodySmall?.color,
                      ),
                      tooltip: _isDeleteMode ? 'إلغاء الحذف' : 'حذف ملف',
                    ),
                    const SizedBox(width: 8),
                    TextButton.icon(
                      onPressed: _pickAndUploadMaterial,
                      icon: const Icon(LucideIcons.plus, size: 16),
                      label: Text(
                        'إضافة',
                        style: GoogleFonts.cairo(fontWeight: FontWeight.bold),
                      ),
                      style: TextButton.styleFrom(
                        foregroundColor: theme.colorScheme.primary,
                      ),
                    ),
                  ],
                ),
                child:
                    _dataService.materials.where((m) {
                      if (_selectedCourse == null) return true;
                      return m.department == _selectedCourse!.department &&
                          m.level == _selectedCourse!.level;
                    }).isEmpty
                    ? _buildEmptyState(
                        'لا توجد مواد مقررات لهذه الفرقة حالياً',
                        icon: LucideIcons.fileText,
                      )
                    : Column(
                        children: _dataService.materials
                            .where((m) {
                              if (_selectedCourse == null) return true;
                              return m.department ==
                                      _selectedCourse!.department &&
                                  m.level == _selectedCourse!.level;
                            })
                            .map((m) {
                              return Stack(
                                children: [
                                  Container(
                                    margin: const EdgeInsets.only(bottom: 12),
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: theme
                                          .colorScheme
                                          .surfaceContainerHighest
                                          .withValues(alpha: 0.3),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: theme.dividerColor,
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                        Icon(
                                          LucideIcons.fileText,
                                          size: 16,
                                          color:
                                              theme.textTheme.bodyLarge?.color,
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                m.originalName,
                                                style: GoogleFonts.cairo(
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                'الأستاذ: ${m.teacherName}',
                                                style: GoogleFonts.cairo(
                                                  color: theme
                                                      .textTheme
                                                      .bodySmall
                                                      ?.color,
                                                  fontSize: 12,
                                                ),
                                              ),
                                              if (m.subject.isNotEmpty ||
                                                  m.department.isNotEmpty ||
                                                  m.level.isNotEmpty) ...[
                                                const SizedBox(height: 4),
                                                Text(
                                                  '${m.subject}${m.subject.isNotEmpty ? ' - ' : ''}${m.level}${m.level.isNotEmpty ? ' - ' : ''}${m.department}',
                                                  style: GoogleFonts.cairo(
                                                    color: theme
                                                        .textTheme
                                                        .bodySmall
                                                        ?.color,
                                                    fontSize: 12,
                                                  ),
                                                ),
                                              ],
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  if (_isDeleteMode)
                                    Positioned(
                                      left: 0,
                                      top: 0,
                                      bottom: 12,
                                      child: Center(
                                        child: Container(
                                          margin: const EdgeInsets.only(
                                            left: 8,
                                          ),
                                          child: IconButton(
                                            icon: const Icon(
                                              LucideIcons.trash2,
                                              color: Colors.red,
                                            ),
                                            onPressed: () {
                                              _dataService.deleteMaterial(m.id);
                                            },
                                          ),
                                        ),
                                      ),
                                    ),
                                ],
                              );
                            })
                            .toList(),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _pickAndUploadMaterial() async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
        withData: true,
      );
      if (result == null || result.files.isEmpty) return;
      final file = result.files.first;
      final bytes = file.bytes;
      if (bytes == null) return;
      final base64Str = 'data:application/pdf;base64,${base64Encode(bytes)}';

      final departmentController = TextEditingController(
        text: _selectedCourse?.department ?? 'إعلام تربوي',
      );
      final levelController = TextEditingController(
        text: _selectedCourse?.level ?? 'الفرقة الثانية',
      );
      final teacherController = TextEditingController(
        text: _teacherProfile?.username ?? '',
      );
      final subjectController = TextEditingController(
        text: _selectedCourse?.name ?? '',
      );

      const List<String> departments = [
        'تكنولوجيا التعليم',
        'الحاسب الآلي',
        'إعلام تربوي',
        'اقتصاد منزلي',
        'تربية فنية',
        'تربية موسيقية',
      ];
      const List<String> levels = [
        'الفرقة الأولى',
        'الفرقة الثانية',
        'الفرقة الثالثة',
        'الفرقة الرابعة',
      ];

      if (!mounted) return;
      final ok =
          await showDialog<bool>(
            context: context,
            builder: (context) {
              return AlertDialog(
                title: Text('بيانات المادة', style: GoogleFonts.cairo()),
                content: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextField(
                        controller: subjectController,
                        decoration: const InputDecoration(
                          labelText: 'اسم المادة',
                        ),
                      ),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<String>(
                        initialValue: departmentController.text.isNotEmpty
                            ? departmentController.text
                            : departments.first,
                        items: departments
                            .map(
                              (e) => DropdownMenuItem(
                                value: e,
                                child: Align(
                                  alignment: Alignment.centerRight,
                                  child: Text(e, style: GoogleFonts.cairo()),
                                ),
                              ),
                            )
                            .toList(),
                        onChanged: (v) {
                          if (v != null) departmentController.text = v;
                          setState(() {});
                        },
                        decoration: const InputDecoration(labelText: 'القسم'),
                      ),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<String>(
                        initialValue: levelController.text.isNotEmpty
                            ? levelController.text
                            : levels.first,
                        items: levels
                            .map(
                              (e) => DropdownMenuItem(
                                value: e,
                                child: Align(
                                  alignment: Alignment.centerRight,
                                  child: Text(e, style: GoogleFonts.cairo()),
                                ),
                              ),
                            )
                            .toList(),
                        onChanged: (v) {
                          if (v != null) levelController.text = v;
                          setState(() {});
                        },
                        decoration: const InputDecoration(labelText: 'الفرقة'),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: teacherController,
                        decoration: const InputDecoration(
                          labelText: 'اسم الدكتور',
                        ),
                      ),
                    ],
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: Text('إلغاء', style: GoogleFonts.cairo()),
                  ),
                  TextButton(
                    onPressed: () => Navigator.pop(context, true),
                    child: Text('حفظ', style: GoogleFonts.cairo()),
                  ),
                ],
              );
            },
          ) ??
          false;

      if (!ok) return;

      await _dataService.addMaterial(
        department: departmentController.text.trim(),
        level: levelController.text.trim(),
        subject: subjectController.text.trim(),
        teacherName: teacherController.text.trim(),
        fileName: file.name,
        fileBase64: base64Str,
      );

      messenger.showSnackBar(
        SnackBar(
          content: Text('تم رفع الملف وحفظه', style: GoogleFonts.cairo()),
          backgroundColor: const Color(0xFF1E8E3E),
        ),
      );
    } catch (_) {
      messenger.showSnackBar(
        SnackBar(
          content: Text('فشل رفع الملف', style: GoogleFonts.cairo()),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Widget _buildSideMenu(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return Drawer(
      backgroundColor: theme.scaffoldBackgroundColor,
      child: ListView(
        // Changed from Column to ListView to make it scrollable
        padding: EdgeInsets.zero,
        children: [
          // Logo Area
          Container(
            padding: const EdgeInsets.symmetric(vertical: 40),
            width: double.infinity,
            decoration: BoxDecoration(
              color: isDark ? theme.colorScheme.surface : Colors.transparent,
            ),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Consumer<ThemeProvider>(
                    builder: (context, themeProvider, _) => ColorFiltered(
                      colorFilter: themeProvider.isDarkMode
                          ? const ColorFilter.matrix([
                              -1,
                              0,
                              0,
                              0,
                              255,
                              0,
                              -1,
                              0,
                              0,
                              255,
                              0,
                              0,
                              -1,
                              0,
                              255,
                              0,
                              0,
                              0,
                              1,
                              0,
                            ])
                          : const ColorFilter.mode(
                              Colors.transparent,
                              BlendMode.dst,
                            ),
                      child: Icon(
                        LucideIcons.graduationCap,
                        size: 40,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Consumer<ThemeProvider>(
                  builder: (context, themeProvider, _) => Text(
                    'EduPorta',
                    style: GoogleFonts.cairo(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: themeProvider.isDarkMode
                          ? Colors.white
                          : theme.colorScheme.primary,
                    ),
                  ),
                ),
              ],
            ),
          ),

          Divider(color: theme.dividerColor),

          // Menu Items
          _buildMenuItem(
            icon: LucideIcons.layoutDashboard,
            title: 'لوحة المعلومات',
            isActive: true,
            onTap: () => Navigator.pop(context),
          ),
          _buildMenuItem(
            icon: LucideIcons.library,
            title: 'المكتبة الرقمية',
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const DigitalLibraryScreen(),
                ),
              );
            },
          ),
          _buildMenuItem(
            icon: LucideIcons.messagesSquare,
            title: 'منتدى الفرقة',
            isActive: false,
            showBadge: _dataService.totalUnreadCount > 0,
            badgeCount: _dataService.totalUnreadCount,
            onTap: () {
              Navigator.pop(context);
              _showLevelSelectionForForum();
            },
          ),
          _buildMenuItem(
            icon: LucideIcons.fileText,
            title: 'مواد المقرر',
            isActive: false,
            onTap: () {
              Navigator.pop(context);
              _pickAndUploadMaterial();
            },
          ),
          _buildMenuItem(
            icon: LucideIcons.clipboardList,
            title: 'الاختبارات الإلكترونية',
            isActive: false,
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => AddExamSetupScreen(
                    initialSubject: _selectedCourse?.name,
                    initialDepartment: _selectedCourse?.department,
                    initialLevel: _selectedCourse?.level,
                  ),
                ),
              );
            },
          ),
          _buildMenuItem(
            icon: LucideIcons.clipboardList,
            title: 'التكليفات (Assignments)',
            onTap: () async {
              Navigator.pop(context); // Close Drawer
              final targetCourse = await _ensureCourseSelected();
              if (targetCourse == null || !context.mounted) return;
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => TeacherAssignmentsScreen(
                    department: targetCourse.department,
                    level: targetCourse.level,
                    subject: targetCourse.name,
                    teacherName: _teacherProfile?.username ?? '',
                  ),
                ),
              );
            },
          ),
          _buildMenuItem(
            icon: LucideIcons.database,
            title: 'بنك الأسئلة',
            isActive: false,
            onTap: () async {
              Navigator.pop(context);
              final targetCourse = await _ensureCourseSelected();
              if (targetCourse == null || !context.mounted) return;
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => QuestionBankScreen(
                    subject: targetCourse.name,
                    department: targetCourse.department,
                    level: targetCourse.level,
                  ),
                ),
              );
            },
          ),
          _buildMenuItem(
            icon: LucideIcons.fileCheck,
            title: 'نتائج الاختبارات',
            isActive: false,
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const TeacherExamResultsScreen(),
                ),
              );
            },
          ),
          _buildMenuItem(
            icon: LucideIcons.qrCode,
            title: 'توليد رمز (QR)',
            isActive: false,
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => SmartAttendanceScreen(
                    teacherId: widget.teacherId,
                    levelId: _selectedCourse != null
                        ? '${_selectedCourse!.department}__${_selectedCourse!.level}'
                        : null,
                    subjectId: _selectedCourse?.name,
                  ),
                ),
              );
            },
          ),
          _buildMenuItem(
            icon: LucideIcons.barChart2,
            title: 'حصاد السنة (الحضور)',
            isActive: false,
            onTap: () async {
              Navigator.pop(context);
              final targetCourse = await _ensureCourseSelected();
              if (targetCourse == null || !context.mounted) return;
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => CumulativeAttendanceReportScreen(
                    levelId:
                        '${targetCourse.department}__${targetCourse.level}',
                    teacherId: widget.teacherId,
                  ),
                ),
              );
            },
          ),
          _buildMenuItem(
            icon: LucideIcons.list,
            title: 'قائمة الطلاب',
            isActive: false,
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => StudentsListScreen(
                    department: _selectedCourse?.department,
                    level: _selectedCourse?.level,
                  ),
                ),
              );
            },
          ),

          Divider(color: theme.dividerColor),

          // Theme Toggle in Drawer
          Consumer<ThemeProvider>(
            builder: (context, themeProvider, _) => ListTile(
              leading: Icon(
                themeProvider.isDarkMode ? LucideIcons.sun : LucideIcons.moon,
                color: theme.colorScheme.primary,
              ),
              title: Text(
                themeProvider.isDarkMode ? 'الوضع الفاتح' : 'الوضع الداكن',
                style: GoogleFonts.cairo(
                  color: theme.textTheme.bodyLarge?.color,
                ),
              ),
              trailing: Switch(
                value: themeProvider.isDarkMode,
                onChanged: (value) => themeProvider.toggleTheme(value),
                activeThumbColor: theme.colorScheme.primary,
              ),
              onTap: () => themeProvider.toggleTheme(!themeProvider.isDarkMode),
            ),
          ),

          const Divider(),

          // Logout
          _buildMenuItem(
            icon: LucideIcons.logOut,
            title: 'تسجيل الخروج',
            color: Colors.red,
            isActive: false,
            onTap: () {
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(
                  builder: (context) => const LoginScreen(userType: 'teacher'),
                ),
                (route) => false,
              );
            },
          ),

          const SizedBox(height: 16),

          // User Profile at bottom
          Container(
            padding: const EdgeInsets.all(16),
            color: isDark
                ? theme.colorScheme.surface
                : theme.colorScheme.surfaceContainerHighest.withValues(
                    alpha: 0.5,
                  ),
            child: Row(
              children: [
                CircleAvatar(
                  backgroundColor: theme.colorScheme.primary.withValues(
                    alpha: 0.1,
                  ),
                  child: Text(
                    (_teacherProfile?.username ?? 'T').substring(0, 1),
                    style: GoogleFonts.cairo(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _teacherProfile?.username ?? '...',
                        style: GoogleFonts.cairo(
                          fontWeight: FontWeight.bold,
                          color: theme.textTheme.bodyLarge?.color,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        'أستاذ جامعي',
                        style: GoogleFonts.cairo(
                          fontSize: 12,
                          color: theme.textTheme.bodySmall?.color,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showLevelSelectionForForum() {
    final theme = Theme.of(context);
    final teacherName = (_teacherProfile?.username ?? widget.teacherId)
        .toString();
    final courses = _teacherProfile?.courses ?? [];

    if (courses.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'لا توجد فرق دراسية مسجلة لك',
            style: GoogleFonts.cairo(),
          ),
        ),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.6,
        decoration: BoxDecoration(
          color: theme.scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: theme.dividerColor,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'اختر الفرقة للمنتدى',
              style: GoogleFonts.cairo(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: courses.length,
                itemBuilder: (context, index) {
                  final course = courses[index];
                  final levelId = '${course.department}__${course.level}';
                  final levelName = '${course.department} - ${course.level}';

                  return FutureBuilder<int>(
                    future: ApiService.getUnreadCount(
                      levelId,
                      widget.teacherId,
                      'teacher',
                    ),
                    builder: (context, snapshot) {
                      final unread = snapshot.data ?? 0;
                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: theme.colorScheme.primary
                                .withValues(alpha: 0.1),
                            child: Icon(
                              LucideIcons.users,
                              color: theme.colorScheme.primary,
                            ),
                          ),
                          title: Text(
                            course.name,
                            style: GoogleFonts.cairo(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          subtitle: Text(
                            levelName,
                            style: GoogleFonts.cairo(fontSize: 12),
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (unread > 0)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.red,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Text(
                                    unread.toString(),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              const SizedBox(width: 8),
                              const Icon(LucideIcons.chevronLeft),
                            ],
                          ),
                          onTap: () {
                            Navigator.pop(context);
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => LevelForumScreen(
                                  levelId: levelId,
                                  levelName: levelName,
                                  userName: teacherName,
                                  userRole: 'teacher',
                                  teacherId: widget.teacherId,
                                  teacherName: teacherName,
                                ),
                              ),
                            ).then(
                              (_) => _dataService.fetchTotalUnreadCount(
                                widget.teacherId,
                                'teacher',
                              ),
                            );
                          },
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    bool isActive = false,
    bool showBadge = false,
    int badgeCount = 0,
    Color? color,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final defaultIconColor = isDark ? Colors.grey[400] : Colors.grey[600];
    final defaultTextColor = isDark ? Colors.white : Colors.grey[800];

    return ListTile(
      leading: Stack(
        clipBehavior: Clip.none,
        children: [
          Icon(
            icon,
            color:
                color ??
                (isActive ? theme.colorScheme.primary : defaultIconColor),
          ),
          if (showBadge && badgeCount > 0)
            Positioned(
              right: -5,
              top: -5,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(
                  color: Colors.red,
                  shape: BoxShape.circle,
                ),
                constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                child: Text(
                  badgeCount.toString(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 8,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
        ],
      ),
      title: Text(
        title,
        style: GoogleFonts.cairo(
          color:
              color ??
              (isActive ? theme.colorScheme.primary : defaultTextColor),
          fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      onTap: onTap,
      selected: isActive,
      selectedTileColor: theme.colorScheme.primary.withValues(alpha: 0.05),
      contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
      shape: const Border(
        right: BorderSide(
          width: 4,
          color: AppColors.primary,
          style: BorderStyle.none,
        ),
      ),
    );
  }

  Widget _buildWelcomeCard() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'مرحباً د. ${_teacherProfile?.username ?? '...'}',
                    style: GoogleFonts.cairo(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: theme.textTheme.bodyLarge?.color,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'لوحة التحكم وإدارة المساقات',
                    style: GoogleFonts.cairo(
                      fontSize: 14,
                      color: theme.textTheme.bodySmall?.color,
                    ),
                  ),
                ],
              ),
              const Text('🎓', style: TextStyle(fontSize: 32)),
            ],
          ),
          if (_selectedCourse != null) ...[
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Divider(color: theme.dividerColor),
            ),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    LucideIcons.bookOpen,
                    color: theme.colorScheme.primary,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _selectedCourse!.name,
                        style: GoogleFonts.cairo(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: isDark ? Colors.white : AppColors.text,
                        ),
                      ),
                      Text(
                        '${_selectedCourse!.department} - ${_selectedCourse!.level}',
                        style: GoogleFonts.cairo(
                          fontSize: 12,
                          color: isDark
                              ? Colors.grey[400]
                              : AppColors.textLight,
                        ),
                      ),
                    ],
                  ),
                ),
                if ((_teacherProfile?.courses.length ?? 0) > 1)
                  TextButton(
                    onPressed: _showCourseSelectionDialog,
                    child: Text(
                      'تغيير',
                      style: GoogleFonts.cairo(fontWeight: FontWeight.bold),
                    ),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildQuickActionsCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1E40AF), // Dark blue
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withValues(alpha: 0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'إجراءات سريعة',
            style: GoogleFonts.cairo(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: _navigateToAddAnnouncement,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white.withValues(alpha: 0.2),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 24),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Column(
                    children: [
                      const Icon(LucideIcons.megaphone, size: 28),
                      const SizedBox(height: 8),
                      Text(
                        'إضافة إعلان',
                        style: GoogleFonts.cairo(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: ElevatedButton(
                  onPressed: () async {
                    final targetCourse = await _ensureCourseSelected();
                    if (targetCourse == null || !context.mounted) return;
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => LiveLectureScreen(
                          channelName: targetCourse.name,
                          userName: _teacherProfile?.username ?? 'معلم',
                          isTeacher: true,
                          userId: widget.teacherId,
                          levelId:
                              '${targetCourse.department}__${targetCourse.level}',
                          subjectId: targetCourse.name,
                        ),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red[600], // Red for Live
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 24),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Column(
                    children: [
                      const Icon(LucideIcons.video, size: 28),
                      const SizedBox(height: 8),
                      Text(
                        'بدء محاضرة لايف',
                        style: GoogleFonts.cairo(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => AddExamSetupScreen(
                          initialSubject: _selectedCourse?.name,
                          initialDepartment: _selectedCourse?.department,
                          initialLevel: _selectedCourse?.level,
                        ),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue[600], // Brighter blue
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 24),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Column(
                    children: [
                      const Icon(LucideIcons.plus, size: 28),
                      const SizedBox(height: 8),
                      Text(
                        'إضافة اختبار',
                        style: GoogleFonts.cairo(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 16),
              const Spacer(),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    required Widget child,
    String? subtitle,
    Widget? action,
    Key? sectionKey,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      key: sectionKey,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF2C2C2C) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(
                      icon,
                      size: 20,
                      color: isDark ? Colors.white : AppColors.text,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      title,
                      style: GoogleFonts.cairo(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : AppColors.text,
                      ),
                    ),
                    if (subtitle != null) const SizedBox(width: 8),
                    if (subtitle != null)
                      Text(
                        subtitle,
                        style: GoogleFonts.cairo(
                          color: isDark
                              ? Colors.grey[400]
                              : AppColors.textLight,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                  ],
                ),
                if (action != null) action,
              ],
            ),
          ),
          Divider(
            height: 1,
            color: isDark ? Colors.grey[800] : Colors.grey[200],
          ),
          Padding(padding: const EdgeInsets.all(24), child: child),
        ],
      ),
    );
  }

  Widget _buildEmptyState(String message, {IconData? icon}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Center(
      child: Column(
        children: [
          if (icon != null)
            Icon(
              icon,
              size: 48,
              color: isDark ? Colors.grey[700] : Colors.grey[300],
            ),
          if (icon != null) const SizedBox(height: 16),
          Text(
            message,
            style: GoogleFonts.cairo(
              color: isDark ? Colors.grey[400] : AppColors.textLight,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}
