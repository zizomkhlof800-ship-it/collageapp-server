import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../constants/theme.dart';
import '../services/api_service.dart';

class StudentAttendanceScreen extends StatefulWidget {
  final String studentName;
  final String studentCode;
  final String department;
  final String level;
  final String studentStatus;

  const StudentAttendanceScreen({
    super.key,
    required this.studentName,
    required this.studentCode,
    required this.department,
    required this.level,
    required this.studentStatus,
  });

  @override
  State<StudentAttendanceScreen> createState() =>
      _StudentAttendanceScreenState();
}

class _StudentAttendanceScreenState extends State<StudentAttendanceScreen> {
  final MobileScannerController _cameraController = MobileScannerController(
    detectionSpeed: DetectionSpeed.noDuplicates,
  );
  bool _isCameraPermissionGranted = false;
  final TextEditingController _codeController = TextEditingController();

  @override
  void dispose() {
    _codeController.dispose();
    _cameraController.dispose();
    super.dispose();
  }

  void _handleAttendance(String payload) async {
    String lectureId = '';
    final raw = payload.trim();
    final messenger = ScaffoldMessenger.of(context);
    final nav = Navigator.of(context);

    if (raw.isEmpty) {
      messenger.showSnackBar(
        SnackBar(
          content: Text('الرجاء إدخال الرمز', style: GoogleFonts.cairo()),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    try {
      final uri = Uri.tryParse(raw);
      if (uri != null && uri.queryParameters.containsKey('lectureId')) {
        lectureId = uri.queryParameters['lectureId']!;
      }
      if (lectureId.isEmpty) {
        final isDigits = RegExp(r'^[0-9]+$').hasMatch(raw);
        if (isDigits) {
          try {
            final data = await ApiService.resolveSession(raw);
            lectureId = (data['lectureId'] ?? '').toString();
          } catch (_) {}
        }
      }
    } catch (_) {}

    if (lectureId.isEmpty) {
      messenger.showSnackBar(
        SnackBar(
          content: Text('رمز غير صالح', style: GoogleFonts.cairo()),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Geofencing Logic (Mock)
    // In a real app, use Geolocator.getCurrentPosition() and compare with teacher's location
    bool isInRange = true; // For demonstration, assume in range
    if (!isInRange) {
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            'عذراً، يجب أن تكون داخل القاعة لتسجيل الحضور',
            style: GoogleFonts.cairo(),
          ),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    try {
      final activeLevelId = '${widget.department}__${widget.level}';
      // In a real scenario, subjectId would come from the session data or QR payload
      // For mock, we'll assume a placeholder or match it from somewhere
      final subjectId = 'MOCK-SUBJECT';
      final teacherId = 'teacher-1'; // Mock teacher

      await ApiService.markAttendance(
        lectureId: lectureId,
        studentId: widget.studentCode,
        name: widget.studentName,
        department: widget.department,
        level: widget.level,
        status: widget.studentStatus,
        levelId: activeLevelId,
        subjectId: subjectId,
        teacherId: teacherId,
      );

      messenger.showSnackBar(
        SnackBar(
          content: Text('تم تسجيل الحضور بنجاح', style: GoogleFonts.cairo()),
          backgroundColor: AppColors.cardGreenIcon,
        ),
      );
      nav.pop();
    } catch (_) {
      messenger.showSnackBar(
        SnackBar(
          content: Text('خطأ في الاتصال بالخادم', style: GoogleFonts.cairo()),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.appBackground,
      appBar: AppBar(
        backgroundColor: context.appSurface,
        elevation: 0,
        centerTitle: true,
        title: Text(
          'مسح رمز الحضور',
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
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header Text
            Text(
              'وجه الكاميرا نحو رمز QR المعروض في القاعة للتسجيل حضورك',
              style: GoogleFonts.cairo(
                fontSize: 14,
                color: context.appTextLight,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),

            // Camera Area / Permission Request
            Container(
              height: 300,
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: context.appBorder),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(
                      alpha: context.isDarkMode ? 0.18 : 0.03,
                    ),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Stack(
                  children: [
                    if (_isCameraPermissionGranted)
                      MobileScanner(
                        controller: _cameraController,
                        onDetect: (capture) {
                          final List<Barcode> barcodes = capture.barcodes;
                          for (final barcode in barcodes) {
                            if (barcode.rawValue != null) {
                              _handleAttendance(barcode.rawValue!);
                              _cameraController
                                  .stop(); // Stop scanning after success
                              break;
                            }
                          }
                        },
                      )
                    else
                      Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              LucideIcons.scanLine,
                              size: 48,
                              color: Colors.grey[400],
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton.icon(
                              onPressed: () {
                                setState(() {
                                  _isCameraPermissionGranted = true;
                                });
                              },
                              icon: const Icon(LucideIcons.camera, size: 18),
                              label: Text(
                                'السماح باستخدام الكاميرا',
                                style: GoogleFonts.cairo(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 24,
                                  vertical: 12,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                    // Overlay Guide
                    if (_isCameraPermissionGranted)
                      Center(
                        child: Container(
                          width: 200,
                          height: 200,
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: AppColors.primary,
                              width: 2,
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 32),

            // Manual Entry Section
            Text(
              'أو أدخل رمز الجلسة يدوياً',
              style: GoogleFonts.cairo(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: context.appText,
              ),
              textAlign: TextAlign.center,
            ),
            Text(
              'في حالة تعذر مسح الرمز، اطلب رمز الجلسة من المحاضر',
              style: GoogleFonts.cairo(
                fontSize: 12,
                color: context.appTextLight,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),

            Row(
              children: [
                // Register Button
                ElevatedButton(
                  onPressed: () =>
                      _handleAttendance(_codeController.text.trim()),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 16,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    'تسجيل',
                    style: GoogleFonts.cairo(fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(width: 12),
                // Input Field
                Expanded(
                  child: TextField(
                    controller: _codeController,
                    textAlign: TextAlign.right,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      hintText: 'أدخل رمز الجلسة هنا...',
                      hintStyle: GoogleFonts.cairo(color: Colors.grey[400]),
                      filled: true,
                      fillColor: context.appSurface,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey[200]!),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey[200]!),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: AppColors.primary),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 16,
                      ),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 32),

            // Instructions Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFF0F9FF), // Light blue background
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFBAE6FD)),
              ),
              child: Row(
                children: [
                  const Icon(LucideIcons.info, color: Color(0xFF0284C7)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'تأكد من تفعيل خدمة الموقع والكاميرا لضمان تسجيل الحضور بنجاح.',
                      style: GoogleFonts.cairo(
                        fontSize: 12,
                        color: const Color(0xFF0369A1),
                        height: 1.5,
                      ),
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
}
