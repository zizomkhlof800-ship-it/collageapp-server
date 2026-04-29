import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';

class PDFViewerScreen extends StatelessWidget {
  final String title;
  final String? url;
  final String? filePath;

  const PDFViewerScreen({
    super.key,
    required this.title,
    this.url,
    this.filePath,
  });

  bool get _hasDataUrl =>
      (url ?? '').startsWith('data:application/pdf;base64,');

  Uint8List _decodePdfDataUrl() {
    return base64Decode(url!.split(',').last);
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            title,
            style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          actions: [
            if (url != null)
              IconButton(
                icon: const Icon(LucideIcons.download),
                onPressed: () {
                  // Simulate download
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'بدء تحميل الملف...',
                        style: GoogleFonts.cairo(),
                      ),
                    ),
                  );
                },
              ),
          ],
        ),
        body: _hasDataUrl
            ? SfPdfViewer.memory(_decodePdfDataUrl())
            : url != null
            ? SfPdfViewer.network(url!)
            : filePath != null
            ? SfPdfViewer.asset(
                filePath!,
              ) // or SfPdfViewer.file if using local file
            : const Center(child: Text('لا يوجد ملف لعرضه')),
      ),
    );
  }
}
