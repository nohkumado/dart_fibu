import 'dart:convert';
import 'dart:io';

import 'package:nohfibu/csv_handler.dart';
import 'package:nohfibu/fibusettings.dart';
import 'package:nohfibu/nohfibu.dart';
import 'package:test/test.dart';

Book load(String path) {
  final book = Book();
  CsvHandler().load(book: book, conf: FibuSettings()..init(['-b', path]));
  return book;
}

Future<String> csvOf(Book book) async {
  final dir = Directory.systemTemp.createTempSync('ledger');
  final file = await CsvHandler().save(book: book, conf: FibuSettings()..init(['-b', '${dir.path}/b.csv', '-o', '${dir.path}/b']));
  final text = file.readAsStringSync();
  dir.deleteSync(recursive: true);
  return text;
}

ChangeGraph copyOf(ChangeGraph g) => ChangeGraph()..merge(g.ordered());

void main() {
  for (final sample in ['compta2018', 'me2000']) {
    test('$sample: imported as a change, replayed, it is the same book', () async {
      final book = load('assets/wbsamples/$sample.csv');
      final graph = ChangeGraph()..record('desktop', Ledger.snapshot(book: book), time: DateTime.utc(2026, 1, 1));
      final again = Ledger.replay(graph).book;
      expect(await csvOf(again), await csvOf(book));
      expect(again.jrl.count(), book.jrl.count());
    });
  }

  test('a change altered on the way is refused', () {
    final g = ChangeGraph()..record('phone', [const ChangeOp('journal.add', {'date': '2026-01-01', 'minus': '', 'plus': '', 'desc': 'x', 'cur': 'EUR', 'valuta': 100})]);
    final sent = jsonEncode(g.changes.single.toJson());
    expect(Change.fromJson(jsonDecode(sent) as Map<String, dynamic>).id, g.changes.single.id);
    final altered = jsonDecode(sent) as Map<String, dynamic>;
    ((altered['ops'] as List).first as Map)['data']['valuta'] = 100000;
    expect(() => Change.fromJson(altered), throwsFormatException);
  });

  group('two devices', () {
    late ChangeGraph desktop, phone;
    const assoc = Customer(id: 'assoc', name: 'Association Exemple', address: ['3 place du Marché']);
    ChangeOp line(String desc, int cents) => ChangeOp('journal.add',
        {'date': '2026-03-01', 'minus': '4410', 'plus': '1001', 'desc': desc, 'cur': 'EUR', 'valuta': cents});

    setUp(() {
      desktop = ChangeGraph()
        ..record('desktop', [
          const ChangeOp('account.put', {'name': '1001', 'desc': 'Caisse', 'cur': 'EUR', 'budget': 0, 'valuta': 0, 'role': 'actif'}),
          const ChangeOp('account.put', {'name': '4410', 'desc': 'Recettes', 'cur': 'EUR', 'budget': 0, 'valuta': 0, 'role': 'produit'}),
          Ledger.customerOp(assoc),
        ], time: DateTime.utc(2026, 3, 1, 8));
      phone = copyOf(desktop);
    });

    test('working at the same time, merged either way: the same book, one conflict', () {
      // offline on both sides
      phone.record('phone', [line('Cours, encaissé au dojo', 6000), Ledger.customerOp(const Customer(id: 'assoc', name: 'Association Exemple', address: ['5 rue Neuve']))],
          time: DateTime.utc(2026, 3, 1, 10));
      desktop.record('desktop', [line('Cotisation', 3000), Ledger.customerOp(const Customer(id: 'assoc', name: 'Association Exemple', address: ['7 rue Haute']))],
          time: DateTime.utc(2026, 3, 1, 11));

      final onDesktop = copyOf(desktop)..merge(phone.changes);
      final onPhone = copyOf(phone)..merge(desktop.changes);
      expect(onDesktop.ordered().map((c) => c.id), onPhone.ordered().map((c) => c.id));
      expect(onDesktop.heads, hasLength(2), reason: 'two branches until one records on top of both');

      final a = Ledger.replay(onDesktop), b = Ledger.replay(onPhone);
      expect(a.book.jrl.journal.map((l) => l.desc), ['Cours, encaissé au dojo', 'Cotisation']);
      expect(b.book.jrl.journal.map((l) => l.desc), a.book.jrl.journal.map((l) => l.desc));
      expect(a.store.customers['assoc']!.address, ['7 rue Haute'], reason: 'the later edit');
      expect(a.conflicts.single.entity, 'customer:assoc');
      expect(a.conflicts.single.replacedData['address'], ['5 rue Neuve'], reason: 'kept for a person to confirm');

      // recording on top of both joins the branches; no new conflict
      onDesktop.record('desktop', [line('Don', 1000)], time: DateTime.utc(2026, 3, 2));
      expect(onDesktop.heads, hasLength(1));
    });

    test('edits made one after the other (synced in between) are no conflict', () {
      phone.record('phone', [Ledger.customerOp(const Customer(id: 'assoc', name: 'A', address: ['1']))], time: DateTime.utc(2026, 3, 2));
      desktop.merge(phone.changes);
      desktop.record('desktop', [Ledger.customerOp(const Customer(id: 'assoc', name: 'A', address: ['2']))], time: DateTime.utc(2026, 3, 3));
      final l = Ledger.replay(desktop);
      expect(l.conflicts, isEmpty);
      expect(l.store.customers['assoc']!.address, ['2']);
    });

    test('changes arriving before their parents wait for them', () {
      final first = phone.record('phone', [line('a', 1)], time: DateTime.utc(2026, 3, 2));
      final second = phone.record('phone', [line('b', 2)], time: DateTime.utc(2026, 3, 3));
      final g = copyOf(desktop);
      g.add(second);
      expect(g.waiting, 1);
      expect(g[second.id], isNull);
      g.add(first);
      expect(g.waiting, 0);
      expect(g.missingFor(desktop.ids).map((c) => c.id), [first.id, second.id]);
    });

    test('offers and invoices travel too: a document and its history', () {
      final doc = Invoice(
          kind: InvoiceKind.estimate, letterhead: 'micro', name: '', number: '', date: DateTime(2026, 3, 1),
          payDate: DateTime(2026, 3, 31), customerId: 'assoc', items: const [InvoiceItem('Stage', 1, 24000)], uid: 'u1');
      final issued = doc.withNumber('P2026-0001');
      phone.record('phone', [
        Ledger.documentOp(issued),
        Ledger.documentEventOp(issued, DocumentEvent(DateTime(2026, 3, 1), DocumentEventKind.issued)),
      ]);
      desktop.merge(phone.changes);
      desktop.record('desktop', [
        Ledger.documentEventOp(issued, DocumentEvent(DateTime(2026, 3, 4), DocumentEventKind.accepted)),
      ]);
      final l = Ledger.replay(desktop);
      expect(l.store.documents.single.number, 'P2026-0001');
      expect(l.store.documents.single.status(), InvoiceStatus.accepted);
    });
  });
}
