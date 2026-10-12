import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'backend.dart';

final _plugin = FlutterLocalNotificationsPlugin();

Future<void> initLocalNotif() async {
  const init = InitializationSettings(
    android: AndroidInitializationSettings('@mipmap/ic_launcher'),
    iOS: DarwinInitializationSettings(),
  );
  await _plugin.initialize(init);
}

/// Loud local push: SOS nearby, new order (works minimized), crash, verify.
Future<void> loudPush(WidgetRef ref, String title, String body) async {
  ref.read(notifProvider.notifier).push(title, body);
  try {
    await _plugin.show(
      DateTime.now().millisecond,
      title,
      body,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'ym_high',
          'YoldashMoto alerts',
          importance: Importance.max,
          priority: Priority.high,
          playSound: true,
          enableVibration: true,
        ),
      ),
    );
  } catch (_) {}
}
