import '../../nohfibu.dart';

/// The history of a book as a graph of [Change]s, as git keeps commits:
/// every device records on top of the heads it knows; merging two
/// histories is their union; the order to replay them puts parents first,
/// changes made without knowing each other by time (then id), the same on
/// every device.
class ChangeGraph {
  final Map<String, Change> _changes = {};

  /// Changes whose parents have not arrived yet (sync in any order).
  final Map<String, Change> _waiting = {};

  Iterable<Change> get changes => _changes.values;
  Set<String> get ids => _changes.keys.toSet();
  int get length => _changes.length;
  Change? operator [](String id) => _changes[id];

  /// The changes no other change builds on (the tips of the history).
  Set<String> get heads {
    final h = ids;
    for (final c in _changes.values) {
      h.removeAll(c.parents);
    }
    return h;
  }

  /// Adds [change]; true when it is new. One whose parents are missing
  /// waits until they come.
  bool add(Change change) {
    if (_changes.containsKey(change.id) || _waiting.containsKey(change.id)) return false;
    _waiting[change.id] = change;
    _settle();
    return true;
  }

  /// Adds all of [other] (a merge); returns how many were new.
  int merge(Iterable<Change> other) => other.where(add).length;

  void _settle() {
    var progress = true;
    while (progress) {
      progress = false;
      for (final c in _waiting.values.toList()) {
        if (c.parents.every(_changes.containsKey)) {
          _changes[c.id] = c;
          _waiting.remove(c.id);
          progress = true;
        }
      }
    }
  }

  /// How many changes still wait for their parents.
  int get waiting => _waiting.length;

  /// Records [ops] by [device] on top of the current heads.
  Change record(String device, List<ChangeOp> ops, {DateTime? time}) {
    final seq = _changes.values.where((c) => c.device == device).fold(0, (m, c) => c.seq > m ? c.seq : m) + 1;
    final change = Change.create(device: device, seq: seq, time: time ?? DateTime.now(), parents: heads.toList(), ops: ops);
    add(change);
    return change;
  }

  /// Whether [ancestor] is in the history of [id].
  bool isAncestor(String ancestor, String id) {
    final todo = [..._changes[id]?.parents ?? const <String>[]];
    final seen = <String>{};
    while (todo.isNotEmpty) {
      final p = todo.removeLast();
      if (p == ancestor) return true;
      if (seen.add(p)) todo.addAll(_changes[p]?.parents ?? const []);
    }
    return false;
  }

  /// The changes in replay order: every change after its parents; among
  /// those ready at the same time, the earlier first (then by id).
  List<Change> ordered() {
    final children = <String, List<String>>{};
    final missing = <String, int>{};
    for (final c in _changes.values) {
      missing[c.id] = c.parents.length;
      for (final p in c.parents) {
        (children[p] ??= []).add(c.id);
      }
    }
    int byTime(Change a, Change b) {
      final t = a.time.compareTo(b.time);
      return t != 0 ? t : a.id.compareTo(b.id);
    }

    final ready = [for (final c in _changes.values) if (c.parents.isEmpty) c]..sort(byTime);
    final out = <Change>[];
    while (ready.isNotEmpty) {
      final c = ready.removeAt(0);
      out.add(c);
      for (final child in children[c.id] ?? const <String>[]) {
        missing[child] = missing[child]! - 1;
        if (missing[child] == 0) {
          ready.add(_changes[child]!);
          ready.sort(byTime);
        }
      }
    }
    return out;
  }

  /// The changes [known] (ids) does not have, in replay order — what to
  /// send to a device that has [known].
  List<Change> missingFor(Set<String> known) => ordered().where((c) => !known.contains(c.id)).toList();
}
