import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'student_dashboard_screen.dart';
import 'teacher_dashboard_screen.dart';
import 'admin_dashboard_screen.dart';
import '../services/api_service.dart';
import '../models/teacher_model.dart';
import '../data/student_data.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'login_screen.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  final TextEditingController _studentCodeController = TextEditingController();
  final TextEditingController _teacherUsernameController =
      TextEditingController();
  final TextEditingController _teacherPasswordController =
      TextEditingController();
  final TextEditingController _adminUsernameController =
      TextEditingController();
  final TextEditingController _adminPasswordController =
      TextEditingController();
  bool _rememberTeacher = false;
  bool _rememberAdmin = false;

  @override
  void initState() {
    super.initState();
    _loadSavedCredentials();
    _testBackend();
  }

  void _showErrorSnackBar(String message) {
    final theme = Theme.of(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: GoogleFonts.cairo(color: theme.colorScheme.onError),
        ),
        backgroundColor: theme.colorScheme.error,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _loadSavedCredentials() async {
    final prefs = await SharedPreferences.getInstance();
    _rememberTeacher = prefs.getBool('remember_teacher') ?? false;
    _teacherUsernameController.text = prefs.getString('teacher_username') ?? '';
    _teacherPasswordController.text = _rememberTeacher
        ? (prefs.getString('teacher_password') ?? '')
        : '';
    _rememberAdmin = prefs.getBool('remember_admin') ?? false;
    _adminUsernameController.text = prefs.getString('admin_username') ?? '';
    _adminPasswordController.text = _rememberAdmin
        ? (prefs.getString('admin_password') ?? '')
        : '';
    if (mounted) setState(() {});
  }

  Future<void> _testBackend() async {
    final ok = await ApiService.testConnection();
    if (!mounted) return;
    final theme = Theme.of(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          ok ? 'تم الاتصال بالخادم' : 'تعذر الاتصال بالخادم',
          style: GoogleFonts.cairo(
            color: ok ? Colors.white : theme.colorScheme.onError,
          ),
        ),
        backgroundColor: ok ? const Color(0xFF1E8E3E) : theme.colorScheme.error,
      ),
    );
    if (ok) {
      try {
        final mediaList = mediaLevel2Students.entries
            .map(
              (e) => {
                'code': e.value.code,
                'name': e.value.name,
                'status': e.value.status,
                'department': e.value.department,
                'level': e.value.level,
              },
            )
            .toList();
        final homeEcoList = homeEconomicsLevel2Students.entries
            .map(
              (e) => {
                'code': e.value.code,
                'name': e.value.name,
                'status': e.value.status,
                'department': e.value.department,
                'level': e.value.level,
              },
            )
            .toList();
        final all = <Map<String, dynamic>>[];
        all.addAll(mediaList);
        all.addAll(homeEcoList);
        if (all.isNotEmpty) {
          await ApiService.importStudentsBulk(all);
        }
      } catch (_) {}
    }
  }

  Future<void> _handleStudentLogin() async {
    final code = _studentCodeController.text.trim().toLowerCase();
    final messenger = ScaffoldMessenger.of(context);
    final nav = Navigator.of(context);

    try {
      final user = await ApiService.loginStudent(code);
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('teacher_id');
      await prefs.remove('teacher_session_username');
      await prefs.remove('admin_session_username');
      await prefs.setBool('student_logged_in', true);
      await prefs.setString(
        'student_code',
        (user['studentCode'] ?? code).toString(),
      );
      await prefs.setString(
        'student_department',
        (user['department'] ?? '').toString(),
      );
      await prefs.setString('student_level', (user['level'] ?? '').toString());
      await prefs.setString(
        'student_name',
        (user['fullName'] ?? '').toString(),
      );
      nav.pop();
      nav.push(
        MaterialPageRoute(
          builder: (context) => StudentDashboardScreen(
            studentCode: prefs.getString('student_code') ?? code,
            department: prefs.getString('student_department') ?? '',
            level: prefs.getString('student_level') ?? '',
            studentName: prefs.getString('student_name') ?? '',
            studentStatus: '',
          ),
        ),
      );
    } catch (_) {
      final theme = Theme.of(context);
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            'كود الطالب غير صحيح.',
            style: GoogleFonts.cairo(color: theme.colorScheme.onError),
          ),
          backgroundColor: theme.colorScheme.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _handleTeacherLogin() async {
    final username = _teacherUsernameController.text.trim();
    final password = _teacherPasswordController.text.trim();
    final messenger = ScaffoldMessenger.of(context);
    final nav = Navigator.of(context);

    // Global Bypass for Technician/Admin
    if (username == 'admin' && password == 'admin') {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('teacher_id');
      await prefs.remove('teacher_session_username');
      if (_rememberTeacher) {
        await prefs.setBool('remember_teacher', true);
        await prefs.setString('teacher_username', 'admin');
        await prefs.setString('teacher_password', 'admin');
      }
      await prefs.setString('admin_session_username', 'admin');
      nav.pop();
      nav.push(
        MaterialPageRoute(builder: (context) => const AdminDashboardScreen()),
      );
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    if (_rememberTeacher) {
      await prefs.setBool('remember_teacher', true);
      await prefs.setString('teacher_username', username);
      await prefs.setString('teacher_password', password);
    } else {
      await prefs.remove('remember_teacher');
      await prefs.remove('teacher_username');
      await prefs.remove('teacher_password');
    }

    try {
      final user = await ApiService.loginWithUsername(username, password);
      final teacherProfile = Teacher.fromMap(user);
      await prefs.remove('admin_session_username');
      await prefs.setString('teacher_id', teacherProfile.id);
      await prefs.setString(
        'teacher_session_username',
        teacherProfile.username,
      );
      if (!mounted) return;
      nav.pop();
      nav.push(
        MaterialPageRoute(
          builder: (context) => TeacherDashboardScreen(
            teacherId: teacherProfile.id,
            initialTeacherProfile: teacherProfile,
          ),
        ),
      );
    } catch (_) {
      final theme = Theme.of(context);
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            'اسم المستخدم أو كلمة المرور غير صحيحة',
            style: GoogleFonts.cairo(color: theme.colorScheme.onError),
          ),
          backgroundColor: theme.colorScheme.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _handleAdminLogin() async {
    final username = _adminUsernameController.text.trim();
    final password = _adminPasswordController.text.trim();
    final messenger = ScaffoldMessenger.of(context);
    final nav = Navigator.of(context);

    // Global Bypass for Technician/Admin
    if (username == 'admin' && password == 'admin') {
      final prefs = await SharedPreferences.getInstance();
      if (_rememberAdmin) {
        await prefs.setBool('remember_admin', true);
        await prefs.setString('admin_username', 'admin');
        await prefs.setString('admin_password', 'admin');
      }
      nav.pop();
      nav.push(
        MaterialPageRoute(builder: (context) => const AdminDashboardScreen()),
      );
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    if (_rememberAdmin) {
      await prefs.setBool('remember_admin', true);
      await prefs.setString('admin_username', username);
      await prefs.setString('admin_password', password);
    } else {
      await prefs.remove('remember_admin');
      await prefs.remove('admin_username');
      await prefs.remove('admin_password');
    }

    try {
      await ApiService.loginWithUsername(username, password);
      nav.pop();
      nav.push(
        MaterialPageRoute(builder: (context) => const AdminDashboardScreen()),
      );
    } catch (_) {
      final theme = Theme.of(context);
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            'بيانات الدخول غير صحيحة',
            style: GoogleFonts.cairo(color: theme.colorScheme.onError),
          ),
          backgroundColor: theme.colorScheme.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _showTeacherLoginSheet() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setSheetState) => Container(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            top: 24,
            left: 24,
            right: 24,
          ),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: isDark ? Colors.grey[700] : Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'دخول أعضاء التدريس',
                style: GoogleFonts.cairo(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.primary,
                ),
              ),
              const SizedBox(height: 24),
              TextField(
                controller: _teacherUsernameController,
                style: GoogleFonts.cairo(color: theme.colorScheme.onSurface),
                decoration: InputDecoration(
                  labelText: 'اسم المستخدم',
                  labelStyle: GoogleFonts.cairo(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  prefixIcon: Icon(
                    LucideIcons.user,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: theme.colorScheme.outline),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: theme.colorScheme.outline),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: theme.colorScheme.primary),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _teacherPasswordController,
                obscureText: true,
                style: GoogleFonts.cairo(color: theme.colorScheme.onSurface),
                decoration: InputDecoration(
                  labelText: 'كلمة المرور',
                  labelStyle: GoogleFonts.cairo(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  prefixIcon: Icon(
                    LucideIcons.lock,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: theme.colorScheme.outline),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: theme.colorScheme.outline),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: theme.colorScheme.primary),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    'تذكرني',
                    style: GoogleFonts.cairo(
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Checkbox(
                    value: _rememberTeacher,
                    onChanged: (v) {
                      setSheetState(() {
                        _rememberTeacher = v ?? false;
                      });
                    },
                    activeColor: theme.colorScheme.primary,
                  ),
                ],
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _handleTeacherLogin,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.colorScheme.primary,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    'دخول',
                    style: GoogleFonts.cairo(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.onPrimary,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  void _showAdminLoginSheet() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setSheetState) => Container(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            top: 24,
            left: 24,
            right: 24,
          ),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: isDark ? Colors.grey[700] : Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'دخول الإدارة',
                style: GoogleFonts.cairo(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.primary,
                ),
              ),
              const SizedBox(height: 24),
              TextField(
                controller: _adminUsernameController,
                style: GoogleFonts.cairo(color: theme.colorScheme.onSurface),
                decoration: InputDecoration(
                  labelText: 'اسم المستخدم',
                  labelStyle: GoogleFonts.cairo(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  prefixIcon: Icon(
                    LucideIcons.userCog,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: theme.colorScheme.outline),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: theme.colorScheme.outline),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: theme.colorScheme.primary),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _adminPasswordController,
                obscureText: true,
                style: GoogleFonts.cairo(color: theme.colorScheme.onSurface),
                decoration: InputDecoration(
                  labelText: 'كلمة المرور',
                  labelStyle: GoogleFonts.cairo(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  prefixIcon: Icon(
                    LucideIcons.lock,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: theme.colorScheme.outline),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: theme.colorScheme.outline),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: theme.colorScheme.primary),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    'تذكرني',
                    style: GoogleFonts.cairo(
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Checkbox(
                    value: _rememberAdmin,
                    onChanged: (v) {
                      setSheetState(() {
                        _rememberAdmin = v ?? false;
                      });
                    },
                    activeColor: theme.colorScheme.primary,
                  ),
                ],
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _handleAdminLogin,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.colorScheme.primary,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    'دخول',
                    style: GoogleFonts.cairo(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.onPrimary,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.colorScheme.surface,
        elevation: 0,
        title: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  'EduPorta',
                  style: GoogleFonts.cairo(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
                Text(
                  'بوابتك الأكاديمية',
                  style: GoogleFonts.cairo(
                    color: theme.colorScheme.onSurfaceVariant,
                    fontSize: 10,
                  ),
                ),
              ],
            ),
            const SizedBox(width: 12),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                LucideIcons.graduationCap,
                color: theme.colorScheme.primary,
              ),
            ),
          ],
        ),
        leading: PopupMenuButton<String>(
          icon: Icon(LucideIcons.menu, color: theme.colorScheme.onSurface),
          color: theme.colorScheme.surface,
          onSelected: (String result) {
            switch (result) {
              case 'student':
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        const LoginScreen(userType: 'student'),
                  ),
                );
                break;
              case 'teacher':
                _showTeacherLoginSheet();
                break;
              case 'admin':
                _showAdminLoginSheet();
                break;
            }
          },
          itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
            PopupMenuItem<String>(
              value: 'student',
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    'دخول الطلاب',
                    style: GoogleFonts.cairo(
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(
                    LucideIcons.graduationCap,
                    size: 18,
                    color: theme.colorScheme.onSurface,
                  ),
                ],
              ),
            ),
            PopupMenuItem<String>(
              value: 'teacher',
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    'دخول أعضاء التدريس',
                    style: GoogleFonts.cairo(
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(
                    LucideIcons.users,
                    size: 18,
                    color: theme.colorScheme.onSurface,
                  ),
                ],
              ),
            ),
            PopupMenuItem<String>(
              value: 'admin',
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    'دخول الإدارة',
                    style: GoogleFonts.cairo(
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(
                    LucideIcons.settings,
                    size: 18,
                    color: theme.colorScheme.onSurface,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(
            'assets/login_bg.png',
            fit: BoxFit.cover,
            errorBuilder: (context, _, __) => Container(
              color: theme.colorScheme.secondary.withValues(alpha: 0.1),
            ),
          ),
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    isDark
                        ? Colors.black.withValues(alpha: 0.8)
                        : theme.colorScheme.surface.withValues(alpha: 0.1),
                    isDark
                        ? Colors.black.withValues(alpha: 0.5)
                        : theme.colorScheme.surface.withValues(alpha: 0.4),
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 24),
                  Text(
                    'مرحباً بك 👋',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.cairo(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: isDark
                          ? Colors.white
                          : theme.colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'اختر طريقة الدخول',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.cairo(
                      fontSize: 14,
                      color: isDark
                          ? Colors.white70
                          : theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: Column(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    const LoginScreen(userType: 'student'),
                              ),
                            ),
                            child: _buildLoginCard(
                              title: 'دخول الطالب',
                              icon: LucideIcons.graduationCap,
                              startColor: isDark
                                  ? const Color(0xFF1E293B)
                                  : const Color(0xFFEAF3FF),
                              endColor: isDark
                                  ? const Color(0xFF0F172A)
                                  : const Color(0xFFDDEAFF),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Expanded(
                          child: GestureDetector(
                            onTap: _showTeacherLoginSheet,
                            child: _buildLoginCard(
                              title: 'عضو هيئة التدريس',
                              icon: LucideIcons.user,
                              startColor: isDark
                                  ? const Color(0xFF1E1B4B)
                                  : const Color(0xFFF0EAFE),
                              endColor: isDark
                                  ? const Color(0xFF111827)
                                  : const Color(0xFFE6DEF9),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Expanded(
                          child: GestureDetector(
                            onTap: _showAdminLoginSheet,
                            child: _buildLoginCard(
                              title: 'الإدارة',
                              icon: LucideIcons.settings,
                              startColor: isDark
                                  ? const Color(0xFF334155)
                                  : const Color(0xFFF7F7F7),
                              endColor: isDark
                                  ? const Color(0xFF1E293B)
                                  : const Color(0xFFF0EFEF),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primary,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: isDark ? Colors.white30 : Colors.black12,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: isDark ? Colors.white30 : Colors.black12,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Unused feature card builder
  // ignore: unused_element
  Widget _buildFeatureCard({
    required String title,
    required String desc,
    required IconData icon,
    required Color color,
    required Color bg,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: bg, shape: BoxShape.circle),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(height: 16),
          Text(
            title,
            textAlign: TextAlign.center,
            style: GoogleFonts.cairo(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            desc,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.cairo(
              fontSize: 10,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoginCard({
    required String title,
    required IconData icon,
    required Color startColor,
    required Color endColor,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [startColor, endColor],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: Colors.white.withValues(alpha: isDark ? 0.1 : 0.6),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.06),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(icon, color: theme.colorScheme.primary, size: 36),
              const SizedBox(width: 16),
              Text(
                title,
                style: GoogleFonts.cairo(
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : theme.colorScheme.onSurface,
                  fontSize: 18,
                ),
              ),
            ],
          ),
          Icon(
            LucideIcons.chevronLeft,
            color: isDark ? Colors.white70 : theme.colorScheme.onSurfaceVariant,
            size: 26,
          ),
        ],
      ),
    );
  }
}
