import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:greenway_mobile/screens/login_screen.dart';

void main() {
  testWidgets('GreenWay Login Screen smoke test', (WidgetTester tester) async {
    // Bangun aplikasi GreenWay dan picu frame pertama.
    await tester.pumpWidget(const MaterialApp(home: LoginScreen()));

    // Verifikasi bahwa aplikasi menampilkan judul utama.
    expect(find.text('GreenWay'), findsOneWidget);

    // Verifikasi bahwa terdapat kolom input untuk Username dan Password.
    expect(find.byType(TextField), findsNWidgets(2));

    // Verifikasi bahwa tombol masuk tersedia.
    expect(find.text('MASUK'), findsOneWidget);
  });
}
