import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ecotahumobile/config/app_config.dart';
import 'package:ecotahumobile/widgets/ecotahu_loader.dart';

void main() {
  test('AppConfig.fileUrl normalizes paths and loopback hosts', () {
    expect(AppConfig.fileUrl(null), '');
    expect(AppConfig.fileUrl('   '), '');
    expect(
      AppConfig.fileUrl('produk/tahu.jpg'),
      '${AppConfig.host}/files/produk/tahu.jpg',
    );
    expect(
      AppConfig.fileUrl('/storage/produk/tahu.jpg'),
      '${AppConfig.host}/files/produk/tahu.jpg',
    );
    expect(
      AppConfig.fileUrl('http://127.0.0.1:8000/files/produk/tahu.jpg'),
      '${AppConfig.host}/files/produk/tahu.jpg',
    );
    expect(
      AppConfig.fileUrl('https://cdn.example.com/img.png'),
      'https://cdn.example.com/img.png',
    );
  });

  testWidgets(
    'EcoTahuSplashLoader renders cleanly on 320px narrow screen with zero overflow',
    (WidgetTester tester) async {
      tester.view.physicalSize = const Size(320, 640);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: EcoTahuSplashLoader(
              progress: 0.55,
              statusText: 'Menyiapkan kesegaran alami untuk Anda...',
            ),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 200));

      expect(tester.takeException(), isNull);
      expect(find.text('55%'), findsOneWidget);
    },
  );
}
