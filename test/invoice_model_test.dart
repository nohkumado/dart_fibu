import 'dart:io';

import 'package:nohfibu/nohfibu.dart';
import 'package:test/test.dart';

void main() {
  // the three issuers of the request: FR micro-entreprise (franchise), FR
  // entreprise individuelle (VAT, 3D printing under reverse charge), and the
  // German association for the courses (German VAT)
  const micro = TaxProfile(country: 'FR', regime: 'franchise');
  const ei = TaxProfile(country: 'FR', regime: 'vat', rate: 0.2, reverseCharge: ['3dprint']);
  const association = TaxProfile(country: 'DE', regime: 'vat', rate: 0.19);

  const deBusiness = Customer(id: 'gmbh', name: 'Druck GmbH', country: 'DE', business: true, vatId: 'DE123456789', lang: 'de');
  const dePrivate = Customer(id: 'anna', name: 'Anna Muster', country: 'DE', lang: 'de');
  const frPrivate = Customer(id: 'paul', name: 'Paul Dupont', country: 'FR', lang: 'fr');

  group('tax treatment', () {
    test('micro-entreprise: no VAT, art. 293 B, in the letter\'s language', () {
      final t = TaxTreatment.of(micro, frPrivate, 'cours');
      expect(t.kind, TaxKind.franchise);
      expect(t.rate, 0);
      expect(t.note, contains('293 B'));
      expect(TaxTreatment.of(micro, dePrivate, 'cours', lang: 'de').note, startsWith('Keine Umsatzsteuer'));
    });

    test('3D printing for a German business with a VAT id: reverse charge', () {
      final t = TaxTreatment.of(ei, deBusiness, '3dprint', lang: 'de');
      expect(t.kind, TaxKind.reverseCharge);
      expect(t.rate, 0);
      expect(t.note, contains('Steuerschuldnerschaft des Leistungsempfängers'));
    });

    test('… but French VAT for a private German customer, or another category', () {
      expect(TaxTreatment.of(ei, dePrivate, '3dprint').rate, 0.2);
      expect(TaxTreatment.of(ei, deBusiness, 'cours').kind, TaxKind.standard);
    });

    test('courses through the association: German VAT', () {
      final t = TaxTreatment.of(association, dePrivate, 'cours', lang: 'de');
      expect(t.kind, TaxKind.standard);
      expect(t.rate, 0.19);
    });
  });

  test('the envelope window follows the letter\'s language, unless set', () {
    expect(frPrivate.windowSide, 'right');
    expect(dePrivate.windowSide, 'left');
    expect(const Customer(id: 'x', name: 'x', lang: 'fr', window: 'left').windowSide, 'left');
  });

  group('documents', () {
    Invoice invoice({List<DocumentEvent>? events}) => Invoice(
          letterhead: 'ei',
          name: 'f1',
          number: '2026-0001',
          date: DateTime(2026, 9, 1),
          payDate: DateTime(2026, 10, 1),
          customerId: 'gmbh',
          items: [const InvoiceItem('Druck', 2, 5000)],
          vatRate: 0.2,
          events: events,
        );

    test('status from the history', () {
      final i = invoice();
      expect(i.status(DateTime(2026, 9, 2)), InvoiceStatus.draft);
      i.events.add(DocumentEvent(DateTime(2026, 9, 1), DocumentEventKind.issued));
      expect(i.status(DateTime(2026, 9, 15)), InvoiceStatus.unpaid);
      expect(i.status(DateTime(2026, 10, 20)), InvoiceStatus.overdue);
      expect(i.daysOverdue(DateTime(2026, 10, 20)), 19);
      i.events.add(DocumentEvent(DateTime(2026, 10, 21), DocumentEventKind.paid, value: 6000));
      expect(i.openCents, 6000);
      expect(i.status(DateTime(2026, 10, 22)), InvoiceStatus.overdue);
      i.events.add(DocumentEvent(DateTime(2026, 10, 25), DocumentEventKind.paid, value: 6000));
      expect(i.status(DateTime(2026, 10, 26)), InvoiceStatus.paid);
    });

    test('the store: JSON round trip with customers and history', () {
      final store = InvoiceStore(customers: {'gmbh': deBusiness}, documents: [
        invoice(events: [DocumentEvent(DateTime(2026, 9, 1), DocumentEventKind.issued)]),
      ]);
      final again = InvoiceStore.parse(store.encode());
      expect(again.encode(), store.encode());
      expect(again.customers['gmbh']!.vatId, 'DE123456789');
      expect(again.find('2026-0001')!.status(DateTime(2026, 9, 2)), InvoiceStatus.unpaid);
    });

    test('the old CSV archive is read as format 1: issued, and paid unless told not to', () {
      final text = File('assets/invoice/archive.example.csv').readAsStringSync();
      final store = InvoiceStore.parse(text);
      expect(store.readFormat, 1);
      final first = store.find('2026-0001')!;
      expect(first.status(DateTime(2030)), InvoiceStatus.paid);
      expect(store.find('2026-0002')!.status(), InvoiceStatus.open, reason: 'an estimate: sent, no answer');
      expect(InvoiceStore.parse(text, assumePaid: false).find('2026-0001')!.status(DateTime(2030)),
          InvoiceStatus.overdue);
      expect(store.customerOf(first).name, 'Association Exemple');
    });
  });

  test('a letterhead written as YAML reads back the same', () {
    final lh = Letterhead.load(File('assets/invoice/letterhead.example.yaml'));
    const changed = Letterhead(
      id: 'ei',
      name: 'Atelier "3D"',
      address: ['1 rue X', '67000 Strasbourg'],
      tax: TaxProfile(country: 'FR', regime: 'vat', rate: 0.2, rates: {'cours': 0.1}, reverseCharge: ['3dprint']),
      reminderDays: [10, 20, 40],
      penaltyRate: 0.1215,
      bookAccounts: {'receivable': '411', 'bank': '512'},
    );
    for (final original in [lh, changed]) {
      final again = Letterhead.parse(original.toYaml(), id: original.id);
      expect(again.toYaml(), original.toYaml());
    }
    final again = Letterhead.parse(changed.toYaml(), id: 'ei');
    expect(again.name, 'Atelier "3D"');
    expect(again.tax.rates['cours'], 0.1);
    expect(again.tax.reverseChargeFor('3dprint'), isTrue);
    expect(again.books, isFalse, reason: 'no revenue account');
  });
}

