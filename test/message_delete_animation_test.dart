import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:humming_bird/components/chat_ui/message_delete_animation.dart';

Widget _harness({
  required GlobalKey key,
  required String id,
  required bool deleted,
  required bool removing,
  VoidCallback? onRemoveComplete,
}) {
  return MaterialApp(
    home: Scaffold(
      body: MessageDeleteAnimation(
        key: key,
        messageId: id,
        deleted: deleted,
        removing: removing,
        onRemoveComplete: onRemoveComplete,
        content: const ColoredBox(
          color: Colors.cyan,
          child: SizedBox(
            width: 220,
            height: 64,
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text('hello-content'),
            ),
          ),
        ),
        placeholder: const ColoredBox(
          color: Colors.grey,
          child: SizedBox(
            width: 220,
            height: 64,
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text('deleted-placeholder'),
            ),
          ),
        ),
      ),
    ),
  );
}

void main() {
  testWidgets('live content shows while not deleted', (tester) async {
    await tester.pumpWidget(
      _harness(
        key: GlobalKey(),
        id: 't1',
        deleted: false,
        removing: false,
      ),
    );
    expect(find.text('hello-content'), findsOneWidget);
    expect(find.text('deleted-placeholder'), findsNothing);
  });

  testWidgets('already-deleted message renders placeholder, no animation',
      (tester) async {
    await tester.pumpWidget(
      _harness(
        key: GlobalKey(),
        id: 't2',
        deleted: true,
        removing: false,
      ),
    );
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.text('deleted-placeholder'), findsOneWidget);
    expect(find.text('hello-content'), findsNothing);
  });

  testWidgets('deleted flip dissolves into placeholder (no capture fallback)',
      (tester) async {
    final key = GlobalKey();
    await tester.pumpWidget(
      _harness(
        key: key,
        id: 't3',
        deleted: false,
        removing: false,
      ),
    );
    await tester.pumpWidget(
      _harness(
        key: key,
        id: 't3',
        deleted: true,
        removing: false,
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));
    expect(find.text('hello-content'), findsWidgets);
    expect(find.text('deleted-placeholder'), findsNothing);
    await tester.pumpAndSettle();
    expect(find.text('deleted-placeholder'), findsOneWidget);
    expect(find.text('hello-content'), findsNothing);
  });

  testWidgets('duplicate deleted events stay idempotent', (tester) async {
    final key = GlobalKey();
    await tester.pumpWidget(
      _harness(
        key: key,
        id: 't4',
        deleted: false,
        removing: false,
      ),
    );
    await tester.pumpWidget(
      _harness(
        key: key,
        id: 't4',
        deleted: true,
        removing: false,
      ),
    );
    await tester.pumpAndSettle();
    await tester.pumpWidget(
      _harness(
        key: key,
        id: 't4',
        deleted: true,
        removing: false,
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('deleted-placeholder'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('removing flip plays removal and fires onRemoveComplete',
      (tester) async {
    final key = GlobalKey();
    int removed = 0;
    await tester.pumpWidget(
      _harness(
        key: key,
        id: 't5',
        deleted: false,
        removing: false,
        onRemoveComplete: () => removed++,
      ),
    );
    await tester.pumpWidget(
      _harness(
        key: key,
        id: 't5',
        deleted: false,
        removing: true,
        onRemoveComplete: () => removed++,
      ),
    );
    await tester.pump(const Duration(milliseconds: 200));
    expect(removed, 0);
    await tester.pumpAndSettle();
    expect(removed, 1);
    expect(find.text('hello-content'), findsNothing);
    expect(find.text('deleted-placeholder'), findsNothing);
  });

  testWidgets('initial removing state animates and removes without a flip',
      (tester) async {
    final key = GlobalKey();
    int removed = 0;
    await tester.pumpWidget(
      _harness(
        key: key,
        id: 't6',
        deleted: false,
        removing: true,
        onRemoveComplete: () => removed++,
      ),
    );
    await tester.pump(const Duration(milliseconds: 200));
    expect(removed, 0);
    await tester.pumpAndSettle();
    expect(removed, 1);
    expect(find.text('hello-content'), findsNothing);
  });

  testWidgets('unmounting mid-animation does not throw or set state',
      (tester) async {
    final key = GlobalKey();
    await tester.pumpWidget(
      _harness(
        key: key,
        id: 't7',
        deleted: false,
        removing: false,
      ),
    );
    await tester.pumpWidget(
      _harness(
        key: key,
        id: 't7',
        deleted: true,
        removing: false,
      ),
    );
    await tester.pump(const Duration(milliseconds: 250));
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(milliseconds: 600));
    expect(tester.takeException(), isNull);
  });
}