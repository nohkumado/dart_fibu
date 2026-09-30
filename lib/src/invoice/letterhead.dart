import 'dart:io';

import 'package:yaml/yaml.dart';

/// Who issues an invoice: address, contact, legal ids, bank, footer, logo —
/// and, when [bookAccounts] is set, the accounts an issued invoice is
/// booked on. Read from a YAML file (see assets/invoice/letterhead.example.yaml);
/// keep your own out of git, they hold your bank details.
class Letterhead {
  final String id;
  final String name;
  final List<String> address;
  final String phone, email, vatId, siret;

  /// Printed when an invoice has no VAT, e.g. "TVA non applicable, art. 293 B du CGI".
  final String vatNote;
  final String bankName, iban, bic;
  final String footer;

  /// Logo image (PNG/JPEG), absolute; empty for none.
  final String logo;

  /// A TrueType font for the PDF (regular; its bold is looked for next to
  /// it); empty: a system sans font (DejaVu, Liberation, Noto).
  final String font;

  /// receivable / revenue / vat account numbers; empty: invoices are not booked.
  final Map<String, String> bookAccounts;

  const Letterhead({
    required this.id,
    required this.name,
    this.address = const [],
    this.phone = '',
    this.email = '',
    this.vatId = '',
    this.siret = '',
    this.vatNote = '',
    this.bankName = '',
    this.iban = '',
    this.bic = '',
    this.footer = '',
    this.logo = '',
    this.font = '',
    this.bookAccounts = const {},
  });

  /// Whether issuing an invoice also books it.
  bool get books => bookAccounts.containsKey('receivable') && bookAccounts.containsKey('revenue');

  /// Reads [file]; the id is the file name without extension.
  factory Letterhead.load(File file) {
    final y = loadYaml(file.readAsStringSync()) as YamlMap;
    String s(String k) => (y[k] ?? '').toString();
    final bank = (y['bank'] as YamlMap?) ?? YamlMap();
    final book = (y['book'] as YamlMap?) ?? YamlMap();
    final logo = s('logo');
    final font = s('font');
    return Letterhead(
      id: file.uri.pathSegments.last.replaceAll(RegExp(r'\.ya?ml$'), ''),
      name: s('name'),
      address: [for (final l in (y['address'] as YamlList?) ?? const []) '$l'],
      phone: s('phone'),
      email: s('email'),
      vatId: s('vat_id'),
      siret: s('siret'),
      vatNote: s('vat_note'),
      bankName: (bank['name'] ?? '').toString(),
      iban: (bank['iban'] ?? '').toString(),
      bic: (bank['bic'] ?? '').toString(),
      footer: s('footer'),
      logo: logo.isEmpty || logo.startsWith('/') ? logo : '${file.parent.path}/$logo',
      font: font.isEmpty || font.startsWith('/') ? font : '${file.parent.path}/$font',
      bookAccounts: {for (final e in book.entries) '${e.key}': '${e.value}'},
    );
  }

  /// Every letterhead of [dir] (*.yaml), by id.
  static Map<String, Letterhead> loadAll(Directory dir) => {
        if (dir.existsSync())
          for (final f in dir.listSync().whereType<File>().where((f) => RegExp(r'\.ya?ml$').hasMatch(f.path)))
            Letterhead.load(f).id: Letterhead.load(f),
      };
}
