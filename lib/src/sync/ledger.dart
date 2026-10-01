import 'package:intl/intl.dart';

import '../../nohfibu.dart';

/// A book, its offers and invoices, and its letterheads, rebuilt from the
/// history ([ChangeGraph]): the CSV book and the JSON archive are views of
/// it. Things set by several changes take the latest in replay order;
/// where those changes did not know each other, [conflicts] says so.
class Ledger {
  final Book book;
  final InvoiceStore store;

  /// Letterhead id → its YAML.
  final Map<String, String> letterheads;
  final List<LedgerConflict> conflicts;

  Ledger._(this.book, this.store, this.letterheads, this.conflicts);

  static final _day = DateFormat('yyyy-MM-dd');

  /// Replays [graph].
  factory Ledger.replay(ChangeGraph graph) {
    final last = <String, (Change, ChangeOp)>{};
    final order = <String>[];
    final journal = <ChangeOp>[];
    final docEvents = <String, List<DocumentEvent>>{};
    final conflicts = <LedgerConflict>[];
    for (final change in graph.ordered()) {
      for (final op in change.ops) {
        final entity = op.entity;
        if (entity != null) {
          final previous = last[entity];
          if (previous != null && previous.$1.id != change.id && !graph.isAncestor(previous.$1.id, change.id)) {
            conflicts.add(LedgerConflict(entity, change, previous.$1, previous.$2.data));
          }
          if (previous == null) order.add(entity);
          last[entity] = (change, op);
        } else if (op.type == 'journal.add') {
          journal.add(op);
        } else if (op.type == 'document.event') {
          (docEvents['${op.data['uid']}'] ??= [])
              .add(DocumentEvent.fromJson(Map<String, dynamic>.from(op.data['event'] as Map)));
        }
      }
    }

    final book = Book();
    final store = InvoiceStore();
    final letterheads = <String, String>{};
    final accounts = [for (final e in order) if (e.startsWith('account:')) last[e]!.$2.data]
      ..sort((a, b) => '${a['name']}'.compareTo('${b['name']}'));
    for (final a in accounts) {
      final name = '${a['name']}';
      final role = '${a['role'] ?? ''}';
      book.kpl.put(
          name,
          Konto(
            name: name,
            desc: '${a['desc'] ?? ''}',
            cur: '${a['cur'] ?? 'EUR'}',
            budget: (a['budget'] as num?)?.toInt() ?? 0,
            valuta: (a['valuta'] as num?)?.toInt() ?? 0,
            plan: book.kpl,
            prefix: name.length > 1 ? name.substring(0, name.length - 2) : '',
            accountType: AccountType.parse(role) ?? AccountType.fromBlock(name),
          )..heading = role == 'heading');
    }
    Konto account(String name) => name.isEmpty ? Konto() : (book.kpl.get(name) ?? Konto(name: name, desc: ''));
    for (final j in journal) {
      final d = j.data;
      book.jrl.add(JrlLine(
        datum: DateTime.parse('${d['date']}'),
        kmin: account('${d['minus'] ?? ''}'),
        kplu: account('${d['plus'] ?? ''}'),
        desc: '${d['desc'] ?? ''}',
        cur: '${d['cur'] ?? 'EUR'}',
        valuta: (d['valuta'] as num).toInt(),
      ));
    }
    for (final e in order) {
      final data = last[e]!.$2.data;
      if (data['deleted'] == true) continue;
      if (e.startsWith('op:')) {
        final op = Operation(book, name: '${data['name']}');
        for (final l in (data['lines'] as List)) {
          final f = [for (final v in (l as List)) '$v'];
          op.add(date: f[0], cminus: f[1], cplus: f[2], desc: f[3], cur: f[4], valuta: f[5], mod: f[6]);
        }
        book.ops[op.name] = op;
      } else if (e.startsWith('customer:')) {
        final c = Customer.fromJson(data);
        store.customers[c.id] = c;
      } else if (e.startsWith('letterhead:')) {
        letterheads['${data['id']}'] = '${data['yaml']}';
      } else if (e.startsWith('document:')) {
        final uid = '${data['uid']}';
        store.documents.add(Invoice.fromJson({...data, 'events': [for (final ev in docEvents[uid] ?? const <DocumentEvent>[]) ev.toJson()]}));
      }
    }
    return Ledger._(book, store, letterheads, conflicts);
  }

  /// The ops that set an account as it is now.
  static ChangeOp accountOp(Konto k) => ChangeOp('account.put', {
        'name': k.name,
        'desc': k.desc,
        'cur': k.cur,
        'budget': k.budget,
        'valuta': k.valuta,
        'role': k.roleKey,
      });

  /// The op that adds [line] to the journal.
  static ChangeOp journalOp(JrlLine line) => ChangeOp('journal.add', {
        'date': _day.format(line.datum),
        'minus': line.kminus.name == 'no name' ? '' : line.kminus.name,
        'plus': line.kplus.name == 'no name' ? '' : line.kplus.name,
        'desc': line.desc,
        'cur': line.cur,
        'valuta': line.valuta,
      });

  /// The op that sets a stored operation.
  static ChangeOp operationOp(Operation op) {
    final rows = <List>[];
    op.asList(rows);
    return ChangeOp('op.put', {
      'name': op.name,
      'lines': [for (final r in rows) r.sublist(1).map((v) => '$v').toList()],
    });
  }

  static ChangeOp customerOp(Customer c) => ChangeOp('customer.put', c.toJson());

  static ChangeOp letterheadOp(Letterhead l) => ChangeOp('letterhead.put', {'id': l.id, 'yaml': l.toYaml()});

  /// The op that sets a document (its history goes as [documentEventOp]s).
  static ChangeOp documentOp(Invoice d) => ChangeOp('document.put', {...d.toJson()..remove('events')});

  static ChangeOp documentEventOp(Invoice d, DocumentEvent e) =>
      ChangeOp('document.event', {'uid': d.uid, 'event': e.toJson()});

  /// Everything of an existing [book], [store] and [letterheads] as ops —
  /// the first change of a history (importing what was kept as files).
  static List<ChangeOp> snapshot({Book? book, InvoiceStore? store, Iterable<Letterhead> letterheads = const []}) {
    final ops = <ChangeOp>[];
    if (book != null) {
      void walk(Konto k) {
        if (k.desc.trim().isNotEmpty) ops.add(accountOp(k));
        for (final c in k.children.values) {
          walk(c);
        }
      }

      for (final k in book.kpl.konten.values) {
        walk(k);
      }
      for (final line in book.jrl.journal) {
        ops.add(journalOp(line));
      }
      for (final op in book.ops.values) {
        ops.add(operationOp(op as Operation));
      }
    }
    if (store != null) {
      ops.addAll(store.customers.values.map(customerOp));
      for (final d in store.documents) {
        ops.add(documentOp(d));
        for (final e in d.events) {
          ops.add(documentEventOp(d, e));
        }
      }
    }
    ops.addAll(letterheads.map(letterheadOp));
    return ops;
  }
}
