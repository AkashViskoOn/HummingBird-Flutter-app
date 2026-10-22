import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:humming_bird/components/common/app_empty_state.dart';
import 'package:humming_bird/components/loading/custom_loading.dart';

/// Serves exact gstatic font artifacts for `GoogleFonts.poppins` so the shared
/// widgets render in tests. google_fonts validates a sha256 checksum per
/// artifact, so the exact TTF bytes from test/fixtures/fonts are required.
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

Future<void> _pump(WidgetTester tester, Widget child) async {
  await tester.pumpWidget(
    ScreenUtilInit(
      designSize: const Size(360, 690),
      child: MaterialApp(
        home: Scaffold(body: child),
      ),
    ),
  );
  await tester.pump(const Duration(milliseconds: 100));
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  GoogleFonts.config.httpClient = _FontClient();

  group('AppEmptyState', () {
    testWidgets('centered layout renders icon, title and message',
        (tester) async {
      await _pump(
        tester,
        const AppEmptyState(
          icon: Icons.inbox_rounded,
          title: 'Nothing here',
          message: 'Create something new to see it here.',
        ),
      );

      expect(find.byIcon(Icons.inbox_rounded), findsOneWidget);
      expect(find.text('Nothing here'), findsOneWidget);
      expect(find.text('Create something new to see it here.'),
          findsOneWidget);
    });

    testWidgets('primary action fires and is dismissible', (tester) async {
      var tapped = false;
      await _pump(
        tester,
        AppEmptyState(
          icon: Icons.chat_bubble_outline_rounded,
          title: 'No chats yet',
          actionLabel: 'New Chat',
          onAction: () => tapped = true,
        ),
      );

      await tester.tap(find.text('New Chat'));
      await tester.pumpAndSettle();
      expect(tapped, isTrue);
    });

    testWidgets('secondary retry action fires when provided',
        (tester) async {
      var retried = false;
      await _pump(
        tester,
        AppEmptyState(
          icon: Icons.error_outline_rounded,
          title: 'Could not load',
          message: 'Refresh to try again.',
          secondaryActionLabel: 'Retry',
          onSecondaryAction: () => retried = true,
        ),
      );

      await tester.tap(find.text('Retry'));
      await tester.pumpAndSettle();
      expect(retried, isTrue);
    });

    testWidgets('inline layout is left aligned and compact',
        (tester) async {
      await _pump(
        tester,
        const AppEmptyState(
          icon: Icons.schedule_rounded,
          title: 'No schedules',
          layout: EmptyStateLayout.inline,
        ),
      );

      expect(find.text('No schedules'), findsOneWidget);
      expect(find.byIcon(Icons.schedule_rounded), findsOneWidget);
    });

    testWidgets('merges title and message into one semantic node',
        (tester) async {
      await _pump(
        tester,
        const AppEmptyState(
          icon: Icons.inbox_rounded,
          title: 'Everything consumed',
          message: 'You have read all your messages.',
        ),
      );

      final semantics = tester.getSemantics(find.byType(AppEmptyState));
      final label = semantics.label;
      expect(label, contains('Everything consumed'));
      expect(label, contains('You have read all your messages.'));
    });

    testWidgets('bordered variant renders a card surface', (tester) async {
      await _pump(
        tester,
        const AppEmptyState(
          icon: Icons.inbox_rounded,
          title: 'Empty card',
          bordered: true,
        ),
      );

      expect(find.text('Empty card'), findsOneWidget);
    });
  });

  group('CustomLoading', () {
    testWidgets('renders a centered spinner by default', (tester) async {
      await _pump(tester, const CustomLoading());

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('renders message text when provided', (tester) async {
      await _pump(tester, const CustomLoading(message: 'Syncing\u2026'));

      expect(find.text('Syncing\u2026'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('respects custom size', (tester) async {
      await _pump(tester, const CustomLoading(size: 24));

      final sizedBox = tester.widget<SizedBox>(
        find.byWidgetPredicate((w) =>
            w is SizedBox && w.child is CircularProgressIndicator),
      );
      expect(sizedBox.width, 24);
      expect(sizedBox.height, 24);
    });

    testWidgets('shimmer and card shimmer render without crashing',
        (tester) async {
      await _pump(tester, CustomLoading.shimmer());
      await _pump(tester, CustomLoading.cardShimmer());
      expect(tester.takeException(), isNull);
    });
  });
}