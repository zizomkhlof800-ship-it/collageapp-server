import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../constants/api.dart';

class CloudinaryService {
  static bool get isConfigured =>
      cloudinaryCloudName.isNotEmpty && cloudinaryUploadPreset.isNotEmpty;

  static Future<String?> uploadFile({
    required Uint8List fileBytes,
    required String fileName,
    String folder = cloudinaryFolder,
  }) async {
    if (isConfigured && fileBytes.isNotEmpty) {
      try {
        final uri = Uri.https(
          'api.cloudinary.com',
          '/v1_1/$cloudinaryCloudName/auto/upload',
        );
        final request = http.MultipartRequest('POST', uri)
          ..fields['upload_preset'] = cloudinaryUploadPreset
          ..fields['folder'] = folder
          ..files.add(
            http.MultipartFile.fromBytes('file', fileBytes, filename: fileName),
          );
        final response = await request.send().timeout(
          const Duration(seconds: 30),
        );
        final body = await response.stream.bytesToString();
        if (response.statusCode >= 200 && response.statusCode < 300) {
          final decoded = jsonDecode(body);
          final secureUrl = (decoded['secure_url'] ?? decoded['url'] ?? '')
              .toString();
          if (secureUrl.isNotEmpty) return secureUrl;
        }
        debugPrint('Cloudinary upload failed: ${response.statusCode} $body');
      } catch (error) {
        debugPrint('Cloudinary upload failed: $error');
      }
    }

    return 'data:${_mimeForFile(fileName)};base64,${base64Encode(fileBytes)}';
  }

  static Future<String?> uploadBase64({
    required String base64Value,
    required String fileName,
    String folder = cloudinaryFolder,
  }) async {
    final raw = base64Value.trim();
    if (raw.isEmpty) return null;
    final commaIndex = raw.indexOf(',');
    final payload = commaIndex == -1 ? raw : raw.substring(commaIndex + 1);
    try {
      return uploadFile(
        fileBytes: base64Decode(payload),
        fileName: fileName,
        folder: folder,
      );
    } catch (error) {
      debugPrint('Cloudinary base64 decode failed: $error');
      return raw;
    }
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
