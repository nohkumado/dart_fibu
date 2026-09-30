import 'dart:io';

import 'package:csv/csv.dart';

import '../../nohfibu.dart';

/// The invoices of one issuer, in facture's CSV layout (compatible with the
/// 2005 base.csv): `;`-separated, a header row "lang;type;config;name;
/// title;date;paydate;invoicenr;address;tva", then the items as
/// denomination;quantity;price triples. Dates dd.MM.yyyy, the address
/// lines joined by `\\`, prices in currency units.
class InvoiceArchive {
  static const header = ['lang', 'type', 'config', 'name', 'title', 'date', 'paydate', 'invoicenr', 'address', 'tva'];

  final List<Invoice> invoices;

  InvoiceArchive([List<Invoice>? invoices]) : invoices = invoices ?? [];

  /// The invoice numbered [number], or null.
  Invoice? byNumber(String number) {
    for (final i in invoices) {
      if (i.number == number) return i;
    }
    return null;
  }

  /// Reads the archive in [text].
  factory InvoiceArchive.parse(String text) {
    final rows = Csv(fieldDelimiter: ';', autoDetect: false).decode(text);
    final out = <Invoice>[];
    for (final row in rows.skip(1)) {
      final f = [for (final v in row) '$v'.trim()];
      if (f.length < header.length) continue;
      final items = <InvoiceItem>[];
      for (var i = header.length; i + 2 < f.length; i += 3) {
        if (f[i].isEmpty) continue;
        items.add(InvoiceItem(f[i], num.tryParse(f[i + 1].replaceAll(',', '.')) ?? 0, Amount.parseCents(f[i + 2]) ?? 0));
      }
      out.add(Invoice(
        lang: f[0].toLowerCase(),
        kind: InvoiceKind.parse(f[1]),
        letterhead: f[2],
        name: f[3],
        title: f[4],
        date: FibuDate.parse(f[5]) ?? DateTime.now(),
        payDate: FibuDate.parse(f[6]) ?? FibuDate.parse(f[5]) ?? DateTime.now(),
        number: f[7],
        address: f[8].split(r'\\').map((l) => l.trim()).where((l) => l.isNotEmpty).toList(),
        vatRate: double.tryParse(f[9].replaceAll(',', '.')) ?? 0,
        items: items,
      ));
    }
    return InvoiceArchive(out);
  }

  /// Reads [file]; an empty archive when it does not exist yet.
  factory InvoiceArchive.load(File file) =>
      file.existsSync() ? InvoiceArchive.parse(file.readAsStringSync()) : InvoiceArchive();

  /// The archive as text, in the same layout [parse] reads.
  String encode() {
    String d(DateTime t) => '${t.day.toString().padLeft(2, '0')}.${t.month.toString().padLeft(2, '0')}.${t.year}';
    String money(int cents) => (cents / 100).toStringAsFixed(2);
    final rows = <List<dynamic>>[header];
    for (final i in invoices) {
      rows.add([
        i.lang.toUpperCase(),
        i.kind == InvoiceKind.estimate ? 'devis' : 'facture',
        i.letterhead,
        i.name,
        i.title,
        d(i.date),
        d(i.payDate),
        i.number,
        i.address.join(r'\\'),
        '${i.vatRate}',
        for (final item in i.items) ...[item.denomination, '${item.quantity}', money(item.unitPriceCents)],
      ]);
    }
    return '${Csv(fieldDelimiter: ';', lineDelimiter: '\n', autoDetect: false).encode(rows)}\n';
  }

  /// Writes the archive to [file].
  void save(File file) => file.writeAsStringSync(encode());
}
