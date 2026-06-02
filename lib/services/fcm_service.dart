import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'api_service.dart';
import 'notification_service.dart';

class FcmService {
  static final _messaging = FirebaseMessaging.instance;
  static bool _initialized = false;

  static Future<void> init() async {
    if (_initialized) return;
    await Firebase.initializeApp();

    await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    final tok = await _messaging.getToken();
    await _saveToken(tok);

    _messaging.onTokenRefresh.listen(_saveToken);

    FirebaseMessaging.onMessage.listen(_onForegroundMessage);

    FirebaseMessaging.onBackgroundMessage(_onBackgroundMessage);

    _initialized = true;
  }

  static Future<String?> get token => _messaging.getToken();

  static Future<void> registerCurrentToken() async {
    final tok = await _messaging.getToken();
    await _saveToken(tok);
  }

  static Future<void> _saveToken(String? tok) async {
    if (tok == null) return;
    debugPrint('FCM token: $tok');
    if (!ApiService().isLoggedIn) return;
    try {
      await ApiService().post('/api/notifications/register', {'token': tok});
    } catch (_) {}
  }

  static Future<void> _onForegroundMessage(RemoteMessage msg) async {
    final data = msg.data;
    final title =
        msg.notification?.title ?? (data['title'] as String? ?? '');
    final body =
        msg.notification?.body ?? (data['body'] as String? ?? '');

    if (title.isEmpty && body.isEmpty) return;

    await NotificationService.show(
      id: DateTime.now().millisecondsSinceEpoch.remainder(1 << 31),
      title: title,
      body: body,
    );
  }

  @pragma('vm:entry-point')
  static Future<void> _onBackgroundMessage(RemoteMessage msg) async {
    debugPrint('Background FCM: ${msg.messageId}');
  }
}
