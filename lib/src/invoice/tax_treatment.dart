import '../../nohfibu.dart';

/// The VAT of one document: kind, rate and the legal note it must carry —
/// decided by the issuer's [TaxProfile], the [Customer] and the service
/// category, printed in the document's language.
class TaxTreatment {
  final TaxKind kind;

  /// The rate applied (0 for franchise and reverse charge).
  final double rate;

  /// The legal note for the document ("" when none is needed).
  final String note;

  const TaxTreatment(this.kind, this.rate, this.note);

  static const _notes = {
    TaxKind.franchise: {
      'fr': 'TVA non applicable, art. 293 B du CGI',
      'de': 'Keine Umsatzsteuer: Steuerbefreiung nach Art. 293 B CGI (französische Kleinunternehmerregelung)',
      'en': 'VAT not applicable, art. 293 B of the French General Tax Code',
    },
    TaxKind.reverseCharge: {
      'fr': 'Autoliquidation : TVA due par le preneur (art. 283-2 du CGI, art. 196 de la directive 2006/112/CE)',
      'de': 'Steuerschuldnerschaft des Leistungsempfängers (Art. 196 MwStSystRL, § 13b UStG)',
      'en': 'Reverse charge: VAT due by the recipient (art. 196 of Directive 2006/112/EC)',
    },
  };

  /// The treatment of a document of [category] from [profile] to
  /// [customer], with notes in [lang]; [franchiseNote] replaces the
  /// standard franchise text when the letterhead gives one.
  ///
  /// Reverse charge first (a business of another country with a VAT id,
  /// for a category the profile lists), then franchise, then the rate of
  /// the category or the standard rate.
  static TaxTreatment of(TaxProfile profile, Customer customer, String category,
      {String lang = 'fr', String franchiseNote = ''}) {
    String note(TaxKind k) => _notes[k]![lang] ?? _notes[k]!['en']!;
    if (customer.business &&
        customer.vatId.isNotEmpty &&
        customer.country != profile.country &&
        profile.reverseChargeFor(category)) {
      return TaxTreatment(TaxKind.reverseCharge, 0, note(TaxKind.reverseCharge));
    }
    if (profile.regime == 'franchise') {
      return TaxTreatment(TaxKind.franchise, 0, franchiseNote.isNotEmpty ? franchiseNote : note(TaxKind.franchise));
    }
    return TaxTreatment(TaxKind.standard, profile.rates[category] ?? profile.rate, '');
  }
}
