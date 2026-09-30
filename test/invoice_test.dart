import 'dart:io';

import 'package:nohfibu/csv_handler.dart';
import 'package:nohfibu/fibusettings.dart';
import 'package:nohfibu/nohfibu.dart';
import 'package:test/test.dart';

void main() {
  final archive = InvoiceArchive.load(File('assets/invoice/archive.example.csv'));
  final letterhead = Letterhead.load(File('assets/invoice/letterhead.example.yaml'));

  test('the archive in facture\'s old layout: fields, address lines, items', () {
    expect(archive.invoices, hasLength(2));
    final first = archive.byNumber('2026-0001')!;
    expect(first.kind, InvoiceKind.invoice);
    expect(first.lang, 'fr');
    expect(first.date, DateTime(2026, 9, 15));
    expect(first.address, ['Association Exemple', '3 place du Marché', '67000 Strasbourg']);
    expect(first.items.map((i) => i.totalCents), [24000, 3550]);
    expect(first.grossCents, 27550);
    expect(archive.byNumber('2026-0002')!.kind, InvoiceKind.estimate);
  });

  test('VAT: net, VAT, gross', () {
    final de = archive.byNumber('2026-0002')!;
    expect(de.netCents, 45000);
    expect(de.vatCents, 8550);
    expect(de.grossCents, 53550);
  });

  test('saved and read again, the archive is the same', () {
    final again = InvoiceArchive.parse(archive.encode());
    expect(again.encode(), archive.encode());
    expect(again.byNumber('2026-0001')!.address, archive.byNumber('2026-0001')!.address);
  });

  test('numbers: continuous within a year, 0001 again in a new year', () {
    final dir = Directory.systemTemp.createTempSync('facture');
    final n = InvoiceNumbering(File('${dir.path}/n'));
    expect(n.take(DateTime(2026, 3, 1)), '2026-0001');
    expect(n.take(DateTime(2026, 3, 2)), '2026-0002');
    expect(n.peek(DateTime(2026, 4, 1)), '2026-0003');
    expect(n.take(DateTime(2027, 1, 5)), '2027-0001');
    dir.deleteSync(recursive: true);
  });

  test('the letterhead: details, and it books', () {
    expect(letterhead.id, 'letterhead.example');
    expect(letterhead.iban, startsWith('FR76'));
    expect(letterhead.books, isTrue);
  });

  test('booking: revenue → receivable; estimates and non-booking letterheads give none', () {
    final settings = FibuSettings()..init(['-b', 'assets/wbsamples/compta2018.csv']);
    final book = Book();
    CsvHandler().load(book: book, conf: settings);
    final lines = InvoiceBooking.lines(archive.byNumber('2026-0001')!, letterhead, book);
    expect(lines, hasLength(1));
    expect(lines.single.kminus.name, '4410');
    expect(lines.single.kplus.name, '1100');
    expect(lines.single.valuta, 27550);
    expect(InvoiceBooking.lines(archive.byNumber('2026-0002')!, letterhead, book), isEmpty);
    const plain = Letterhead(id: 'x', name: 'x');
    expect(InvoiceBooking.lines(archive.byNumber('2026-0001')!, plain, book), isEmpty);
  });

  test('the PDF', () async {
    final bytes = await InvoicePdf.render(archive.byNumber('2026-0001')!, letterhead);
    expect(String.fromCharCodes(bytes.take(5)), '%PDF-');
    expect(bytes.length, greaterThan(1000));
  });
}
