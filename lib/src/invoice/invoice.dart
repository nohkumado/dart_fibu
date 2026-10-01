import '../../nohfibu.dart';

/// One offer (estimate) or invoice: to whom, when, what, its totals — and
/// its history ([events]), from which its [status] follows.
class Invoice {
  final InvoiceKind kind;

  /// Language of the document: fr, de or en.
  final String lang;

  /// Id of the [Letterhead] it is issued under.
  final String letterhead;

  /// File name of its PDF (without extension).
  final String name;

  /// Subject line under the heading (e.g. "Mission d'enseignement").
  final String title;
  final DateTime date;

  /// Due date of an invoice; for an offer, the date it is valid until.
  final DateTime payDate;

  /// When the service was rendered (German invoices must say it); null:
  /// the document date.
  final DateTime? serviceDate;

  /// The number, unique per kind in the archive.
  final String number;

  /// The customer's address, one entry per line (archives before the
  /// customer register; with [customerId] the register's address is used).
  final List<String> address;

  /// Id of the [Customer] in the archive's register ("" for old documents).
  final String customerId;

  /// The kind of service (e.g. 3dprint, cours): decides the tax treatment.
  final String category;

  /// VAT rate, 0.2 for 20 %; 0 for none.
  final double vatRate;

  /// The tax kind the document was issued with.
  final TaxKind taxKind;

  /// The legal tax note printed on it ("" when none).
  final String taxNote;
  final List<InvoiceItem> items;

  /// For an invoice made from an offer: the offer's number.
  final String source;

  /// What happened to it, in order.
  final List<DocumentEvent> events;

  Invoice({
    this.kind = InvoiceKind.invoice,
    this.lang = 'fr',
    required this.letterhead,
    required this.name,
    this.title = '',
    required this.date,
    required this.payDate,
    this.serviceDate,
    required this.number,
    this.address = const [],
    this.customerId = '',
    this.category = '',
    this.vatRate = 0,
    this.taxKind = TaxKind.standard,
    this.taxNote = '',
    required this.items,
    this.source = '',
    List<DocumentEvent>? events,
  }) : events = events ?? [];

  /// The same document with a number (given when it is issued) and, when
  /// given, other events.
  Invoice withNumber(String number, {String? name}) => Invoice(
        kind: kind,
        lang: lang,
        letterhead: letterhead,
        name: name ?? this.name,
        title: title,
        date: date,
        payDate: payDate,
        serviceDate: serviceDate,
        number: number,
        address: address,
        customerId: customerId,
        category: category,
        vatRate: vatRate,
        taxKind: taxKind,
        taxNote: taxNote,
        items: items,
        source: source,
        events: events,
      );

  /// Sum of the items before VAT, in cents.
  int get netCents => items.fold(0, (sum, i) => sum + i.totalCents);

  /// The VAT on [netCents], in cents.
  int get vatCents => (netCents * vatRate).round();

  /// What the customer pays, in cents.
  int get grossCents => netCents + vatCents;

  /// Payments received so far, in cents.
  int get paidCents => events.where((e) => e.kind == DocumentEventKind.paid).fold(0, (s, e) => s + e.value);

  /// What is still owed, in cents.
  int get openCents => grossCents - paidCents;

  /// The highest reminder level sent (0: none).
  int get reminderLevel => events
      .where((e) => e.kind == DocumentEventKind.reminded)
      .fold(0, (m, e) => e.value > m ? e.value : m);

  bool _has(DocumentEventKind k) => events.any((e) => e.kind == k);

  /// Where it stands on [today] (default: now).
  InvoiceStatus status([DateTime? today]) {
    final now = today ?? DateTime.now();
    if (_has(DocumentEventKind.cancelled)) return InvoiceStatus.cancelled;
    if (!_has(DocumentEventKind.issued)) return InvoiceStatus.draft;
    if (kind == InvoiceKind.estimate) {
      if (_has(DocumentEventKind.invoiced)) return InvoiceStatus.invoiced;
      if (_has(DocumentEventKind.refused)) return InvoiceStatus.refused;
      if (_has(DocumentEventKind.accepted)) return InvoiceStatus.accepted;
      return InvoiceStatus.open;
    }
    if (openCents <= 0) return InvoiceStatus.paid;
    final due = DateTime(payDate.year, payDate.month, payDate.day);
    return now.isAfter(due.add(const Duration(days: 1))) ? InvoiceStatus.overdue : InvoiceStatus.unpaid;
  }

  /// Days past the due date on [today] (0 when not due yet).
  int daysOverdue([DateTime? today]) {
    final d = (today ?? DateTime.now()).difference(DateTime(payDate.year, payDate.month, payDate.day)).inDays;
    return d > 0 ? d : 0;
  }

  Map<String, dynamic> toJson() {
    String day(DateTime d) => d.toIso8601String().substring(0, 10);
    return {
      'kind': kind.name,
      'number': number,
      'lang': lang,
      'letterhead': letterhead,
      'name': name,
      if (title.isNotEmpty) 'title': title,
      'date': day(date),
      'pay_date': day(payDate),
      if (serviceDate != null) 'service_date': day(serviceDate!),
      if (customerId.isNotEmpty) 'customer': customerId,
      if (address.isNotEmpty) 'address': address,
      if (category.isNotEmpty) 'category': category,
      'vat_rate': vatRate,
      'tax': taxKind.name,
      if (taxNote.isNotEmpty) 'tax_note': taxNote,
      'items': [
        for (final i in items) {'what': i.denomination, 'quantity': i.quantity, 'unit_cents': i.unitPriceCents}
      ],
      if (source.isNotEmpty) 'source': source,
      'events': [for (final e in events) e.toJson()],
    };
  }

  factory Invoice.fromJson(Map<String, dynamic> j) => Invoice(
        kind: InvoiceKind.values.byName('${j['kind'] ?? 'invoice'}'),
        number: '${j['number']}',
        lang: '${j['lang'] ?? 'fr'}',
        letterhead: '${j['letterhead'] ?? ''}',
        name: '${j['name'] ?? j['number']}',
        title: '${j['title'] ?? ''}',
        date: DateTime.parse('${j['date']}'),
        payDate: DateTime.parse('${j['pay_date'] ?? j['date']}'),
        serviceDate: j['service_date'] == null ? null : DateTime.parse('${j['service_date']}'),
        customerId: '${j['customer'] ?? ''}',
        address: [for (final l in (j['address'] as List?) ?? const []) '$l'],
        category: '${j['category'] ?? ''}',
        vatRate: (j['vat_rate'] as num?)?.toDouble() ?? 0,
        taxKind: TaxKind.values.byName('${j['tax'] ?? 'standard'}'),
        taxNote: '${j['tax_note'] ?? ''}',
        items: [
          for (final i in (j['items'] as List?) ?? const [])
            InvoiceItem('${i['what']}', (i['quantity'] as num?) ?? 1, (i['unit_cents'] as num?)?.toInt() ?? 0)
        ],
        source: '${j['source'] ?? ''}',
        events: [for (final e in (j['events'] as List?) ?? const []) DocumentEvent.fromJson(Map<String, dynamic>.from(e as Map))],
      );
}
