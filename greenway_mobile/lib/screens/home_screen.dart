import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:local_auth/local_auth.dart';
import '../helpers/db_helper.dart';
import '../helpers/notification_helper.dart';
import 'package:pedometer/pedometer.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'dart:async';
import 'dart:io';
import 'dart:math' as math;
import 'dart:convert';

import 'login_screen.dart';
import 'currency_converter_screen.dart';
import 'timezone_screen.dart';
import 'green_bot_screen.dart';
import 'ai_scan_screen.dart';
import 'game_screen.dart';
import 'eco_hunt_screen.dart'; // Import file game baru

const _bg        = Color(0xFF081C0E);
const _surface   = Color(0xFF0D2B18);
const _card      = Color(0xFF122E1C);
const _accent    = Color(0xFF52B788);
const _accentDim = Color(0xFF2D6A4F);
const _textPrim  = Colors.white;

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  int _selectedIndex = 0;
  late AnimationController _fabPulse;
  late PageController _pageController;

  @override
  void initState() {
    super.initState();
    NotificationHelper.scheduleDailyNotification();
    _fabPulse = AnimationController(vsync: this, duration: const Duration(seconds: 2))
      ..repeat(reverse: true);
    _pageController = PageController(initialPage: 0);
  }

  @override
  void dispose() {
    _fabPulse.dispose();
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _logout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: _surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: BorderSide(color: _accentDim.withOpacity(0.4)),
        ),
        title: const Text('Keluar?', style: TextStyle(color: _textPrim, fontWeight: FontWeight.w700)),
        content: Text('Kamu harus login ulang setelah keluar.',
          style: TextStyle(color: Colors.white.withOpacity(0.6))),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Batal', style: TextStyle(color: Colors.white.withOpacity(0.5))),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent, foregroundColor: Colors.white,
              elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Keluar'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      final session = await DatabaseHelper.instance.getActiveSession();
      final name = session?['full_name'] ?? 'User';
      await DatabaseHelper.instance.deleteSession();
      await NotificationHelper.showLogoutNotif(name);

      if (mounted) {
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const LoginScreen()));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Gagal logout: $e'),
          backgroundColor: Colors.redAccent,
        ));
      }
    }
  }

  void _showAIPicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        margin: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: _surface,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: _accentDim.withOpacity(0.4)),
        ),
        padding: const EdgeInsets.all(28),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2))),
          const SizedBox(height: 20),
          const Text('Fitur AI GreenWay', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: _textPrim)),
          const SizedBox(height: 28),
          Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
            _buildAIAction(Icons.camera_alt_rounded, 'AI Scan', 'Identifikasi Objek', const Color(0xFF023E8A), () {
              Navigator.pop(context);
              Navigator.push(context, MaterialPageRoute(builder: (_) => const AIScanScreen()));
            }),
            _buildAIAction(Icons.psychology_rounded, 'GreenBot', 'Chat Lingkungan', const Color(0xFF6A0572), () {
              Navigator.pop(context);
              Navigator.push(context, MaterialPageRoute(builder: (_) => const GreenBotScreen()));
            }),
          ]),
          const SizedBox(height: 8),
        ]),
      ),
    );
  }

  Widget _buildAIAction(IconData icon, String label, String sub, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 130,
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.12),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(children: [
          Icon(icon, color: color == const Color(0xFF023E8A) ? Colors.blue[300] : Colors.purple[300], size: 36),
          const SizedBox(height: 10),
          Text(label, style: const TextStyle(fontWeight: FontWeight.w700, color: _textPrim, fontSize: 14)),
          const SizedBox(height: 4),
          Text(sub, style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 11), textAlign: TextAlign.center),
        ]),
      ),
    );
  }

  void _onTabTap(int index) {
    setState(() => _selectedIndex = index);
    _pageController.jumpToPage(index);
  }

  @override
  Widget build(BuildContext context) {
    final tabs  = ['Beranda', 'Tools', 'Saran', 'Profil'];
    final icons = [Icons.home_rounded, Icons.build_rounded, Icons.chat_bubble_outline_rounded, Icons.person_rounded];

    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _bg, elevation: 0,
        title: Row(children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              gradient: const LinearGradient(colors: [_accent, _accentDim]),
            ),
            child: const Icon(Icons.eco_rounded, color: Colors.white, size: 18),
          ),
          const SizedBox(width: 10),
          const Text('GreenWay', style: TextStyle(fontWeight: FontWeight.w800, color: _textPrim, fontSize: 20)),
        ]),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_rounded, color: Colors.white54),
            onPressed: _logout, tooltip: 'Logout',
          ),
        ],
      ),
      body: PageView(
        controller: _pageController,
        physics: const NeverScrollableScrollPhysics(),
        children: const [HomeTab(), ToolsTab(), SaranTab(), ProfileTab()],
      ),
      floatingActionButton: AnimatedBuilder(
        animation: _fabPulse,
        builder: (context, child) => Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: [BoxShadow(
              color: _accent.withOpacity(0.25 + _fabPulse.value * 0.2),
              blurRadius: 20 + _fabPulse.value * 10, spreadRadius: 2,
            )],
          ),
          child: FloatingActionButton(
            onPressed: _showAIPicker, backgroundColor: _accent, elevation: 0,
            child: const Icon(Icons.auto_awesome_rounded, color: Colors.white, size: 26),
          ),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: _surface,
          border: Border(top: BorderSide(color: _accentDim.withOpacity(0.2))),
        ),
        child: SafeArea(
          child: SizedBox(
            height: 64,
            child: Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
              ...List.generate(2, (i) => _navItem(icons[i], tabs[i], i)),
              const SizedBox(width: 56),
              ...List.generate(2, (i) => _navItem(icons[i + 2], tabs[i + 2], i + 2)),
            ]),
          ),
        ),
      ),
    );
  }

  Widget _navItem(IconData icon, String label, int index) {
    final active = _selectedIndex == index;
    return GestureDetector(
      onTap: () => _onTabTap(index),
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 72,
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(icon, color: active ? _accent : Colors.white30, size: 24),
          const SizedBox(height: 4),
          Text(label, style: TextStyle(
            fontSize: 10, fontWeight: active ? FontWeight.w700 : FontWeight.w400,
            color: active ? _accent : Colors.white30,
          )),
        ]),
      ),
    );
  }
}

// ─── HOME TAB ───────────────────────────────────────────────────────────────
class HomeTab extends StatefulWidget {
  const HomeTab({super.key});
  @override
  State<HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<HomeTab> with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  String _steps = '0', _fullName = 'User';
  double _co2Saved = 0.0;
  GoogleMapController? _mapController;
  Set<Marker> _markers = {};
  bool _isLoadingMap = true;
  static const CameraPosition _initialPosition =
      CameraPosition(target: LatLng(-6.200000, 106.816666), zoom: 12);
  StreamSubscription<AccelerometerEvent>? _accelSub;
  DateTime _lastShake = DateTime.now();
  int _stepCount = 0;
  bool _pedometerNotifSent5k = false;
  bool _pedometerNotifSent10k = false;

  final List<String> _tips = [
    'Gunakan tas belanja sendiri untuk mengurangi sampah plastik.',
    'Matikan lampu dan cabut alat elektronik saat tidak digunakan.',
    'Bawa botol minum (tumbler) ke kampus.',
    'Pilah sampah organik dan anorganik dari rumah.',
    'Gunakan transportasi umum atau jalan kaki untuk jarak dekat.',
  ];
  String _currentTip = 'Goyang HP kamu untuk mendapatkan tip baru!';

  @override
  void initState() {
    super.initState();
    _loadUser();
    _initSensors();
    _checkLocationPermission();
  }

  void _loadUser() async {
    final s = await DatabaseHelper.instance.getActiveSession();
    if (s != null && mounted) setState(() => _fullName = s['full_name']);
  }

  void _initSensors() async {
    if (await Permission.activityRecognition.request().isGranted) {
      Pedometer.stepCountStream.listen((e) {
        if (mounted) {
          setState(() {
            _stepCount = e.steps;
            _steps = e.steps.toString();
            _co2Saved = e.steps * 0.04;
          });
          if (_stepCount >= 10000 && !_pedometerNotifSent10k) {
            _pedometerNotifSent10k = true;
            NotificationHelper.showPedometerNotif(_stepCount);
          } else if (_stepCount >= 5000 && !_pedometerNotifSent5k) {
            _pedometerNotifSent5k = true;
            NotificationHelper.showPedometerNotif(_stepCount);
          }
        }
      });
    }
    _accelSub = accelerometerEventStream().listen((AccelerometerEvent event) {
      double gForce = math.sqrt(math.pow(event.x, 2) + math.pow(event.y, 2) + math.pow(event.z, 2));
      if (gForce > 15.0) {
        final now = DateTime.now();
        if (now.difference(_lastShake).inSeconds > 2) {
          _lastShake = now;
          if (mounted) {
            setState(() => _currentTip = _tips[math.Random().nextInt(_tips.length)]);
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: const Text('🌟 Tip baru!'), backgroundColor: _accentDim,
              duration: const Duration(seconds: 1), behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ));
          }
        }
      }
    });
  }

  Future<void> _checkLocationPermission() async {
    var status = await Permission.location.request();
    if (status.isGranted) _getCurrentLocation();
    else if (mounted) setState(() => _isLoadingMap = false);
  }

  Future<void> _getCurrentLocation() async {
    try {
      Position position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
      if (mounted) setState(() {
        _isLoadingMap = false;
        _markers.add(Marker(
          markerId: const MarkerId('current_user'),
          position: LatLng(position.latitude, position.longitude),
          infoWindow: const InfoWindow(title: 'Lokasi Kamu'),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
        ));
        _generateGreenSpots(position.latitude, position.longitude);
      });
      _mapController?.animateCamera(
        CameraUpdate.newLatLngZoom(LatLng(position.latitude, position.longitude), 14.0));
    } catch (e) {
      if (mounted) setState(() => _isLoadingMap = false);
    }
  }

  void _generateGreenSpots(double lat, double lng) {
    _markers.add(Marker(markerId: const MarkerId('spot_1'), position: LatLng(lat + 0.005, lng + 0.005),
      infoWindow: const InfoWindow(title: 'Bank Sampah Berkah', snippet: 'Terima plastik & kardus'),
      icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen)));
    _markers.add(Marker(markerId: const MarkerId('spot_2'), position: LatLng(lat - 0.003, lng - 0.004),
      infoWindow: const InfoWindow(title: 'Taman Kota Hijau', snippet: 'Area resapan air'),
      icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen)));
  }

  @override
  void dispose() { _accelSub?.cancel(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        RichText(text: TextSpan(children: [
          TextSpan(text: 'Halo, ', style: TextStyle(fontSize: 26, fontWeight: FontWeight.w300, color: Colors.white.withOpacity(0.6))),
          TextSpan(text: _fullName, style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: _textPrim)),
        ])),
        const SizedBox(height: 4),
        Text('Setiap langkahmu menyelamatkan bumi 🌍', style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 13)),
        const SizedBox(height: 24),
        Row(children: [
          Expanded(child: _statCard('Langkah', _steps, Icons.directions_walk_rounded, _accent)),
          const SizedBox(width: 12),
          Expanded(child: _statCard('CO₂ Hemat', '${_co2Saved.toStringAsFixed(1)}g', Icons.cloud_done_rounded, const Color(0xFF48CAE4))),
        ]),
        const SizedBox(height: 16),
        Container(
          height: 250,
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(20), border: Border.all(color: _accentDim.withOpacity(0.3))),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Stack(children: [
              GoogleMap(
                initialCameraPosition: _initialPosition,
                myLocationEnabled: true, myLocationButtonEnabled: false, zoomControlsEnabled: true,
                mapType: MapType.normal, markers: _markers,
                gestureRecognizers: <Factory<OneSequenceGestureRecognizer>>{
                  Factory<OneSequenceGestureRecognizer>(() => EagerGestureRecognizer()),
                },
                onMapCreated: (controller) => _mapController = controller,
              ),
              if (_isLoadingMap)
                Container(color: _card, child: const Center(child: CircularProgressIndicator(color: _accent))),
              Positioned(top: 10, left: 10,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(color: _bg.withOpacity(0.8), borderRadius: BorderRadius.circular(10)),
                  child: const Text('📍 Lokasi Hijau Terdekat', style: TextStyle(color: _textPrim, fontWeight: FontWeight.bold, fontSize: 12)),
                )),
              Positioned(bottom: 10, right: 10,
                child: FloatingActionButton.small(
                  backgroundColor: _accent, heroTag: 'map_location',
                  onPressed: _getCurrentLocation,
                  child: const Icon(Icons.my_location_rounded, color: Colors.white),
                )),
            ]),
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: LinearGradient(colors: [_accentDim.withOpacity(0.5), _accent.withOpacity(0.2)], begin: Alignment.topLeft, end: Alignment.bottomRight),
            border: Border.all(color: _accent.withOpacity(0.2)),
          ),
          child: Row(children: [
            const Text('💡', style: TextStyle(fontSize: 28)),
            const SizedBox(width: 14),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('Tip Hijau (Shake HP)', style: TextStyle(fontWeight: FontWeight.w700, color: _textPrim, fontSize: 13)),
              const SizedBox(height: 4),
              Text(_currentTip, style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 12)),
            ])),
          ]),
        ),
      ]),
    );
  }

  Widget _statCard(String label, String value, IconData icon, Color color) => Container(
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(color: _card, borderRadius: BorderRadius.circular(20), border: Border.all(color: color.withOpacity(0.2))),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Icon(icon, color: color, size: 28), const SizedBox(height: 12),
      Text(value, style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: color)),
      const SizedBox(height: 4),
      Text(label, style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 12)),
    ]),
  );
}

// ─── TOOLS TAB ──────────────────────────────────────────────────────────────
class ToolsTab extends StatefulWidget {
  const ToolsTab({super.key});
  @override
  State<ToolsTab> createState() => _ToolsTabState();
}

class _ToolsTabState extends State<ToolsTab> with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  double _heading = 0.0;
  StreamSubscription<MagnetometerEvent>? _magSub;
  String _searchQuery = '';

  final List<Map<String, dynamic>> _allTools = [
    {'title': 'Eco Scavenger Hunt', 'sub': 'Cari sampah organik pake kamera!', 'icon': Icons.auto_fix_high_rounded, 'color': Color(0xFF52B788), 'screen': const EcoHuntScreen()},
    {'title': 'Kurs Mata Uang', 'sub': 'Konversi 8 mata uang', 'icon': Icons.currency_exchange_rounded, 'color': const Color(0xFFF4A261), 'screen': const CurrencyConverterScreen()},
    {'title': 'Zona Waktu', 'sub': 'WIB · WITA · WIT · Global', 'icon': Icons.language_rounded, 'color': const Color(0xFF48CAE4), 'screen': const TimezoneScreen()},
    {'title': 'Eco-Quiz', 'sub': 'Mini game lingkungan', 'icon': Icons.videogame_asset_rounded, 'color': const Color(0xFFB185DB), 'screen': const GameScreen()},
  ];

  @override
  void initState() {
    super.initState();
    _magSub = magnetometerEventStream().listen((event) {
      double heading = math.atan2(event.y, event.x) * (180 / math.pi);
      if (mounted) setState(() => _heading = heading);
    });
  }

  @override
  void dispose() { _magSub?.cancel(); super.dispose(); }

  String _getDirection(double h) {
    if (h >= -22.5 && h < 22.5) return 'Utara';
    if (h >= 22.5 && h < 67.5) return 'Timur Laut';
    if (h >= 67.5 && h < 112.5) return 'Timur';
    if (h >= 112.5 && h < 157.5) return 'Tenggara';
    if (h >= 157.5 || h < -157.5) return 'Selatan';
    if (h >= -157.5 && h < -112.5) return 'Barat Daya';
    if (h >= -112.5 && h < -67.5) return 'Barat';
    return 'Barat Laut';
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final filteredTools = _allTools.where((t) =>
      t['title'].toString().toLowerCase().contains(_searchQuery.toLowerCase()) ||
      t['sub'].toString().toLowerCase().contains(_searchQuery.toLowerCase())
    ).toList();

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 100),
      children: [
        const Text('Tools & Utilities', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: _textPrim)),
        const SizedBox(height: 4),
        Text('Pencarian dan pemilihan fitur', style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 13)),
        const SizedBox(height: 20),
        TextField(
          onChanged: (v) => setState(() => _searchQuery = v),
          style: const TextStyle(color: _textPrim, fontSize: 14),
          decoration: InputDecoration(
            hintText: 'Cari alat...', hintStyle: TextStyle(color: Colors.white.withOpacity(0.3)),
            prefixIcon: const Icon(Icons.search_rounded, color: _accent),
            filled: true, fillColor: _card,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
            contentPadding: const EdgeInsets.symmetric(vertical: 0),
          ),
        ),
        const SizedBox(height: 16),
        _compassCard(),
        const SizedBox(height: 16),
        if (filteredTools.isEmpty)
          const Center(child: Padding(padding: EdgeInsets.all(20),
            child: Text('Alat tidak ditemukan', style: TextStyle(color: Colors.white54)))),
        ...filteredTools.map((t) => _ToolCard(
          title: t['title'] as String, sub: t['sub'] as String,
          icon: t['icon'] as IconData, color: t['color'] as Color, screen: t['screen'] as Widget,
        )),
      ],
    );
  }

  Widget _compassCard() => Container(
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(color: _card, borderRadius: BorderRadius.circular(20), border: Border.all(color: _accentDim.withOpacity(0.2))),
    child: Row(children: [
      SizedBox(width: 80, height: 80,
        child: Stack(alignment: Alignment.center, children: [
          Container(decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: _accentDim.withOpacity(0.3), width: 1.5))),
          ...['U', 'S', 'B', 'T'].asMap().entries.map((e) {
            final angles = [0.0, math.pi, -math.pi / 2, math.pi / 2];
            return Positioned(
              left: 40 + 30.0 * math.sin(angles[e.key]) - 6,
              top: 40 - 30.0 * math.cos(angles[e.key]) - 7,
              child: Text(e.value, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700,
                color: e.key == 0 ? Colors.red[300] : Colors.white38)),
            );
          }),
          Transform.rotate(angle: _heading * math.pi / 180 * -1,
            child: Icon(Icons.navigation_rounded, size: 28, color: Colors.red[300])),
        ]),
      ),
      const SizedBox(width: 20),
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Kompas Arah', style: TextStyle(fontWeight: FontWeight.w700, color: _textPrim, fontSize: 15)),
        const SizedBox(height: 4),
        Text(_getDirection(_heading), style: const TextStyle(color: _accent, fontWeight: FontWeight.w600, fontSize: 18)),
        const SizedBox(height: 2),
        Text('${_heading.toStringAsFixed(0)}°', style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 12)),
      ]),
    ]),
  );
}

class _ToolCard extends StatelessWidget {
  final String title, sub;
  final IconData icon;
  final Color color;
  final Widget screen;
  const _ToolCard({required this.title, required this.sub, required this.icon, required this.color, required this.screen});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => screen)),
    child: Container(
      margin: const EdgeInsets.only(bottom: 14), padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: _card, borderRadius: BorderRadius.circular(20), border: Border.all(color: color.withOpacity(0.2))),
      child: Row(children: [
        Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(14)), child: Icon(icon, color: color, size: 26)),
        const SizedBox(width: 16),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.w700, color: _textPrim, fontSize: 15)),
          const SizedBox(height: 3),
          Text(sub, style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 12)),
        ])),
        Icon(Icons.arrow_forward_ios_rounded, size: 14, color: Colors.white.withOpacity(0.25)),
      ]),
    ),
  );
}

// ─── SARAN TAB ──────────────────────────────────────────────────────────────
class SaranTab extends StatelessWidget {
  const SaranTab({super.key});
  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    padding: const EdgeInsets.fromLTRB(20, 12, 20, 100),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Text('Saran & Kesan', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: _textPrim)),
      const SizedBox(height: 4),
      Text('Mata kuliah Teknologi Pemrograman Mobile', style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 13)),
      const SizedBox(height: 28),
      TextField(
        maxLines: 5, style: const TextStyle(color: _textPrim, fontSize: 14),
        decoration: InputDecoration(
          hintText: 'Tulis saran dan kesanmu di sini...',
          hintStyle: TextStyle(color: Colors.white.withOpacity(0.25), fontSize: 14),
          filled: true, fillColor: _card,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: _accentDim.withOpacity(0.3))),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: _accentDim.withOpacity(0.3))),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: _accent, width: 1.5)),
        ),
      ),
      const SizedBox(height: 16),
      SizedBox(
        width: double.infinity, height: 52,
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: _accent, foregroundColor: Colors.white, elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
          onPressed: () => ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: const Text('Saran terkirim! Terima kasih 🌿'), backgroundColor: _accentDim,
            behavior: SnackBarBehavior.floating, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          )),
          child: const Text('KIRIM SARAN', style: TextStyle(fontWeight: FontWeight.w700, letterSpacing: 1.2)),
        ),
      ),
    ]),
  );
}

// ─── PROFILE TAB ─────────────────────────────────────────────────────────────
class ProfileTab extends StatefulWidget {
  const ProfileTab({super.key});
  @override
  State<ProfileTab> createState() => _ProfileTabState();
}

class _ProfileTabState extends State<ProfileTab> {
  String _name = 'User', _username = '-', _imageUrl = '';
  bool _notifAuth = true, _notifEvent = true, _notifPedometer = true, _notifDaily = true;
  bool _fingerprintEnabled = false;
  final _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _loadProfile();
    _loadNotifPrefs();
    _loadFingerprintStatus();
  }

  void _loadProfile() async {
    final s = await DatabaseHelper.instance.getActiveSession();
    if (s != null && mounted) setState(() { 
      _name = s['full_name']; 
      _username = s['username'] ?? '-'; 
      _imageUrl = s['profile_image'] ?? ''; 
    });
  }

  void _loadNotifPrefs() async {
    final auth      = await NotificationHelper.isEnabled(NotificationHelper.keyAuth);
    final event     = await NotificationHelper.isEnabled(NotificationHelper.keyEvent);
    final pedometer = await NotificationHelper.isEnabled(NotificationHelper.keyPedometer);
    final daily     = await NotificationHelper.isEnabled(NotificationHelper.keyDaily);
    if (mounted) setState(() {
      _notifAuth      = auth;
      _notifEvent     = event;
      _notifPedometer = pedometer;
      _notifDaily     = daily;
    });
  }

  void _loadFingerprintStatus() async {
    final enabled = await DatabaseHelper.instance.isFingerprintEnabled();
    if (mounted) setState(() => _fingerprintEnabled = enabled);
  }

  // --- Fungsi Edit Profil Lengkap (Nama & Foto) ---
  Future<void> _showEditProfileDialog() async {
    final nameCtrl = TextEditingController(text: _name);
    File? tempImage;

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: _card,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: const Text('Edit Profil', style: TextStyle(color: _textPrim, fontWeight: FontWeight.bold)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Preview Foto di dalam Dialog
                GestureDetector(
                  onTap: () async {
                    final picked = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 50);
                    if (picked != null) {
                      setDialogState(() => tempImage = File(picked.path));
                    }
                  },
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      CircleAvatar(
                        radius: 40,
                        backgroundColor: _accentDim,
                        backgroundImage: tempImage != null 
                          ? FileImage(tempImage!) 
                          : (_imageUrl.isNotEmpty ? NetworkImage(_imageUrl) : null) as ImageProvider?,
                        child: tempImage == null && _imageUrl.isEmpty 
                          ? const Icon(Icons.person, size: 40, color: Colors.white) 
                          : null,
                      ),
                      const CircleAvatar(
                        radius: 40,
                        backgroundColor: Colors.black26,
                        child: Icon(Icons.camera_alt, color: Colors.white70),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: nameCtrl,
                  style: const TextStyle(color: _textPrim),
                  decoration: InputDecoration(
                    labelText: 'Nama Lengkap',
                    labelStyle: const TextStyle(color: _accent),
                    enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: _accent.withOpacity(0.3))),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal', style: TextStyle(color: Colors.white54))),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: _accent),
              onPressed: () {
                Navigator.pop(ctx);
                _performUpdate(nameCtrl.text, tempImage);
              },
              child: const Text('Simpan'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _performUpdate(String newName, File? newImage) async {
    try {
      var request = http.MultipartRequest('POST', Uri.parse('http://192.168.1.24:3000/update-profile'));
      request.fields['username'] = _username;
      request.fields['full_name'] = newName;
      
      if (newImage != null) {
        request.files.add(await http.MultipartFile.fromPath('image', newImage.path));
      }

      var response = await request.send();
      if (response.statusCode == 200) {
        var resBody = await response.stream.bytesToString();
        var data = jsonDecode(resBody);
        
        // Update local database
        await DatabaseHelper.instance.updateLocalProfile(newName, data['image_url']);
        
        _loadProfile(); // Refresh UI
        _showSnackBar('Profil berhasil diperbarui! ✨');
      } else {
        _showSnackBar('Gagal memperbarui profil ke server.');
      }
    } catch (e) {
      _showSnackBar('Terjadi kesalahan koneksi.');
    }
  }

  Future<void> _toggleFingerprint(bool value) async {
    if (value) {
      final auth = LocalAuthentication();
      try {
        bool authenticated = await auth.authenticate(
          localizedReason: 'Daftarkan sidik jari untuk akses cepat GreenWay',
          options: const AuthenticationOptions(biometricOnly: true),
        );
        if (authenticated) {
          await DatabaseHelper.instance.setFingerprintEnabled(true);
          _showSnackBar('Sidik jari berhasil didaftarkan! 🔐');
        } else {
          return;
        }
      } catch (e) {
        _showSnackBar('Biometrik tidak tersedia atau bermasalah.');
        return;
      }
    } else {
      await DatabaseHelper.instance.setFingerprintEnabled(false);
      _showSnackBar('Akses sidik jari dinonaktifkan.');
    }
    _loadFingerprintStatus();
  }

  Future<void> _toggleNotif(String key, bool value) async {
    await NotificationHelper.setEnabled(key, value);
    if (key == NotificationHelper.keyDaily) {
      if (value) await NotificationHelper.scheduleDailyNotification();
      else await NotificationHelper.cancelDailyNotification();
    }
    _loadNotifPrefs();
  }

  void _showSnackBar(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg), 
      backgroundColor: _accentDim, 
      behavior: SnackBarBehavior.floating, 
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))
    ));
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 100),
      child: Column(children: [
        const SizedBox(height: 20),
        // ── Avatar ──
        CircleAvatar(
          radius: 50, 
          backgroundColor: _accentDim,
          backgroundImage: _imageUrl.isNotEmpty ? NetworkImage(_imageUrl) : null, 
          child: _imageUrl.isEmpty 
              ? Text(_name.isNotEmpty ? _name[0].toUpperCase() : 'U', 
                  style: const TextStyle(fontSize: 36, fontWeight: FontWeight.w800, color: Colors.white)) 
              : null
        ),
        const SizedBox(height: 16),
        Text(_name, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: _textPrim)),
        const SizedBox(height: 4),
        Text('@$_username', style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 14)),
        const SizedBox(height: 8),
        // Tombol Edit Profil Baru
        TextButton.icon(
          onPressed: _showEditProfileDialog, 
          icon: const Icon(Icons.edit_note_rounded, color: _accent), 
          label: const Text('Edit Profil', style: TextStyle(color: _accent, fontWeight: FontWeight.bold))
        ),
        const SizedBox(height: 28),

        // ── Info tiles ──
        _infoTile(Icons.school_rounded,       'Program Studi', 'Informatika'),
        _infoTile(Icons.badge_rounded,         'NIM',           '123230122'),
        _infoTile(Icons.calendar_today_rounded,'Semester',      '6'),
        const SizedBox(height: 28),

        // ── Settings Container ──
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: _card,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: _accentDim.withOpacity(0.3)),
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: _accent.withOpacity(0.15), borderRadius: BorderRadius.circular(10)),
                child: const Icon(Icons.settings_rounded, color: _accent, size: 18),
              ),
              const SizedBox(width: 12),
              const Text('Pengaturan Keamanan & Notif',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: _textPrim)),
            ]),
            const SizedBox(height: 20),
            _notifToggle(
              icon: Icons.fingerprint_rounded,
              color: _accent,
              title: 'Login Sidik Jari',
              sub: 'Gunakan biometrik untuk masuk',
              value: _fingerprintEnabled,
              onChanged: (v) => _toggleFingerprint(v),
            ),
            _divider(),
            _notifToggle(
              icon: Icons.notifications_rounded,
              color: const Color(0xFF52B788),
              title: 'Login & Logout',
              sub: 'Notif saat akses akun',
              value: _notifAuth,
              onChanged: (v) => _toggleNotif(NotificationHelper.keyAuth, v),
            ),
            _divider(),
            _notifToggle(
              icon: Icons.emoji_events_rounded,
              color: const Color(0xFFB185DB),
              title: 'Event & Quiz',
              sub: 'Notif aktivitas aplikasi',
              value: _notifEvent,
              onChanged: (v) => _toggleNotif(NotificationHelper.keyEvent, v),
            ),
            _divider(),
            _notifToggle(
              icon: Icons.directions_walk_rounded,
              color: const Color(0xFF48CAE4),
              title: 'Langkah Kaki',
              sub: 'Pengingat milestone langkah',
              value: _notifPedometer,
              onChanged: (v) => _toggleNotif(NotificationHelper.keyPedometer, v),
            ),
            _divider(),
            _notifToggle(
              icon: Icons.wb_sunny_rounded,
              color: const Color(0xFFF4A261),
              title: 'Pengingat Harian',
              sub: 'Notif pagi jam 08.00',
              value: _notifDaily,
              onChanged: (v) => _toggleNotif(NotificationHelper.keyDaily, v),
            ),
          ]),
        ),
      ]),
    );
  }

  Widget _infoTile(IconData icon, String label, String value) => Container(
    margin: const EdgeInsets.only(bottom: 12), padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(color: _card, borderRadius: BorderRadius.circular(16),
      border: Border.all(color: _accentDim.withOpacity(0.2))),
    child: Row(children: [
      Icon(icon, color: _accent, size: 20), const SizedBox(width: 14),
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 11)),
        const SizedBox(height: 2),
        Text(value, style: const TextStyle(color: _textPrim, fontWeight: FontWeight.w600, fontSize: 15)),
      ]),
    ]),
  );

  Widget _notifToggle({
    required IconData icon,
    required Color color,
    required String title,
    required String sub,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(10)),
          child: Icon(icon, color: color, size: 18),
        ),
        const SizedBox(width: 14),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, style: const TextStyle(color: _textPrim, fontWeight: FontWeight.w600, fontSize: 14)),
          const SizedBox(height: 2),
          Text(sub, style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 11)),
        ])),
        Switch(
          value: value,
          onChanged: onChanged,
          activeColor: _accent,
        ),
      ]),
    );
  }

  Widget _divider() => Divider(color: Colors.white.withOpacity(0.06), height: 1);
}