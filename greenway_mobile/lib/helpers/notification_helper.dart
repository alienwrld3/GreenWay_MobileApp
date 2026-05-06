import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class NotificationHelper {
  static final _notif = FlutterLocalNotificationsPlugin();

  // ── Preference Keys ───────────────────────────────────────────────────────
  static const keyAuth      = 'notif_auth';      // login / register / logout
  static const keyEvent     = 'notif_event';     // quiz selesai, scan selesai
  static const keyPedometer = 'notif_pedometer'; // pengingat langkah kaki
  static const keyDaily     = 'notif_daily';     // harian jam 08.00

  // ── Init ──────────────────────────────────────────────────────────────────
  static Future<void> init() async {
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    await _notif.initialize(const InitializationSettings(android: android));
    tz.initializeTimeZones();
  }

  // ── Preferences helpers ───────────────────────────────────────────────────
  static Future<bool> isEnabled(String key) async {
    final p = await SharedPreferences.getInstance();
    return p.getBool(key) ?? true; // default ON
  }

  static Future<void> setEnabled(String key, bool val) async {
    final p = await SharedPreferences.getInstance();
    await p.setBool(key, val);
  }

  // ── Notification Details ──────────────────────────────────────────────────
  static NotificationDetails _details(String channelId, String channelName,
      {Importance importance = Importance.high}) {
    return NotificationDetails(
      android: AndroidNotificationDetails(
        channelId, channelName,
        importance: importance,
        priority: Priority.high,
        icon: '@mipmap/ic_launcher',
      ),
    );
  }

  // ── AUTH: Login ───────────────────────────────────────────────────────────
  static Future<void> showLoginNotif(String name) async {
    if (!await isEnabled(keyAuth)) return;
    await _notif.show(
      10,
      'Selamat datang kembali, $name! 👋',
      'Kamu berhasil masuk ke GreenWay. Yuk mulai jejak hijaumu hari ini!',
      _details('ch_auth', 'Autentikasi'),
    );
  }

  // ── AUTH: Register ────────────────────────────────────────────────────────
  static Future<void> showRegisterNotif(String name) async {
    if (!await isEnabled(keyAuth)) return;
    await _notif.show(
      11,
      'Akun berhasil dibuat! 🌱',
      'Halo $name, selamat bergabung di GreenWay. Mari jaga bumi bersama!',
      _details('ch_auth', 'Autentikasi'),
    );
  }

  // ── AUTH: Logout ──────────────────────────────────────────────────────────
  static Future<void> showLogoutNotif(String name) async {
    if (!await isEnabled(keyAuth)) return;
    await _notif.show(
      12,
      'Sampai jumpa, $name! 🌿',
      'Kamu telah keluar dari GreenWay. Jangan lupa buang sampah pada tempatnya ya!',
      _details('ch_auth', 'Autentikasi'),
    );
  }

  // ── EVENT: Quiz / Scan selesai ────────────────────────────────────────────
  static Future<void> showNotification({
    int id = 0,
    String? title,
    String? body,
  }) async {
    if (!await isEnabled(keyEvent)) return;
    await _notif.show(id, title, body, _details('ch_event', 'Event GreenWay'));
  }

  // ── PEDOMETER: Pengingat langkah kaki ────────────────────────────────────
  static Future<void> showPedometerNotif(int steps) async {
    if (!await isEnabled(keyPedometer)) return;
    String title, body;
    if (steps >= 10000) {
      title = 'Luar biasa! 10.000 langkah tercapai 🏆';
      body  = 'Kamu sudah berjalan $steps langkah hari ini. Pahlawan hijau!';
    } else if (steps >= 5000) {
      title = 'Setengah jalan! 5.000 langkah 🚶';
      body  = 'Sudah $steps langkah, terus semangat menuju 10.000!';
    } else {
      title = 'Pengingat langkah kaki 👟';
      body  = 'Baru $steps langkah hari ini. Ayo lebih aktif bergerak!';
    }
    await _notif.show(20, title, body,
        _details('ch_pedometer', 'Langkah Kaki', importance: Importance.defaultImportance));
  }

  // ── DAILY: Terjadwal jam 08.00 ────────────────────────────────────────────
  static Future<void> scheduleDailyNotification() async {
    if (!await isEnabled(keyDaily)) return;
    await _notif.zonedSchedule(
      1,
      'Pagi Hijau! 🌿',
      'Jangan lupa cek langkah kakimu dan buang sampah sesuai jenisnya ya!',
      _nextEightAM(),
      _details('ch_daily', 'Pengingat Harian'),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  static Future<void> cancelDailyNotification() async {
    await _notif.cancel(1);
  }

  static tz.TZDateTime _nextEightAM() {
    final now = tz.TZDateTime.now(tz.local);
    var t = tz.TZDateTime(tz.local, now.year, now.month, now.day, 8);
    if (t.isBefore(now)) t = t.add(const Duration(days: 1));
    return t;
  }
}