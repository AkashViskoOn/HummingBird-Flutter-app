import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:humming_bird/main.dart' as app;
import 'package:integration_test/integration_test.dart';

/// Real-device launch smoke test.
///
/// This does NOT require backend credentials: it only verifies the app
/// boots, runs its async init (Hive, GetStorage, Firebase silent init,
/// background service) and renders its first screen without crashing.
///
/// Full chat/schedule integration flows require a logged-in session and are
/// covered by manual device verification (see PENDING_DEPLOY.md smoke list).
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('app launches and renders first screen without crashing',
      (tester) async {
    app.main();

    // Give async init (Hive/GetStorage/Firebase/background service) time to
    // settle without depending on network or a real login session.
    await tester.pump(const Duration(seconds: 2));
    await tester.pump(const Duration(seconds: 2));
    await tester.pump(const Duration(seconds: 1));

    expect(tester.takeException(), isNull,
        reason: 'app threw during startup or first frame');

    expect(find.byType(MaterialApp), findsWidgets,
        reason: 'GetMaterialApp root must be on the tree');
  });
}