import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:humming_bird/components/home/premium_bottom_nav.dart';
import 'package:humming_bird/controllers/user_controller.dart';

/// Serves exact gstatic font artifacts for `GoogleFonts.poppins`.
class _FontClient extends http.BaseClient {
  final Map<String, List<int>> urls = {
    'https://fonts.gstatic.com/s/a/ec23e010878cf0841f910ef94f62294e40c7d77ce99be250dba2911d0a1a61cd.ttf':
        _fontBytes('poppins-semi-bold.ttf'),
    'https://fonts.gstatic.com/s/a/2dd6eb23c4972b346197d272c4e2479b89ed240ece4d2b0e0cd89f0c1caa2710.ttf':
        _fontBytes('poppins-regular.ttf'),
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

class _FakeUserController extends UserController {
  _FakeUserController() {
    // Leave user == null so the profile avatar falls back to the icon.
  }

  @override
  void onReady() {}
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

  setUp(() async {
    // UserController's constructor touches GetStorage, whose default temp file
    // is shared across parallel test processes — initialize it up front so the
    // container is cached and never races another process' file lock.
    await GetStorage.init();
    Get.put<UserController>(_FakeUserController(), permanent: true);
  });

  tearDown(() {
    Get.reset();
  });

  Future<void> setPhoneViewport(WidgetTester tester) async {
    // 360x690 logical @3x — the design size ScreenUtil scales against.
    tester.view.devicePixelRatio = 3.0;
    tester.view.physicalSize = const Size(1080, 2070);
    addTearDown(tester.view.reset);
  }

  Future<void> pumpApp(
    WidgetTester tester, {
    required int currentIndex,
    ValueChanged<int>? onTap,
  }) async {
    await setPhoneViewport(tester);
    await tester.pumpWidget(
      ScreenUtilInit(
        designSize: const Size(360, 690),
        builder: (context, child) => MaterialApp(
          home: Scaffold(
            bottomNavigationBar: PremiumBottomNav(
              currentIndex: currentIndex,
              onTap: onTap ?? (_) {},
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> pumpNav(WidgetTester tester, {required int currentIndex}) async {
    await pumpApp(tester, currentIndex: currentIndex);
  }

  group('PremiumBottomNav widgets', () {
    testWidgets('renders all 5 destinations', (tester) async {
      await pumpNav(tester, currentIndex: 0);

      // The Chat tab is a semantic logo button, not a text label.
      expect(find.text('Calls'), findsOneWidget);
      expect(find.text('Status'), findsOneWidget);
      expect(find.text('Schedule'), findsOneWidget);
      expect(find.text('You'), findsOneWidget);
      expect(
        find.bySemanticsLabel('Chat'),
        findsOneWidget,
        reason: 'Chat home is the floating logo, reachable by semantics',
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('tapping Schedule reports index 3 (schedule tab contract)',
        (tester) async {
      int? tapped;
      await pumpApp(tester, currentIndex: 0, onTap: (i) => tapped = i);

      await tester.tap(find.text('Schedule'));
      await tester.pump();

      expect(tapped, 3,
          reason: 'Schedule must stay the bottom-nav index 3 — home dashboard '
              'and "View All" navigate by hard-coding index 3');
    });

    testWidgets('tapping each destination reports its index', (tester) async {
      int? tapped;
      await pumpApp(tester, currentIndex: 0, onTap: (i) => tapped = i);

      await tester.tap(find.text('Calls'));
      expect(tapped, 1);

      await tester.tap(find.text('Status'));
      expect(tapped, 2);

      await tester.tap(find.text('You'));
      expect(tapped, 4);
    });

    testWidgets('tap targets are at least 44px tall', (tester) async {
      await pumpNav(tester, currentIndex: 0);

      for (final label in ['Calls', 'Status', 'Schedule', 'You']) {
        final ink = find.ancestor(
          of: find.text(label),
          matching: find.byType(InkWell),
        );
        expect(ink, findsOneWidget, reason: "'$label' must be tappable");
        final size = tester.getSize(ink);
        expect(
          size.height >= 44,
          isTrue,
          reason: "'$label' tap target is ${size.height}px, needs >=44px",
        );
      }
    });
  });

  group('main_humming_screen.dart nav invariants', () {
    final source =
        File('lib/main_humming_screen.dart').readAsStringSync();

    test('schedule tab is bottom-nav index 3 with showHeader', () {
      expect(source, contains("ScheduleMessagesList(showHeader: true)"));
      expect(source, contains('onViewAll: () => setState(() => _currentNavIndex = 3)'));
      expect(source, contains('_buildScheduleTab()'),
          reason: 'schedule tab must be wired into the IndexedStack body');
    });

    test('IndexedStack keeps every tab alive (no ValueKey churn)', () {
      expect(source, contains('return IndexedStack('));
      expect(source, contains('index: _currentNavIndex,'));

      // AGENTS.md: keying the IndexedStack on _currentNavIndex threw away the
      // whole subtree on every tab tap — this is a deliberate fix. Guard it.
      expect(source, isNot(contains('ValueKey:')),
          reason: '\'IndexedStack index: ValueKey(_currentNavIndex)\' resets '
              'every tab on each tap, losing scroll & state');
    });

    test('FAB renders only on tab 0', () {
      expect(source, contains(
          'floatingActionButton: _currentNavIndex == 0 ? _buildFab() : null,'));
    });

    test('IndexedStack has exactly the five tabs', () {
      final rs = source.indexOf('return IndexedStack(');
      final from = source.indexOf('children: [', rs);
      final to = source.indexOf('],', from);
      final children = source.substring(from, to);

      expect(children, contains('_buildChatHome()'));
      expect(children, contains('const CallHistoryPage()'));
      expect(children, contains('_buildStatusPlaceholder()'));
      expect(children, contains('_buildScheduleTab()'));
      expect(children, contains('const YouProfileScreen()'));
    });
  });
}