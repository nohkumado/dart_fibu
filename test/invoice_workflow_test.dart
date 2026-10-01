import 'dart:io';

import 'package:nohfibu/nohfibu.dart';
import 'package:test/test.dart';

void main() {
  late Directory dir;
  late InvoiceDesk desk;
  late Book book;

  setUp(() {
    dir = Directory.systemTemp.createTempSync('facture');
    final store = InvoiceStore(customers: {
      'gmbh': const Customer(id: 'gmbh', name: 'Druck GmbH', address: ['Hauptstr. 1', '77694 Kehl'],
          country: 'DE', business: true, vatId: 'DE123456789', lang: 'de'),
    });
    const ei = Letterhead(
      id: 'ei',
      name: 'Atelier 3D',
      tax: TaxProfile(country: 'FR', regime: 'vat', rate: 0.2, reverseCharge: ['3dprint']),
      penaltyRate: 0.12,
      bookAccounts: {'receivable': '411', 'revenue': '706', 'vat': '4457', 'bank': '512'},
    );
    desk = InvoiceDesk.forFile(store, File('${dir.path}/factures.json'), {'ei': ei});
    book = Book();
    for (final (n, d, r) in [
      ('411', 'Clients', AccountType.Actif),
      ('512', 'Banque', AccountType.Actif),
      ('706', 'Prestations', AccountType.Produit),
      ('4457', 'TVA collectée', AccountType.Passif),
    ]) {
      book.kpl.put(n, Konto(name: n, desc: d, plan: book.kpl, accountType: r));
    }
  });

  tearDown(() => dir.deleteSync(recursive: true));

  test('offer → accepted → invoice → overdue → reminders → paid, with the bookings', () {
    final items = [const InvoiceItem('Druck PLA, 20 Teile', 20, 1500)];
    var offer = desk.draft(
        kind: InvoiceKind.estimate, letterhead: 'ei', customerId: 'gmbh', items: items,
        category: '3dprint', date: DateTime(2026, 9, 1));
    expect(offer.status(), InvoiceStatus.draft);
    expect(offer.taxKind, TaxKind.reverseCharge, reason: '3D printing for a German business with a VAT id');
    expect(offer.lang, 'de');

    (offer, _) = desk.issue(offer, date: DateTime(2026, 9, 1));
    expect(offer.number, 'D2026-0001');
    expect(offer.status(), InvoiceStatus.open);

    desk.answer(offer, accepted: true, date: DateTime(2026, 9, 5), note: 'per E-Mail');
    expect(offer.status(), InvoiceStatus.accepted);

    final (invoice, booked) = desk.invoiceOffer(offer, date: DateTime(2026, 9, 20), book: book);
    expect(invoice.number, '2026-0001');
    expect(invoice.source, 'D2026-0001');
    expect(offer.status(), InvoiceStatus.invoiced);
    expect(invoice.grossCents, 30000, reason: 'reverse charge: no VAT');
    expect(booked.map((l) => '${l.kminus.name}>${l.kplus.name} ${l.valuta}'), ['706>411 30000']);

    // not due yet, then overdue: one reminder level at a time
    expect(desk.remindersDue(DateTime(2026, 10, 15)), isEmpty);
    final r1 = desk.remindersDue(DateTime(2026, 11, 5));
    expect(r1.single.level, 1);
    expect(r1.single.totalCents, 30000, reason: 'a first reminder adds nothing');
    desk.sent(r1.single);
    expect(desk.remindersDue(DateTime(2026, 11, 6)), isEmpty, reason: 'level 2 only after 30 days');
    final r2 = desk.remindersDue(DateTime(2026, 11, 25)).single;
    expect(r2.level, 2);
    // 36 days late at 12 %: 30000 * 0.12 * 36 / 365 = 355; + 40 € for a business
    expect(r2.interestCents, 355);
    expect(r2.feeCents, 4000);
    desk.sent(r2);

    // paid in two parts; each payment booked receivable → bank
    final p1 = desk.pay(invoice, 10000, date: DateTime(2026, 11, 28), book: book);
    expect(p1.single.kminus.name, '411');
    expect(p1.single.kplus.name, '512');
    expect(invoice.status(DateTime(2026, 11, 29)), InvoiceStatus.overdue);
    desk.pay(invoice, 20000, date: DateTime(2026, 12, 2), book: book);
    expect(invoice.status(DateTime(2026, 12, 3)), InvoiceStatus.paid);
    expect(desk.remindersDue(DateTime(2027, 1, 1)), isEmpty);
  });

  test('French VAT for a domestic invoice: net, VAT and their bookings', () {
    desk.store.customers['dupont'] = const Customer(id: 'dupont', name: 'Paul Dupont', country: 'FR');
    final draft = desk.draft(
        kind: InvoiceKind.invoice, letterhead: 'ei', customerId: 'dupont',
        items: [const InvoiceItem('Impression', 1, 10000)], category: '3dprint', date: DateTime(2026, 9, 1));
    final (invoice, booked) = desk.issue(draft, book: book);
    expect(invoice.vatCents, 2000);
    expect(booked.map((l) => '${l.kminus.name}>${l.kplus.name} ${l.valuta}'), ['706>411 10000', '4457>411 2000']);
  });

  test('numbers are continuous and only given on issue; a refused offer is not invoiced', () {
    final a = desk.draft(kind: InvoiceKind.invoice, letterhead: 'ei', customerId: 'gmbh', items: const [], date: DateTime(2026, 9, 1));
    final b = desk.draft(kind: InvoiceKind.invoice, letterhead: 'ei', customerId: 'gmbh', items: const [], date: DateTime(2026, 9, 2));
    expect(desk.issue(b).$1.number, '2026-0001', reason: 'the order of issue, not of drafting');
    expect(desk.issue(a).$1.number, '2026-0002');
    var offer = desk.draft(kind: InvoiceKind.estimate, letterhead: 'ei', customerId: 'gmbh', items: const []);
    (offer, _) = desk.issue(offer);
    desk.answer(offer, accepted: false);
    expect(offer.status(), InvoiceStatus.refused);
    expect(() => desk.invoiceOffer(offer), throwsStateError);
  });
}
