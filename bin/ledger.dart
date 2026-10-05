// ledger — a book kept as an encrypted history (changesets), synced between
// the desktop (hub) and phones or co-workers on the local network.
//
//   dart run nohfibu:ledger -B compta init --from compta2026.csv [--archive factures.json] [--letterheads DIR]
//   … status | conflicts
//   … export --csv compta2026.csv [--archive factures.json] [--letterheads DIR]
//   … serve [--port 4711]         (the hub: shows the QR code for pairing)
//   … sync '<invitation>'         (sync with a hub; first time: pairing)
//   … backup FILE | restore FILE  (passphrase-protected)
import 'dart:async';
import 'dart:io';

import 'package:args/args.dart';
import 'package:nohfibu/csv_handler.dart';
import 'package:nohfibu/fibusettings.dart';
import 'package:nohfibu/nohfibu.dart';
import 'package:qr/qr.dart';

const _commands = {
  'init': 'import a CSV book (and an invoice archive, letterheads) as the start of the history',
  'status': 'devices, changes, open branches, conflicts',
  'conflicts': 'what two devices changed at the same time',
  'export': 'write the book as CSV (and the archive, the letterheads) — views of the history',
  'serve': 'be the hub on the local network; shows the QR code to pair a device',
  'sync': '<invitation>: sync with a hub (the first time pairs this device)',
  'backup': '<file>: the whole history in one file, under a passphrase',
  'key': '--to-rbw: keep the book\'s key in Bitwarden (rbw); --from-rbw: take it back from there',
  'restore': '<file>: bring a backup in (merged with what is here)',
};

Future<void> main(List<String> arguments) async {
  final home = Platform.environment['HOME'] ?? '.';
  final parser = ArgParser()
    ..addOption('book', abbr: 'B', help: 'the book (its history under --base/books/<book>)')
    ..addOption('base', defaultsTo: '$home/.config/nohfibu', help: 'where histories and keys live')
    ..addOption('from', help: 'init: the CSV book to import')
    ..addOption('archive', help: 'init/export: the invoice archive (JSON or old CSV)')
    ..addOption('letterheads', help: 'init/export: directory of letterheads (*.yaml)')
    ..addOption('csv', help: 'export: where to write the book')
    ..addOption('port', defaultsTo: '4711', help: 'serve: the port')
    ..addFlag('to-rbw', negatable: false, help: 'key: keep the key in Bitwarden through rbw')
    ..addFlag('from-rbw', negatable: false, help: 'key: take the key from Bitwarden through rbw (a new computer)')
    ..addFlag('help', abbr: 'h', negatable: false);
  String usage() => 'ledger — books as encrypted history, synced with the desktop\n\n'
      'ledger -B <book> <command> [arguments]\n\n'
      '${_commands.entries.map((e) => '  ${e.key.padRight(10)} ${e.value}').join('\n')}\n\n${parser.usage}';
  final ArgResults args;
  try {
    args = parser.parse(arguments);
  } on FormatException catch (e) {
    stderr.writeln('${e.message}\n\n${usage()}');
    exitCode = 64;
    return;
  }
  if (args['help'] as bool || args.rest.isEmpty || args['book'] == null || !_commands.containsKey(args.rest.first)) {
    if (args.rest.isNotEmpty && !_commands.containsKey(args.rest.first)) stderr.writeln('ledger: unknown command "${args.rest.first}"\n');
    if (args.rest.isNotEmpty && args['book'] == null) stderr.writeln('ledger: which book? give it with -B\n');
    print(usage());
    return;
  }
  final base = Directory(args['base'] as String);
  final book = args['book'] as String;
  final command = args.rest.first;
  final arg = args.rest.length > 1 ? args.rest[1] : null;

  try {
    if (command == 'key' && args['from-rbw'] as bool) {
      final vault = const RbwVault();
      if (!vault.available) throw StateError('rbw is not installed');
      final key = vault.get(book) ?? (throw StateError('no "${RbwVault.entry(book)}" in Bitwarden'));
      final keyFile = File('${base.path}/keys/$book.key');
      if (keyFile.existsSync() && LedgerKey.inFile(keyFile).toBase64() != key.toBase64()) {
        throw StateError('${keyFile.path} holds another key — move it away first, it may be needed');
      }
      await LedgerRepo.open(base, book, key: key);
      print('key of $book taken from Bitwarden into ${keyFile.path}');
      return;
    }
    if (command == 'sync') {
      if (arg == null) throw StateError('sync needs the invitation (the text of the hub\'s QR code)');
      final invitation = SyncInvitation.parse(arg);
      final repo = await LedgerRepo.open(base, book, key: invitation.key);
      final result = await SyncClient(invitation, repo.device).sync(repo.graph);
      await repo.saveAll();
      print('${repo.device} ↔ hub: $result');
      return;
    }
    final repo = await LedgerRepo.open(base, book);
    for (final p in repo.problems) {
      stderr.writeln('! $p');
    }
    switch (command) {
      case 'init':
        if (repo.graph.length > 0) throw StateError('$book has a history already (${repo.graph.length} changes)');
        final from = args['from'] as String?;
        Book? b;
        if (from != null) {
          b = Book();
          CsvHandler().load(book: b, conf: FibuSettings()..init(['-b', from]));
        }
        final archive = args['archive'] == null ? null : InvoiceStore.load(File(args['archive'] as String));
        final letterheads = args['letterheads'] == null
            ? const <Letterhead>[]
            : Letterhead.loadAll(Directory(args['letterheads'] as String)).values;
        await repo.record(Ledger.snapshot(book: b, store: archive, letterheads: letterheads));
        print('$book: history started on ${repo.device} — ${repo.graph.changes.single.ops.length} items imported');
        print('key: ${base.path}/keys/$book.key (keep it safe; make a backup with: ledger -B $book backup FILE)');
      case 'status':
        final byDevice = <String, int>{};
        for (final c in repo.graph.changes) {
          byDevice[c.device] = (byDevice[c.device] ?? 0) + 1;
        }
        final ledger = repo.ledger;
        print('$book on ${repo.device}: ${repo.graph.length} changes');
        byDevice.forEach((d, n) => print('  $d: $n'));
        print('open branches: ${repo.graph.heads.length}${repo.graph.heads.length > 1 ? ' (joined by the next change)' : ''}');
        print('journal lines: ${ledger.book.jrl.count()}, documents: ${ledger.store.documents.length}, '
            'customers: ${ledger.store.customers.length}');
        print('conflicts: ${ledger.conflicts.length}${ledger.conflicts.isEmpty ? '' : ' — ledger -B $book conflicts'}');
      case 'conflicts':
        for (final c in repo.ledger.conflicts) {
          print(c);
          print('  replaced: ${c.replacedData}');
        }
      case 'export':
        final ledger = repo.ledger;
        if (args['csv'] != null) {
          final csv = (args['csv'] as String).replaceAll(RegExp(r'\.csv$'), '');
          final f = await CsvHandler().save(book: ledger.book, conf: FibuSettings()..init(['-b', '$csv.csv', '-o', csv]));
          print('wrote ${f.path}');
        }
        if (args['archive'] != null) {
          ledger.store.save(File(args['archive'] as String));
          print('wrote ${args['archive']}');
        }
        if (args['letterheads'] != null) {
          final dir = Directory(args['letterheads'] as String)..createSync(recursive: true);
          ledger.letterheads.forEach((id, yaml) => File('${dir.path}/$id.yaml').writeAsStringSync(yaml));
          print('wrote ${ledger.letterheads.length} letterheads to ${dir.path}');
        }
      case 'serve':
        final host = await _lanAddress();
        var invitation = SyncInvitation(
            host: host, port: int.parse(args['port'] as String), book: book, token: SyncInvitation.newToken(), key: repo.key);
        final server = SyncServer(repo.graph, invitation, onChanged: (_) => repo.saveAll(), log: print);
        await server.start();
        invitation = SyncInvitation(host: host, port: server.port, book: book, token: invitation.token, key: repo.key);
        print('\nScan to pair or sync (this code holds the book\'s key — show it only to your own devices):\n');
        print(_qr(invitation.toString()));
        print('\nor: ledger -B $book sync \'$invitation\'\n\nCtrl-C to stop.');
        await ProcessSignal.sigint.watch().first;
        await server.stop();
      case 'key':
        if (!(args['to-rbw'] as bool)) throw StateError('key: --to-rbw or --from-rbw');
        final vault = const RbwVault();
        if (!vault.available) throw StateError('rbw is not installed');
        await vault.put(book, repo.key);
        print('key of $book kept in Bitwarden as "${RbwVault.entry(book)}" (user ${RbwVault.user})');
      case 'backup':
        if (arg == null) throw StateError('backup needs the file to write');
        final pass = _passphrase('passphrase for the backup');
        if (_passphrase('again') != pass) throw StateError('the passphrases differ');
        File(arg).writeAsStringSync(await LedgerBackup.export(repo.graph, pass));
        print('wrote $arg (${repo.graph.length} changes) — without the passphrase it cannot be read');
      case 'restore':
        if (arg == null) throw StateError('restore needs the backup file');
        final changes = await LedgerBackup.restore(File(arg).readAsStringSync(), _passphrase('passphrase of the backup'));
        final added = repo.graph.merge(changes);
        await repo.saveAll();
        print('restored: $added new changes, ${repo.graph.length} in all');
    }
  } on StateError catch (e) {
    stderr.writeln('ledger: ${e.message}');
    exitCode = 1;
  } on LedgerCipherException catch (e) {
    stderr.writeln('ledger: ${e.message}');
    exitCode = 1;
  } on SocketException catch (e) {
    stderr.writeln(command == 'serve'
        ? 'ledger: cannot listen on port ${args['port']} — another program uses it? (--port …) (${e.message})'
        : 'ledger: cannot reach the hub (${e.message})');
    exitCode = 1;
  }
}

String _passphrase(String prompt) {
  stdout.write('$prompt: ');
  final echo = stdin.hasTerminal ? stdin.echoMode : false;
  if (stdin.hasTerminal) stdin.echoMode = false;
  final p = stdin.readLineSync() ?? '';
  if (stdin.hasTerminal) stdin.echoMode = echo;
  stdout.writeln();
  return p;
}

/// The first non-loopback IPv4 address (the one phones on the Wi-Fi reach).
Future<String> _lanAddress() async {
  for (final i in await NetworkInterface.list(type: InternetAddressType.IPv4)) {
    for (final a in i.addresses) {
      if (!a.isLoopback) return a.address;
    }
  }
  return InternetAddress.loopbackIPv4.address;
}

/// [data] as a QR code in the terminal: two modules per character, light
/// modules drawn, so it scans on a dark terminal.
String _qr(String data) {
  final image = QrImage(QrCode.fromData(data: data, errorCorrectLevel: QrErrorCorrectLevel.L));
  final n = image.moduleCount;
  bool dark(int x, int y) => x >= 0 && y >= 0 && x < n && y < n && image.isDark(y, x);
  final out = StringBuffer();
  for (var y = -2; y < n + 2; y += 2) {
    for (var x = -2; x < n + 2; x++) {
      final top = !dark(x, y), bottom = !dark(x, y + 1);
      out.write(top && bottom ? '█' : top ? '▀' : bottom ? '▄' : ' ');
    }
    out.writeln();
  }
  return out.toString();
}
