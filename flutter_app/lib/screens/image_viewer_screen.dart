import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:url_launcher/url_launcher.dart';

import '../constants/api.dart';
import '../constants/theme.dart';

class ImageViewerScreen extends StatelessWidget {
  final String imageUrl;
  final String title;

  const ImageViewerScreen({super.key, required this.imageUrl, this.title = ''});

  String _resolve(String value) =>
      value.startsWith('http') ? value : '$baseUrl$value';

  Widget _buildImage(String resolved) {
    if (resolved.startsWith('data:image/')) {
      return Image.memory(
        base64Decode(resolved.split(',').last),
        fit: BoxFit.contain,
      );
    }

    return Image.network(
      resolved,
      fit: BoxFit.contain,
      errorBuilder: (context, _, __) => Container(
        alignment: Alignment.center,
        padding: const EdgeInsets.all(24),
        child: Text(
          'تعذر تحميل الصورة',
          style: GoogleFonts.cairo(color: AppColors.textLight),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final resolved = _resolve(imageUrl);
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          backgroundColor: Colors.black,
          iconTheme: const IconThemeData(color: Colors.white),
          title: Text(
            title.isEmpty ? 'عرض الصورة' : title,
            style: GoogleFonts.cairo(color: Colors.white),
          ),
          actions: [
            if (!resolved.startsWith('data:'))
              IconButton(
                tooltip: 'تحميل',
                icon: const Icon(LucideIcons.download, color: Colors.white),
                onPressed: () async {
                  final uri = Uri.parse(resolved);
                  if (await canLaunchUrl(uri)) {
                    await launchUrl(uri, mode: LaunchMode.externalApplication);
                  }
                },
              ),
          ],
        ),
        body: Center(
          child: InteractiveViewer(
            minScale: 0.5,
            maxScale: 4,
            child: _buildImage(resolved),
          ),
        ),
      ),
    );
  }
}
