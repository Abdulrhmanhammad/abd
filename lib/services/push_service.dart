import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// معالج الإشعارات في الخلفية (يجب أن يكون دالة علوية).
@pragma('vm:entry-point')
Future<void> _backgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  // النظام يعرض الإشعار تلقائياً في الخلفية؛ لا حاجة لإجراء إضافي هنا.
}

/// خدمة إشعارات Push عبر Firebase + الإشعارات المحلية.
///
/// مصمّمة لتعمل بأمان حتى لو لم يُهيّأ Firebase بعد (try/catch)،
/// فلا يتعطّل التطبيق قبل إضافة ملفات الإعداد.
class PushService {
  PushService._();

  static const String _topic = 'all';
  static const String _prefKey = 'notifications_enabled';

  static final FlutterLocalNotificationsPlugin _local =
      FlutterLocalNotificationsPlugin();

  static const AndroidNotificationChannel _channel = AndroidNotificationChannel(
    'daleelak_default',
    'إشعارات دليلك',
    description: 'الإشعارات العامة من تطبيق دليلك',
    importance: Importance.high,
  );

  static bool _ready = false;

  /// تهيئة الإشعارات. تُستدعى مرة واحدة عند الإقلاع.
  static Future<void> init() async {
    try {
      await Firebase.initializeApp();
      FirebaseMessaging.onBackgroundMessage(_backgroundHandler);

      // قناة أندرويد
      await _local
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(_channel);

      const init = InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        iOS: DarwinInitializationSettings(),
      );
      await _local.initialize(init);

      // عرض الإشعار والتطبيق في المقدّمة
      FirebaseMessaging.onMessage.listen(_showLocal);

      _ready = true;

      // إن سبق للمستخدم تفعيل الإشعارات، أعد الاشتراك
      final prefs = await SharedPreferences.getInstance();
      if (prefs.getBool(_prefKey) ?? false) {
        await enable();
      }
    } catch (e) {
      debugPrint('PushService.init: لم يُهيّأ Firebase بعد ($e)');
    }
  }

  static Future<void> _showLocal(RemoteMessage message) async {
    final n = message.notification;
    if (n == null) return;
    await _local.show(
      n.hashCode,
      n.title,
      n.body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          _channel.id,
          _channel.name,
          channelDescription: _channel.description,
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: const DarwinNotificationDetails(),
      ),
    );
  }

  /// هل الإشعارات مفعّلة (حسب تفضيل المستخدم المخزّن)؟
  static Future<bool> isEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_prefKey) ?? false;
  }

  /// تفعيل الإشعارات: طلب الإذن + الاشتراك بالموضوع العام.
  static Future<bool> enable() async {
    try {
      final settings = await FirebaseMessaging.instance.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );
      final granted = settings.authorizationStatus ==
              AuthorizationStatus.authorized ||
          settings.authorizationStatus == AuthorizationStatus.provisional;
      if (granted && _ready) {
        await FirebaseMessaging.instance.subscribeToTopic(_topic);
      }
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_prefKey, granted);
      return granted;
    } catch (e) {
      debugPrint('PushService.enable: $e');
      return false;
    }
  }

  /// إيقاف الإشعارات.
  static Future<void> disable() async {
    try {
      if (_ready) {
        await FirebaseMessaging.instance.unsubscribeFromTopic(_topic);
      }
    } catch (_) {}
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefKey, false);
  }
}
