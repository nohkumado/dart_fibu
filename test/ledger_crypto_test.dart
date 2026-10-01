import 'dart:io';

import 'package:nohfibu/nohfibu.dart';
import 'package:test/test.dart';

void main() {
  late Directory dir;
  setUp(() => dir = Directory.systemTemp.createTempSync('ledgercrypto'));
  tearDown(() => dir.deleteSync(recursive: true));

  ChangeGraph sample() => ChangeGraph()
    ..record('desktop', [
      Ledger.customerOp(const Customer(id: 'assoc', name: 'Association Exemple', address: ['3 place du Marché'])),
      const ChangeOp('journal.add', {'date': '2026-03-01', 'minus': '4410', 'plus': '1001', 'desc': 'Cotisation', 'cur': 'EUR', 'valuta': 3000}),
    ], time: DateTime.utc(2026, 3, 1))
    ..record('phone', [
      const ChangeOp('journal.add', {'date': '2026-03-02', 'minus': '4410', 'plus': '1001', 'desc': 'Cours', 'cur': 'EUR', 'valuta': 6000}),
    ], time: DateTime.utc(2026, 3, 2));

  test('the key file: made once, readable by its owner only, then reused', () {
    final file = File('${dir.path}/keys/compta.key');
    final key = LedgerKey.inFile(file);
    expect(LedgerKey.inFile(file).toBase64(), key.toBase64());
    final mode = Process.runSync('stat', ['-c', '%a', file.path]).stdout.toString().trim();
    expect(mode, '600');
  });

  test('the history on disk: one encrypted file per device, read back the same', () async {
    final key = LedgerKey.generate();
    final graph = sample();
    await ChangeFiles(dir, LedgerCipher(key)).save(graph);
    final names = dir.listSync().map((f) => f.uri.pathSegments.last).toList()..sort();
    expect(names, ['desktop.jsonl', 'phone.jsonl']);
    for (final f in dir.listSync().whereType<File>()) {
      final text = f.readAsStringSync();
      expect(text, isNot(contains('Association')));
      expect(text, isNot(contains('Cotisation')));
    }
    final again = await ChangeFiles(dir, LedgerCipher(key)).load();
    expect(again.ordered().map((c) => c.id), graph.ordered().map((c) => c.id));
  });

  test('another key opens nothing; the problems are named, not hidden', () async {
    await ChangeFiles(dir, LedgerCipher(LedgerKey.generate())).save(sample());
    final problems = <String>[];
    final graph = await ChangeFiles(dir, LedgerCipher(LedgerKey.generate())).load(problems: problems);
    expect(graph.length, 0);
    expect(problems, hasLength(2));
  });

  test("a line moved into another device's file is refused", () async {
    final key = LedgerKey.generate();
    await ChangeFiles(dir, LedgerCipher(key)).save(sample());
    final phoneLine = File('${dir.path}/phone.jsonl').readAsLinesSync().first;
    File('${dir.path}/desktop.jsonl').writeAsStringSync('$phoneLine\n', mode: FileMode.append);
    final problems = <String>[];
    final graph = await ChangeFiles(dir, LedgerCipher(key)).load(problems: problems);
    expect(problems.single, contains('desktop.jsonl'));
    expect(graph.length, 2);
  });

  test('a backup restores with its passphrase — and only with it', () async {
    final graph = sample();
    final text = await LedgerBackup.export(graph, 'correct horse battery staple', iterations: 1000);
    expect(text, isNot(contains('Association')));
    final restored = ChangeGraph()..merge(await LedgerBackup.restore(text, 'correct horse battery staple'));
    expect(Ledger.replay(restored).book.jrl.journal.map((l) => l.desc), ['Cotisation', 'Cours']);
    expect(() => LedgerBackup.restore(text, 'wrong'), throwsA(isA<LedgerCipherException>()));
  });
}
