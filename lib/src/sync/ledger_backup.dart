import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:cryptography/cryptography.dart';

import '../../nohfibu.dart';

/// A whole history in one file, protected by a passphrase — independent of
/// any device's key, so it restores on a new phone or computer:
/// `{"format": 1, "kdf": "pbkdf2-sha256", "iterations": …, "salt": …,
/// "data": base64(nonce ‖ AES-256-GCM(changes) ‖ tag)}`.
class LedgerBackup {
  const LedgerBackup._();

  static final _aes = AesGcm.with256bits();

  static Future<SecretKey> _derive(String passphrase, List<int> salt, int iterations) =>
      Pbkdf2(macAlgorithm: Hmac.sha256(), iterations: iterations, bits: 256)
          .deriveKey(secretKey: SecretKey(utf8.encode(passphrase)), nonce: salt);

  /// The backup of [graph] under [passphrase] (as text, to save anywhere).
  static Future<String> export(ChangeGraph graph, String passphrase, {int iterations = 600000}) async {
    final r = Random.secure();
    final salt = List.generate(16, (_) => r.nextInt(256));
    final key = await _derive(passphrase, salt, iterations);
    final payload = utf8.encode(jsonEncode([for (final c in graph.ordered()) c.toJson()]));
    final box = await _aes.encrypt(payload, secretKey: key, aad: utf8.encode('nohfibu-backup-1'));
    return const JsonEncoder.withIndent('  ').convert({
      'format': 1,
      'software': 'nohfibu ${BookFormat.software}',
      'kdf': 'pbkdf2-sha256',
      'iterations': iterations,
      'salt': base64Url.encode(salt),
      'changes': graph.length,
      'data': base64Url.encode(box.concatenation()),
    });
  }

  /// The changes of a backup; throws [LedgerCipherException] for a wrong
  /// passphrase or a damaged file.
  static Future<List<Change>> restore(String text, String passphrase) async {
    final j = jsonDecode(text) as Map<String, dynamic>;
    if (j['format'] != 1) throw FormatException('backup format ${j['format']} unknown');
    final key = await _derive(passphrase, base64Url.decode('${j['salt']}'), (j['iterations'] as num).toInt());
    final List<int> clear;
    try {
      final box = SecretBox.fromConcatenation(Uint8List.fromList(base64Url.decode('${j['data']}')),
          nonceLength: _aes.nonceLength, macLength: _aes.macAlgorithm.macLength);
      clear = await _aes.decrypt(box, secretKey: key, aad: utf8.encode('nohfibu-backup-1'));
    } catch (_) {
      throw const LedgerCipherException('wrong passphrase, or the backup is damaged');
    }
    return [for (final c in jsonDecode(utf8.decode(clear)) as List) Change.fromJson(Map<String, dynamic>.from(c as Map))];
  }
}
