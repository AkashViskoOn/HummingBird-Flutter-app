import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:humming_bird/models/linked_device_model.dart';

/// Pure-Dart tests for the linked-device payload contract.
///
/// No widgets, so no GoogleFonts stub and no path_provider mock is needed
/// (see AGENTS.md: only tests that render a real widget need the font stub).
///
/// The QR parser is the security boundary of this feature: anything it accepts
/// is forwarded to `POST /user/desktop-pairing/approve`, so the negative cases
/// matter as much as the happy path.
void main() {
  const goodRef = 'a1b2c3d4e5f60718293a4b5c6d7e8f90';
  const goodChallenge = '0f1e2d3c4b5a69788796a5b4c3d2e1f0';

  String qr({String type = 'hb-desktop-pairing', int v = 1, String ref = goodRef, String ch = goodChallenge}) {
    return jsonEncode({'v': v, 'type': type, 'ref': ref, 'ch': ch, 'sk': 'ab' * 24});
  }

  group('DesktopPairingRequest.parse', () {
    test('parses a real desktop payload', () {
      final request = DesktopPairingRequest.parse(qr());
      expect(request.version, 1);
      expect(request.pairingRef, goodRef);
      expect(request.challenge, goodChallenge);
    });

    test('never exposes the claim secret sk to the caller', () {
      // The phone must not be able to send the desktop's one-time secret. It is
      // deliberately absent from the parsed object, so the approve call cannot
      // leak it even by accident.
      final request = DesktopPairingRequest.parse(qr());
      expect(request.toString(), isNot(contains('ab' * 24)));
    });

    test('rejects a non-Humming-Bird QR', () {
      // Scanning a payment code or a contact card must fail with a clear
      // message, not POST an opaque string to the pairing endpoint.
      expect(
        () => DesktopPairingRequest.parse(qr(type: 'whatsapp-pairing')),
        throwsA(isA<FormatException>()),
      );
    });

    test('rejects an unsupported version instead of guessing', () {
      expect(
        () => DesktopPairingRequest.parse(qr(v: 2)),
        throwsA(isA<FormatException>()),
      );
    });

    test('rejects a missing or malformed ref/challenge', () {
      expect(() => DesktopPairingRequest.parse(qr(ref: '')), throwsA(isA<FormatException>()));
      expect(() => DesktopPairingRequest.parse(qr(ch: '')), throwsA(isA<FormatException>()));
      // Uppercase hex is not what the server emits; refuse rather than normalise.
      expect(() => DesktopPairingRequest.parse(qr(ref: goodRef.toUpperCase())), throwsA(isA<FormatException>()));
      expect(() => DesktopPairingRequest.parse(qr(ref: 'short')), throwsA(isA<FormatException>()));
    });

    test('rejects a non-JSON / empty scan', () {
      expect(() => DesktopPairingRequest.parse('not json'), throwsA(isA<FormatException>()));
      expect(() => DesktopPairingRequest.parse(''), throwsA(isA<FormatException>()));
      expect(() => DesktopPairingRequest.parse('"a string"'), throwsA(isA<FormatException>()));
    });

    test('accepts a v sent as a string', () {
      // Tolerated deliberately: a future desktop build may serialise it loosely.
      final request = DesktopPairingRequest.parse(
        jsonEncode({'v': '1', 'type': 'hb-desktop-pairing', 'ref': goodRef, 'ch': goodChallenge}),
      );
      expect(request.version, 1);
    });
  });

  group('LinkedDevice.fromJson', () {
    test('reads the exact publicDevice() shape', () {
      final device = LinkedDevice.fromJson({
        'device_id': 7,
        'platform': 'windows',
        'device_name': 'Chrome on Windows',
        'browser': 'Chrome',
        'app_version': '0.1.0',
        'status': 'active',
        'created_at': '2026-09-30 10:00:00',
        'last_seen': '2026-09-30 10:05:00',
        'revoked_at': null,
      });

      expect(device.deviceId, 7);
      expect(device.platform, 'windows');
      expect(device.displayName, 'Chrome on Windows');
      expect(device.subtitleParts, 'Chrome • v0.1.0');
      expect(device.isRevoked, isFalse);
    });

    test('treats server datetimes as UTC, not local', () {
      // `DateTime.parse` on a zoneless string reads it as LOCAL time, which
      // shifts the user into the wrong timezone. The model must convert.
      final device = LinkedDevice.fromJson({
        'device_id': 1,
        'platform': 'macos',
        'status': 'active',
        'last_seen': '2026-09-30 10:05:00',
      });
      expect(device.lastSeen, isNotNull);
      expect(device.lastSeen!.isUtc, isFalse, reason: 'converted to local');
      expect(device.lastSeen!.hour, DateTime.utc(2026, 9, 30, 10, 5).toLocal().hour);
    });

    test('falls back to a browser name when the desktop sent no device_name', () {
      final device = LinkedDevice.fromJson({
        'device_id': 2,
        'platform': 'linux',
        'browser': 'Firefox',
        'status': 'active',
      });
      expect(device.displayName, 'Firefox');
    });

    test('marks a revoked device', () {
      final device = LinkedDevice.fromJson({
        'device_id': 3,
        'platform': 'windows',
        'status': 'revoked',
        'revoked_at': '2026-09-30 11:00:00',
      });
      expect(device.isRevoked, isTrue);
      expect(device.displayName, 'Unknown device');
      expect(device.subtitleParts, '');
    });

    test('ignores an is_current flag rather than surfacing it', () {
      // The phone JWT has no device_id claim and the real payload has no
      // is_current, so the model exposes no "this device" notion at all. If the
      // server ever adds the field, this proves we do not silently start
      // labelling rows with it — a badge we cannot verify is a lie.
      final device = LinkedDevice.fromJson({
        'device_id': 4,
        'platform': 'windows',
        'status': 'active',
        'is_current': true,
      });
      expect(device.deviceId, 4);
      expect(device.toString(), isNot(contains('current')));
    });
  });
}
