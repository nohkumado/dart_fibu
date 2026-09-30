import '../../nohfibu.dart';

/// The journal lines of an issued invoice, with the accounts of its
/// letterhead: revenue → receivable for the net amount, VAT account →
/// receivable for the VAT. Estimates, and letterheads without a `book:`
/// block, give none.
class InvoiceBooking {
  const InvoiceBooking._();

  /// Journal lines for [invoice] in [book]; throws [StateError] when an
  /// account of the letterhead is not in the book's plan.
  static List<JrlLine> lines(Invoice invoice, Letterhead letterhead, Book book) {
    if (invoice.kind != InvoiceKind.invoice || !letterhead.books) return const [];
    Konto account(String role) {
      final number = letterhead.bookAccounts[role]!;
      final k = book.kpl.get(number);
      if (k == null || !k.valid()) {
        throw StateError('letterhead ${letterhead.id}: $role account $number is not in the plan');
      }
      return k;
    }

    final receivable = account('receivable');
    final what = 'Facture ${invoice.number} ${invoice.address.isEmpty ? '' : invoice.address.first}'.trim();
    final out = [
      JrlLine(datum: invoice.date, kmin: account('revenue'), kplu: receivable, desc: what, valuta: invoice.netCents),
    ];
    if (invoice.vatCents != 0) {
      out.add(JrlLine(datum: invoice.date, kmin: account('vat'), kplu: receivable, desc: '$what TVA', valuta: invoice.vatCents));
    }
    return out;
  }
}
