import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:humming_bird/controllers/chat_customization_controller.dart';
import 'package:humming_bird/pages/setting/chat_customization/chat_customization_page.dart';

/// Serves exact gstatic font artifacts for `GoogleFonts.poppins` so the page
/// renders. google_fonts validates a sha256/checksum per artifact.
class _FontClient extends http.BaseClient {
  final Map<String, List<int>> urls = {
    'https://fonts.gstatic.com/s/a/ec23e010878cf0841f910ef94f62294e40c7d77ce99be250dba2911d0a1a61cd.ttf':
        _fontBytes('poppins-semi-bold.ttf'),
    'https://fonts.gstatic.com/s/a/2dd6eb23c4972b346197d272c4e2479b89ed240ece4d2b0e0cd89f0c1caa2710.ttf':
        _fontBytes('poppins-regular.ttf'),
    'https://fonts.gstatic.com/s/a/c0ba5609d6562c76ab7db73fa9c9b283d210598cb318a45d4085f540e4753d60.ttf':
        _fontBytes('poppins-bold.ttf'),
  };

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    final url = request.url.toString();
    final bytes = urls[url];
    if (bytes == null) debugPrint('GF-FONT-URL: $url');
    final stream = http.ByteStream.fromBytes(bytes ?? const []);
    return http.StreamedResponse(stream, 200,
        contentLength: bytes?.length ?? 0);
  }
}

List<int> _fontBytes(String fileName) =>
    File('test/fixtures/fonts/$fileName').readAsBytesSync();

Future<void> _pumpPage(WidgetTester tester) async {
  await tester.pumpWidget(
    ScreenUtilInit(
      designSize: const Size(360, 690),
      builder: (context, child) => GetMaterialApp(
        home: const ChatCustomizationPage(),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  GoogleFonts.config.httpClient = _FontClient();

  const pathProviderChannel = MethodChannel('plugins.flutter.io/path_provider');
  TestWidgetsFlutterBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(pathProviderChannel, (call) async {
    if (call.method == 'getApplicationDocumentsDirectory' ||
        call.method == 'getApplicationSupportDirectory') {
      return Directory.systemTemp.path;
    }
    return null;
  });

  setUpAll(() async {
    await GetStorage.init();
    GoogleFonts.config.httpClient = _FontClient();
  });

  setUp(() {
    Get.put<ChatCustomizationController>(ChatCustomizationController(),
        permanent: true);
  });

  tearDown(() {
    Get.reset();
  });

  testWidgets('page opens without init errors and shows all 6 bubble styles',
      (tester) async {
    await _pumpPage(tester);

    expect(tester.takeException(), isNull);
    expect(find.text('Chat Customization'), findsOneWidget);
    for (final label in [
      'Premium',
      'Classic',
      'Rounded',
      'Minimal',
      'WhatsApp',
      'Compact',
    ]) {
      expect(find.text(label), findsOneWidget,
          reason: 'bubble style chip "$label" missing');
    }
  });

  testWidgets('selecting each of the 6 styles updates controller + storage',
      (tester) async {
    await _pumpPage(tester);
    final controller = Get.find<ChatCustomizationController>();

    const pickOrder = [
      (label: 'Premium', key: 'premium'),
      (label: 'Classic', key: 'modern'),
      (label: 'Rounded', key: 'rounded'),
      (label: 'Minimal', key: 'minimal'),
      (label: 'WhatsApp', key: 'whatsapp'),
      (label: 'Compact', key: 'compact'),
      (label: 'Premium', key: 'premium'),
    ];

    for (final picked in pickOrder) {
      await tester.ensureVisible(find.text(picked.label));
      await tester.pumpAndSettle();
      await tester.tap(find.text(picked.label), warnIfMissed: true);
      await tester.pumpAndSettle();
      expect(controller.bubbleStyle.value, picked.key,
          reason: 'controller did not update after tapping ${picked.label}');
      expect(GetStorage().read<String>('bubble_style'), picked.key,
          reason: 'storage did not update after tapping ${picked.label}');
    }
  });

  testWidgets('each of the 6 bubble styles survives a fresh controller (restart)',
      (tester) async {
    await _pumpPage(tester);
    final controller = Get.find<ChatCustomizationController>();

    const keys = [
      'premium',
      'modern',
      'rounded',
      'minimal',
      'whatsapp',
      'compact',
    ];
    for (final key in keys) {
      controller.setBubbleStyle(key);
      expect(GetStorage().read<String>('bubble_style'), key);

      final fresh = ChatCustomizationController();
      fresh.onInit();
      expect(fresh.bubbleStyle.value, key,
          reason: 'bubble style "$key" must persist across app restart');
    }
  });

  testWidgets('stale-typed storage values do not crash controller init',
      (tester) async {
    final s = GetStorage();
    s.write('chat_font_size', 16);
    s.write('cc_shadow_blur', 7);
    s.write('cc_show_read_receipts', 'yes');
    s.write('bubble_received_color', 12.5);

    final c = ChatCustomizationController();
    c.onInit();
    expect(c.fontSize.value, 16.0);
    expect(c.shadowBlur.value, 7.0);
    expect(c.showReadReceipts.value, true);
    expect(tester.takeException(), isNull);
  });

  testWidgets('sent bubble color updates controller and persists',
      (tester) async {
    await _pumpPage(tester);
    final controller = Get.find<ChatCustomizationController>();
    final target = const Color(0xff22C55E).toARGB32();
    controller.setSentColor(const Color(0xff22C55E));
    await tester.pumpAndSettle();
    expect(controller.sentColor.toARGB32(), target);
    expect(GetStorage().read<int>('bubble_sent_color'), target);

    final fresh = ChatCustomizationController();
    fresh.onInit();
    expect(fresh.sentColor.toARGB32(), target,
        reason: 'sent color must persist across restart');
  });
}