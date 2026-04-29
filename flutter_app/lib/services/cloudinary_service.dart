import 'dart:convert';
import 'dart:typed_data';

class CloudinaryService {
  static Future<String?> uploadFile({
    required Uint8List fileBytes,
    required String fileName,
    String folder = 'collage_app',
  }) async {
    return 'data:${_mimeForFile(fileName)};base64,${base64Encode(fileBytes)}';
  }

  static String _mimeForFile(String fileName) {
    final lower = fileName.toLowerCase();
    if (lower.endsWith('.pdf')) return 'application/pdf';
    if (lower.endsWith('.png')) return 'image/png';
    if (lower.endsWith('.jpg') || lower.endsWith('.jpeg')) return 'image/jpeg';
    if (lower.endsWith('.gif')) return 'image/gif';
    if (lower.endsWith('.webp')) return 'image/webp';
    if (lower.endsWith('.mp4')) return 'video/mp4';
    return 'application/octet-stream';
  }
}
