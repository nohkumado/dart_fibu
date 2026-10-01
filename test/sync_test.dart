import 'dart:io';

import 'package:nohfibu/nohfibu.dart';
import 'package:test/test.dart';

ChangeOp line(String desc, int cents) => ChangeOp('journal.add',
    {'date': '2026-03-01', 'minus': '4410', 'plus': '1001', 'desc': desc, 'cur': 'EUR', 'valuta': cents});

void main() {
  late Directory dir;
  late ChangeGraph hub;
  late SyncServer server;
  late SyncInvitation invitation;
  final key = LedgerKey.generate();

  setUp(() async {
    dir = Directory.systemTemp.createTempSync('sync');
    hub = ChangeGraph()..record('desktop', [line('Ouverture', 100)], time: DateTime.utc(2026, 3, 1));
    invitation = SyncInvitation(host: '127.0.0.1', port: 0, book: 'compta', token: SyncInvitation.newToken(), key: key);
    server = SyncServer(hub, invitation,
        onChanged: (_) => ChangeFiles(Directory('${dir.path}/hub'), LedgerCipher(key)).save(hub));
    await server.start();
    invitation = SyncInvitation(host: '127.0.0.1', port: server.port, book: 'compta', token: invitation.token, key: key);
  });
  tearDown(() async {
    await server.stop();
    dir.deleteSync(recursive: true);
  });

  test('the invitation survives the QR code', () {
    final again = SyncInvitation.parse(invitation.toString());
    expect(again.host, '127.0.0.1');
    expect(again.port, invitation.port);
    expect(again.key.toBase64(), key.toBase64());
    expect(() => SyncInvitation.parse('https://example.org'), throwsFormatException);
  });

  test('phone and co-worker, offline at the same time, end up with the hub on the same history', () async {
    // both paired earlier: they have the hub's history
    final phone = ChangeGraph()..merge(hub.changes);
    final coworker = ChangeGraph()..merge(hub.changes);
    // offline work everywhere
    phone.record('phone', [line('Cours encaissé', 6000)], time: DateTime.utc(2026, 3, 2, 10));
    coworker.record('coworker', [line('Stage', 24000)], time: DateTime.utc(2026, 3, 2, 11));
    hub.record('desktop', [line('Banque', 500)], time: DateTime.utc(2026, 3, 2, 12));

    expect((await SyncClient(invitation, 'phone').sync(phone)).toString(), 'received 1, sent 1');
    expect((await SyncClient(invitation, 'coworker').sync(coworker)).toString(), 'received 2, sent 1');
    await SyncClient(invitation, 'phone').sync(phone); // takes the co-worker's
    final ids = hub.ordered().map((c) => c.id).toList();
    expect(phone.ordered().map((c) => c.id), ids);
    expect(coworker.ordered().map((c) => c.id), ids);
    expect(Ledger.replay(phone).book.jrl.journal.map((l) => l.desc),
        ['Ouverture', 'Cours encaissé', 'Stage', 'Banque']);
    // the hub saved what came in, encrypted
    final saved = await ChangeFiles(Directory('${dir.path}/hub'), LedgerCipher(key)).load();
    expect(saved.length, hub.length);
  });

  test('a device without the key gets nothing and changes nothing', () async {
    final stranger = ChangeGraph()..record('stranger', [line('Fake', 1)]);
    final wrongKey = SyncInvitation(host: '127.0.0.1', port: invitation.port, book: 'compta', token: invitation.token, key: LedgerKey.generate());
    await expectLater(SyncClient(wrongKey, 'stranger').sync(stranger, timeout: const Duration(seconds: 5)), throwsA(anything));
    final wrongToken = SyncInvitation(host: '127.0.0.1', port: invitation.port, book: 'compta', token: 'nope', key: key);
    await expectLater(SyncClient(wrongToken, 'stranger').sync(stranger, timeout: const Duration(seconds: 5)), throwsA(anything));
    expect(hub.length, 1);
    expect(stranger.length, 1);
  });
}
