import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import '../services/api_service.dart';
import '../models/teacher_model.dart';
import 'student_dashboard_screen.dart';
import 'admin_dashboard_screen.dart';
import 'teacher_dashboard_screen.dart';
import '../providers/theme_provider.dart';

class LoginScreen extends StatefulWidget {
  final String userType;
  const LoginScreen({super.key, required this.userType});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _controller =
      TextEditingController(); // student code OR username
  final TextEditingController _passwordController =
      TextEditingController(); // password for teacher/admin
  bool _remember = false; // remember me for teacher/admin
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _loadSavedCredentialsIfNeeded();
  }

  Future<void> _loadSavedCredentialsIfNeeded() async {
    if (widget.userType == 'teacher' || widget.userType == 'admin') {
      final prefs = await SharedPreferences.getInstance();
      if (widget.userType == 'teacher') {
        final remembered = prefs.getBool('remember_teacher') ?? false;
        final u = prefs.getString('teacher_username') ?? '';
        final p = prefs.getString('teacher_password') ?? '';
        setState(() {
          _remember = remembered;
          _controller.text = u;
          _passwordController.text = p;
        });
      } else {
        final remembered = prefs.getBool('remember_admin') ?? false;
        final u = prefs.getString('admin_username') ?? '';
        final p = prefs.getString('admin_password') ?? '';
        setState(() {
          _remember = remembered;
          _controller.text = u;
          _passwordController.text = p;
        });
      }
    }
  }

  Future<void> _handleLogin() async {
    if (_submitting) return;

    final username = _controller.text.trim();
    final password = _passwordController.text.trim();
    final messenger = ScaffoldMessenger.of(context);
    final nav = Navigator.of(context);

    // Global Bypass for Technician/Admin
    if (username == 'admin' && password == 'admin') {
      setState(() => _submitting = true);
      if (kDebugMode) print('Bypass Auth: Admin/Technician Login Success');

      // Save credentials if remember is checked
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('teacher_id');
      await prefs.remove('teacher_session_username');
      if (_remember) {
        if (widget.userType == 'admin') {
          await prefs.setBool('remember_admin', true);
          await prefs.setString('admin_username', 'admin');
          await prefs.setString('admin_password', 'admin');
        } else if (widget.userType == 'teacher') {
          await prefs.setBool('remember_teacher', true);
          await prefs.setString('teacher_username', 'admin');
          await prefs.setString('teacher_password', 'admin');
        }
      }
      await prefs.setString('admin_session_username', 'admin');

      setState(() => _submitting = false);
      nav.pushReplacement(
        MaterialPageRoute(builder: (context) => const AdminDashboardScreen()),
      );
      return;
    }

    final isStudent = widget.userType == 'student';
    setState(() => _submitting = true);
    try {
      if (isStudent) {
        final code = _controller.text.trim();
        if (code.isEmpty) {
          throw Exception('missing_code');
        }
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
        await prefs.setString(
          'student_level',
          (user['level'] ?? '').toString(),
        );
        await prefs.setString(
          'student_name',
          (user['fullName'] ?? '').toString(),
        );
        nav.pushReplacement(
          MaterialPageRoute(
            builder: (context) => StudentDashboardScreen(
              studentCode: prefs.getString('student_code') ?? code,
              department: prefs.getString('student_department') ?? '',
              level: prefs.getString('student_level') ?? '',
              studentName: prefs.getString('student_name') ?? '',
              studentStatus: (user['status'] ?? '').toString(),
            ),
          ),
        );
      } else if (widget.userType == 'admin') {
        if (kDebugMode) {
          print('Login Attempt for user: $username (Admin)');
        }

        if (username.isEmpty || password.isEmpty) {
          throw Exception('missing_credentials');
        }
        final prefs = await SharedPreferences.getInstance();
        if (_remember) {
          await prefs.setBool('remember_admin', true);
          await prefs.setString('admin_username', username);
          await prefs.setString('admin_password', password);
        } else {
          await prefs.remove('remember_admin');
          await prefs.remove('admin_username');
          await prefs.remove('admin_password');
        }

        throw Exception('invalid_credentials');
      } else if (widget.userType == 'teacher') {
        final username = _controller.text.trim();
        final password = _passwordController.text.trim();

        print('Login Attempt for user: $username');

        if (username.isEmpty || password.isEmpty) {
          throw Exception('missing_credentials');
        }
        final prefs = await SharedPreferences.getInstance();
        if (_remember) {
          await prefs.setBool('remember_teacher', true);
          await prefs.setString('teacher_username', username);
          await prefs.setString('teacher_password', password);
        } else {
          await prefs.remove('remember_teacher');
          await prefs.remove('teacher_username');
          await prefs.remove('teacher_password');
        }

        final result = await ApiService.loginWithUsername(username, password);
        print('Auth Result: $result');

        if (result['role'] == 'admin') {
          await prefs.remove('teacher_id');
          await prefs.remove('teacher_session_username');
          await prefs.setString('admin_session_username', username);
          nav.pushReplacement(
            MaterialPageRoute(
              builder: (context) => const AdminDashboardScreen(),
            ),
          );
        } else {
          final teacherProfile = Teacher.fromMap(result);
          await prefs.remove('admin_session_username');
          await prefs.setString('teacher_id', teacherProfile.id);
          await prefs.setString(
            'teacher_session_username',
            teacherProfile.username,
          );
          nav.pushReplacement(
            MaterialPageRoute(
              builder: (context) => TeacherDashboardScreen(
                teacherId: teacherProfile.id,
                initialTeacherProfile: teacherProfile,
              ),
            ),
          );
        }
      }
    } catch (_) {
      final msg = isStudent
          ? 'تعذر تسجيل الدخول، تأكد من الرقم.'
          : 'بيانات الدخول غير صحيحة.';
      messenger.showSnackBar(
        SnackBar(content: Text(msg, style: GoogleFonts.cairo())),
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  Future<void> _openScanner() async {
    final messenger = ScaffoldMessenger.of(context);
    final value = await showDialog<String>(
      context: context,
      barrierDismissible: true,
      builder: (context) {
        return Dialog(
          insetPadding: const EdgeInsets.all(16),
          backgroundColor: Colors.black,
          child: AspectRatio(
            aspectRatio: 3 / 4,
            child: _BarcodeScanner(
              onDetect: (code) {
                Navigator.of(context).pop(code);
              },
            ),
          ),
        );
      },
    );
    if (value != null && value.isNotEmpty) {
      String? resolved;
      try {
        resolved = await ApiService.resolveStudentCodeFromScan(value);
      } catch (_) {}
      final isDigits =
          (resolved ?? '').isNotEmpty &&
          RegExp(r'^\d{6,}$').hasMatch(resolved!);
      if (isDigits) {
        _controller.text = resolved;
        await _handleLogin();
      } else {
        messenger.showSnackBar(
          SnackBar(
            content: Text(
              'تعذر استخراج الرقم من الباركود. من فضلك جرّب مرة أخرى.',
              style: GoogleFonts.cairo(),
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bool isStudent = widget.userType == 'student';
    final isDark = theme.brightness == Brightness.dark;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        drawer: _buildSideMenu(context, isStudent),
        appBar: AppBar(
          backgroundColor: theme.colorScheme.surface,
          elevation: 0,
          centerTitle: false,
          leading: Builder(
            builder: (context) => IconButton(
              icon: Icon(LucideIcons.menu, color: theme.colorScheme.onSurface),
              onPressed: () => Scaffold.of(context).openDrawer(),
            ),
          ),
          title: Row(
            children: [
              Consumer<ThemeProvider>(
                builder: (context, themeProvider, _) => ColorFiltered(
                  colorFilter: themeProvider.isDarkMode
                      ? const ColorFilter.matrix([
                          -1, 0, 0, 0, 255, // red
                          0, -1, 0, 0, 255, // green
                          0, 0, -1, 0, 255, // blue
                          0, 0, 0, 1, 0, // alpha
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
          actions: [
            Consumer<ThemeProvider>(
              builder: (context, themeProvider, _) => IconButton(
                tooltip: themeProvider.isDarkMode
                    ? 'الوضع الفاتح'
                    : 'الوضع الداكن',
                icon: Icon(
                  themeProvider.isDarkMode ? LucideIcons.sun : LucideIcons.moon,
                  color: theme.colorScheme.onSurface,
                ),
                onPressed: () =>
                    themeProvider.toggleTheme(!themeProvider.isDarkMode),
              ),
            ),
            const SizedBox(width: 8),
          ],
        ),
        body: Stack(
          children: [
            Positioned.fill(
              child: Image.asset(
                'assets/login_bg.png',
                fit: BoxFit.cover,
                errorBuilder: (context, _, __) => Container(
                  color: theme.colorScheme.secondary.withValues(alpha: 0.1),
                ),
              ),
            ),
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      isDark
                          ? Colors.black.withValues(alpha: 0.85)
                          : theme.colorScheme.secondary.withValues(alpha: 0.85),
                      isDark
                          ? Colors.black.withValues(alpha: 0.6)
                          : theme.colorScheme.secondary.withValues(alpha: 0.6),
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
              ),
            ),
            SafeArea(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 520),
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 16,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const SizedBox(height: 16),
                        Center(
                          child: Text(
                            isStudent ? 'تسجيل الدخول للطلاب' : 'تسجيل الدخول',
                            style: GoogleFonts.cairo(
                              fontSize: 26,
                              fontWeight: FontWeight.bold,
                              color: Colors
                                  .white, // Keep white for contrast on gradient
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.surface,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(
                                  alpha: isDark ? 0.3 : 0.08,
                                ),
                                blurRadius: 20,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                isStudent
                                    ? 'الرقم الجامعي (ID)'
                                    : 'اسم المستخدم / البريد الإلكتروني',
                                style: GoogleFonts.cairo(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: theme.textTheme.bodyLarge?.color,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Container(
                                height: 56,
                                decoration: BoxDecoration(
                                  border: Border.all(color: theme.dividerColor),
                                  borderRadius: BorderRadius.circular(10),
                                  color: isDark
                                      ? theme.colorScheme.surface
                                      : Colors.white,
                                ),
                                child: Row(
                                  children: [
                                    if (isStudent) ...[
                                      IconButton(
                                        onPressed: _openScanner,
                                        icon: Icon(
                                          LucideIcons.camera,
                                          color: theme.colorScheme.primary,
                                        ),
                                      ),
                                      VerticalDivider(
                                        width: 1,
                                        color: theme.dividerColor,
                                      ),
                                    ],
                                    Expanded(
                                      child: TextField(
                                        controller: _controller,
                                        textAlign: TextAlign.right,
                                        keyboardType: isStudent
                                            ? TextInputType.number
                                            : TextInputType.text,
                                        style: GoogleFonts.cairo(
                                          fontSize: 16,
                                          color:
                                              theme.textTheme.bodyLarge?.color,
                                        ),
                                        decoration: InputDecoration(
                                          border: InputBorder.none,
                                          hintText: isStudent
                                              ? 'أدخل الرقم الجامعي'
                                              : 'اسم المستخدم',
                                          hintStyle: GoogleFonts.cairo(
                                            color: theme
                                                .textTheme
                                                .bodySmall
                                                ?.color,
                                          ),
                                          contentPadding:
                                              const EdgeInsets.symmetric(
                                                horizontal: 12,
                                              ),
                                        ),
                                        onSubmitted: (_) => _handleLogin(),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              if (!isStudent) ...[
                                const SizedBox(height: 12),
                                Text(
                                  'كلمة المرور',
                                  style: GoogleFonts.cairo(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: theme.textTheme.bodyLarge?.color,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Container(
                                  height: 56,
                                  decoration: BoxDecoration(
                                    border: Border.all(
                                      color: theme.dividerColor,
                                    ),
                                    borderRadius: BorderRadius.circular(10),
                                    color: isDark
                                        ? theme.colorScheme.surface
                                        : Colors.white,
                                  ),
                                  child: Row(
                                    children: [
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: TextField(
                                          controller: _passwordController,
                                          textAlign: TextAlign.right,
                                          obscureText: true,
                                          style: GoogleFonts.cairo(
                                            fontSize: 16,
                                            color: theme
                                                .textTheme
                                                .bodyLarge
                                                ?.color,
                                          ),
                                          decoration: InputDecoration(
                                            border: InputBorder.none,
                                            hintText: 'كلمة المرور',
                                            hintStyle: GoogleFonts.cairo(
                                              color: theme
                                                  .textTheme
                                                  .bodySmall
                                                  ?.color,
                                            ),
                                            contentPadding:
                                                const EdgeInsets.symmetric(
                                                  horizontal: 12,
                                                ),
                                          ),
                                          onSubmitted: (_) => _handleLogin(),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    Text(
                                      'تذكرني',
                                      style: GoogleFonts.cairo(
                                        color: theme.textTheme.bodyLarge?.color,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Checkbox(
                                      value: _remember,
                                      onChanged: (v) => setState(
                                        () => _remember = v ?? false,
                                      ),
                                      activeColor: theme.colorScheme.primary,
                                    ),
                                  ],
                                ),
                              ],
                              const SizedBox(height: 16),
                              SizedBox(
                                width: double.infinity,
                                height: 54,
                                child: ElevatedButton(
                                  onPressed: _submitting ? null : _handleLogin,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: theme.colorScheme.primary,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                  ),
                                  child: Text(
                                    'تسجيل الدخول',
                                    style: GoogleFonts.cairo(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: theme.colorScheme.onPrimary,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            TextButton(
                              onPressed: () {},
                              child: Text(
                                'الدعم الفني',
                                style: GoogleFonts.cairo(color: Colors.white),
                              ),
                            ),
                            TextButton(
                              onPressed: () {},
                              child: Text(
                                isStudent
                                    ? 'نسيت الرقم الجامعي؟'
                                    : 'نسيت كلمة السر؟',
                                style: GoogleFonts.cairo(color: Colors.white),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BarcodeScanner extends StatefulWidget {
  final ValueChanged<String> onDetect;
  const _BarcodeScanner({required this.onDetect});

  @override
  State<_BarcodeScanner> createState() => _BarcodeScannerState();
}

class _BarcodeScannerState extends State<_BarcodeScanner> {
  bool _locked = false;
  final MobileScannerController _controller = MobileScannerController(
    detectionSpeed: DetectionSpeed.normal,
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        MobileScanner(
          controller: _controller,
          errorBuilder: (context, error, child) => Center(
            child: Text(
              'تعذر تشغيل الكاميرا. تأكد من الصلاحيات ثم أعد المحاولة.',
              textAlign: TextAlign.center,
              style: GoogleFonts.cairo(color: Colors.white),
            ),
          ),
          onDetect: (capture) {
            if (_locked) return;
            final barcodes = capture.barcodes;
            if (barcodes.isEmpty) return;
            final raw = barcodes.first.rawValue ?? '';
            if (raw.isEmpty) return;
            _locked = true;
            widget.onDetect(raw.trim());
          },
        ),
        Positioned(
          top: 12,
          left: 12,
          child: IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(LucideIcons.x, color: Colors.white),
          ),
        ),
      ],
    );
  }
}

Drawer _buildSideMenu(BuildContext context, bool isStudent) {
  final theme = Theme.of(context);
  final isDark = theme.brightness == Brightness.dark;
  return Drawer(
    backgroundColor: theme.scaffoldBackgroundColor,
    child: Column(
      children: [
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
        ListTile(
          leading: Icon(
            LucideIcons.graduationCap,
            color: isStudent
                ? theme.colorScheme.primary
                : (isDark
                      ? theme.colorScheme.onSurfaceVariant
                      : theme.textTheme.bodyLarge?.color),
          ),
          title: Text(
            'دخول الطلاب',
            style: GoogleFonts.cairo(
              color: isStudent
                  ? theme.colorScheme.primary
                  : (isDark ? Colors.white : theme.textTheme.bodyLarge?.color),
              fontWeight: isStudent ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          onTap: () {
            Navigator.pop(context);
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => const LoginScreen(userType: 'student'),
              ),
            );
          },
          selected: isStudent,
          selectedTileColor: theme.colorScheme.primary.withValues(alpha: 0.05),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 24,
            vertical: 4,
          ),
        ),
        ListTile(
          leading: Icon(
            LucideIcons.users,
            color: isDark
                ? theme.colorScheme.onSurfaceVariant
                : theme.textTheme.bodyLarge?.color,
          ),
          title: Text(
            'دخول أعضاء التدريس',
            style: GoogleFonts.cairo(
              color: isDark ? Colors.white : theme.textTheme.bodyLarge?.color,
            ),
          ),
          onTap: () {
            Navigator.pop(context);
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => const LoginScreen(userType: 'teacher'),
              ),
            );
          },
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 24,
            vertical: 4,
          ),
        ),
        ListTile(
          leading: Icon(
            LucideIcons.settings,
            color: isDark
                ? theme.colorScheme.onSurfaceVariant
                : theme.textTheme.bodyLarge?.color,
          ),
          title: Text(
            'دخول الإدارة',
            style: GoogleFonts.cairo(
              color: isDark ? Colors.white : theme.textTheme.bodyLarge?.color,
            ),
          ),
          onTap: () {
            Navigator.pop(context);
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => const LoginScreen(userType: 'admin'),
              ),
            );
          },
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 24,
            vertical: 4,
          ),
        ),
        const Spacer(),

        // Theme Toggle in Drawer
        Consumer<ThemeProvider>(
          builder: (context, themeProvider, _) => ListTile(
            leading: Icon(
              themeProvider.isDarkMode ? LucideIcons.sun : LucideIcons.moon,
              color: theme.colorScheme.primary,
            ),
            title: Text(
              themeProvider.isDarkMode ? 'الوضع الفاتح' : 'الوضع الداكن',
              style: GoogleFonts.cairo(color: theme.textTheme.bodyLarge?.color),
            ),
            trailing: Switch(
              value: themeProvider.isDarkMode,
              onChanged: (value) => themeProvider.toggleTheme(value),
              activeThumbColor: theme.colorScheme.primary,
            ),
            onTap: () => themeProvider.toggleTheme(!themeProvider.isDarkMode),
          ),
        ),

        Divider(color: theme.dividerColor),
        const SizedBox(height: 16),
      ],
    ),
  );
}
