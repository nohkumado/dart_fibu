import 'dart:io';

/// Invoice numbers YYYY-NNNN, continuous within a year (as French law
/// wants: chronological, no gaps). The last number issued is kept in a
/// small file next to the archive.
class InvoiceNumbering {
  final File counter;

  /// Put before the year, e.g. "D" for offers (D2026-0001).
  final String prefix;

  InvoiceNumbering(this.counter, {this.prefix = ''});

  /// The next number for [date], without taking it (see [take]).
  String peek(DateTime date) {
    final last = counter.existsSync() ? counter.readAsStringSync().trim() : '';
    final m = RegExp('^${RegExp.escape(prefix)}(\\d{4})-(\\d+)\$').firstMatch(last);
    final n = (m != null && int.parse(m.group(1)!) == date.year) ? int.parse(m.group(2)!) + 1 : 1;
    return '$prefix${date.year}-${n.toString().padLeft(4, '0')}';
  }

  /// Takes the next number for [date]: stored as the last one issued.
  String take(DateTime date) {
    final number = peek(date);
    counter.writeAsStringSync('$number\n');
    return number;
  }
}
