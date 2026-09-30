// facture — invoices and estimates of nohfibu (successor of the 2005 PHP
// facture): the archive in its CSV layout, letterheads as YAML, PDFs.
//
//   dart run nohfibu:facture -a factures.csv --list
//   dart run nohfibu:facture -a factures.csv --pdf 2026-0001
//   dart run nohfibu:facture -a factures.csv --new [--book compta2026.csv]
import 'dart:io';

import 'package:args/args.dart';
import 'package:nohfibu/csv_handler.dart';
import 'package:nohfibu/fibusettings.dart';
import 'package:nohfibu/nohfibu.dart';

Future<void> main(List<String> arguments) async {
  final home = Platform.environment['HOME'] ?? '.';
  final parser = ArgParser()
    ..addOption('archive', abbr: 'a', help: 'the invoice archive (CSV)', mandatory: true)
    ..addOption('letterheads', abbr: 'l', defaultsTo: '$home/.config/nohfibu/letterheads', help: 'directory of the letterheads (*.yaml)')
    ..addOption('out', abbr: 'o', help: 'directory for the PDFs (default: next to the archive)')
    ..addFlag('list', help: 'list the archive')
    ..addOption('pdf', help: 'make the PDF of invoice <number>')
    ..addFlag('new', help: 'write a new invoice (asks for it), then its PDF')
    ..addOption('book', abbr: 'b', help: 'book an issued invoice into this book (letterheads with a book: block)')
    ..addFlag('help', abbr: 'h', negatable: false);
  final ArgResults args;
  try {
    args = parser.parse(arguments);
  } on FormatException catch (e) {
    stderr.writeln('${e.message}\n\n${parser.usage}');
    exitCode = 64;
    return;
  }
  if (args['help'] as bool) {
    print(parser.usage);
    return;
  }
  final archiveFile = File(args['archive'] as String);
  final archive = InvoiceArchive.load(archiveFile);
  final letterheads = Letterhead.loadAll(Directory(args['letterheads'] as String));
  final outDir = Directory((args['out'] as String?) ?? archiveFile.parent.path);

  if (args['list'] as bool) {
    for (final i in archive.invoices) {
      final who = i.address.isEmpty ? '' : i.address.first;
      print('${i.number.padRight(18)} ${FibuDate.show(i.date)}  ${(i.grossCents / 100).toStringAsFixed(2).padLeft(10)} €  ${i.kind.name.padRight(8)} $who');
    }
    return;
  }

  Future<void> pdf(Invoice invoice) async {
    final letterhead = letterheads[invoice.letterhead];
    if (letterhead == null) {
      stderr.writeln('no letterhead "${invoice.letterhead}" in ${args['letterheads']} (known: ${letterheads.keys.join(', ')})');
      exitCode = 1;
      return;
    }
    outDir.createSync(recursive: true);
    final file = File('${outDir.path}/${invoice.name.isEmpty ? invoice.number : invoice.name}.pdf');
    file.writeAsBytesSync(await InvoicePdf.render(invoice, letterhead));
    print('wrote ${file.path}');
  }

  if (args['pdf'] != null) {
    final invoice = archive.byNumber(args['pdf'] as String);
    if (invoice == null) {
      stderr.writeln('no invoice ${args['pdf']} in ${archiveFile.path}');
      exitCode = 1;
      return;
    }
    await pdf(invoice);
    return;
  }

  if (args['new'] as bool) {
    if (letterheads.isEmpty) {
      stderr.writeln('no letterhead in ${args['letterheads']} — copy assets/invoice/letterhead.example.yaml there');
      exitCode = 1;
      return;
    }
    final invoice = _ask(letterheads, InvoiceNumbering(File('${archiveFile.path}.number')));
    archive.invoices.add(invoice);
    archive.save(archiveFile);
    print('added ${invoice.number} to ${archiveFile.path}');
    await pdf(invoice);
    final letterhead = letterheads[invoice.letterhead]!;
    if (args['book'] != null && letterhead.books) {
      final settings = FibuSettings()..init(['-b', args['book'] as String]);
      final book = Book();
      final handler = CsvHandler()..load(book: book, conf: settings);
      final lines = InvoiceBooking.lines(invoice, letterhead, book);
      for (final l in lines) {
        print('  $l');
      }
      stdout.write('book these lines into ${args['book']} (old one kept as .bak)? (y/n) ');
      if ((stdin.readLineSync() ?? '').trim().toLowerCase() == 'y') {
        final bookFile = File(args['book'] as String);
        bookFile.copySync('${bookFile.path}.bak');
        for (final l in lines) {
          book.jrl.add(l);
        }
        settings['output'] = bookFile.path.replaceAll(RegExp(r'\.csv$'), '');
        await handler.save(book: book, conf: settings);
      }
    }
    return;
  }
  print(parser.usage);
}

/// Asks for a new invoice on the terminal.
Invoice _ask(Map<String, Letterhead> letterheads, InvoiceNumbering numbering) {
  String q(String prompt, [String def = '']) {
    stdout.write(def.isEmpty ? '$prompt: ' : '$prompt [$def]: ');
    final a = (stdin.readLineSync() ?? '').trim();
    return a.isEmpty ? def : a;
  }

  final letterhead = q('letterhead (${letterheads.keys.join(', ')})', letterheads.keys.first);
  final kind = InvoiceKind.parse(q('type (facture/devis)', 'facture'));
  final lang = q('language (fr/de/en)', 'fr');
  DateTime date;
  while (true) {
    final d = FibuDate.parse(q('date', FibuDate.show(DateTime.now())));
    if (d != null) {
      date = d;
      break;
    }
    print('not a date');
  }
  final pay = FibuDate.parse(q('due date', FibuDate.show(date.add(const Duration(days: 30))))) ?? date;
  final address = <String>[];
  print('customer address, one line at a time, empty line to end:');
  while (true) {
    final l = q('  address');
    if (l.isEmpty) break;
    address.add(l);
  }
  final title = q('subject line (optional)');
  final vat = double.tryParse(q('VAT rate (0, 0.2, …)', '0').replaceAll(',', '.')) ?? 0;
  final items = <InvoiceItem>[];
  print('items, empty description to end:');
  while (true) {
    final what = q('  description');
    if (what.isEmpty) break;
    final n = num.tryParse(q('  quantity', '1').replaceAll(',', '.')) ?? 1;
    final price = Amount.parseCents(q('  unit price (net)', '0')) ?? 0;
    items.add(InvoiceItem(what, n, price));
  }
  final number = numbering.take(date);
  final who = address.isEmpty ? '' : address.first.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '_');
  return Invoice(
    kind: kind,
    lang: lang,
    letterhead: letterhead,
    name: '${number}_$who',
    title: title,
    date: date,
    payDate: pay,
    number: number,
    address: address,
    vatRate: vat,
    items: items,
  );
}
