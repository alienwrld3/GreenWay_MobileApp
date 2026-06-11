import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'dart:convert';
import 'dart:io';
import '../helpers/db_helper.dart';
import '../services/greenway_ai_client.dart';

const _bg      = Color(0xFF081C0E);
const _surface = Color(0xFF0D2B18);
const _card    = Color(0xFF122E1C);
const _accent  = Color(0xFF52B788);

// Enum untuk jenis sampah dengan deskripsi
enum TrashType {
  organik,
  plastik,
  kertas,
  logam,
  kaca,
}

extension TrashTypeExt on TrashType {
  String get label => {
    TrashType.organik: 'Organik',
    TrashType.plastik: 'Plastik',
    TrashType.kertas: 'Kertas',
    TrashType.logam: 'Logam',
    TrashType.kaca: 'Kaca',
  }[this] ?? '';

  String get emoji => {
    TrashType.organik: '🌿',
    TrashType.plastik: '🪣',
    TrashType.kertas: '📄',
    TrashType.logam: '⚙️',
    TrashType.kaca: '🥤',
  }[this] ?? '';

  String get description => {
    TrashType.organik: 'Daun, makanan, kayu, sampah alam',
    TrashType.plastik: 'Botol plastik, tas plastik, kantong',
    TrashType.kertas: 'Kardus, koran, tisu, kertas bekas',
    TrashType.logam: 'Kaleng, paku, besi, aluminium',
    TrashType.kaca: 'Botol kaca, piring pecah, kaca rusak',
  }[this] ?? '';

  String get aiPrompt => {
    TrashType.organik: 'Apakah ini sampah ORGANIK (daun, makanan, kayu, rumput, sisa makanan)?',
    TrashType.plastik: 'Apakah ini sampah PLASTIK (botol plastik, tas plastik, kemasan plastik)?',
    TrashType.kertas: 'Apakah ini sampah KERTAS (kardus, koran, tisu, kertas bekas)?',
    TrashType.logam: 'Apakah ini sampah LOGAM (kaleng, paku, besi, aluminium, tembaga)?',
    TrashType.kaca: 'Apakah ini sampah KACA (botol kaca, piring pecah, kaca rusak)?',
  }[this] ?? '';
}

class EcoHuntScreen extends StatefulWidget {
  const EcoHuntScreen({super.key});
  @override
  State<EcoHuntScreen> createState() => _EcoHuntScreenState();
}

class _EcoHuntScreenState extends State<EcoHuntScreen> {
  CameraController? _controller;
  bool _isInitializing = true;
  bool _isAnalyzing = false;
  
  TrashType _selectedTrashType = TrashType.organik;
  final Map<TrashType, int> _collectedTrash = {
    TrashType.organik: 0,
    TrashType.plastik: 0,
    TrashType.kertas: 0,
    TrashType.logam: 0,
    TrashType.kaca: 0,
  };
  
  final int _targetPerType = 1; // Target 1 dari setiap jenis
  String _statusMessage = "Pilih jenis sampah, arahkan kamera, dan tekan Scan";
  final GreenwayAiClient _aiClient = const GreenwayAiClient();

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

  bool get _isMissionComplete => _collectedTrash.values.every((count) => count >= _targetPerType);
  int get _totalCollected => _collectedTrash.values.fold(0, (a, b) => a + b);

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
      
      // 2. Bersihkan Base64
      final String base64Image = base64Encode(bytes).replaceAll(RegExp(r'\s+'), '');

      // 3. Kirim ke proxy AI backend dengan prompt sesuai jenis sampah
      final response = await _aiClient.chatCompletions(
        feature: 'eco_hunt',
        body: {
          'messages': [
            {
              'role': 'user',
              'content': [
                {
                  'type': 'text',
                  'text': '${_selectedTrashType.aiPrompt} Jawab HANYA dengan format JSON: {"match": true} atau {"match": false}. Jangan beri penjelasan lain.'
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
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        String rawContent = data['choices'][0]['message']['content'] as String;
        
        // 4. Bersihkan Markdown JSON
        final cleaned = rawContent.replaceAll(RegExp(r'```json|```'), '').trim();
        final Map<String, dynamic> parsed = jsonDecode(cleaned);

        if (parsed['match'] == true) {
          // Cek apakah sudah max untuk jenis ini
          if (_collectedTrash[_selectedTrashType]! >= _targetPerType) {
            setState(() => _statusMessage = "✅ Quota ${_selectedTrashType.label} sudah penuh! Pilih jenis lain.");
          } else {
            setState(() {
              _collectedTrash[_selectedTrashType] = _collectedTrash[_selectedTrashType]! + 1;
              _statusMessage = "✅ ${_selectedTrashType.emoji} BERHASIL! ${_collectedTrash[_selectedTrashType]}/${_targetPerType}";
            });
            
            // Tambah skor ke database
            await DatabaseHelper.instance.addScore(60);

            if (_isMissionComplete) {
              _showWinDialog();
            }
          }
        } else {
          setState(() => _statusMessage = "❌ Bukan ${_selectedTrashType.label}. Coba yang lain!");
        }
      } else {
        setState(() => _statusMessage = "Error API: ${response.statusCode}");
        debugPrint("Groq Error Response: ${response.body}");
      }
    } catch (e) {
      debugPrint("EcoHunt Error: $e");
      setState(() => _statusMessage = e is GreenwayAiException
          ? e.message
          : "Tidak bisa terhubung ke server AI. Pastikan backend aktif dan HP satu Wi-Fi dengan laptop.");
    } finally {
      if (mounted) setState(() => _isAnalyzing = false);
    }
  }

  void _showWinDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: _card,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('🎉 MISI SELESAI!', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Hebat! Kamu telah mengumpulkan semua jenis sampah!', style: TextStyle(color: Colors.white70)),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: _surface, borderRadius: BorderRadius.circular(12)),
              child: Column(
                children: TrashType.values.map((type) => 
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('${type.emoji} ${type.label}', style: const TextStyle(color: Colors.white70)),
                        Text('${_collectedTrash[type]} / $_targetPerType', style: const TextStyle(color: _accent, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  )
                ).toList(),
              ),
            ),
            const SizedBox(height: 12),
            Text('+${_totalCollected * 60} Poin ditambahkan!', style: const TextStyle(color: _accent, fontWeight: FontWeight.bold, fontSize: 16)),
          ],
        ),
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
          // ─── Progress Container ───
          Padding(
            padding: const EdgeInsets.all(20),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: _card, borderRadius: BorderRadius.circular(20)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text("MISI: KUMPULKAN SEMUA JENIS SAMPAH", style: TextStyle(color: _accent, fontWeight: FontWeight.w800, fontSize: 12)),
                      Text("${_totalCollected}/5", style: const TextStyle(color: Colors.white54, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 60,
                    child: GridView.count(
                      crossAxisCount: 5,
                      mainAxisSpacing: 8,
                      crossAxisSpacing: 6,
                      children: TrashType.values.map((type) {
                        final collected = _collectedTrash[type] ?? 0;
                        final isComplete = collected >= _targetPerType;
                        return Container(
                          decoration: BoxDecoration(
                            color: isComplete ? _accent.withOpacity(0.3) : _surface,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: isComplete ? _accent : Colors.white12),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(type.emoji, style: const TextStyle(fontSize: 16)),
                              Text(collected.toString(), style: TextStyle(
                                color: isComplete ? _accent : Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 10,
                              )),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ─── Trash Type Selector ───
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("Pilih Jenis Sampah:", style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w600)),
                const SizedBox(height: 10),
                SizedBox(
                  height: 48,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: TrashType.values.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 8),
                    itemBuilder: (context, index) {
                      final type = TrashType.values[index];
                      final isSelected = _selectedTrashType == type;
                      final isComplete = _collectedTrash[type]! >= _targetPerType;
                      
                      return GestureDetector(
                        onTap: () => setState(() => _selectedTrashType = type),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          decoration: BoxDecoration(
                            color: isSelected ? _accent : (isComplete ? _accent.withOpacity(0.2) : _surface),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isSelected ? _accent : (isComplete ? _accent : Colors.white10),
                              width: isSelected ? 2 : 1,
                            ),
                          ),
                          child: Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(type.emoji, style: const TextStyle(fontSize: 16)),
                                Text(type.label, style: TextStyle(
                                  color: isSelected ? Colors.black : Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 10,
                                )),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 8),
                Text(_selectedTrashType.description, style: const TextStyle(color: Colors.white38, fontSize: 10, fontStyle: FontStyle.italic)),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // ─── Camera Preview ───
          Expanded(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 20),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(30), 
                border: Border.all(color: _accent.withOpacity(0.5), width: 2),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(28), 
                child: CameraPreview(_controller!),
              ),
            ),
          ),

          // ─── Status & Scan Button ───
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                Text(_statusMessage, style: const TextStyle(color: Colors.white, fontSize: 13), textAlign: TextAlign.center),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton.icon(
                    onPressed: _isAnalyzing || _isMissionComplete ? null : _verifyObject,
                    icon: _isAnalyzing 
                        ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : const Icon(Icons.camera_alt),
                    label: Text(_isAnalyzing ? "MENGECEK..." : "SCAN & VERIFIKASI"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _accent, 
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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
