import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/app_config.dart';
import '../helpers/db_helper.dart';

class GreenwayAiException implements Exception {
  final String message;

  const GreenwayAiException(this.message);

  @override
  String toString() => message;
}

class GreenwayAiClient {
  const GreenwayAiClient();

  Future<http.Response> chatCompletions({
    required String feature,
    required Map<String, dynamic> body,
  }) async {
    final session = await DatabaseHelper.instance.getActiveSession();
    final token = session?['token'] as String?;
    if (token == null || token.isEmpty) {
      throw const GreenwayAiException('Sesi login tidak ditemukan. Silakan login ulang.');
    }

    return http.post(
      AppConfig.apiUri('/ai/chat'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        ...body,
        'feature': feature,
      }),
    ).timeout(const Duration(seconds: 45));
  }
}
