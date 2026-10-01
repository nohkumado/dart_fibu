import 'dart:convert';
import 'dart:typed_data';

import 'package:cryptography/cryptography.dart';

import '../../nohfibu.dart';

/// Seals and opens the lines of a book's history with its [LedgerKey]:
/// AES-256-GCM, a fresh nonce per line, [aad] (the device's name) bound in
/// so a line cannot be moved to another device's file unnoticed.
class LedgerCipher {
  static final _aes = AesGcm.with256bits();
  final SecretKey _key;

  LedgerCipher(LedgerKey key) : _key = SecretKey(key.bytes);

  /// [text] sealed: base64url(nonce ‖ ciphertext ‖ tag).
  Future<String> seal(String text, {String aad = ''}) async {
    final box = await _aes.encrypt(utf8.encode(text), secretKey: _key, aad: utf8.encode(aad));
    return base64Url.encode(box.concatenation());
  }

  /// The text of a sealed line; throws [LedgerCipherException] when it was
  /// not sealed with this key and [aad], or was altered.
  Future<String> open(String sealed, {String aad = ''}) async {
    try {
      final box = SecretBox.fromConcatenation(Uint8List.fromList(base64Url.decode(sealed.trim())),
          nonceLength: _aes.nonceLength, macLength: _aes.macAlgorithm.macLength);
      return utf8.decode(await _aes.decrypt(box, secretKey: _key, aad: utf8.encode(aad)));
    } catch (_) {
      throw const LedgerCipherException('a line that does not open with this key');
    }
  }
}

/// A sealed line that does not open (other key, other device, altered).
class LedgerCipherException implements Exception {
  final String message;
  const LedgerCipherException(this.message);

  @override
  String toString() => 'LedgerCipherException: $message';
}
