import 'dart:convert';

import 'package:crypto/crypto.dart';

import '../../nohfibu.dart';

/// A changeset, as in git: what one device recorded at one moment, on top
/// of the changesets it knew ([parents]). Its [id] is the hash of its
/// content, so it is the same everywhere and cannot be altered unnoticed.
class Change {
  final String id;

  /// The device (or person) that recorded it.
  final String device;

  /// Its number among that device's changes (1, 2, 3…).
  final int seq;
  final DateTime time;

  /// The ids of the changes it was made on top of (the heads known then).
  final List<String> parents;
  final List<ChangeOp> ops;

  Change._(this.id, this.device, this.seq, this.time, this.parents, this.ops);

  /// A new change; its id is computed from everything else.
  factory Change.create({
    required String device,
    required int seq,
    required DateTime time,
    required List<String> parents,
    required List<ChangeOp> ops,
  }) {
    final sortedParents = [...parents]..sort();
    final utc = time.toUtc();
    return Change._(_hash(device, seq, utc, sortedParents, ops), device, seq, utc, sortedParents, ops);
  }

  static String _hash(String device, int seq, DateTime time, List<String> parents, List<ChangeOp> ops) =>
      sha256
          .convert(utf8.encode(CanonicalJson.encode({
            'device': device,
            'seq': seq,
            'time': time.toIso8601String(),
            'parents': parents,
            'ops': [for (final o in ops) o.toJson()],
          })))
          .toString();

  Map<String, dynamic> toJson() => {
        'id': id,
        'device': device,
        'seq': seq,
        'time': time.toIso8601String(),
        'parents': parents,
        'ops': [for (final o in ops) o.toJson()],
      };

  /// Reads a change; throws [FormatException] when its id does not match
  /// its content (damaged or altered).
  factory Change.fromJson(Map<String, dynamic> j) {
    final c = Change.create(
      device: '${j['device']}',
      seq: (j['seq'] as num).toInt(),
      time: DateTime.parse('${j['time']}'),
      parents: [for (final p in (j['parents'] as List)) '$p'],
      ops: [for (final o in (j['ops'] as List)) ChangeOp.fromJson(Map<String, dynamic>.from(o as Map))],
    );
    if (c.id != j['id']) throw FormatException('change ${j['id']} does not match its content');
    return c;
  }
}
