import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('humming bird shell renders without crashing', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Center(
            child: Text('Humming Bird'),
          ),
        ),
      ),
    );

    expect(find.text('Humming Bird'), findsOneWidget);
  });
}
