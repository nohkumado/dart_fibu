import 'package:intl/intl.dart';

/// Dates as people type them in a book: 17-11-2005, 17.11.05, 2005-11-17…
class FibuDate {
  const FibuDate._();

  static final _formats = [
    'dd-MM-yyyy', 'dd.MM.yyyy', 'dd/MM/yyyy',
    'dd-MM-yy', 'dd.MM.yy', 'dd/MM/yy',
  ];

  /// The date [text] stands for; null when it is none of the known forms.
  static DateTime? parse(String text) {
    final t = text.trim();
    if (t.isEmpty) return null;
    if (RegExp(r'^\d{4}-\d{2}-\d{2}').hasMatch(t)) return DateTime.tryParse(t);
    for (final f in _formats) {
      try {
        final d = DateFormat(f).parseStrict(t);
        // two-digit years belong to this century
        return d.year < 100 ? DateTime(2000 + d.year, d.month, d.day) : d;
      } on FormatException {
        continue;
      }
    }
    return null;
  }

  /// How the book shows a date (dd-MM-yyyy).
  static String show(DateTime d) => DateFormat('dd-MM-yyyy').format(d);
}
