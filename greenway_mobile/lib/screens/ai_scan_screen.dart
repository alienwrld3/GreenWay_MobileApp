import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';

const _bg      = Color(0xFF081C0E);
const _surface = Color(0xFF0D2B18);
const _card    = Color(0xFF122E1C);
const _accent  = Color(0xFF52B788);
const _accentDim = Color(0xFF2D6A4F);

class AIScanScreen extends StatefulWidget {
  const AIScanScreen({super.key});
  @override
  State<AIScanScreen> createState() => _AIScanScreenState();
}

class _AIScanScreenState extends State<AIScanScreen> {
  CameraController? _controller;
  bool _isInitializing = true;
  bool _isAnalyzing = false;

  // Mode: false = live camera, true = hasil foto (freeze)
  bool _isFrozen = false;
  String? _capturedImagePath;

  String _result = '';
  String _category = '';   // organik / anorganik / bukan sampah
  String _statusLabel = '';

  final String _apiKey = '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';

  @override
  void initState() {
    super.initState();
    _initCamera();
  }

  Future<void> _initCamera() async {
    final cameras = await availableCameras();
    if (cameras.isEmpty) return;
    _controller = CameraController(cameras[0], ResolutionPreset.medium, enableAudio: false);
    await _controller!.initialize();
    if (mounted) setState(() => _isInitializing = false);
  }

  Future<void> _analyzeImage() async {
    if (_controller == null || !_controller!.value.isInitialized) return;

    final image = await _controller!.takePicture();

    setState(() {
      _isAnalyzing = true;
      _isFrozen = true;           // freeze tampilan → tampilkan foto
      _capturedImagePath = image.path;
      _result = '';
      _category = '';
      _statusLabel = 'Menganalisis...';
    });

    try {
      final bytes = await image.readAsBytes();
      final base64Image = base64Encode(bytes).replaceAll(RegExp(r'\s+'), '');

      final response = await http.post(
        Uri.parse('https://api.groq.com/openai/v1/chat/completions'),
        headers: {
          'Authorization': 'Bearer $_apiKey',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'model': 'meta-llama/llama-4-scout-17b-16e-instruct',
          'messages': [
            {
              'role': 'user',
              'content': [
                {
                  'type': 'text',
                  'text': '''Kamu adalah asisten lingkungan. Analisis gambar ini dan jawab dalam format JSON berikut (tanpa markdown, tanpa kode blok):
{
  "nama_objek": "...",
  "kategori": "organik" | "anorganik" | "B3" | "bukan sampah",
  "deskripsi": "penjelasan singkat 1-2 kalimat tentang objek",
  "cara_penanganan": "langkah konkret cara membuang/mengolah sampah ini",
  "dampak_lingkungan": "dampak jika tidak ditangani dengan benar"
}'''
                },
                {
                  'type': 'image_url',
                  'image_url': {'url': 'data:image/jpeg;base64,$base64Image'}
                }
              ]
            }
          ],
          'max_tokens': 512,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final raw = data['choices'][0]['message']['content'] as String;

        try {
          // Bersihkan jika ada sisa markdown
          final cleaned = raw.replaceAll(RegExp(r'```json|```'), '').trim();
          final parsed = jsonDecode(cleaned);
          setState(() {
            _category = parsed['kategori'] ?? '';
            _result = [
              '📦 ${parsed['nama_objek'] ?? ''}',
              '',
              '📝 ${parsed['deskripsi'] ?? ''}',
              '',
              '♻️ Cara penanganan:\n${parsed['cara_penanganan'] ?? ''}',
              '',
              '⚠️ Dampak lingkungan:\n${parsed['dampak_lingkungan'] ?? ''}',
            ].join('\n');
            _statusLabel = _categoryLabel(_category);
          });
        } catch (_) {
          // Fallback jika AI tidak return JSON
          setState(() {
            _result = raw;
            _statusLabel = 'Hasil Analisis';
          });
        }
      } else {
        final errorInfo = jsonDecode(response.body);
        setState(() {
          _result = 'Gagal menghubungi AI.';
          _statusLabel = 'Error';
        });
        debugPrint('Groq error: ${errorInfo['error']['message']}');
      }
    } catch (e) {
      setState(() {
        _result = 'Periksa koneksi internet kamu.';
        _statusLabel = 'Koneksi Error';
      });
    } finally {
      setState(() => _isAnalyzing = false);
    }
  }

  String _categoryLabel(String cat) {
    switch (cat.toLowerCase()) {
      case 'organik': return '🟢 Sampah Organik';
      case 'anorganik': return '🔵 Sampah Anorganik';
      case 'b3': return '🔴 Sampah B3 (Berbahaya)';
      case 'bukan sampah': return '✅ Bukan Sampah';
      default: return '🔍 Hasil Analisis';
    }
  }

  Color _categoryColor(String cat) {
    switch (cat.toLowerCase()) {
      case 'organik': return const Color(0xFF52B788);
      case 'anorganik': return const Color(0xFF48CAE4);
      case 'b3': return Colors.redAccent;
      default: return _accent;
    }
  }

  void _resetScan() {
    setState(() {
      _isFrozen = false;
      _capturedImagePath = null;
      _result = '';
      _category = '';
      _statusLabel = '';
    });
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isInitializing) {
      return const Scaffold(
        backgroundColor: _bg,
        body: Center(child: CircularProgressIndicator(color: _accent)),
      );
    }

    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        title: const Text('AI Scan', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
        backgroundColor: _bg, elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          if (_isFrozen)
            TextButton.icon(
              onPressed: _resetScan,
              icon: const Icon(Icons.refresh_rounded, color: _accent, size: 18),
              label: const Text('Scan Ulang', style: TextStyle(color: _accent, fontSize: 13)),
            ),
        ],
      ),
      body: Column(
        children: [
          // ── Viewfinder ──────────────────────────────────────────
          Expanded(
            flex: 5,
            child: Container(
              margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: _accent.withOpacity(0.3)),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(22),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    // Tampilkan foto freeze atau live camera
                    if (_isFrozen && _capturedImagePath != null)
                      Image.file(File(_capturedImagePath!), fit: BoxFit.cover)
                    else
                      CameraPreview(_controller!),

                    // Badge status di atas foto
                    if (_isFrozen && _statusLabel.isNotEmpty)
                      Positioned(
                        top: 12, left: 12,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: _bg.withOpacity(0.85),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: _categoryColor(_category).withOpacity(0.5)),
                          ),
                          child: Text(
                            _statusLabel,
                            style: TextStyle(
                              color: _categoryColor(_category),
                              fontWeight: FontWeight.w700, fontSize: 12,
                            ),
                          ),
                        ),
                      ),

                    // Overlay analyzing
                    if (_isAnalyzing)
                      Container(
                        color: Colors.black45,
                        child: const Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              CircularProgressIndicator(color: _accent),
                              SizedBox(height: 16),
                              Text('Menganalisis...', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),

          // ── Panel Bawah ─────────────────────────────────────────
          Expanded(
            flex: 4,
            child: Container(
              width: double.infinity,
              decoration: const BoxDecoration(
                color: _surface,
                borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
              ),
              child: _result.isEmpty
                  // State awal / belum scan
                  ? Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.document_scanner_rounded, size: 48, color: _accent.withOpacity(0.4)),
                        const SizedBox(height: 12),
                        Text(
                          'Arahkan kamera ke objek\nlalu tekan tombol Scan',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 14),
                        ),
                        const SizedBox(height: 28),
                        _buildScanButton(),
                      ],
                    )
                  // State hasil scan
                  : Column(
                      children: [
                        Expanded(
                          child: SingleChildScrollView(
                            padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                            child: Container(
                              padding: const EdgeInsets.all(18),
                              decoration: BoxDecoration(
                                color: _card,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: _categoryColor(_category).withOpacity(0.25)),
                              ),
                              child: Text(
                                _result,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                  height: 1.6,
                                ),
                              ),
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: _buildScanButton(),
                        ),
                      ],
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScanButton() {
    return SizedBox(
      width: 180,
      height: 52,
      child: ElevatedButton.icon(
        onPressed: _isAnalyzing ? null : _analyzeImage,
        icon: const Icon(Icons.camera_alt_rounded, size: 20),
        label: const Text('SCAN OBJEK', style: TextStyle(fontWeight: FontWeight.w700, letterSpacing: 1)),
        style: ElevatedButton.styleFrom(
          backgroundColor: _accent,
          foregroundColor: Colors.white,
          disabledBackgroundColor: _accentDim,
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
      ),
    );
  }
}