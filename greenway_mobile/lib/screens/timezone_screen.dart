import 'package:flutter/material.dart';
import 'dart:async';

// ─── THEME CONSTANTS ────────────────────────────────────────────────────────
const _bg       = Color(0xFF081C0E);
const _surface  = Color(0xFF0D2B18);
const _card     = Color(0xFF122E1C);
const _accent   = Color(0xFF52B788);
const _accentDim= Color(0xFF2D6A4F);
const _textPrim = Colors.white;
// ────────────────────────────────────────────────────────────────────────────

class TimezoneScreen extends StatefulWidget {
  const TimezoneScreen({super.key});

  @override
  State<TimezoneScreen> createState() => _TimezoneScreenState();
}

class _TimezoneScreenState extends State<TimezoneScreen> {
  Timer? _timer;

  final List<Map<String, dynamic>> _localZones = [
    {'city': 'WIB', 'country': 'Indonesia (Barat)', 'offset': 7},
    {'city': 'WITA', 'country': 'Indonesia (Tengah)', 'offset': 8},
    {'city': 'WIT', 'country': 'Indonesia (Timur)', 'offset': 9},
  ];

  final List<Map<String, dynamic>> _intlZones = [
    {'city': 'London', 'country': 'Inggris (GMT)', 'offset': 0},
    {'city': 'Tokyo', 'country': 'Jepang', 'offset': 9},
    {'city': 'New York', 'country': 'Amerika Serikat', 'offset': -4},
  ];

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() { _timer?.cancel(); super.dispose(); }

  String _getTime(int offset) {
    DateTime utc = DateTime.now().toUtc();
    DateTime local = utc.add(Duration(hours: offset));
    return "${local.hour.toString().padLeft(2, '0')}:${local.minute.toString().padLeft(2, '0')}:${local.second.toString().padLeft(2, '0')}";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        title: const Text('Zona Waktu', style: TextStyle(color: _textPrim, fontWeight: FontWeight.w700)),
        backgroundColor: _bg,
        elevation: 0,
        iconTheme: const IconThemeData(color: _textPrim),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionHeader('LOKAL (INDONESIA)', Icons.location_on_rounded),
            ..._localZones.map((zone) => _buildTimeCard(zone)),
            const SizedBox(height: 32),
            _buildSectionHeader('INTERNASIONAL', Icons.public_rounded),
            ..._intlZones.map((zone) => _buildTimeCard(zone)),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: _accent.withOpacity(0.15), borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, color: _accent, size: 20),
          ),
          const SizedBox(width: 14),
          Text(title, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: _textPrim, letterSpacing: 1.2)),
        ],
      ),
    );
  }

  Widget _buildTimeCard(Map<String, dynamic> zone) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _accentDim.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(zone['city'], style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: _textPrim)),
              const SizedBox(height: 4),
              Text(zone['country'], style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 13)),
            ],
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(color: _surface, borderRadius: BorderRadius.circular(14), border: Border.all(color: _accentDim.withOpacity(0.1))),
            child: Text(
              _getTime(zone['offset']),
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: _accent, fontFamily: 'monospace'),
            ),
          ),
        ],
      ),
    );
  }
}