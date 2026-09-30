/// One line of an invoice: what, how many, at which unit price.
class InvoiceItem {
  final String denomination;
  final num quantity;

  /// Unit price before VAT, in cents.
  final int unitPriceCents;

  const InvoiceItem(this.denomination, this.quantity, this.unitPriceCents);

  /// Quantity × unit price, in cents (rounded).
  int get totalCents => (quantity * unitPriceCents).round();
}
