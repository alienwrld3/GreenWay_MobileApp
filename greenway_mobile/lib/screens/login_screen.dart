import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:local_auth/local_auth.dart';
import 'home_screen.dart';
import 'register_screen.dart';
import '../config/app_config.dart';
import '../helpers/db_helper.dart';
import '../helpers/notification_helper.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final LocalAuthentication _auth = LocalAuthentication();
  bool _isLoading = false, _obscurePassword = true, _fingerprintEnabled = false;

  @override
  void initState() {
    super.initState();
    _checkFingerprint(); // Cek status saat pertama buka[cite: 10]
  }

  Future<void> _checkFingerprint() async {
    try {
      final enabled = await DatabaseHelper.instance.isFingerprintEnabled();
      if (mounted) setState(() => _fingerprintEnabled = enabled);
    } catch (_) {
      if (mounted) setState(() => _fingerprintEnabled = false);
    }
  }

  Future<void> _loginWithBiometric() async {
    try {
      bool ok = await _auth.authenticate(
        localizedReason: 'Masuk ke GreenWay dengan Sidik Jari',
        options: const AuthenticationOptions(biometricOnly: true),
      );
      if (ok) {
        final session = await DatabaseHelper.instance.getActiveSession();
        if (session != null && session['username'] != '') {
          await NotificationHelper.showLoginNotif(session['full_name']);
          if (mounted) Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const HomeScreen()));
        } else {
          _showSnackBar('Data akun tidak ditemukan, silakan login manual sekali.');
        }
      }
    } catch (e) {
      _showSnackBar('Biometrik error: $e');
    }
  }

  Future<void> _loginManual() async {
    if (_usernameController.text.isEmpty || _passwordController.text.isEmpty) return;
    setState(() => _isLoading = true);
    try {
      final response = await http.post(
        AppConfig.apiUri('/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'username': _usernameController.text, 'password': _passwordController.text}),
      ).timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        await DatabaseHelper.instance.saveSession(_usernameController.text, data['user']['name'], data['token']);
        await NotificationHelper.showLoginNotif(data['user']['name']);
        if (mounted) Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const HomeScreen()));
      } else {
        _showSnackBar('Login gagal, periksa kembali akun Anda.');
      }
    } catch (e) {
      _showSnackBar('Gagal terhubung ke server.');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showSnackBar(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), backgroundColor: const Color(0xFF122E1C)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF081C0E),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(28),
          child: Column(children: [
            const Icon(Icons.eco_rounded, size: 80, color: Color(0xFF52B788)),
            const SizedBox(height: 10),
            const Text('GreenWay', style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white)),
            const SizedBox(height: 40),
            _buildField(_usernameController, 'Username', Icons.person),
            const SizedBox(height: 16),
            _buildField(_passwordController, 'Password', Icons.lock, obscure: _obscurePassword),
            const SizedBox(height: 32),
            _isLoading 
              ? const CircularProgressIndicator(color: Color(0xFF52B788)) 
              : SizedBox(width: double.infinity, height: 50, child: ElevatedButton(onPressed: _loginManual, style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF52B788)), child: const Text('MASUK'))),
            if (_fingerprintEnabled) ...[
              const SizedBox(height: 24),
              const Text('Atau masuk dengan', style: TextStyle(color: Colors.white38, fontSize: 12)),
              const SizedBox(height: 16),
              IconButton(icon: const Icon(Icons.fingerprint, size: 60, color: Color(0xFF52B788)), onPressed: _loginWithBiometric),
            ],
            const SizedBox(height: 20),
            TextButton(onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const RegisterScreen())), child: const Text('Daftar Akun Baru', style: TextStyle(color: Color(0xFF52B788)))),
          ]),
        ),
      ),
    );
  }

  Widget _buildField(TextEditingController controller, String hint, IconData icon, {bool obscure = false}) {
    return TextField(
      controller: controller, obscureText: obscure,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        hintText: hint, hintStyle: const TextStyle(color: Colors.white24),
        prefixIcon: Icon(icon, color: const Color(0xFF52B788)),
        filled: true, fillColor: const Color(0xFF0D2B18),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
      ),
    );
  }
}
