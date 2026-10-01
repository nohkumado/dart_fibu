import 'dart:convert';

import '../../nohfibu.dart';

/// A sync message, sealed with the book's key (aad "sync"): someone on the
/// network sees neither the book nor which changes travel.
class SyncMessage {
  /// hello (client: who, what it has), changes (what the other lacks, and
  /// what the sender has), done (how many were new).
  final String type;
  final String device;
  final Set<String> have;
  final List<Change> changes;
  final int added;

  const SyncMessage(this.type, {this.device = '', this.have = const {}, this.changes = const [], this.added = 0});

  Future<String> seal(LedgerCipher cipher) => cipher.seal(
      jsonEncode({
        'type': type,
        'device': device,
        'have': have.toList(),
        'changes': [for (final c in changes) c.toJson()],
        'added': added,
      }),
      aad: 'sync');

  static Future<SyncMessage> open(String sealed, LedgerCipher cipher) async {
    final j = jsonDecode(await cipher.open(sealed, aad: 'sync')) as Map<String, dynamic>;
    return SyncMessage(
      '${j['type']}',
      device: '${j['device'] ?? ''}',
      have: {for (final h in (j['have'] as List?) ?? const []) '$h'},
      changes: [for (final c in (j['changes'] as List?) ?? const []) Change.fromJson(Map<String, dynamic>.from(c as Map))],
      added: (j['added'] as num?)?.toInt() ?? 0,
    );
  }
}
