import 'package:flutter_test/flutter_test.dart';
import 'package:humming_bird/services/encrypt_decrypt_service.dart';

/// Round-trip guards for the client-side 5-layer cascade
/// (AES-256-CBC -> Salsa20 -> Blowfish -> 3DES -> RC4).
///
/// The whole point of the service is: what [encrypt*] produces, [decrypt*]
/// must hand back, and a failure must degrade to empty rather than throw —
/// because message loaders and senders depend on that never-throw contract.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('EncryptionHelper round-trip (sync)', () {
    test('text survives encrypt+decrypt unchanged', () {
      const sample = 'hello humming bird';
      final cipher = EncryptionHelper().encryptMessage(sample);
      expect(cipher, isNotEmpty);
      expect(cipher, isNot(sample));
      expect(EncryptionHelper().decryptMessage(cipher), sample);
    });

    test('unicode and emoji survive the cascade', () {
      const sample = 'नमस्ते 🐦 déjà vu — ünicode ✓';
      final cipher = EncryptionHelper().encryptMessage(sample);
      expect(EncryptionHelper().decryptMessage(cipher), sample);
    });

    test('long message survives the cascade', () {
      final sample = 'x' * 10000;
      final cipher = EncryptionHelper().encryptMessage(sample);
      expect(EncryptionHelper().decryptMessage(cipher), sample);
    });

    test('same plaintext produces different ciphertext (random AES IV)', () {
      const sample = 'never the same twice';
      final a = EncryptionHelper().encryptMessage(sample);
      final b = EncryptionHelper().encryptMessage(sample);
      expect(a, isNot(b));
      expect(EncryptionHelper().decryptMessage(a), sample);
      expect(EncryptionHelper().decryptMessage(b), sample);
    });

    test('garbage input decrypts to empty, never throws', () {
      expect(EncryptionHelper().decryptMessage('not-ciphertext'), '');
      expect(EncryptionHelper().decryptMessage(''), '');
    });

    test('empty input round-trips', () {
      final cipher = EncryptionHelper().encryptMessage('');
      expect(EncryptionHelper().decryptMessage(cipher), '');
    });
  });

  group('EncryptionHelper round-trip (async isolate)', () {
    test('encryptAsync + decryptAsync round-trip', () async {
      const sample = 'async isolate message';
      final cipher = await EncryptionHelper.encryptAsync(sample);
      expect(cipher, isNotEmpty);
      final restored = await EncryptionHelper.decryptAsync(cipher);
      expect(restored, sample);
    });

    test('decryptListAsync round-trips a batch with unicode', () async {
      const samples = <String>['one', 'दो', '🐦 three', ''];
      final ciphers = <String>[
        for (final s in samples) EncryptionHelper().encryptMessage(s),
      ];
      final restored = await EncryptionHelper.decryptListAsync(ciphers);
      expect(restored, samples);
    });

    test('decryptListAsync returns empties for corrupt entries, still batch',
        () async {
      final restored = await EncryptionHelper.decryptListAsync(<String>[
        EncryptionHelper().encryptMessage('good'),
        'garbage',
        EncryptionHelper().encryptMessage(''),
      ]);
      expect(restored, <String>['good', '', '']);
    });
  });
}