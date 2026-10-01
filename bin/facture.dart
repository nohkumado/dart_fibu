// facture — offers, invoices, reminders and payments (successor of the
// 2005 PHP facture), on one archive per issuer:
//
//   dart run nohfibu:facture -s factures.json status
//   … customer add | customer list
//   … offer | invoice                 (asks, issues, writes the PDF)
//   … accept D2026-0001 | refuse D2026-0001
//   … invoice-offer D2026-0001        (the invoice of an accepted offer)
//   … reminders [--send]              (due reminders; --send writes them)
//   … pay 2026-0001 435,00 [--date 2026-11-02]
//   … pdf 2026-0001
//   … import base.csv                 (facture's old CSV archive)
//
// With --book compta.csv issued invoices and payments are also booked
// (letterheads with a book: block; the book's previous version as .bak).
import 'dart:io';

import 'package:args/args.dart';
import 'package:nohfibu/csv_handler.dart';
import 'package:nohfibu/fibusettings.dart';
import 'package:nohfibu/nohfibu.dart';

const _commands = {
  'status': 'documents, open offers, overdue invoices, reminders due',
  'customer': 'add | list',
  'offer': 'write and issue an offer (asks)',
  'invoice': 'write and issue an invoice (asks)',
  'accept': '<offer number>: the customer accepted',
  'refuse': '<offer number>: the customer declined',
  'invoice-offer': '<offer number>: issue the invoice of an accepted offer',
  'reminders': 'list the reminders due; --send writes and records them',
  'pay': '<invoice number> <amount>: record a payment',
  'pdf': '<number>: write the PDF of an offer or invoice',
  'import': "<base.csv>: facture's old CSV archive into the store",
};

Future<void> main(List<String> arguments) async {
  final home = Platform.environment['HOME'] ?? '.';
  final parser = ArgParser()
    ..addOption('store', abbr: 's', help: 'the archive of offers, invoices and customers (JSON; created when missing)')
    ..addOption('ledger', abbr: 'B', help: 'work on this book\'s history instead (see the ledger command): archive and book from it, changes recorded')
    ..addOption('base', defaultsTo: '$home/.config/nohfibu', help: 'with --ledger: where histories and keys live')
    ..addOption('letterheads', abbr: 'l', defaultsTo: '$home/.config/nohfibu/letterheads', help: 'directory of the letterheads (*.yaml)')
    ..addOption('out', abbr: 'o', help: 'directory for the PDFs (default: next to the store)')
    ..addOption('book', abbr: 'b', help: 'book issued invoices and payments into this book (CSV)')
    ..addOption('date', help: 'date of the action (default: today)')
    ..addFlag('send', negatable: false, help: 'reminders: write the PDFs and record them as sent')
    ..addFlag('help', abbr: 'h', negatable: false);
  String usage() => 'facture — offers, invoices, reminders, payments\n\n'
      'facture -s <store.json> <command> [arguments]\n\n'
      '${_commands.entries.map((e) => '  ${e.key.padRight(14)} ${e.value}').join('\n')}\n\n${parser.usage}';

  final ArgResults args;
  try {
    args = parser.parse(arguments);
  } on FormatException catch (e) {
    stderr.writeln('${e.message}\n\n${usage()}');
    exitCode = 64;
    return;
  }
  final rest = args.rest;
  if (args['help'] as bool || rest.isEmpty) {
    print(usage());
    return;
  }
  if (args['store'] == null && args['ledger'] == null) {
    stderr.writeln('facture: which archive? give it with -s / --store (created when missing), or a book\'s history with -B\n\n${usage()}');
    exitCode = 64;
    return;
  }
  final command = rest.first;
  if (!_commands.containsKey(command)) {
    stderr.writeln('facture: unknown command "$command"\n\n${usage()}');
    exitCode = 64;
    return;
  }

  // the archive: a JSON file, or a book's history (then the book too)
  final repo = args['ledger'] == null ? null : await LedgerRepo.open(Directory(args['base'] as String), args['ledger'] as String);
  final ledger = repo?.ledger;
  final storeFile = File((args['store'] as String?) ?? '${repo!.historyDir.path}/factures.json');
  final store = ledger?.store ?? InvoiceStore.load(storeFile);
  final letterheads = {
    if (ledger != null)
      for (final e in ledger.letterheads.entries) e.key: Letterhead.parse(e.value, id: e.key),
    ...Letterhead.loadAll(Directory(args['letterheads'] as String)),
  };
  final desk = repo == null
      ? InvoiceDesk.forFile(store, storeFile, letterheads)
      : InvoiceDesk.forHistory(store, letterheads, series: repo.series);
  final outDir = Directory((args['out'] as String?) ?? (repo == null ? storeFile.absolute.parent.path : Directory.current.path));
  final date = args['date'] == null ? DateTime.now() : FibuDate.parse(args['date'] as String);
  if (date == null) {
    stderr.writeln('facture: --date ${args['date']} is no date');
    exitCode = 64;
    return;
  }
  final bookPath = args['book'] as String?;
  final book = ledger?.book ?? (bookPath == null ? null : _loadBook(bookPath));
  final before = ledger == null ? null : LedgerDiff.capture(book: ledger.book, store: store);
  final booked = <JrlLine>[];

  String eur(int cents) => '${(cents / 100).toStringAsFixed(2)} €';

  Future<void> pdf(Invoice doc) async {
    final lh = letterheads[doc.letterhead];
    if (lh == null) throw StateError('no letterhead "${doc.letterhead}" in ${args['letterheads']}');
    outDir.createSync(recursive: true);
    final file = File('${outDir.path}/${doc.name.isEmpty ? doc.number : doc.name}.pdf');
    file.writeAsBytesSync(await InvoicePdf.render(doc, lh, customer: store.customerOf(doc)));
    print('wrote ${file.path}');
  }

  Invoice need(String number, {InvoiceKind? kind}) =>
      store.find(number, kind: kind) ?? (throw StateError('no ${kind?.name ?? 'document'} $number in ${storeFile.path}'));

  try {
    switch (command) {
      case 'status':
        for (final d in store.documents) {
          final who = store.customerOf(d).name;
          print('${d.number.padRight(12)} ${FibuDate.show(d.date)}  ${eur(d.grossCents).padLeft(12)}  '
              '${d.kind.name.padRight(8)} ${d.status(date).name.padRight(9)} $who');
        }
        final due = desk.remindersDue(date);
        if (due.isNotEmpty) {
          print('\nreminders due:');
          for (final r in due) {
            print('  ${r.invoice.number}: level ${r.level}, ${r.invoice.daysOverdue(date)} days late, ${eur(r.totalCents)}');
          }
        }
      case 'customer':
        if (rest.length > 1 && rest[1] == 'add') {
          final c = _askCustomer(store);
          store.customers[c.id] = c;
          print('added customer ${c.id}');
        } else {
          for (final c in store.customers.values) {
            print('${c.id.padRight(14)} ${c.name.padRight(30)} ${c.country} ${c.business ? 'business' : 'private '} '
                '${c.lang} ${c.vatId}');
          }
        }
      case 'offer' || 'invoice':
        if (letterheads.isEmpty) throw StateError('no letterhead in ${args['letterheads']} — start from assets/invoice/letterhead.example.yaml');
        if (store.customers.isEmpty) throw StateError('no customer yet — facture -s … customer add');
        final kind = command == 'offer' ? InvoiceKind.estimate : InvoiceKind.invoice;
        final draft = _askDocument(desk, kind, date);
        final (doc, lines) = desk.issue(draft, date: date, book: book);
        booked.addAll(lines);
        print('issued ${doc.kind.name} ${doc.number}: ${eur(doc.grossCents)} (${doc.taxKind.name})');
        await pdf(doc);
      case 'accept' || 'refuse':
        final offer = need(rest[1], kind: InvoiceKind.estimate);
        desk.answer(offer, accepted: command == 'accept', date: date);
        print('${offer.number}: ${offer.status(date).name}');
      case 'invoice-offer':
        final offer = need(rest[1], kind: InvoiceKind.estimate);
        final (invoice, lines) = desk.invoiceOffer(offer, date: date, book: book);
        booked.addAll(lines);
        print('issued invoice ${invoice.number} for offer ${offer.number}: ${eur(invoice.grossCents)}');
        await pdf(invoice);
      case 'reminders':
        final due = desk.remindersDue(date);
        if (due.isEmpty) print('no reminder due');
        for (final r in due) {
          print('${r.invoice.number}: level ${r.level}, open ${eur(r.invoice.openCents)}'
              '${r.interestCents + r.feeCents > 0 ? ', + ${eur(r.interestCents)} interest, + ${eur(r.feeCents)} fee' : ''}');
          if (args['send'] as bool) {
            final lh = letterheads[r.invoice.letterhead]!;
            outDir.createSync(recursive: true);
            final file = File('${outDir.path}/${r.invoice.number}_reminder${r.level}.pdf');
            file.writeAsBytesSync(await ReminderPdf.render(r, lh, store.customerOf(r.invoice)));
            desk.sent(r);
            print('  wrote ${file.path}');
          }
        }
      case 'pay':
        final invoice = need(rest[1], kind: InvoiceKind.invoice);
        final cents = rest.length > 2 ? Amount.parseCents(rest[2]) : invoice.openCents;
        if (cents == null) throw StateError('${rest[2]} is no amount');
        booked.addAll(desk.pay(invoice, cents, date: date, book: book));
        print('${invoice.number}: paid ${eur(cents)}, open ${eur(invoice.openCents)} — ${invoice.status(date).name}');
      case 'pdf':
        await pdf(need(rest[1]));
      case 'import':
        final old = InvoiceStore.load(File(rest[1]));
        var added = 0;
        for (final d in old.documents) {
          if (store.find(d.number, kind: d.kind) == null) {
            store.documents.add(d);
            added++;
          }
        }
        print('imported $added documents from ${rest[1]} (old invoices counted as paid)');
    }
  } on StateError catch (e) {
    stderr.writeln('facture: ${e.message}');
    exitCode = 1;
    return;
  } on RangeError {
    stderr.writeln('facture: $command needs an argument (${_commands[command]})');
    exitCode = 64;
    return;
  }

  if (repo != null) {
    // booked lines into the book of the history, then everything recorded
    for (final l in booked) {
      print('  booked $l');
      book!.jrl.add(l);
    }
    final change = await repo.record(LedgerDiff.since(before!, book: book, store: store));
    if (change != null) print('recorded in ${repo.book} (${change.ops.length} changes) on ${repo.device}');
    return;
  }
  store.save(storeFile);
  if (book != null && booked.isNotEmpty) {
    for (final l in booked) {
      print('  booked $l');
      book.jrl.add(l);
    }
    final bookFile = File(bookPath!);
    bookFile.copySync('${bookFile.path}.bak');
    final settings = FibuSettings()..init(['-b', bookPath, '-o', bookPath.replaceAll(RegExp(r'\.csv$'), '')]);
    await CsvHandler().save(book: book, conf: settings);
  }
}

Book _loadBook(String path) {
  final book = Book();
  CsvHandler().load(book: book, conf: FibuSettings()..init(['-b', path]));
  return book;
}

String _ask(String prompt, [String def = '']) {
  stdout.write(def.isEmpty ? '$prompt: ' : '$prompt [$def]: ');
  final a = (stdin.readLineSync() ?? '').trim();
  return a.isEmpty ? def : a;
}

Customer _askCustomer(InvoiceStore store) {
  final name = _ask('name');
  var id = _ask('short id', name.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '-'));
  while (store.customers.containsKey(id)) {
    id = _ask('"$id" exists, another id');
  }
  final address = <String>[];
  print('address, one line at a time, empty line to end:');
  while (true) {
    final l = _ask('  address');
    if (l.isEmpty) break;
    address.add(l);
  }
  final country = _ask('country (FR, DE, …)', 'FR').toUpperCase();
  final business = _ask('business (y/n)', 'n').toLowerCase().startsWith('y');
  final vat = business ? _ask('VAT id (empty: none)') : '';
  final lang = _ask('language (fr/de/en)', country == 'DE' ? 'de' : 'fr');
  return Customer(id: id, name: name, address: address, country: country, business: business, vatId: vat, lang: lang);
}

Invoice _askDocument(InvoiceDesk desk, InvoiceKind kind, DateTime date) {
  final letterhead = _ask('letterhead (${desk.letterheads.keys.join(', ')})', desk.letterheads.keys.first);
  final customer = _ask('customer (${desk.store.customers.keys.join(', ')})', desk.store.customers.keys.first);
  final category = _ask('category (e.g. 3dprint, cours; decides the tax)');
  final title = _ask('subject line (optional)');
  final service = FibuDate.parse(_ask('date of the service (optional)'));
  final days = int.tryParse(_ask(kind == InvoiceKind.estimate ? 'valid for days' : 'payable within days', '30')) ?? 30;
  final items = <InvoiceItem>[];
  print('items, empty description to end:');
  while (true) {
    final what = _ask('  description');
    if (what.isEmpty) break;
    final n = num.tryParse(_ask('  quantity', '1').replaceAll(',', '.')) ?? 1;
    final price = Amount.parseCents(_ask('  unit price (net)', '0')) ?? 0;
    items.add(InvoiceItem(what, n, price));
  }
  return desk.draft(
      kind: kind, letterhead: letterhead, customerId: customer, items: items,
      category: category, title: title, date: date, serviceDate: service, days: days);
}
