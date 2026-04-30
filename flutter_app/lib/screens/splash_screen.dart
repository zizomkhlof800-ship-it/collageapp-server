import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'login_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'student_dashboard_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _navigateNext();
  }

  Future<void> _navigateNext() async {
    await Future.delayed(const Duration(seconds: 2));
    final nav = Navigator.of(context);
    try {
      final prefs = await SharedPreferences.getInstance();
      final logged = prefs.getBool('student_logged_in') ?? false;
      final code = prefs.getString('student_code') ?? '';
      if (logged && code.isNotEmpty) {
        final dep = prefs.getString('student_department') ?? '';
        final lvl = prefs.getString('student_level') ?? '';
        final name = prefs.getString('student_name') ?? '';
        nav.pushReplacement(
          MaterialPageRoute(
            builder: (context) => StudentDashboardScreen(
              studentCode: code,
              department: dep,
              level: lvl,
              studentName: name,
              studentStatus: '',
            ),
          ),
        );
        return;
      }
    } catch (_) {}
    nav.pushReplacement(
      MaterialPageRoute(
        builder: (context) => const LoginScreen(userType: 'student'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F9), // Fixed Light Background
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(
            'assets/splash.png',
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.05),
                            blurRadius: 20,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.school,
                        color: Color(0xFF0F3C66), // Fixed Light Primary
                        size: 48,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'EduPorta',
                      style: GoogleFonts.cairo(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF0F3C66), // Fixed Light Primary
                      ),
                    ),
                    Text(
                      'بوابتك الأكاديمية الذكية',
                      style: GoogleFonts.cairo(
                        color: const Color(0xFF6B7280), // Fixed Light Text
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
