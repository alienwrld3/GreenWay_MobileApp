import 'package:flutter/material.dart';
import 'dart:async';
import '../helpers/notification_helper.dart';

const _bg       = Color(0xFF081C0E);
const _card     = Color(0xFF122E1C);
const _accent   = Color(0xFF52B788);
const _accentDim= Color(0xFF2D6A4F);
const _textPrim = Colors.white;

class GameScreen extends StatefulWidget {
  const GameScreen({super.key});
  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  int _totalScore = 0, _currentQuestion = 0, _timerSeconds = 15;
  Timer? _timer;

  final List<Map<String, dynamic>> _questions = [
    {'q': 'Manakah yang termasuk sampah organik?', 'a': ['Plastik', 'Kulit Pisang', 'Kaleng', 'Kaca'], 'correct': 1},
    {'q': 'Berapa lama plastik terurai di tanah?', 'a': ['1 Tahun', '10 Tahun', 'Ratusan Tahun', '1 Bulan'], 'correct': 2},
    {'q': 'Warna tempat sampah untuk kertas adalah...', 'a': ['Biru', 'Hijau', 'Kuning', 'Merah'], 'correct': 0},
    {'q': 'Mengolah kembali sampah menjadi barang baru disebut?', 'a': ['Reduce', 'Reuse', 'Recycle', 'Replace'], 'correct': 2},
    {'q': 'Sampah B3 biasanya ditandai dengan warna?', 'a': ['Hijau', 'Merah', 'Abu-abu', 'Cokelat'], 'correct': 1},
  ];

  @override
  void initState() { super.initState(); _startTimer(); }

  void _startTimer() {
    _timerSeconds = 15;
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_timerSeconds > 0) setState(() => _timerSeconds--);
      else _answer(-1);
    });
  }

  void _answer(int index) {
    _timer?.cancel();
    if (index == _questions[_currentQuestion]['correct']) _totalScore += 10 + _timerSeconds; 
    setState(() {
      if (_currentQuestion < _questions.length - 1) { _currentQuestion++; _startTimer(); }
      else _showResult();
    });
  }

  String _getRank(int score) {
    if (score >= 100) return "Pahlawan Bumi (SSS)";
    if (score >= 70) return "Penjaga Alam (A)";
    return "Pemula Hijau (C)";
  }

  void _showResult() {
    NotificationHelper.showNotification(title: "Eco-Quiz Selesai! 🏆", body: "Skor kamu $_totalScore! Kamu adalah ${_getRank(_totalScore)}.");
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (c) => AlertDialog(
        backgroundColor: _card,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(28), 
          side: BorderSide(color: _accentDim),
        ),
        title: const Text("Hasil Akhir 🏆", style: TextStyle(color: _textPrim, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text("$_totalScore", style: const TextStyle(fontSize: 48, fontWeight: FontWeight.w800, color: _accent)),
            const Text("TOTAL SKOR", style: TextStyle(color: Colors.white54, fontSize: 12, letterSpacing: 1.5)),
            const SizedBox(height: 20),
            Text(_getRank(_totalScore), style: const TextStyle(color: _textPrim, fontWeight: FontWeight.w600)),
          ],
        ),
        actions: [
          Center(
            child: TextButton(
              onPressed: () { Navigator.pop(c); Navigator.pop(context); },
              child: const Text("KEMBALI KE MENU", style: TextStyle(color: _accent, fontWeight: FontWeight.bold)),
            ),
          )
        ],
      ),
    );
  }

  @override
  void dispose() { _timer?.cancel(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(title: const Text("Eco-Quiz v2.0", style: TextStyle(color: _textPrim, fontWeight: FontWeight.bold)), backgroundColor: _bg, elevation: 0, iconTheme: const IconThemeData(color: _textPrim)),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Text("Soal ${_currentQuestion + 1}/${_questions.length}", style: const TextStyle(color: Colors.white70, fontWeight: FontWeight.w600)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(color: _timerSeconds < 5 ? Colors.red.withOpacity(0.2) : _accent.withOpacity(0.2), borderRadius: BorderRadius.circular(10)),
                child: Text("$_timerSeconds s", style: TextStyle(color: _timerSeconds < 5 ? Colors.redAccent : _accent, fontWeight: FontWeight.bold)),
              ),
            ]),
            const SizedBox(height: 16),
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: LinearProgressIndicator(value: (_currentQuestion + 1) / _questions.length, minHeight: 8, backgroundColor: _card, color: _accent),
            ),
            const SizedBox(height: 40),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(color: _card, borderRadius: BorderRadius.circular(20), border: Border.all(color: _accentDim.withOpacity(0.3))),
              child: Text(_questions[_currentQuestion]['q'], style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: _textPrim), textAlign: TextAlign.center),
            ),
            const SizedBox(height: 40),
            ...(_questions[_currentQuestion]['a'] as List).asMap().entries.map((e) => 
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 60),
                    backgroundColor: _card,
                    foregroundColor: _textPrim,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18), 
                    side: BorderSide(color: _accentDim.withOpacity(0.5)))
                  ),
                  onPressed: () => _answer(e.key), 
                  child: Text(e.value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500))
                ),
              )
            ).toList(),
          ],
        ),
      ),
    );
  }
}