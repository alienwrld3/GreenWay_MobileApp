import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';
import '../helpers/db_helper.dart';

const _bg      = Color(0xFF081C0E);
const _accent  = Color(0xFF52B788);
const _accentDim = Color(0xFF2D6A4F);

class EcoHuntScreen extends StatefulWidget {
  const EcoHuntScreen({super.key});
  @override
  State<EcoHuntScreen> createState() => _EcoHuntScreenState();
}

class _EcoHuntScreenState extends State<EcoHuntScreen> {
  CameraController? _controller;
  bool _isInitializing = true;
  bool _isAnalyzing = false;
  
  int _foundCount = 0;
  final int _targetCount = 3;
  String _statusMessage = "Arahkan kamera ke sampah organik dan tekan Scan";

  // API Key Groq
  final String _apiKey = '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';

  @override
  void initState() {
    super.initState();
    _initCamera();
  }

  Future<void> _initCamera() async {
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) return;
      
      _controller = CameraController(cameras[0], ResolutionPreset.medium, enableAudio: false);
      await _controller!.initialize();
      if (mounted) setState(() => _isInitializing = false);
    } catch (e) {
      if (mounted) setState(() => _statusMessage = "Gagal memuat kamera");
    }
  }

  Future<void> _verifyObject() async {
    if (_controller == null || !_controller!.value.isInitialized || _isAnalyzing) return;

    setState(() {
      _isAnalyzing = true;
      _statusMessage = "Sedang memverifikasi...";
    });

    try {
      // 1. Ambil Gambar
      final XFile image = await _controller!.takePicture();
      final bytes = await File(image.path).readAsBytes();
      
      // 2. Bersihkan Base64 (Sesuai referensi AI Scan lu)
      final String base64Image = base64Encode(bytes).replaceAll(RegExp(r'\s+'), '');

      // 3. Kirim ke API Groq
      final response = await http.post(
        Uri.parse('https://api.groq.com/openai/v1/chat/completions'),
        headers: {
          'Authorization': 'Bearer $_apiKey',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'model': 'llama-3.2-11b-vision-preview',
          'messages': [
            {
              'role': 'user',
              'content': [
                {
                  'type': 'text',
                  'text': 'Analisis gambar ini. Apakah ini sampah organik (daun, makanan, kayu)? Jawab HANYA dengan format JSON: {"organik": true} atau {"organik": false}. Jangan beri penjelasan lain.'
                },
                {
                  'type': 'image_url',
                  'image_url': {
                    'url': 'data:image/jpeg;base64,$base64Image'
                  }
                }
              ]
            }
          ],
          'temperature': 0.1,
          'max_tokens': 100,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        String rawContent = data['choices'][0]['message']['content'] as String;
        
        // 4. Bersihkan Markdown JSON (Sesuai referensi AI Scan lu)
        final cleaned = rawContent.replaceAll(RegExp(r'```json|```'), '').trim();
        final Map<String, dynamic> parsed = jsonDecode(cleaned);

        if (parsed['organik'] == true) {
          setState(() {
            _foundCount++;
            _statusMessage = "✅ BERHASIL! Ditemukan $_foundCount/$_targetCount";
          });
          
          // Tambah skor ke database
          await DatabaseHelper.instance.addScore(100);

          if (_foundCount >= _targetCount) {
            _showWinDialog();
          }
        } else {
          setState(() => _statusMessage = "❌ Objek bukan organik. Coba cari yang lain!");
        }
      } else {
        setState(() => _statusMessage = "Error API: ${response.statusCode}");
        debugPrint("Groq Error Response: ${response.body}");
      }
    } catch (e) {
      debugPrint("EcoHunt Error: $e");
      setState(() => _statusMessage = "Gagal memproses. Pastikan internet aktif.");
    } finally {
      if (mounted) setState(() => _isAnalyzing = false);
    }
  }

  void _showWinDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF122E1C),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('🎉 MISI SELESAI!', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        content: const Text('Hebat! Kamu telah menemukan 3 sampah organik. +300 Poin telah ditambahkan!', style: TextStyle(color: Colors.white70)),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: _accent),
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.pop(context);
            },
            child: const Text('MANTAP'),
          )
        ],
      ),
    );
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isInitializing) return const Scaffold(backgroundColor: _bg, body: Center(child: CircularProgressIndicator(color: _accent)));

    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _bg, 
        elevation: 0, 
        title: const Text("Eco Scavenger Hunt", style: TextStyle(fontWeight: FontWeight.bold))
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(color: const Color(0xFF122E1C), borderRadius: BorderRadius.circular(24)),
              child: Column(
                children: [
                  const Text("MISI: TEMUKAN 3 SAMPAH ORGANIK", style: TextStyle(color: _accent, fontWeight: FontWeight.w800, fontSize: 14)),
                  const SizedBox(height: 12),
                  LinearProgressIndicator(value: _foundCount / _targetCount, minHeight: 10, backgroundColor: Colors.white10, color: _accent),
                  const SizedBox(height: 8),
                  Text("$_foundCount / $_targetCount Objek Terkumpul", style: const TextStyle(color: Colors.white38, fontSize: 12)),
                ],
              ),
            ),
          ),
          Expanded(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 20),
              decoration: BoxDecoration(borderRadius: BorderRadius.circular(30), border: Border.all(color: _accent.withOpacity(0.5), width: 2)),
              child: ClipRRect(borderRadius: BorderRadius.circular(28), child: CameraPreview(_controller!)),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(30),
            child: Column(
              children: [
                Text(_statusMessage, style: const TextStyle(color: Colors.white, fontSize: 14), textAlign: TextAlign.center),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 60,
                  child: ElevatedButton.icon(
                    onPressed: _isAnalyzing || _foundCount >= _targetCount ? null : _verifyObject,
                    icon: _isAnalyzing 
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : const Icon(Icons.camera_alt),
                    label: Text(_isAnalyzing ? "MENGECEK..." : "SCAN & VERIFIKASI"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _accent, 
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                      disabledBackgroundColor: Colors.white10
                    ),
                  ),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }
}