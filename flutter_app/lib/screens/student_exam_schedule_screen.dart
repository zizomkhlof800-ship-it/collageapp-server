import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'dart:convert';
import 'dart:typed_data';
import '../constants/theme.dart';
import '../services/data_service.dart';
import '../constants/api.dart';
import 'image_viewer_screen.dart';

class StudentExamScheduleScreen extends StatefulWidget {
  final String department;
  final String level;

  const StudentExamScheduleScreen({
    super.key,
    required this.department,
    required this.level,
  });

  @override
  State<StudentExamScheduleScreen> createState() =>
      _StudentExamScheduleScreenState();
}

class _StudentExamScheduleScreenState extends State<StudentExamScheduleScreen> {
  final DataService _dataService = DataService();

  @override
  void initState() {
    super.initState();
    _dataService.addListener(_onDataChanged);
    _dataService.fetchSchedules(
      department: widget.department,
      level: widget.level,
    );
  }

  @override
  void dispose() {
    _dataService.removeListener(_onDataChanged);
    super.dispose();
  }

  void _onDataChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    // Filter schedules for this student's department and level
    final schedules = _dataService.examSchedules
        .where(
          (s) => s.department == widget.department && s.level == widget.level,
        )
        .toList();
    final ScheduleItem? imageItem =
        schedules
            .firstWhere(
              (s) => s.imageUrl.isNotEmpty,
              orElse: () => ScheduleItem(
                subject: '',
                day: '',
                date: '',
                time: '',
                location: '',
                department: '',
                level: '',
                imageUrl: '',
                isExam: true,
                id: '',
              ),
            )
            .imageUrl
            .isNotEmpty
        ? schedules.firstWhere((s) => s.imageUrl.isNotEmpty)
        : null;
    final List<ScheduleItem> nonImageSchedules = imageItem == null
        ? schedules
        : schedules.where((s) => s != imageItem).toList();

    return Scaffold(
      backgroundColor: context.appBackground,
      appBar: AppBar(
        backgroundColor: context.appSurface,
        elevation: 0,
        centerTitle: true,
        title: Text(
          'جدول الامتحانات',
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
            // Department Info Card
            _buildDepartmentInfoCard(),
            const SizedBox(height: 24),

            // Schedule Section
            Text(
              'جدول الامتحانات',
              style: GoogleFonts.cairo(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: context.appText,
              ),
              textAlign: TextAlign.right,
            ),
            const SizedBox(height: 16),
            if (imageItem != null) ...[
              _buildScheduleImageSection(imageItem),
              const SizedBox(height: 16),
            ],

            if (nonImageSchedules.isEmpty)
              _buildSchedulePlaceholder()
            else
              ...nonImageSchedules.map((item) => _buildScheduleItem(item)),
          ],
        ),
      ),
    );
  }

  Widget _buildScheduleItem(ScheduleItem item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.appSurface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(
              alpha: context.isDarkMode ? 0.18 : 0.03,
            ),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  item.date,
                  style: GoogleFonts.cairo(
                    color: Colors.orange,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
              Text(
                item.subject,
                style: GoogleFonts.cairo(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: context.appText,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Text(
                item.time,
                style: GoogleFonts.cairo(color: context.appText, fontSize: 14),
              ),
              const SizedBox(width: 8),
              Icon(LucideIcons.clock, size: 16, color: context.appTextLight),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Text(
                item.location,
                style: GoogleFonts.cairo(color: context.appText, fontSize: 14),
              ),
              const SizedBox(width: 8),
              Icon(LucideIcons.mapPin, size: 16, color: context.appTextLight),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDepartmentInfoCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: context.appSurface,
        borderRadius: BorderRadius.circular(16),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'معلومات القسم',
                    style: GoogleFonts.cairo(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: context.appText,
                    ),
                  ),
                  Text(
                    'بياناتك الأكاديمية المسجلة',
                    style: GoogleFonts.cairo(
                      fontSize: 12,
                      color: context.appTextLight,
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  LucideIcons.graduationCap,
                  color: AppColors.primary,
                  size: 24,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          const Divider(),
          const SizedBox(height: 16),
          _buildInfoRow('الكلية', 'التربية النوعية'),
          const SizedBox(height: 12),
          _buildInfoRow('القسم', widget.department),
          const SizedBox(height: 12),
          _buildInfoRow('الفرقة الدراسية', widget.level),
          const SizedBox(height: 12),
          _buildInfoRow('العام الجامعي', '2025 - 2026'),
        ],
      ),
    );
  }

  Uint8List? _decodeDataUrl(String url) {
    try {
      final part = url.contains('base64,')
          ? url.split('base64,').last
          : url.split(',').last;
      var b64 = part.trim().replaceAll(RegExp(r'\s+'), '');
      final mod = b64.length % 4;
      if (mod != 0) b64 = b64 + '=' * (4 - mod);
      return base64Decode(b64);
    } catch (_) {
      return null;
    }
  }

  Widget _buildImageWidget(String url) {
    if (url.startsWith('data:')) {
      final bytes = _decodeDataUrl(url);
      if (bytes != null) {
        return Image.memory(
          bytes,
          height: 180,
          width: double.infinity,
          fit: BoxFit.cover,
        );
      }
      return Container(
        height: 180,
        alignment: Alignment.center,
        color: Colors.grey[200],
        child: Text(
          'تعذر قراءة الصورة',
          style: GoogleFonts.cairo(color: Colors.grey[600]),
        ),
      );
    }
    final u = url.startsWith('http') ? url : '$baseUrl$url';
    return Image.network(
      u,
      height: 180,
      width: double.infinity,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) => Container(
        height: 180,
        alignment: Alignment.center,
        color: Colors.grey[200],
        child: Text(
          'تعذر تحميل الصورة',
          style: GoogleFonts.cairo(color: Colors.grey[600]),
        ),
      ),
    );
  }

  Widget _buildImageWidgetContain(String url) {
    if (url.startsWith('data:')) {
      final bytes = _decodeDataUrl(url);
      if (bytes != null) {
        return Image.memory(
          bytes,
          height: 280,
          width: double.infinity,
          fit: BoxFit.contain,
        );
      }
      return Container(
        height: 280,
        alignment: Alignment.center,
        color: Colors.grey[200],
        child: Text(
          'تعذر قراءة الصورة',
          style: GoogleFonts.cairo(color: Colors.grey[600]),
        ),
      );
    }
    final u = url.startsWith('http') ? url : '$baseUrl$url';
    return Image.network(
      u,
      height: 280,
      width: double.infinity,
      fit: BoxFit.contain,
      errorBuilder: (context, error, stackTrace) => Container(
        height: 280,
        alignment: Alignment.center,
        color: Colors.grey[200],
        child: Text(
          'تعذر تحميل الصورة',
          style: GoogleFonts.cairo(color: Colors.grey[600]),
        ),
      ),
    );
  }

  Widget _buildScheduleImageSection(ScheduleItem item) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.appSurface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(
              alpha: context.isDarkMode ? 0.18 : 0.03,
            ),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            'صورة الجدول',
            style: GoogleFonts.cairo(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: context.appText,
            ),
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: GestureDetector(
              onTap: () {
                final img = item.imageUrl;
                if (img.isEmpty) return;
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ImageViewerScreen(
                      imageUrl: img,
                      title: 'صورة جدول الامتحانات',
                    ),
                  ),
                );
              },
              child: _buildImageWidgetContain(item.imageUrl),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          value,
          style: GoogleFonts.cairo(
            color: context.appText,
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
        Text(
          label,
          style: GoogleFonts.cairo(color: context.appTextLight, fontSize: 14),
        ),
      ],
    );
  }

  Widget _buildSchedulePlaceholder() {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: context.appSurface,
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
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.orange.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              LucideIcons.fileClock,
              size: 48,
              color: Colors.orange,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'جدول الامتحانات',
            style: GoogleFonts.cairo(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: context.appText,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'لم يتم إعلان جدول الامتحانات بعد',
            textAlign: TextAlign.center,
            style: GoogleFonts.cairo(
              fontSize: 14,
              color: context.appTextLight,
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }
}
