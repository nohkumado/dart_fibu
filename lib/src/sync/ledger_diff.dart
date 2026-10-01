import 'dart:convert';

import '../../nohfibu.dart';

/// The ops that turn one state of a book and its archive into another:
/// what an action (a CLI command, a screen of the app) changed, so it can
/// be recorded as a [Change] without the action knowing about history.
class LedgerDiff {
  const LedgerDiff._();

  /// A copy of [book] and [store] as plain data, to compare after an action.
  static Map<String, dynamic> capture({Book? book, InvoiceStore? store, Iterable<Letterhead> letterheads = const []}) {
    final entities = <String, String>{};
    var journal = 0;
    final events = <String, int>{};
    for (final op in Ledger.snapshot(book: book, store: store, letterheads: letterheads)) {
      final e = op.entity;
      if (e != null) {
        entities[e] = CanonicalJson.encode(op.data);
      } else if (op.type == 'journal.add') {
        journal++;
      } else if (op.type == 'document.event') {
        events['${op.data['uid']}'] = (events['${op.data['uid']}'] ?? 0) + 1;
      }
    }
    return {'entities': entities, 'journal': journal, 'events': events};
  }

  /// What changed between [before] (a [capture]) and the state now.
  static List<ChangeOp> since(Map<String, dynamic> before,
      {Book? book, InvoiceStore? store, Iterable<Letterhead> letterheads = const []}) {
    final old = Map<String, String>.from(before['entities'] as Map);
    final oldEvents = Map<String, int>.from(before['events'] as Map);
    final ops = <ChangeOp>[];
    final now = Ledger.snapshot(book: book, store: store, letterheads: letterheads);
    final seen = <String>{};
    var journal = 0;
    final events = <String, int>{};
    for (final op in now) {
      final e = op.entity;
      if (e != null) {
        seen.add(e);
        if (old[e] != CanonicalJson.encode(op.data)) ops.add(op);
      } else if (op.type == 'journal.add') {
        if (++journal > (before['journal'] as int)) ops.add(op);
      } else if (op.type == 'document.event') {
        final uid = '${op.data['uid']}';
        events[uid] = (events[uid] ?? 0) + 1;
        if (events[uid]! > (oldEvents[uid] ?? 0)) ops.add(op);
      }
    }
    // gone: drafts dropped, ops or letterheads deleted
    for (final e in old.keys.where((e) => !seen.contains(e))) {
      final data = Map<String, dynamic>.from(jsonDecode(old[e]!) as Map)..['deleted'] = true;
      final type = '${e.split(':').first}.put';
      ops.add(ChangeOp(type, data));
    }
    return ops;
  }
}
