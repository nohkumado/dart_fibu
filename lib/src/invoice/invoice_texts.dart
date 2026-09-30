/// The words on an invoice, per language (fr, de, en; English otherwise).
class InvoiceTexts {
  final String invoice, estimate, number, date, dateOfIssue, dueDate, designation,
      quantity, unitPrice, total, totalNet, vat, totalGross, transfer, account;

  const InvoiceTexts({
    required this.invoice,
    required this.estimate,
    required this.number,
    required this.date,
    required this.dateOfIssue,
    required this.dueDate,
    required this.designation,
    required this.quantity,
    required this.unitPrice,
    required this.total,
    required this.totalNet,
    required this.vat,
    required this.totalGross,
    required this.transfer,
    required this.account,
  });

  static const _all = {
    'fr': InvoiceTexts(
      invoice: 'FACTURE',
      estimate: 'DEVIS',
      number: 'n°',
      date: 'Date',
      dateOfIssue: "Date d'émission",
      dueDate: 'Échéance',
      designation: 'Désignation',
      quantity: 'Quantité',
      unitPrice: 'PU HT',
      total: 'Total HT',
      totalNet: 'Total HT',
      vat: 'TVA',
      totalGross: 'Total net à payer',
      transfer: 'Le montant de {amount} est à virer sur le compte bancaire suivant :',
      account: 'Compte',
    ),
    'de': InvoiceTexts(
      invoice: 'RECHNUNG',
      estimate: 'KOSTENVORANSCHLAG',
      number: 'Nr.',
      date: 'Datum',
      dateOfIssue: 'Rechnungsdatum',
      dueDate: 'Zahlbar bis',
      designation: 'Bezeichnung',
      quantity: 'Menge',
      unitPrice: 'Einzelpreis netto',
      total: 'Gesamt netto',
      totalNet: 'Summe netto',
      vat: 'MwSt.',
      totalGross: 'Zu zahlender Betrag',
      transfer: 'Bitte überweisen Sie {amount} auf folgendes Konto:',
      account: 'Konto',
    ),
    'en': InvoiceTexts(
      invoice: 'INVOICE',
      estimate: 'ESTIMATE',
      number: 'no.',
      date: 'Date',
      dateOfIssue: 'Date of issue',
      dueDate: 'Due date',
      designation: 'Description',
      quantity: 'Quantity',
      unitPrice: 'Unit price (net)',
      total: 'Total (net)',
      totalNet: 'Total (net)',
      vat: 'VAT',
      totalGross: 'Amount due',
      transfer: 'Please transfer {amount} to the following account:',
      account: 'Account',
    ),
  };

  static InvoiceTexts of(String lang) => _all[lang.toLowerCase()] ?? _all['en']!;
}
