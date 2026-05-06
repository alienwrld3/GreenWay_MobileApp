import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:local_auth/local_auth.dart';
import 'home_screen.dart';
import 'register_screen.dart';
import '../helpers/db_helper.dart';
import '../helpers/notification_helper.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> with TickerProviderStateMixin {
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final LocalAuthentication _auth = LocalAuthentication();

  bool _isLoading         = false;
  bool _obscurePassword   = true;
  bool _fingerprintEnabled = false; // apakah user sudah daftarkan fingerprint

  late AnimationController _fadeController;
  late Animation<double>   _fadeAnimation;
  late AnimationController _slideController;
  late Animation<Offset>   _slideAnimation;

  @override
  void initState() {
    super.initState();
    _fadeController  = AnimationController(vsync: this, duration: const Duration(milliseconds: 900));
    _fadeAnimation   = CurvedAnimation(parent: _fadeController, curve: Curves.easeOut);
    _slideController = AnimationController(vsync: this, duration: const Duration(milliseconds: 800));
    _slideAnimation  = Tween<Offset>(begin: const Offset(0, 0.08), end: Offset.zero)
        .animate(CurvedAnimation(parent: _slideController, curve: Curves.easeOutCubic));
    _fadeController.forward();
    _slideController.forward();
    _checkFingerprintFlag();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // Cek apakah user sudah daftarkan fingerprint sebelumnya
  Future<void> _checkFingerprintFlag() async {
    final enabled = await DatabaseHelper.instance.isFingerprintEnabled();
    if (mounted) setState(() => _fingerprintEnabled = enabled);
  }

  // ── Login Manual ──────────────────────────────────────────────────────────
  Future<void> _loginManual() async {
    final username = _usernameController.text.trim();
    final password = _passwordController.text.trim();
    if (username.isEmpty || password.isEmpty) {
      _showSnackBar('Username dan password wajib diisi!');
      return;
    }
    await _performLogin(username, password);
  }

  // ── Login Fingerprint ─────────────────────────────────────────────────────
  // Bisa dipakai langsung tanpa harus manual dulu (asalkan sudah terdaftar)
  Future<void> _loginWithBiometric() async {
    try {
      final bool canCheck  = await _auth.canCheckBiometrics;
      final bool supported = canCheck || await _auth.isDeviceSupported();
      if (!supported) { _showSnackBar('Perangkat tidak mendukung biometrik'); return; }

      final bool ok = await _auth.authenticate(
        localizedReason: 'Pindai sidik jari untuk masuk ke GreenWay',
        options: const AuthenticationOptions(biometricOnly: true),
      );

      if (!ok) return;

      // Fingerprint berhasil → ambil data tersimpan dan navigasi ke Home
      final session = await DatabaseHelper.instance.getActiveSession();
      if (session != null && session['username'] != '') {
        // Buat token sementara atau panggil ulang login ke server jika diperlukan
        // Untuk sekarang: langsung navigasi (token sudah tersimpan dari login terakhir)
        await NotificationHelper.showLoginNotif(session['full_name'] ?? 'User');
        _navigateToHome();
      } else {
        _showSnackBar('Data tidak ditemukan. Silakan login manual terlebih dahulu.');
      }
    } catch (e) {
      _showSnackBar('Error Biometrik: $e');
    }
  }

  Future<void> _performLogin(String username, String password) async {
    setState(() => _isLoading = true);
    try {
      final response = await http.post(
        Uri.parse('http://192.168.1.24:3000/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'username': username, 'password': password}),
      ).timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final data     = jsonDecode(response.body);
        final fullName = data['user']['name'] as String;
        await DatabaseHelper.instance.saveSession(username, fullName, data['token']);
        await NotificationHelper.showLoginNotif(fullName);
        _navigateToHome();
      } else {
        _showSnackBar('Login Gagal: ${jsonDecode(response.body)['message']}');
      }
    } catch (e) {
      _showSnackBar('Kesalahan Koneksi: Pastikan server aktif.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showSnackBar(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: const Color(0xFF1B4332),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ));
  }

  void _navigateToHome() {
    if (mounted) Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const HomeScreen()));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF081C0E),
      body: Stack(
        children: [
          Positioned(top: -80, right: -80,
            child: Container(width: 280, height: 280,
              decoration: BoxDecoration(shape: BoxShape.circle, color: const Color(0xFF1B4332).withOpacity(0.5)))),
          Positioned(bottom: -60, left: -60,
            child: Container(width: 220, height: 220,
              decoration: BoxDecoration(shape: BoxShape.circle, color: const Color(0xFF2D6A4F).withOpacity(0.3)))),
          SafeArea(
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: SlideTransition(
                position: _slideAnimation,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 40),
                  child: Column(children: [
                    const SizedBox(height: 40),
                    // ── Logo ──
                    Container(
                      width: 80, height: 80,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(24),
                        gradient: const LinearGradient(
                          colors: [Color(0xFF52B788), Color(0xFF2D6A4F)],
                          begin: Alignment.topLeft, end: Alignment.bottomRight,
                        ),
                        boxShadow: [BoxShadow(color: const Color(0xFF52B788).withOpacity(0.4), blurRadius: 20, spreadRadius: 2)],
                      ),
                      child: const Icon(Icons.eco_rounded, color: Colors.white, size: 44),
                    ),
                    const SizedBox(height: 20),
                    const Text('GreenWay',
                      style: TextStyle(fontSize: 36, fontWeight: FontWeight.w800, color: Colors.white, letterSpacing: -0.5)),
                    const SizedBox(height: 6),
                    Text('Jejak hijau dimulai dari sini',
                      style: TextStyle(fontSize: 14, color: Colors.white.withOpacity(0.5))),
                    const SizedBox(height: 56),

                    // ── Form Card ──
                    Container(
                      padding: const EdgeInsets.all(28),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0D2B18),
                        borderRadius: BorderRadius.circular(28),
                        border: Border.all(color: const Color(0xFF2D6A4F).withOpacity(0.4)),
                      ),
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        const Text('Masuk',
                          style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: Colors.white)),
                        const SizedBox(height: 6),
                        Text('Selamat datang kembali!',
                          style: TextStyle(color: Colors.white.withOpacity(0.45), fontSize: 13)),
                        const SizedBox(height: 28),
                        _buildField(controller: _usernameController, hint: 'Username', icon: Icons.person_outline_rounded),
                        const SizedBox(height: 16),
                        _buildField(
                          controller: _passwordController, hint: 'Password',
                          icon: Icons.lock_outline_rounded, obscure: _obscurePassword,
                          suffix: IconButton(
                            icon: Icon(_obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                              color: Colors.white38, size: 20),
                            onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                          ),
                        ),
                        const SizedBox(height: 28),
                        _isLoading
                            ? const Center(child: CircularProgressIndicator(color: Color(0xFF52B788)))
                            : SizedBox(
                                width: double.infinity, height: 52,
                                child: ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF52B788), foregroundColor: Colors.white,
                                    elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                  ),
                                  onPressed: _loginManual,
                                  child: const Text('MASUK',
                                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, letterSpacing: 1.5)),
                                ),
                              ),
                      ]),
                    ),
                    const SizedBox(height: 32),

                    // ── Fingerprint (hanya tampil jika sudah terdaftar) ──
                    if (_fingerprintEnabled) ...[
                      Text('atau masuk dengan',
                        style: TextStyle(color: Colors.white.withOpacity(0.35), fontSize: 13)),
                      const SizedBox(height: 16),
                      GestureDetector(
                        onTap: _loginWithBiometric,
                        child: Container(
                          padding: const EdgeInsets.all(18),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: const Color(0xFF0D2B18),
                            border: Border.all(color: const Color(0xFF2D6A4F).withOpacity(0.5)),
                            boxShadow: [BoxShadow(color: const Color(0xFF52B788).withOpacity(0.2), blurRadius: 20)],
                          ),
                          child: const Icon(Icons.fingerprint_rounded, size: 48, color: Color(0xFF52B788)),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text('Sidik Jari',
                        style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 12)),
                      const SizedBox(height: 24),
                    ] else
                      const SizedBox(height: 8),

                    // ── Link Register ──
                    GestureDetector(
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const RegisterScreen())),
                      child: RichText(text: TextSpan(children: [
                        TextSpan(text: 'Belum punya akun? ',
                          style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 14)),
                        const TextSpan(text: 'Daftar',
                          style: TextStyle(color: Color(0xFF52B788), fontSize: 14, fontWeight: FontWeight.w700)),
                      ])),
                    ),
                  ]),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    bool obscure = false,
    Widget? suffix,
  }) {
    return TextField(
      controller: controller,
      obscureText: obscure,
      style: const TextStyle(color: Colors.white, fontSize: 15),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: Colors.white.withOpacity(0.3), fontSize: 15),
        prefixIcon: Icon(icon, color: const Color(0xFF52B788), size: 20),
        suffixIcon: suffix,
        filled: true, fillColor: const Color(0xFF081C0E),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: const Color(0xFF2D6A4F).withOpacity(0.3))),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: const Color(0xFF2D6A4F).withOpacity(0.3))),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFF52B788), width: 1.5)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
    );
  }
}