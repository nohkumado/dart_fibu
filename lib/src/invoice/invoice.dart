import '../../nohfibu.dart';

/// One invoice or estimate: to whom, when, what — and its totals.
class Invoice {
  final InvoiceKind kind;

  /// Language of the document: fr, de or en.
  final String lang;

  /// Id of the [Letterhead] it is issued under.
  final String letterhead;

  /// File name of its PDF (without extension).
  final String name;

  /// Subject line under the heading (e.g. "Mission d'enseignement").
  final String title;
  final DateTime date;
  final DateTime payDate;

  /// The invoice number, unique in the archive.
  final String number;

  /// The customer's address, one entry per line.
  final List<String> address;

  /// VAT rate, 0.2 for 20 %; 0 for none.
  final double vatRate;
  final List<InvoiceItem> items;

  const Invoice({
    this.kind = InvoiceKind.invoice,
    this.lang = 'fr',
    required this.letterhead,
    required this.name,
    this.title = '',
    required this.date,
    required this.payDate,
    required this.number,
    required this.address,
    this.vatRate = 0,
    required this.items,
  });

  /// Sum of the items before VAT, in cents.
  int get netCents => items.fold(0, (sum, i) => sum + i.totalCents);

  /// The VAT on [netCents], in cents.
  int get vatCents => (netCents * vatRate).round();

  /// What the customer pays, in cents.
  int get grossCents => netCents + vatCents;
}
