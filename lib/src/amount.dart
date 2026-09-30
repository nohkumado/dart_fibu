/// Amounts typed by a person or read from a book, as cents.
class Amount {
  const Amount._();

  /// "12" → 1200, "12,5" / "12.50" → 1250, "1.234,56" / "1,234.56" /
  /// "1 234,56 €" → 123456, "-3" → -300; null when it is no amount.
  ///
  /// The last "," or "." followed by one or two digits is the decimal mark;
  /// every other "," "." or space groups thousands.
  static int? parseCents(String text) {
    var s = text.replaceAll(RegExp(r'[€$£\s]|EUR|CHF|USD', caseSensitive: false), '');
    if (s.isEmpty) return null;
    final negative = s.startsWith('-');
    if (negative || s.startsWith('+')) s = s.substring(1);
    final decimal = RegExp(r'^(.*)[.,](\d{1,2})$').firstMatch(s);
    String whole = s, fraction = '0';
    if (decimal != null) {
      whole = decimal.group(1)!;
      fraction = decimal.group(2)!.padRight(2, '0');
    }
    whole = whole.replaceAll(RegExp(r'[.,]'), '');
    if (whole.isEmpty) whole = '0';
    if (!RegExp(r'^\d+$').hasMatch(whole)) return null;
    final cents = int.parse(whole) * 100 + int.parse(fraction);
    return negative ? -cents : cents;
  }
}
