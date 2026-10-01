import 'dart:io';

import '../../nohfibu.dart';

/// Invoice numbers YYYY-NNNN, continuous within a year (as French law
/// wants: chronological, no gaps). The last number issued is kept in a
/// small file next to the archive.
class InvoiceNumbering {
  /// The counter file; null: the numbers come from [documents].
  final File? counter;

  /// Put before the year, e.g. "D" for offers (D2026-0001), a device's
  /// series for documents issued there (PHONE-2026-0001).
  final String prefix;

  /// With a history: the documents of this kind, the next number is the
  /// highest of this prefix and year + 1 — no counter file to keep in sync.
  final Iterable<Invoice> Function()? documents;

  InvoiceNumbering(File this.counter, {this.prefix = ''}) : documents = null;

  /// Numbers taken from [documents] (the history), not from a file.
  InvoiceNumbering.fromDocuments(Iterable<Invoice> Function() this.documents, {this.prefix = ''}) : counter = null;

  /// The next number for [date], without taking it (see [take]).
  String peek(DateTime date) {
    final pattern = RegExp('^${RegExp.escape(prefix)}(\\d{4})-(\\d+)\$');
    var n = 1;
    if (documents != null) {
      for (final d in documents!()) {
        final m = pattern.firstMatch(d.number);
        if (m != null && int.parse(m.group(1)!) == date.year) {
          final k = int.parse(m.group(2)!) + 1;
          if (k > n) n = k;
        }
      }
    } else {
      final last = counter!.existsSync() ? counter!.readAsStringSync().trim() : '';
      final m = pattern.firstMatch(last);
      if (m != null && int.parse(m.group(1)!) == date.year) n = int.parse(m.group(2)!) + 1;
    }
    return '$prefix${date.year}-${n.toString().padLeft(4, '0')}';
  }

  /// Takes the next number for [date]: stored as the last one issued.
  String take(DateTime date) {
    final number = peek(date);
    counter?.writeAsStringSync('$number\n');
    return number;
  }
}
