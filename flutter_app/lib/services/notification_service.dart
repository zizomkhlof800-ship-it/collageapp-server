import 'dart:convert';

import 'package:flutter/foundation.dart';

class NotificationService {
  static String sanitizeTopic(String topic) {
    if (topic.isEmpty) return 'global';
    return base64Url.encode(utf8.encode(topic)).replaceAll('=', '');
  }

  static Future<void> initialize() async {
    if (kDebugMode) {
      debugPrint('Offline notifications initialized');
    }
  }

  static Future<void> sendPushNotification({
    required String title,
    required String body,
    required String levelId,
  }) async {
    if (kDebugMode) {
      debugPrint('Offline notification: [$levelId] $title - $body');
    }
  }
}
