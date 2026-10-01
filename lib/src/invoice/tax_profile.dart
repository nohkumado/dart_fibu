/// The tax regime of an issuer (a letterhead's `tax:` block):
///
/// ```yaml
/// country: FR
/// tax:
///   regime: franchise        # or vat
///   rate: 0.20               # standard rate (regime vat)
///   rates: {cours: 0.19}     # other rates by category
///   reverse_charge: [3dprint]   # categories under reverse charge for EU
///                               # businesses with a VAT id; [*] for all
/// ```
class TaxProfile {
  /// ISO country of the issuer.
  final String country;

  /// "franchise" (no VAT, art. 293 B CGI) or "vat".
  final String regime;

  /// Standard VAT rate (0.2 = 20 %).
  final double rate;

  /// Rates by category, overriding [rate].
  final Map<String, double> rates;

  /// Categories invoiced under reverse charge to businesses of other EU
  /// countries that have a VAT id; `*` for every category.
  final List<String> reverseCharge;

  const TaxProfile({
    this.country = 'FR',
    this.regime = 'franchise',
    this.rate = 0.2,
    this.rates = const {},
    this.reverseCharge = const [],
  });

  /// From a letterhead's `tax:` block (a map) and its `country:`.
  factory TaxProfile.fromMap(Map? m, {String country = 'FR'}) {
    m ??= const {};
    double r(dynamic v) => double.tryParse('$v'.replaceAll(',', '.')) ?? 0;
    return TaxProfile(
      country: country.toUpperCase(),
      regime: '${m['regime'] ?? 'franchise'}',
      rate: m.containsKey('rate') ? r(m['rate']) : 0.2,
      rates: {for (final e in ((m['rates'] as Map?) ?? const {}).entries) '${e.key}': r(e.value)},
      reverseCharge: [for (final c in (m['reverse_charge'] as List?) ?? const []) '$c'],
    );
  }

  bool reverseChargeFor(String category) =>
      reverseCharge.contains('*') || (category.isNotEmpty && reverseCharge.contains(category));
}
