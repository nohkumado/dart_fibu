import 'dart:convert';
import 'dart:io';
import 'dart:math';

/// The key a book's history is encrypted with: 32 random bytes. On the
/// desktop it lives in a key file only its owner can read; the app keeps it
/// in the phone's secure storage (Android Keystore). It never goes to a
/// server; a new device gets it by pairing.
class LedgerKey {
  final List<int> bytes;

  LedgerKey(this.bytes) {
    if (bytes.length != 32) throw ArgumentError('a ledger key has 32 bytes, not ${bytes.length}');
  }

  /// A fresh random key.
  factory LedgerKey.generate() {
    final r = Random.secure();
    return LedgerKey(List.generate(32, (_) => r.nextInt(256)));
  }

  factory LedgerKey.fromBase64(String text) => LedgerKey(base64Url.decode(base64Url.normalize(text.trim())));

  String toBase64() => base64Url.encode(bytes);

  /// The key in [file], made (and readable by its owner only) when missing.
  static LedgerKey inFile(File file) {
    if (file.existsSync()) return LedgerKey.fromBase64(file.readAsStringSync());
    file.parent.createSync(recursive: true);
    final key = LedgerKey.generate();
    file.writeAsStringSync('${key.toBase64()}\n');
    if (!Platform.isWindows) Process.runSync('chmod', ['600', file.path]);
    return key;
  }
}
