// Writes sample offers, invoices and reminders as PDFs into a directory,
// to check the letter layout (DIN 5008 / French window, fold marks):
//
//   dart run tool/sample_letters.dart /tmp/letters
import 'dart:io';

import 'package:nohfibu/nohfibu.dart';

Future<void> main(List<String> args) async {
  final out = Directory(args.isEmpty ? 'sample_letters' : args.first)..createSync(recursive: true);
  const issuer = Letterhead(
    id: 'ei',
    name: 'Jean Exemple — Impression 3D',
    address: ["12 rue de l'Exemple", '67000 Strasbourg', 'France'],
    phone: '+33 3 00 00 00 00',
    email: 'jean@example.org',
    siret: '000 000 000 00000',
    vatId: 'FR00000000000',
    bankName: 'Banque Exemple',
    iban: 'FR76 0000 0000 0000 0000 0000 000',
    bic: 'EXEMFRPP',
    tax: TaxProfile(country: 'FR', regime: 'vat', rate: 0.2, reverseCharge: ['3dprint']),
    penaltyRate: 0.1215,
  );
  const micro = Letterhead(
    id: 'micro',
    name: 'Jean Exemple',
    address: ["12 rue de l'Exemple", '67000 Strasbourg'],
    email: 'jean@example.org',
    siret: '000 000 000 00001',
    bankName: 'Banque Exemple',
    iban: 'FR76 0000 0000 0000 0000 0000 001',
    bic: 'EXEMFRPP',
    tax: TaxProfile(country: 'FR', regime: 'franchise'),
  );
  final store = InvoiceStore(customers: {
    'gmbh': const Customer(id: 'gmbh', name: 'Druck GmbH', address: ['Hauptstraße 1', '77694 Kehl', 'Deutschland'],
        country: 'DE', business: true, vatId: 'DE123456789', lang: 'de'),
    'assoc': const Customer(id: 'assoc', name: 'Association Exemple', address: ['3 place du Marché', '67000 Strasbourg'],
        country: 'FR', business: true, lang: 'fr'),
  });
  final desk = InvoiceDesk(store, {'ei': issuer, 'micro': micro},
      offerNumbers: InvoiceNumbering(File('${out.path}/.offers')),
      invoiceNumbers: InvoiceNumbering(File('${out.path}/.invoices')));
  File('${out.path}/.offers').deleteSyncIfExists();
  File('${out.path}/.invoices').deleteSyncIfExists();

  Future<void> write(String name, List<int> bytes) async {
    File('${out.path}/$name.pdf').writeAsBytesSync(bytes);
    print('wrote ${out.path}/$name.pdf');
  }

  var de = desk.draft(
      kind: InvoiceKind.invoice, letterhead: 'ei', customerId: 'gmbh', category: '3dprint',
      title: 'Druckaufträge September', date: DateTime(2026, 9, 30), serviceDate: DateTime(2026, 9, 15),
      items: const [InvoiceItem('Druck PLA, 20 Teile', 20, 1500), InvoiceItem('Konstruktion (Stunden)', 3, 4500)]);
  (de, _) = desk.issue(de);
  await write('invoice_de', await InvoicePdf.render(de, issuer, customer: store.customers['gmbh']));

  var fr = desk.draft(
      kind: InvoiceKind.estimate, letterhead: 'micro', customerId: 'assoc', category: 'cours',
      title: "Stage d'initiation", date: DateTime(2026, 9, 30),
      items: const [InvoiceItem("Cours d'aïkido, séance de 2 h", 4, 6000)]);
  (fr, _) = desk.issue(fr);
  await write('offer_fr', await InvoicePdf.render(fr, micro, customer: store.customers['assoc']));

  desk.sent(desk.remindersDue(DateTime(2026, 11, 20)).single);
  final second = desk.remindersDue(DateTime(2026, 12, 10)).single;
  await write('reminder2_de', await ReminderPdf.render(second, issuer, store.customers['gmbh']!));
}

extension on File {
  void deleteSyncIfExists() {
    if (existsSync()) deleteSync();
  }
}
