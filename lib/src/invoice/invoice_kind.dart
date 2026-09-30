/// What a document of the invoice archive is (the old facture "type").
enum InvoiceKind {
  /// An invoice (facture, Rechnung): numbered, may be booked.
  invoice,

  /// An estimate (devis, Kostenvoranschlag): numbered, never booked.
  estimate;

  /// From the archive's type column (facture, devis, invoice, …).
  static InvoiceKind parse(String text) => switch (text.trim().toLowerCase()) {
        'devis' || 'estimate' || 'angebot' || 'kostenvoranschlag' => estimate,
        _ => invoice,
      };
}
