import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('greenway_local.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);
    // Versi ditingkatkan ke 4 untuk mendukung kolom game_score
    return await openDatabase(path, version: 4, onCreate: _createDB, onUpgrade: _upgradeDB);
  }

  Future _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE users (
        id            INTEGER PRIMARY KEY AUTOINCREMENT,
        username      TEXT NOT NULL,
        full_name     TEXT NOT NULL,
        token         TEXT NOT NULL,
        fingerprint   INTEGER NOT NULL DEFAULT 0,
        profile_image TEXT,
        game_score    INTEGER DEFAULT 0
      )
    ''');
  }

  Future _upgradeDB(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('ALTER TABLE users ADD COLUMN fingerprint INTEGER NOT NULL DEFAULT 0');
    }
    if (oldVersion < 3) {
      await db.execute('ALTER TABLE users ADD COLUMN profile_image TEXT'); //
    }
    if (oldVersion < 4) {
      await db.execute('ALTER TABLE users ADD COLUMN game_score INTEGER DEFAULT 0');
    }
  }

  Future<void> saveSession(String username, String fullName, String token) async {
    final db = await instance.database;
    final existing = await getActiveSession();
    final keepFingerprint = existing?['fingerprint'] ?? 0;
    final keepImage = existing?['profile_image'];
    final keepScore = existing?['game_score'] ?? 0;
    
    await db.delete('users');
    await db.insert('users', {
      'username'   : username,
      'full_name'  : fullName,
      'token'      : token,
      'fingerprint': keepFingerprint,
      'profile_image': keepImage,
      'game_score' : keepScore,
    });
  }

  Future<Map<String, dynamic>?> getActiveSession() async {
    final db = await instance.database;
    final maps = await db.query('users', limit: 1);
    return maps.isNotEmpty ? maps.first : null;
  }

  Future<void> updateLocalProfile(String fullName, String? imageUrl) async {
    final db = await instance.database;
    final Map<String, dynamic> updateData = {'full_name': fullName};
    
    // Only update image if it's provided (not null)
    if (imageUrl != null && imageUrl.isNotEmpty) {
      updateData['profile_image'] = imageUrl;
    }
    
    await db.update('users', updateData);
  }

  // Fungsi untuk menambah skor game
  Future<void> addScore(int points) async {
    final db = await instance.database;
    final session = await getActiveSession();
    if (session != null) {
      int currentScore = session['game_score'] ?? 0;
      await db.update('users', {
        'game_score': currentScore + points
      });
      debugPrint("Skor bertambah: $points. Total sekarang: ${currentScore + points}");
    }
  }

  Future<void> deleteSession() async {
    final db = await instance.database;
    final existing = await getActiveSession();
    if (existing == null) return;
    
    final keepFingerprint = existing['fingerprint'] ?? 0;
    final keepImage = existing['profile_image'];
    final keepScore = existing['game_score'] ?? 0;
    final username  = existing['username'];
    final fullName  = existing['full_name'];
    
    await db.delete('users');
    await db.insert('users', {
      'username'   : username,
      'full_name'  : fullName,
      'token'      : '',
      'fingerprint': keepFingerprint,
      'profile_image': keepImage,
      'game_score' : keepScore,
    });
  }

  Future<bool> hasActiveToken() async {
    final s = await getActiveSession();
    return s != null && (s['token'] as String).isNotEmpty;
  }

  Future<void> setFingerprintEnabled(bool enabled) async {
    final db = await instance.database;
    await db.update('users', {'fingerprint': enabled ? 1 : 0});
  }

  Future<bool> isFingerprintEnabled() async {
    final s = await getActiveSession();
    return s != null && s['fingerprint'] == 1;
  }
}