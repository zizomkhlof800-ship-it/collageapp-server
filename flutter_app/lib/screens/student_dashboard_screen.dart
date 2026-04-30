import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import '../constants/theme.dart';
import '../providers/theme_provider.dart';
import '../services/data_service.dart';
import 'student_attendance_screen.dart';
import 'department_schedule_screen.dart';
import 'student_exam_schedule_screen.dart';
import 'student_assignments_screen.dart';
import 'student_electronic_exams_screen.dart';
import 'login_screen.dart';
import 'package:url_launcher/url_launcher.dart';
import '../constants/api.dart';
import 'student_announcements_screen.dart';
import 'student_materials_screen.dart';
import '../services/api_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'announcement_detail_screen.dart';
import 'subject_forum_screen.dart';
import 'digital_library_screen.dart';
import '../widgets/offline_image.dart';

import 'live_lecture_screen.dart';

class StudentDashboardScreen extends StatefulWidget {
  final String studentCode;
  final String department;
  final String level;
  final String? studentName;
  final String? studentStatus;

  const StudentDashboardScreen({
    super.key,
    required this.studentCode,
    required this.department,
    required this.level,
    this.studentName,
    this.studentStatus,
  });

  @override
  State<StudentDashboardScreen> createState() => _StudentDashboardScreenState();
}

class _StudentDashboardScreenState extends State<StudentDashboardScreen> {
  final DataService _dataService = DataService();
  final GlobalKey _announcementsKey = GlobalKey();
  final GlobalKey _materialsKey = GlobalKey();
  Map<String, dynamic>? _latestExamResult;
  String _latestExamSubject = '';
  bool _allowedAccess = true;

  @override
  void initState() {
    super.initState();
    final levelId = '${widget.department}__${widget.level}';
    _dataService.addListener(_onDataChanged);
    _dataService.fetchAnnouncements(levelId: levelId);
    _dataService.fetchSchedules(
      department: widget.department,
      level: widget.level,
    );
    _dataService.fetchMaterials(
      department: widget.department,
      level: widget.level,
    );
    _dataService.startUnreadCountsStream(levelId, 'student');
    _dataService.startNotificationsStream(levelId);
    _fetchLatestExamResult();
    _fetchAccessFlag();
  }

  @override
  void dispose() {
    _dataService.removeListener(_onDataChanged);
    _dataService.stopUnreadCountsStream();
    _dataService.stopNotificationsStream();
    super.dispose();
  }

  void _onDataChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  void _showNotifications() {
    final levelId = '${widget.department}__${widget.level}';
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // Mark as read immediately when opening
    _dataService.markNotificationsAsRead(levelId);

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.75,
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(25)),
        ),
        child: Column(
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'الإشعارات',
                    style: GoogleFonts.cairo(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(LucideIcons.x),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            const Divider(),
            Expanded(
              child: StreamBuilder<List<Map<String, dynamic>>>(
                stream: ApiService.getNotificationsStream(levelId),
                builder: (context, snapshot) {
                  final notifications = snapshot.data ?? [];
                  if (notifications.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            LucideIcons.bellOff,
                            size: 48,
                            color: Colors.grey.withValues(alpha: 0.5),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'لا توجد إشعارات حالياً',
                            style: GoogleFonts.cairo(color: Colors.grey),
                          ),
                        ],
                      ),
                    );
                  }
                  return ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: notifications.length,
                    itemBuilder: (context, index) {
                      final n = notifications[index];
                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surfaceContainerHighest
                              .withValues(alpha: 0.3),
                          borderRadius: BorderRadius.circular(15),
                          border: Border.all(
                            color: theme.dividerColor.withValues(alpha: 0.5),
                          ),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: theme.colorScheme.primary.withValues(
                                  alpha: 0.1,
                                ),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                LucideIcons.bell,
                                size: 20,
                                color: theme.colorScheme.primary,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    n['title'] ?? '',
                                    style: GoogleFonts.cairo(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                      color: theme.colorScheme.onSurface,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    n['message'] ?? '',
                                    style: GoogleFonts.cairo(
                                      fontSize: 12,
                                      color: theme.colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    n['timestamp'] != null
                                        ? _formatTimestamp(
                                            n['timestamp'].toString(),
                                          )
                                        : '',
                                    style: GoogleFonts.cairo(
                                      fontSize: 10,
                                      color: Colors.grey,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
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

  String _formatTimestamp(String timestamp) {
    try {
      final dt = DateTime.parse(timestamp);
      final now = DateTime.now();
      final diff = now.difference(dt);

      if (diff.inMinutes < 60) return 'منذ ${diff.inMinutes} دقيقة';
      if (diff.inHours < 24) return 'منذ ${diff.inHours} ساعة';
      return '${dt.day}/${dt.month}/${dt.year}';
    } catch (_) {
      return timestamp;
    }
  }

  Future<void> _fetchAccessFlag() async {
    try {
      final students = await ApiService.getStudents(
        department: widget.department,
        level: widget.level,
      );
      final me = students.firstWhere(
        (s) =>
            (s['studentCode'] ?? s['code'] ?? '').toString() ==
            widget.studentCode,
        orElse: () => {},
      );
      final status = (me['status'] ?? '').toString();
      setState(() {
        _allowedAccess = status.contains('مصرح');
      });
    } catch (_) {
      setState(() {
        _allowedAccess = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      drawer: _buildSideMenu(context),
      onDrawerChanged: (isOpen) {
        if (isOpen) {
          _fetchAccessFlag();
        }
      },
      appBar: AppBar(
        elevation: 0,
        centerTitle: false,
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(LucideIcons.menu),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
        actions: [
          // Notifications Bell
          StreamBuilder<List<Map<String, dynamic>>>(
            stream: ApiService.getNotificationsStream(
              '${widget.department}__${widget.level}',
            ),
            builder: (context, snapshot) {
              final notifications = snapshot.data ?? [];
              final unreadCount = notifications
                  .where((n) => !(n['isRead'] ?? false))
                  .length;

              return Stack(
                children: [
                  IconButton(
                    icon: const Icon(LucideIcons.bell),
                    onPressed: _showNotifications,
                  ),
                  if (unreadCount > 0)
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 16,
                          minHeight: 16,
                        ),
                        child: Text(
                          unreadCount.toString(),
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
              );
            },
          ),
          Consumer<ThemeProvider>(
            builder: (context, themeProvider, child) {
              return IconButton(
                icon: Icon(
                  themeProvider.isDarkMode ? LucideIcons.sun : LucideIcons.moon,
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
                    : const ColorFilter.mode(Colors.transparent, BlendMode.dst),
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
            // 1. Welcome Header
            _buildWelcomeHeader(),
            const SizedBox(height: 16),

            _buildLevelForumCard(),
            const SizedBox(height: 16),

            _buildLiveLectureCard(),
            const SizedBox(height: 16),

            // 2. Announcements
            _buildAnnouncementsCard(),
            const SizedBox(height: 24),

            // 3. Weakness Points
            _buildLatestExamResultCard(),
            const SizedBox(height: 16),

            // 4. Course Materials
            if (_allowedAccess) _buildMaterialsCard(),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildLiveLectureCard() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.red[600],
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.red.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(LucideIcons.video, color: Colors.white),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'المحاضرات المباشرة (Live)',
                  style: GoogleFonts.cairo(
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {
                _showLiveLectureSelection();
              },
              icon: const Icon(LucideIcons.playCircle),
              label: Text(
                'الانضمام للمحاضرة الآن',
                style: GoogleFonts.cairo(fontWeight: FontWeight.bold),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: Colors.red[600],
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showLiveLectureSelection() async {
    final theme = Theme.of(context);
    final subjects = _dataService.materials
        .map((m) => m.subject)
        .toSet()
        .toList();

    if (subjects.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'لا توجد محاضرات مجدولة حالياً',
            style: GoogleFonts.cairo(),
          ),
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          title: Text(
            'اختر المحاضرة',
            style: GoogleFonts.cairo(fontWeight: FontWeight.bold),
          ),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: subjects.length,
              itemBuilder: (context, index) {
                final subject = subjects[index];
                return ListTile(
                  leading: const Icon(LucideIcons.video, color: Colors.red),
                  title: Text(subject, style: GoogleFonts.cairo()),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => LiveLectureScreen(
                          channelName: subject,
                          userName: widget.studentName ?? widget.studentCode,
                          isTeacher: false,
                          userId: widget.studentCode,
                          levelId: '${widget.department}__${widget.level}',
                          subjectId: subject,
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLevelForumCard() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final levelName = '${widget.department} - ${widget.level}';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.2 : 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: theme.dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                LucideIcons.messagesSquare,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'منتدى الفرقة',
                  style: GoogleFonts.cairo(
                    fontWeight: FontWeight.bold,
                    color: theme.textTheme.bodyLarge?.color,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            levelName,
            style: GoogleFonts.cairo(color: theme.textTheme.bodySmall?.color),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {
                _showTeacherSelectionForForum();
              },
              icon: const Icon(LucideIcons.arrowLeftRight),
              label: Text(
                'دخول منتدى الفرقة',
                style: GoogleFonts.cairo(fontWeight: FontWeight.bold),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.colorScheme.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSideMenu(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return Drawer(
      backgroundColor: theme.scaffoldBackgroundColor,
      child: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  // Logo Area
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 40),
                    decoration: BoxDecoration(
                      color: isDark
                          ? theme.colorScheme.surface
                          : Colors.transparent,
                    ),
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primary.withValues(
                              alpha: 0.1,
                            ),
                            shape: BoxShape.circle,
                          ),
                          child: Consumer<ThemeProvider>(
                            builder: (context, themeProvider, _) =>
                                ColorFiltered(
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
                    isActive: false,
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
                      _showTeacherSelectionForForum();
                    },
                  ),
                  _buildMenuItem(
                    icon: LucideIcons.calendar,
                    title: 'القسم والجدول',
                    isActive: false,
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => DepartmentScheduleScreen(
                            department: widget.department,
                            level: widget.level,
                          ),
                        ),
                      );
                    },
                  ),
                  _buildMenuItem(
                    icon: LucideIcons.megaphone,
                    title: 'الإعلانات',
                    isActive: false,
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              const StudentAnnouncementsScreen(),
                        ),
                      );
                    },
                  ),
                  _buildMenuItem(
                    icon: LucideIcons.fileText,
                    title: 'مواد المقرر',
                    isActive: false,
                    onTap: () async {
                      final messenger = ScaffoldMessenger.of(context);
                      final nav = Navigator.of(context);
                      await _fetchAccessFlag();
                      if (!_allowedAccess) {
                        messenger.showSnackBar(
                          SnackBar(
                            content: Text(
                              'غير مصرح لك بالوصول إلى مواد المقرر',
                              style: GoogleFonts.cairo(),
                            ),
                          ),
                        );
                        return;
                      }
                      nav.pop();
                      nav.push(
                        MaterialPageRoute(
                          builder: (context) => StudentMaterialsScreen(
                            department: widget.department,
                            level: widget.level,
                            studentName: widget.studentName,
                            studentCode: widget.studentCode,
                          ),
                        ),
                      );
                    },
                  ),
                  _buildMenuItem(
                    icon: LucideIcons.fileClock,
                    title: 'جدول الامتحانات',
                    isActive: false,
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => StudentExamScheduleScreen(
                            department: widget.department,
                            level: widget.level,
                          ),
                        ),
                      );
                    },
                  ),
                  _buildMenuItem(
                    icon: LucideIcons.listChecks,
                    title: 'الاختبارات الالكترونية',
                    isActive: false,
                    onTap: () async {
                      final messenger = ScaffoldMessenger.of(context);
                      final nav = Navigator.of(context);
                      await _fetchAccessFlag();
                      if (!_allowedAccess) {
                        messenger.showSnackBar(
                          SnackBar(
                            content: Text(
                              'غير مصرح لك بالوصول إلى الاختبارات الإلكترونية',
                              style: GoogleFonts.cairo(),
                            ),
                          ),
                        );
                        return;
                      }
                      nav.pop();
                      nav.push(
                        MaterialPageRoute(
                          builder: (context) => StudentElectronicExamsScreen(
                            department: widget.department,
                            level: widget.level,
                            studentCode: widget.studentCode,
                          ),
                        ),
                      );
                    },
                  ),
                  _buildMenuItem(
                    icon: LucideIcons.clipboardList,
                    title: 'التكليفات (Assignments)',
                    isActive: false,
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => StudentAssignmentsScreen(
                            department: widget.department,
                            level: widget.level,
                            studentCode: widget.studentCode,
                            studentName: widget.studentName ?? '',
                          ),
                        ),
                      );
                    },
                  ),
                  _buildMenuItem(
                    icon: LucideIcons.qrCode,
                    title: 'مسح رمز الحضور',
                    isActive: false,
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => StudentAttendanceScreen(
                            studentName: widget.studentName ?? '',
                            studentCode: widget.studentCode,
                            department: widget.department,
                            level: widget.level,
                            studentStatus: widget.studentStatus ?? '',
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 12),
                  const Divider(),

                  Consumer<ThemeProvider>(
                    builder: (context, themeProvider, _) => ListTile(
                      leading: Icon(
                        themeProvider.isDarkMode
                            ? LucideIcons.sun
                            : LucideIcons.moon,
                        color: theme.colorScheme.primary,
                      ),
                      title: Text(
                        themeProvider.isDarkMode
                            ? 'الوضع الفاتح'
                            : 'الوضع الداكن',
                        style: GoogleFonts.cairo(
                          color: isDark
                              ? Colors.white
                              : theme.textTheme.bodyLarge?.color,
                        ),
                      ),
                      trailing: Switch(
                        value: themeProvider.isDarkMode,
                        onChanged: (value) => themeProvider.toggleTheme(value),
                        activeThumbColor: theme.colorScheme.primary,
                      ),
                      onTap: () =>
                          themeProvider.toggleTheme(!themeProvider.isDarkMode),
                    ),
                  ),
                  const Divider(),
                  _buildMenuItem(
                    icon: LucideIcons.logOut,
                    title: 'تسجيل الخروج',
                    color: Colors.red,
                    isActive: false,
                    onTap: _logoutStudent,
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
            // User Profile card
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
                      widget.studentCode.isNotEmpty
                          ? widget.studentCode[0].toUpperCase()
                          : 'S',
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
                          widget.studentName ?? 'طالب ${widget.department}',
                          style: GoogleFonts.cairo(
                            fontWeight: FontWeight.bold,
                            color: theme.textTheme.bodyLarge?.color,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          widget.studentStatus != null
                              ? '${widget.studentCode} • ${widget.studentStatus}'
                              : widget.studentCode,
                          style: GoogleFonts.cairo(
                            fontSize: 12,
                            color: theme.textTheme.bodySmall?.color,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _logoutStudent() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('student_logged_in');
    await prefs.remove('student_code');
    await prefs.remove('student_department');
    await prefs.remove('student_level');
    await prefs.remove('student_name');
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
        builder: (context) => const LoginScreen(userType: 'student'),
      ),
      (route) => false,
    );
  }

  Widget _buildMaterialsCard() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return Container(
      key: _materialsKey,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.2 : 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(LucideIcons.fileText, color: theme.colorScheme.primary),
              const SizedBox(width: 8),
              Text(
                'مواد المقررات (PDF)',
                style: GoogleFonts.cairo(
                  fontWeight: FontWeight.bold,
                  color: theme.textTheme.bodyLarge?.color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (_dataService.materials.isEmpty)
            Text(
              'لا توجد مواد حالياً',
              style: GoogleFonts.cairo(color: theme.textTheme.bodySmall?.color),
            )
          else
            ..._dataService.materials.map((m) {
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest.withOpacity(
                    0.3,
                  ),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: theme.dividerColor),
                ),
                child: Row(
                  children: [
                    Icon(
                      LucideIcons.fileText,
                      size: 16,
                      color: theme.textTheme.bodyLarge?.color,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            m.originalName,
                            style: GoogleFonts.cairo(
                              fontWeight: FontWeight.bold,
                              color: theme.textTheme.bodyLarge?.color,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'الأستاذ: ${m.teacherName}',
                            style: GoogleFonts.cairo(
                              color: theme.textTheme.bodySmall?.color,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    TextButton(
                      onPressed: () => _openUrl(m.url),
                      child: Text('فتح', style: GoogleFonts.cairo()),
                    ),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }

  Future<void> _openUrl(String url) async {
    final full = url.startsWith('http') ? url : '$baseUrl$url';
    final uri = Uri.tryParse(full);
    if (uri == null) return;
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  void _showTeacherSelectionForForum() async {
    final theme = Theme.of(context);
    final levelId = '${widget.department}__${widget.level}';
    final levelName = '${widget.department} - ${widget.level}';
    final userName =
        (widget.studentName != null && widget.studentName!.trim().isNotEmpty)
        ? widget.studentName!.trim()
        : (widget.studentCode.trim().isNotEmpty
              ? widget.studentCode.trim()
              : 'طالب');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
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
              'اختر المعلم للمحادثة',
              style: GoogleFonts.cairo(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: FutureBuilder<List<Map<String, dynamic>>>(
                future: ApiService.getTeachers(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return Center(
                      child: Text(
                        'لا يوجد معلمون متاحون',
                        style: GoogleFonts.cairo(),
                      ),
                    );
                  }

                  // Filter teachers who teach this level
                  final teachers = snapshot.data!.where((t) {
                    final courses = List<Map<String, dynamic>>.from(
                      t['courses'] ?? [],
                    );
                    return courses.any(
                      (c) =>
                          c['department'] == widget.department &&
                          c['level'] == widget.level,
                    );
                  }).toList();

                  if (teachers.isEmpty) {
                    return Center(
                      child: Text(
                        'لا يوجد معلمون لهذه الفرقة',
                        style: GoogleFonts.cairo(),
                      ),
                    );
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: teachers.length,
                    itemBuilder: (context, index) {
                      final t = teachers[index];
                      final tId = t['id'].toString();
                      final tName = t['username'].toString();

                      return FutureBuilder<int>(
                        future: ApiService.getUnreadCount(
                          levelId,
                          tId,
                          'student',
                        ),
                        builder: (context, countSnapshot) {
                          final unread = countSnapshot.data ?? 0;
                          return Card(
                            margin: const EdgeInsets.only(bottom: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: theme.colorScheme.primary
                                    .withOpacity(0.1),
                                child: Icon(
                                  LucideIcons.user,
                                  color: theme.colorScheme.primary,
                                ),
                              ),
                              title: Text(
                                tName,
                                style: GoogleFonts.cairo(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              subtitle: Text(
                                'معلم الفرقة',
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
                                      userName: userName,
                                      userRole: 'student',
                                      teacherId: tId,
                                      teacherName: tName,
                                    ),
                                  ),
                                ).then(
                                  (_) => _dataService.fetchTotalUnreadCount(
                                    levelId,
                                    'student',
                                  ),
                                );
                              },
                            ),
                          );
                        },
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

  Widget _buildWelcomeHeader() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(20),
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
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  _buildTag(widget.department, LucideIcons.home),
                  const SizedBox(width: 8),
                  _buildTag(widget.level, LucideIcons.graduationCap),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.studentName != null
                          ? 'مرحباً بك، ${widget.studentName}'
                          : 'مرحباً بك، طالب ${widget.department}',
                      style: GoogleFonts.cairo(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: theme.textTheme.bodyLarge?.color,
                      ),
                      textAlign: TextAlign.right,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'جاهزة لمتابعة تدريبك اليوم؟',
                      style: GoogleFonts.cairo(
                        fontSize: 14,
                        color: theme.textTheme.bodySmall?.color,
                      ),
                      textAlign: TextAlign.right,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              const Text('👋', style: TextStyle(fontSize: 32)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTag(String text, IconData icon) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: theme.dividerColor),
      ),
      child: Row(
        children: [
          Icon(icon, size: 14, color: theme.colorScheme.primary),
          const SizedBox(width: 4),
          Text(
            text,
            style: GoogleFonts.cairo(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: theme.textTheme.bodySmall?.color,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _fetchLatestExamResult() async {
    try {
      final result = await ApiService.getLatestExamResult(widget.studentCode);
      if (result != null) {
        String subject = '';
        try {
          final exam = await ApiService.getExamById(
            (result['examId'] ?? '').toString(),
          );
          subject = (exam['subject'] ?? '').toString();
        } catch (_) {}
        if (mounted) {
          setState(() {
            _latestExamResult = result;
            _latestExamSubject = subject;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _latestExamResult = null;
            _latestExamSubject = '';
          });
        }
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _latestExamResult = null;
          _latestExamSubject = '';
        });
      }
    }
  }

  Widget _buildLatestExamResultCard() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.2 : 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'نتائج الاختبار السابق',
                style: GoogleFonts.cairo(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: theme.textTheme.bodyLarge?.color,
                ),
              ),
              Icon(
                LucideIcons.trophy,
                color: theme.colorScheme.primary,
                size: 20,
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (_latestExamResult == null) ...[
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerHighest
                        .withOpacity(0.5),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    LucideIcons.info,
                    color: theme.textTheme.bodySmall?.color,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'لا توجد نتائج مسجلة حالياً',
                    style: GoogleFonts.cairo(
                      color: theme.textTheme.bodySmall?.color,
                    ),
                  ),
                ),
              ],
            ),
          ] else ...[
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    LucideIcons.star,
                    color: theme.colorScheme.primary,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _latestExamSubject.isNotEmpty
                            ? _latestExamSubject
                            : 'اختبار',
                        style: GoogleFonts.cairo(
                          fontWeight: FontWeight.bold,
                          color: theme.textTheme.bodyLarge?.color,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'آخر نتيجة: ${(double.tryParse((_latestExamResult!['score'] ?? 0).toString()) ?? 0).toStringAsFixed(2)}%',
                        style: GoogleFonts.cairo(
                          color: theme.textTheme.bodySmall?.color,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                _buildResultBadge(
                  'إجمالي',
                  (_latestExamResult!['total'] ?? 0).toString(),
                  Colors.blue,
                ),
                const SizedBox(width: 8),
                _buildResultBadge(
                  'صحيح',
                  (_latestExamResult!['correct'] ?? 0).toString(),
                  Colors.green,
                ),
                const SizedBox(width: 8),
                _buildResultBadge(
                  'خطأ',
                  (_latestExamResult!['wrong'] ?? 0).toString(),
                  Colors.red,
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildResultBadge(String label, String value, Color color) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(LucideIcons.circle, size: 10, color: color),
          const SizedBox(width: 6),
          Text(
            '$label: $value',
            style: GoogleFonts.cairo(
              color: theme.textTheme.bodyLarge?.color,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnnouncementsCard() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final announcements = _dataService.announcements;

    return Container(
      key: _announcementsKey,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.2 : 0.03),
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
              Row(
                children: [
                  Icon(
                    LucideIcons.megaphone,
                    color: theme.colorScheme.primary,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'الإعلانات',
                    style: GoogleFonts.cairo(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: theme.textTheme.bodyLarge?.color,
                    ),
                  ),
                ],
              ),
              if (announcements.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${announcements.length} جديدة',
                    style: GoogleFonts.cairo(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 24),
          if (announcements.isEmpty)
            Center(
              child: Text(
                'لا توجد إعلانات حالياً.',
                style: GoogleFonts.cairo(
                  color: theme.textTheme.bodySmall?.color,
                  fontSize: 14,
                ),
              ),
            )
          else
            Column(
              children: announcements.map((announcement) {
                return InkWell(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => AnnouncementDetailScreen(
                          announcementId: announcement.id,
                        ),
                      ),
                    );
                  },
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerHighest
                          .withOpacity(0.3),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: theme.dividerColor),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                announcement.title,
                                style: GoogleFonts.cairo(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                  color: theme.textTheme.bodyLarge?.color,
                                ),
                              ),
                            ),
                            if (announcement.priority == 'هام جداً')
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.red.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
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
                            color: theme.textTheme.bodySmall?.color,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (announcement.imageUrl.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: OfflineImage(
                              url: announcement.imageUrl,
                              height: 140,
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
                );
              }).toList(),
            ),
        ],
      ),
    );
  }
}
