import 'dart:math';

import '../../nohfibu.dart';

/// What the hub's QR code carries for a device to join a book: where the
/// hub listens, which book, a token for this pairing, and the book's key —
/// pairing is handing the key over, screen to camera, never via a server.
///
/// `nohfibu://sync?h=192.168.1.10&p=4711&b=compta&t=…&k=…`
class SyncInvitation {
  final String host;
  final int port;
  final String book;
  final String token;
  final LedgerKey key;

  const SyncInvitation({required this.host, required this.port, required this.book, required this.token, required this.key});

  /// A fresh token for a pairing.
  static String newToken() {
    final r = Random.secure();
    return List.generate(12, (_) => r.nextInt(256).toRadixString(16).padLeft(2, '0')).join();
  }

  Uri get uri => Uri(scheme: 'nohfibu', host: 'sync', queryParameters: {
        'h': host,
        'p': '$port',
        'b': book,
        't': token,
        'k': key.toBase64(),
      });

  @override
  String toString() => uri.toString();

  /// Reads an invitation; throws [FormatException] when it is none.
  factory SyncInvitation.parse(String text) {
    final u = Uri.parse(text.trim());
    final q = u.queryParameters;
    if (u.scheme != 'nohfibu' || u.host != 'sync' || !['h', 'p', 'b', 't', 'k'].every(q.containsKey)) {
      throw FormatException('not a nohfibu sync invitation: $text');
    }
    return SyncInvitation(
      host: q['h']!,
      port: int.parse(q['p']!),
      book: q['b']!,
      token: q['t']!,
      key: LedgerKey.fromBase64(q['k']!),
    );
  }

  /// Where the client connects.
  Uri get endpoint => Uri(scheme: 'ws', host: host, port: port, path: '/sync/$book', queryParameters: {'t': token});
}
