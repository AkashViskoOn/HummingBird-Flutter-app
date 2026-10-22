import 'dart:convert';

/// One row of `GET /user/linked-devices`.
///
/// Mirrors `DevicePairingService::publicDevice()` exactly, which returns:
///
/// ```php
/// ['device_id' => int, 'platform' => string, 'device_name' => string,
///  'browser' => string, 'app_version' => string, 'status' => string,
///  'created_at' => string, 'last_seen' => string, 'revoked_at' => string]
/// ```
///
/// Note what is NOT here: there is no `is_current`. The server cannot know which
/// row is the caller's own device, because a phone JWT carries only `user_id`
/// and `user_mobile_num` — no `device_id` claim (only a paired desktop gets
/// one). So this class deliberately has no "is current" flag; inventing one is
/// what made the previous version of this screen lie to the user.
class LinkedDevice {
  final int deviceId;
  final String platform;
  final String? deviceName;
  final String? browser;
  final String? appVersion;
  final String status;
  final DateTime? createdAt;
  final DateTime? lastSeen;
  final DateTime? revokedAt;

  const LinkedDevice({
    required this.deviceId,
    required this.platform,
    this.deviceName,
    this.browser,
    this.appVersion,
    required this.status,
    this.createdAt,
    this.lastSeen,
    this.revokedAt,
  });

  bool get isRevoked => status == 'revoked';

  /// "Chrome on Windows", or a sensible fallback when the desktop sent neither.
  String get displayName {
    final name = deviceName?.trim();
    if (name != null && name.isNotEmpty) return name;
    final os = browser?.trim();
    if (os != null && os.isNotEmpty) return os;
    return 'Unknown device';
  }

  /// The second line under the name. Avoids a lonely "null • null".
  String get subtitleParts {
    final parts = <String>[];
    final b = browser?.trim();
    final v = appVersion?.trim();
    if (b != null && b.isNotEmpty) parts.add(b);
    if (v != null && v.isNotEmpty) parts.add('v$v');
    return parts.join(' • ');
  }

  factory LinkedDevice.fromJson(Map<String, dynamic> json) {
    return LinkedDevice(
      deviceId: _asInt(json['device_id']) ?? 0,
      platform: (json['platform'] ?? 'unknown').toString(),
      deviceName: _asString(json['device_name']),
      browser: _asString(json['browser']),
      appVersion: _asString(json['app_version']),
      status: (json['status'] ?? 'active').toString(),
      createdAt: parseServerDateTime(json['created_at']),
      lastSeen: parseServerDateTime(json['last_seen']),
      revokedAt: parseServerDateTime(json['revoked_at']),
    );
  }

  static String? _asString(dynamic value) {
    if (value == null) return null;
    final text = value.toString().trim();
    return text.isEmpty ? null : text;
  }

  static int? _asInt(dynamic value) {
    if (value is int) return value;
    if (value is String) return int.tryParse(value);
    return null;
  }

  /// Server datetimes are UTC `YYYY-MM-DD HH:MM:SS` with no zone suffix, so
  /// `DateTime.parse` would read them as LOCAL time and land the user in the
  /// wrong timezone. Parse as UTC, then convert.
  static DateTime? parseServerDateTime(dynamic value) {
    final text = _asString(value);
    if (text == null || text.isEmpty) return null;
    final parsed = DateTime.tryParse(text.contains('T') ? text : text.replaceFirst(' ', 'T'));
    if (parsed == null) return null;
    return parsed.isUtc ? parsed.toLocal() : DateTime.utc(
          parsed.year,
          parsed.month,
          parsed.day,
          parsed.hour,
          parsed.minute,
          parsed.second,
        ).toLocal();
  }
}

/// A desktop pairing request parsed out of a scanned QR image.
///
/// The desktop renders a JSON payload (see the Nuxt `pairingPayload` helper):
///
/// ```json
/// { "v": 1, "type": "hb-desktop-pairing", "ref": "<32 hex>", "ch": "<32 hex>", "sk": "<48 hex>" }
/// ```
///
/// `sk` is the desktop's one-time claim secret. The phone does NOT need it and
/// must never send it anywhere — the desktop already holds it, and the server
/// stored only its hash. It is deliberately not a field on this class, so it is
/// structurally impossible for the approve call to leak it.
///
/// Parsing is strict on purpose: a QR that is not a well-formed pairing request
/// must be rejected with a clear message rather than POSTed as an opaque string,
/// which is what the old `save-secret-key` flow did.
class DesktopPairingRequest {
  /// Payload type tag the desktop writes. Guards against scanning an unrelated
  /// QR (a payment code, a contact card) and getting a confusing 400 back.
  static const String type = 'hb-desktop-pairing';

  /// Only version 1 exists. A future format must not be parsed by guesswork.
  static const int supportedVersion = 1;

  final int version;
  final String pairingRef;
  final String challenge;

  /// 32 lowercase hex characters, as produced by the server's `randomHex(16)`.
  static final RegExp _hex32 = RegExp(r'^[0-9a-f]{32}$');

  const DesktopPairingRequest({
    required this.version,
    required this.pairingRef,
    required this.challenge,
  });

  /// Throws [FormatException] with a user-presentable reason.
  ///
  /// `FormatException.message` is written to be shown directly, because these
  /// failures are almost always "the user scanned the wrong thing".
  factory DesktopPairingRequest.parse(String raw) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty) {
      throw const FormatException('That QR code was empty. Try scanning the code on your computer.');
    }

    Object? decoded;
    try {
      decoded = jsonDecode(trimmed);
    } on FormatException {
      throw const FormatException(
        "That doesn't look like a Humming Bird pairing code. Scan the code shown on your computer.",
      );
    }

    if (decoded is! Map) {
      throw const FormatException(
        "That doesn't look like a Humming Bird pairing code. Scan the code shown on your computer.",
      );
    }

    final map = Map<String, dynamic>.from(decoded);

    if (map['type'] != type) {
      throw const FormatException('This QR code is not a Humming Bird device link.');
    }

    final version = map['v'] is int ? map['v'] as int : int.tryParse('${map['v']}');
    if (version == null || version != supportedVersion) {
      throw FormatException(
        'This pairing code uses an unsupported format (v${map['v']}). '
        'Update the Humming Bird app and try again.',
      );
    }

    final ref = '${map['ref'] ?? ''}';
    final challenge = '${map['ch'] ?? ''}';

    if (!_hex32.hasMatch(ref) || !_hex32.hasMatch(challenge)) {
      throw const FormatException('This pairing code looks damaged. Generate a new code on your computer.');
    }

    return DesktopPairingRequest(
      version: version,
      pairingRef: ref,
      challenge: challenge,
    );
  }
}
