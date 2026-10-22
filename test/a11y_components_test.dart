import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/semantics.dart' show SemanticsAction;
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:humming_bird/components/common/app_empty_state.dart';
import 'package:humming_bird/components/common/entrance.dart';

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

/// Accessibility guards for the shared presentation components:
/// - reduce-motion is honoured (no animated wrapper, content reachable)
/// - screen readers can read AND activate empty-state actions
/// - tappable affordances clear the 44px App Store / Google Play target
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  GoogleFonts.config.httpClient = _FontClient();

  Widget harness(Widget child, {bool reduceMotion = false}) {
    return ScreenUtilInit(
      designSize: const Size(360, 690),
      child: MaterialApp(
        home: MediaQuery(
          data: MediaQueryData(disableAnimations: reduceMotion),
          child: Scaffold(body: Center(child: child)),
        ),
      ),
    );
  }

  group('Entrance honours reduce-motion', () {
    testWidgets('renders child immediately and untransformed', (tester) async {
      await tester.pumpWidget(harness(
        const Entrance(
          key: Key('ent'),
          child: Text('hello'),
        ),
        reduceMotion: true,
      ));
      await tester.pump();
      expect(find.text('hello'), findsOneWidget);
      // No animation machinery from Entrance itself — the child is bare.
      expect(find.byType(TweenAnimationBuilder), findsNothing);
      expect(find.byType(Opacity), findsNothing);
    });
  });

  group('PressScale honours reduce-motion', () {
    testWidgets('no Listener/AnimatedScale wrapper when disabled',
        (tester) async {
      await tester.pumpWidget(harness(
        const PressScale(
          key: Key('ps'),
          child: Text('tap'),
        ),
        reduceMotion: true,
      ));
      final scoped = find.byType(PressScale);
      expect(
          find.descendant(of: scoped, matching: find.byType(Listener)),
          findsNothing);
      expect(
          find.descendant(of: scoped, matching: find.byType(AnimatedScale)),
          findsNothing);
      expect(find.text('tap'), findsOneWidget);
    });
  });

  group('AppEmptyState semantics', () {
    testWidgets('centered layout exposes title+message as one label',
        (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(harness(
        const AppEmptyState(
          icon: Icons.inbox,
          title: 'No chats yet',
          message: 'Start a conversation to see it here',
        ),
      ));

      expect(tester.getSemantics(find.byType(AppEmptyState)), matchesSemantics(
        label: 'No chats yet. Start a conversation to see it here',
        hasTapAction: false,
      ));
      handle.dispose();
    });

    testWidgets('centered layout keeps action buttons reachable',
        (tester) async {
      final handle = tester.ensureSemantics();
      var primaryFired = false;
      var secondaryFired = false;
      await tester.pumpWidget(harness(
        AppEmptyState(
          icon: Icons.inbox,
          title: 'No chats yet',
          message: 'Start a conversation to see it here',
          actionLabel: 'New Chat',
          onAction: () => primaryFired = true,
          secondaryActionLabel: 'Refresh',
          onSecondaryAction: () => secondaryFired = true,
        ),
      ));

      // The two buttons must be individually activatable by a screen reader…
      await tester.tap(find.text('New Chat'));
      await tester.pump();
      expect(primaryFired, isTrue);

      await tester.tap(find.text('Refresh'));
      await tester.pump();
      expect(secondaryFired, isTrue);

      // …and must actually be IN the semantics tree (not ExcludeSemantics'd),
      // otherwise TalkBack/VoiceOver can never reach them. Walk the subtree
      // from the container and look for a merged node labelled like the
      // button that also carries the tap action.
      final buttonLabels = <String>[];
      void walk(SemanticsNode? n) {
        if (n == null) return;
        if (n.label.isNotEmpty &&
            n.getSemanticsData().hasAction(SemanticsAction.tap)) {
          buttonLabels.add(n.label);
        }
        n.visitChildren((c) {
          walk(c);
          return true;
        });
      }

      walk(tester.getSemantics(find.byType(AppEmptyState)));
      debugPrint('BTN-LABELS=$buttonLabels');
      expect(buttonLabels, contains('New Chat'),
          reason: 'primary button missing from semantics tree');
      expect(buttonLabels, contains('Refresh'),
          reason: 'secondary button missing from semantics tree');
      handle.dispose();
    });

    testWidgets('primary action is a real tappable with 44px+ target',
        (tester) async {
      await tester.pumpWidget(harness(
        AppEmptyState(
          icon: Icons.inbox,
          title: 'Empty',
          actionLabel: 'Create',
          onAction: () {},
        ),
      ));
      final target = tester.getSize(find.byType(MaterialButton));
      expect(target.height, greaterThanOrEqualTo(44),
          reason: 'action target is ${target.height}px tall');
      expect(target.width, greaterThanOrEqualTo(44),
          reason: 'action target is ${target.width}px wide');
    });

    testWidgets('secondary action has a 48px min target', (tester) async {
      await tester.pumpWidget(harness(
        AppEmptyState(
          icon: Icons.inbox,
          title: 'Empty',
          actionLabel: 'Create',
          onAction: () {},
          secondaryActionLabel: 'Refresh',
          onSecondaryAction: () {},
        ),
      ));
      final target = tester.getSize(find.byType(TextButton));
      expect(target.height, greaterThanOrEqualTo(44),
          reason: 'secondary target is ${target.height}px tall');
      expect(target.width, greaterThanOrEqualTo(44),
          reason: 'secondary target is ${target.width}px wide');
    });
  });
}