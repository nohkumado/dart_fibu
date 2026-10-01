/// The role of an account in the books: asset, liability (and equity),
/// expense or income.
///
/// Book format 1 (files without a version line) knows the role only from
/// the account plan's block — the first digit: 1 asset, 2 liability,
/// 3 expense, 4 income. From format 2 on every account carries its role in
/// the KPL's `role` column, so modern charts (e.g. the French PCG, where
/// 6 is expenses and 7 income) work too.
enum AccountType {
  Actif,
  Passif,
  Charge,
  Produit;

  /// How the role is written in the book file.
  String get key => name.toLowerCase();

  /// Assets and expenses grow with debits; liabilities and income with
  /// credits.
  bool get debitSide => this == Actif || this == Charge;

  /// The role a book file names: actif/passif/charge/produit, or the German
  /// and English words for them; null for anything else.
  static AccountType? parse(String text) => switch (text.trim().toLowerCase()) {
        'actif' || 'aktiv' || 'aktiva' || 'asset' || 'assets' => Actif,
        'passif' || 'passiv' || 'passiva' || 'liability' || 'liabilities' || 'equity' => Passif,
        'charge' || 'charges' || 'kosten' || 'aufwand' || 'expense' || 'expenses' => Charge,
        'produit' || 'produits' || 'einnahmen' || 'ertrag' || 'income' || 'revenue' => Produit,
        _ => null,
      };

  /// The role by the old block rule (format 1): from the account's first
  /// digit; assets for anything else.
  static AccountType fromBlock(String account) => switch (account.isEmpty ? '' : account[0]) {
        '2' => Passif,
        '3' => Charge,
        '4' => Produit,
        _ => Actif,
      };
}
