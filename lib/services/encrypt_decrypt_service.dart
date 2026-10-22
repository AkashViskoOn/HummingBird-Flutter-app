import 'dart:convert';
import 'dart:math';

import 'package:blowfish/blowfish.dart';
import 'package:dart_des/dart_des.dart';
import 'package:encrypt/encrypt.dart';
import 'package:flutter/foundation.dart' hide Key;
import 'package:simple_rc4/simple_rc4.dart';

// ── Top-level functions required by compute() (must not capture instance state) ─

String _encryptInIsolate(String message) =>
    EncryptionHelper()._encryptSync(message);

String _decryptInIsolate(String message) =>
    EncryptionHelper()._decryptSync(message);

List<String> _decryptListInIsolate(List<String> messages) =>
    messages.map(EncryptionHelper()._decryptSync).toList();

// ─────────────────────────────────────────────────────────────────────────────

class EncryptionHelper {
  // Cached key/IV objects — built once per isolate invocation, avoiding
  // the allocation cost on every single message operation.
  static final _aesKey = Key.fromUtf8('12345678901234567890123456789001');
  static final _salsaKey = Key.fromUtf8('32characterslongsecretkeyhere!11');
  static final _salsaIV = IV(Uint8List.fromList(utf8.encode('8bytesiv')));
  static final _blowfishKeyBytes = utf8.encode('myblowfishsecretkey');
  static final _blowfishIVBytes = utf8.encode('12345678');
  static final _desKeyUnits = 'mytripledeskey1234567890'.codeUnits;
  static final _desIVUnits = '23128309'.codeUnits;

  // ── Public async API (offloads to a background isolate) ──────────────────

  static Future<String> encryptAsync(String message) =>
      compute(_encryptInIsolate, message);

  static Future<String> decryptAsync(String message) =>
      compute(_decryptInIsolate, message);

  /// Decrypts a whole list of messages in one isolate hop — far cheaper than
  /// calling [decryptAsync] once per message when loading a chat.
  static Future<List<String>> decryptListAsync(List<String> messages) =>
      compute(_decryptListInIsolate, messages);

  // ── Synchronous methods (used inside isolates only) ──────────────────────

  String encryptMessage(String message) => _encryptSync(message);
  String decryptMessage(String message) => _decryptSync(message);

  String _encryptSync(String message) {
    try {
      final iv = _generateRandomIV();
      final encrypted =
          Encrypter(AES(_aesKey, mode: AESMode.cbc, padding: 'PKCS7'))
              .encrypt(message, iv: iv);
      final combined = iv.bytes + encrypted.bytes;
      final aesEncrypted = base64Encode(combined);

      final salsaEncrypted = _salsa20Encrypt(aesEncrypted);
      final blowfishEncrypted = _blowFishEncrypt(salsaEncrypted);
      final tripleDesEncrypted = _tripleDESEncrypt(blowfishEncrypted);
      return _rc4Encrypt(tripleDesEncrypted);
    } catch (e) {
      return '';
    }
  }

  String _decryptSync(String encryptedMessage) {
    try {
      final rc4Decrypted = _rc4Decrypt(encryptedMessage);
      final tripleDesDecrypted = _tripleDESDecrypt(rc4Decrypted);
      final blowFishDecrypted = _blowFishDecrypt(tripleDesDecrypted);
      final salsaDecrypted = _salsa20Decrypt(blowFishDecrypted);
      final combined = base64Decode(salsaDecrypted);

      final ivBytes = combined.sublist(0, 16);
      final encryptedBytes = combined.sublist(16);
      final iv = IV(Uint8List.fromList(ivBytes));

      return Encrypter(AES(_aesKey, mode: AESMode.cbc, padding: 'PKCS7'))
          .decrypt(Encrypted(encryptedBytes), iv: iv);
    } catch (e) {
      return '';
    }
  }

  // ── Private cipher helpers ────────────────────────────────────────────────

  static IV _generateRandomIV() {
    final random = Random.secure();
    return IV(
        Uint8List.fromList(List<int>.generate(16, (_) => random.nextInt(256))));
  }

  String _salsa20Encrypt(String message) {
    final encrypter = Encrypter(Salsa20(_salsaKey));
    return base64Encode(encrypter.encrypt(message, iv: _salsaIV).bytes);
  }

  String _salsa20Decrypt(String encryptedMessage) {
    final encrypter = Encrypter(Salsa20(_salsaKey));
    return encrypter.decrypt64(encryptedMessage, iv: _salsaIV);
  }

  String _blowFishEncrypt(String message) {
    final blowfish = newBlowfish(_blowfishKeyBytes);
    return base64Encode(blowfish.encryptCBC(
        utf8.encode(message), _blowfishIVBytes,
        applyPadding: true));
  }

  String _blowFishDecrypt(String encrypted) {
    final blowfish = newBlowfish(_blowfishKeyBytes);
    return utf8.decode(blowfish.decryptCBC(
        base64Decode(encrypted), _blowfishIVBytes,
        applyPadding: true));
  }

  String _tripleDESEncrypt(String message) {
    final des3 = DES3(
        key: _desKeyUnits,
        mode: DESMode.CBC,
        iv: _desIVUnits,
        paddingType: DESPaddingType.PKCS7);
    return base64Encode(des3.encrypt(message.codeUnits));
  }

  String _tripleDESDecrypt(String encrypted) {
    final des3 = DES3(
        key: _desKeyUnits,
        mode: DESMode.CBC,
        iv: _desIVUnits,
        paddingType: DESPaddingType.PKCS7);
    return utf8.decode(des3.decrypt(base64Decode(encrypted)));
  }

  String _rc4Encrypt(String message) {
    final rc4 = RC4('myrc4secretkey');
    return base64UrlEncode(rc4.encodeBytes(utf8.encode(message)));
  }

  String _rc4Decrypt(String message) {
    final rc4 = RC4('myrc4secretkey');
    return rc4.decodeString(message);
  }
}
