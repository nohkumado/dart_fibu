/// How VAT is handled on a document.
enum TaxKind {
  /// The issuer charges no VAT (French franchise en base, art. 293 B CGI).
  franchise,

  /// VAT at a rate (the issuer's standard rate, or its category's).
  standard,

  /// No VAT charged: the business customer of another EU country owes it
  /// (autoliquidation / Steuerschuldnerschaft des Leistungsempfängers).
  reverseCharge,
}
