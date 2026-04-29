import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../constants/theme.dart';

class LiveLectureScreen extends StatelessWidget {
  final String channelName;
  final String userName;
  final bool isTeacher;
  final String? levelId;
  final String? subjectId;

  const LiveLectureScreen({
    super.key,
    required this.channelName,
    required this.userName,
    required this.isTeacher,
    this.levelId,
    this.subjectId,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        appBar: AppBar(
          title: Text(
            channelName,
            style: GoogleFonts.cairo(fontWeight: FontWeight.bold),
          ),
          leading: IconButton(
            icon: const Icon(LucideIcons.arrowRight),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 88,
                  height: 88,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    LucideIcons.wifiOff,
                    size: 42,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'المحاضرات المباشرة غير متاحة في وضع الأوفلاين',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.cairo(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'تم تعطيل خدمة البث السحابي. باقي بيانات التطبيق تعمل محليا على الجهاز.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.cairo(
                    fontSize: 14,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
