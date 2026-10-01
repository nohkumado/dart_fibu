/// Someone offers and invoices go to: a business or a private person, in a
/// country, maybe with a VAT id — what decides the tax treatment — and the
/// language and envelope window their letters use.
class Customer {
  /// Short key, unique in the archive (e.g. "assoc-exemple").
  final String id;
  final String name;

  /// Postal address below the name, one entry per line.
  final List<String> address;

  /// ISO country code, upper case (FR, DE, …).
  final String country;

  /// A business (B2B) rather than a private person.
  final bool business;

  /// The customer's VAT id ("" when none).
  final String vatId;

  /// Language of their documents: fr, de or en.
  final String lang;

  /// Where their envelopes have the window: "left" (DIN 5008), "right"
  /// (usual in France) or "" (by the letter's language: fr right, else
  /// left).
  final String window;

  const Customer({
    required this.id,
    required this.name,
    this.address = const [],
    this.country = 'FR',
    this.business = false,
    this.vatId = '',
    this.lang = 'fr',
    this.window = '',
  });

  /// The window side of their letters.
  String get windowSide => window.isNotEmpty ? window : (lang == 'fr' ? 'right' : 'left');

  /// The lines of the address field: name, then the address.
  List<String> get addressBlock => [name, ...address];

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'address': address,
        'country': country,
        'business': business,
        'vat_id': vatId,
        'lang': lang,
        if (window.isNotEmpty) 'window': window,
      };

  factory Customer.fromJson(Map<String, dynamic> j) => Customer(
        id: '${j['id']}',
        name: '${j['name'] ?? ''}',
        address: [for (final l in (j['address'] as List?) ?? const []) '$l'],
        country: '${j['country'] ?? 'FR'}'.toUpperCase(),
        business: j['business'] == true,
        vatId: '${j['vat_id'] ?? ''}',
        lang: '${j['lang'] ?? 'fr'}',
        window: '${j['window'] ?? ''}',
      );
}
