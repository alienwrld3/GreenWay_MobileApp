import 'package:flutter/material.dart';
import 'screens/login_screen.dart';
import 'screens/home_screen.dart';
import 'helpers/db_helper.dart';
import 'helpers/notification_helper.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Cek apakah ada TOKEN aktif (bukan sekadar session/record)
  final hasToken = await DatabaseHelper.instance.hasActiveToken();

  await NotificationHelper.init();

  runApp(MaterialApp(
    debugShowCheckedModeBanner: false,
    // Jika token aktif → HomeScreen, jika tidak → LoginScreen
    home: hasToken ? const HomeScreen() : const LoginScreen(),
  ));
}