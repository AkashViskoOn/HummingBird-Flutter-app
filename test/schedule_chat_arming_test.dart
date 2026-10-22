import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Regression guard for scheduling a message from the chat / group
/// "Schedule Message" bottom sheet (`_ScheduleSheetPanel`).
///
/// The bottom sheet submits through `ChatController.setDateAndTime`, which
/// arms the schedule state and then runs `sendMessage` on the next frame.
/// `sendMessage` reads `isScheduledMessage` (and `scheduledMessageDateTime`)
/// **synchronously** while it builds the request payload to decide between a
/// scheduled store and an immediate send. An earlier revision armed the flag,
/// deferred the send to `addPostFrameCallback`, then reset the flag to `'0'`
/// *synchronously* — so by the time the callback ran the message was always
/// sent immediately and never scheduled. The main Schedule screen never hit
/// this because it calls `sendMessage` directly after arming.
///
/// These assertions pin that contract: the reset must live inside the deferred
/// callback's `finally`, never between the `else` block and the callback.
/// It is a static, source-level guard on purpose — instantiating the real
/// controller pulls in the socket, Hive and GetStorage, which the platform
/// test environment does not stand up.
void main() {
  late String source;

  setUpAll(() {
    // Normalise CRLF so the brace-based slicing below is line-ending agnostic.
    source = File('lib/controllers/chat_controller.dart')
        .readAsStringSync()
        .replaceAll('\r\n', '\n');
  });

  String setDateAndTimeBody() {
    final start = source.indexOf('void setDateAndTime(');
    expect(start, greaterThanOrEqualTo(0),
        reason: 'setDateAndTime must exist in chat_controller.dart');
    // The method closes at the first line that is exactly two-space + brace.
    final end = source.indexOf('\n  }\n', start);
    expect(end, greaterThan(start));
    return source.substring(start, end);
  }

  group('chat/group schedule arming', () {
    test('defers the send through addPostFrameCallback', () {
      expect(setDateAndTimeBody(), contains('addPostFrameCallback'));
    });

    test('releases the schedule flag only after the deferred send', () {
      final body = setDateAndTimeBody();
      final callback = body.indexOf('addPostFrameCallback');
      final callbackClose = body.indexOf('});', callback);
      expect(callbackClose, greaterThan(callback),
          reason: 'the deferred callback must be closed with `});`');

      final afterCallback = body.substring(callbackClose);
      // The flag must survive until the callback has built its payload.
      expect(afterCallback, isNot(contains("isScheduledMessage.value = '0'")),
          reason: 'resetting isScheduledMessage after the callback returns '
              'makes sendMessage build an immediate payload — every chat/group '
              'schedule would leave now instead of at the picked time');
      // ...and the reset must actually happen on completion.
      expect(body, contains("isScheduledMessage.value = '0'"),
          reason: 'the schedule flag must still be released once the send '
              'finishes, or the next composer send stays in schedule mode');
      expect(afterCallback, contains('_safePopRoute()'));
    });
  });
}
