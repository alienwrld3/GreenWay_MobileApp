import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'login_screen.dart';
import '../config/app_config.dart';
import '../helpers/notification_helper.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> with TickerProviderStateMixin {
  final _fullNameController    = TextEditingController();
  final _usernameController    = TextEditingController();
  final _emailController       = TextEditingController();
  final _passwordController    = TextEditingController();
  final _confirmPassController = TextEditingController();

  bool _isLoading       = false;
  bool _obscurePassword = true;
  bool _obscureConfirm  = true;

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
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    _fullNameController.dispose();
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPassController.dispose();
    super.dispose();
  }

  String? _validate() {
    final fullName = _fullNameController.text.trim();
    final username = _usernameController.text.trim();
    final email    = _emailController.text.trim();
    final password = _passwordController.text;
    final confirm  = _confirmPassController.text;

    if (fullName.isEmpty || username.isEmpty || email.isEmpty || password.isEmpty || confirm.isEmpty) {
      return 'Semua field wajib diisi!';
    }
    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w]{2,4}$').hasMatch(email)) {
      return 'Format email tidak valid!';
    }
    if (password.length < 6) return 'Password minimal 6 karakter!';
    if (password != confirm) return 'Password dan konfirmasi tidak cocok!';
    return null;
  }

  Future<void> _register() async {
    final error = _validate();
    if (error != null) { _showSnackBar(error); return; }

    setState(() => _isLoading = true);
    try {
      final fullName = _fullNameController.text.trim();
      final response = await http.post(
        AppConfig.apiUri('/register'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'full_name': fullName,
          'username' : _usernameController.text.trim(),
          'email'    : _emailController.text.trim(),
          'password' : _passwordController.text,
        }),
      ).timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        // ── Notifikasi Register Berhasil ──
        await NotificationHelper.showRegisterNotif(fullName);
        _showSuccessDialog(fullName);
      } else {
        final msg = jsonDecode(response.body)['message'] ?? 'Registrasi gagal.';
        _showSnackBar(msg);
      }
    } catch (e) {
      _showSnackBar('Kesalahan Koneksi: Pastikan server aktif.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showSuccessDialog(String fullName) {
    showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black87,
      builder: (ctx) => Dialog(
        backgroundColor: const Color(0xFF0D2B18),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(28),
          side: BorderSide(color: const Color(0xFF2D6A4F).withOpacity(0.4)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Container(
              width: 72, height: 72,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                  colors: [Color(0xFF52B788), Color(0xFF2D6A4F)],
                  begin: Alignment.topLeft, end: Alignment.bottomRight,
                ),
                boxShadow: [BoxShadow(color: const Color(0xFF52B788).withOpacity(0.4), blurRadius: 20, spreadRadius: 2)],
              ),
              child: const Icon(Icons.check_rounded, color: Colors.white, size: 38),
            ),
            const SizedBox(height: 20),
            const Text('Registrasi Berhasil!',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: Colors.white)),
            const SizedBox(height: 8),
            Text('Halo $fullName, akunmu sudah siap.\nSilakan login untuk melanjutkan.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 13, height: 1.5)),
            const SizedBox(height: 28),
            SizedBox(
              width: double.infinity, height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF52B788), foregroundColor: Colors.white,
                  elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                onPressed: () {
                  Navigator.pop(ctx);
                  Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const LoginScreen()));
                },
                child: const Text('MASUK SEKARANG',
                  style: TextStyle(fontWeight: FontWeight.w700, letterSpacing: 1.2, fontSize: 14)),
              ),
            ),
          ]),
        ),
      ),
    );
  }

  void _showSnackBar(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: const Color(0xFF1B4332),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ));
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
                  padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    // Back button
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0D2B18),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFF2D6A4F).withOpacity(0.4)),
                        ),
                        child: const Icon(Icons.arrow_back_ios_new_rounded, color: Color(0xFF52B788), size: 18),
                      ),
                    ),
                    const SizedBox(height: 28),
                    // Logo & Title
                    Center(child: Column(children: [
                      Container(
                        width: 70, height: 70,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(22),
                          gradient: const LinearGradient(
                            colors: [Color(0xFF52B788), Color(0xFF2D6A4F)],
                            begin: Alignment.topLeft, end: Alignment.bottomRight,
                          ),
                          boxShadow: [BoxShadow(color: const Color(0xFF52B788).withOpacity(0.35), blurRadius: 18, spreadRadius: 2)],
                        ),
                        child: const Icon(Icons.eco_rounded, color: Colors.white, size: 38),
                      ),
                      const SizedBox(height: 16),
                      const Text('Buat Akun',
                        style: TextStyle(fontSize: 30, fontWeight: FontWeight.w800, color: Colors.white, letterSpacing: -0.5)),
                      const SizedBox(height: 6),
                      Text('Bergabung dan mulai jejak hijaumu',
                        style: TextStyle(fontSize: 13, color: Colors.white.withOpacity(0.45))),
                    ])),
                    const SizedBox(height: 36),
                    // Form Card
                    Container(
                      padding: const EdgeInsets.all(28),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0D2B18),
                        borderRadius: BorderRadius.circular(28),
                        border: Border.all(color: const Color(0xFF2D6A4F).withOpacity(0.4)),
                      ),
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        const Text('Data Diri',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white)),
                        Text('Lengkapi informasi akunmu',
                          style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 12)),
                        const SizedBox(height: 20),
                        _buildField(controller: _fullNameController, hint: 'Nama Lengkap', icon: Icons.badge_outlined),
                        const SizedBox(height: 14),
                        _buildField(controller: _usernameController, hint: 'Username', icon: Icons.person_outline_rounded),
                        const SizedBox(height: 14),
                        _buildField(controller: _emailController, hint: 'Email', icon: Icons.email_outlined,
                          keyboardType: TextInputType.emailAddress),
                        const SizedBox(height: 24),
                        const Text('Keamanan',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white)),
                        Text('Buat password yang kuat',
                          style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 12)),
                        const SizedBox(height: 16),
                        _buildField(
                          controller: _passwordController, hint: 'Password', icon: Icons.lock_outline_rounded,
                          obscure: _obscurePassword,
                          suffix: IconButton(
                            icon: Icon(_obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                              color: Colors.white38, size: 20),
                            onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                          ),
                        ),
                        const SizedBox(height: 14),
                        _buildField(
                          controller: _confirmPassController, hint: 'Konfirmasi Password', icon: Icons.lock_person_outlined,
                          obscure: _obscureConfirm,
                          suffix: IconButton(
                            icon: Icon(_obscureConfirm ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                              color: Colors.white38, size: 20),
                            onPressed: () => setState(() => _obscureConfirm = !_obscureConfirm),
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
                                  onPressed: _register,
                                  child: const Text('DAFTAR SEKARANG',
                                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, letterSpacing: 1.5)),
                                ),
                              ),
                      ]),
                    ),
                    const SizedBox(height: 28),
                    // Link ke Login
                    Center(
                      child: GestureDetector(
                        onTap: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const LoginScreen())),
                        child: RichText(text: TextSpan(children: [
                          TextSpan(text: 'Sudah punya akun? ',
                            style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 14)),
                          const TextSpan(text: 'Masuk',
                            style: TextStyle(color: Color(0xFF52B788), fontSize: 14, fontWeight: FontWeight.w700)),
                        ])),
                      ),
                    ),
                    const SizedBox(height: 16),
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
    TextInputType? keyboardType,
  }) {
    return TextField(
      controller: controller,
      obscureText: obscure,
      keyboardType: keyboardType,
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
