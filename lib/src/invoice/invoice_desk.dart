import 'dart:io';
import 'dart:math';

import '../../nohfibu.dart';

/// The offer → invoice workflow on an [InvoiceStore]: write offers, issue
/// them, record the answer, turn an accepted offer into an invoice, find
/// what needs a reminder, record payments — and, for letterheads that book,
/// the journal lines that go with it.
///
/// Numbers are given when a document is issued (continuous, no gaps):
/// offers D2026-0001, invoices 2026-0001, each counter in a file next to
/// the store.
class InvoiceDesk {
  final InvoiceStore store;
  final Map<String, Letterhead> letterheads;
  final InvoiceNumbering offerNumbers;
  final InvoiceNumbering invoiceNumbers;

  InvoiceDesk(this.store, this.letterheads, {required this.offerNumbers, required this.invoiceNumbers});

  /// The desk of the store kept in [file] (counters next to it).
  factory InvoiceDesk.forFile(InvoiceStore store, File file, Map<String, Letterhead> letterheads) => InvoiceDesk(
        store,
        letterheads,
        offerNumbers: InvoiceNumbering(File('${file.path}.offers'), prefix: 'D'),
        invoiceNumbers: InvoiceNumbering(File('${file.path}.invoices')),
      );

  static final _random = Random.secure();

  /// A random identity for a new document (stable across devices).
  static String _uid() => List.generate(16, (_) => _random.nextInt(256).toRadixString(16).padLeft(2, '0')).join();

  Letterhead _letterhead(String id) =>
      letterheads[id] ?? (throw StateError('no letterhead "$id" (known: ${letterheads.keys.join(', ')})'));

  Customer _customer(String id) =>
      store.customers[id] ?? (throw StateError('no customer "$id" (known: ${store.customers.keys.join(', ')})'));

  /// A new draft — an offer or an invoice — for [customerId] under
  /// [letterhead]: tax from the issuer, the customer and the [category];
  /// language from the customer. [days]: valid (offer) or payable
  /// (invoice) for that long.
  Invoice draft({
    required InvoiceKind kind,
    required String letterhead,
    required String customerId,
    required List<InvoiceItem> items,
    String category = '',
    String title = '',
    DateTime? date,
    DateTime? serviceDate,
    int days = 30,
    String source = '',
  }) {
    final lh = _letterhead(letterhead);
    final customer = _customer(customerId);
    final d = date ?? DateTime.now();
    final tax = TaxTreatment.of(lh.tax, customer, category, lang: customer.lang, franchiseNote: lh.vatNote);
    final doc = Invoice(
      kind: kind,
      lang: customer.lang,
      letterhead: letterhead,
      name: '',
      title: title,
      date: d,
      payDate: d.add(Duration(days: days)),
      serviceDate: serviceDate,
      number: '',
      customerId: customerId,
      category: category,
      vatRate: tax.rate,
      taxKind: tax.kind,
      taxNote: tax.note,
      items: items,
      source: source,
      events: [DocumentEvent(d, DocumentEventKind.created)],
      uid: _uid(),
    );
    store.documents.add(doc);
    return doc;
  }

  /// Issues the draft [doc] on [date]: it gets its number (and file name)
  /// and counts as sent. Returns the issued document — and, for an invoice
  /// under a letterhead that books, its journal lines in [book].
  (Invoice, List<JrlLine>) issue(Invoice doc, {DateTime? date, Book? book}) {
    if (doc.status() != InvoiceStatus.draft) throw StateError('${doc.number} is already issued');
    final d = date ?? doc.date;
    final numbers = doc.kind == InvoiceKind.estimate ? offerNumbers : invoiceNumbers;
    final number = numbers.take(d);
    final who = _customer(doc.customerId).name.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '_');
    final issued = doc.withNumber(number, name: '${number}_$who');
    issued.events.add(DocumentEvent(d, DocumentEventKind.issued));
    store.documents[store.documents.indexOf(doc)] = issued;
    final lines = (book != null && doc.kind == InvoiceKind.invoice)
        ? InvoiceBooking.lines(issued, _letterhead(doc.letterhead), book)
        : const <JrlLine>[];
    return (issued, lines);
  }

  /// Records the customer's answer to an open offer.
  void answer(Invoice offer, {required bool accepted, DateTime? date, String note = ''}) {
    if (offer.status() != InvoiceStatus.open) throw StateError('${offer.number} is not an open offer');
    offer.events.add(DocumentEvent(date ?? DateTime.now(),
        accepted ? DocumentEventKind.accepted : DocumentEventKind.refused, note: note));
  }

  /// The invoice for an accepted [offer], issued on [date] (same customer,
  /// items, category, tax), the offer marked as invoiced.
  (Invoice, List<JrlLine>) invoiceOffer(Invoice offer, {DateTime? date, DateTime? serviceDate, int days = 30, Book? book}) {
    if (offer.status() != InvoiceStatus.accepted) throw StateError('${offer.number} is not an accepted offer');
    final d = date ?? DateTime.now();
    final draftInvoice = draft(
      kind: InvoiceKind.invoice,
      letterhead: offer.letterhead,
      customerId: offer.customerId,
      items: offer.items,
      category: offer.category,
      title: offer.title,
      date: d,
      serviceDate: serviceDate ?? offer.serviceDate,
      days: days,
      source: offer.number,
    );
    final result = issue(draftInvoice, date: d, book: book);
    offer.events.add(DocumentEvent(d, DocumentEventKind.invoiced, note: result.$1.number));
    return result;
  }

  /// Invoices needing a reminder on [today], each with the level now due
  /// (the letterhead's delays after the due date; one level at a time).
  List<Reminder> remindersDue([DateTime? today]) {
    final now = today ?? DateTime.now();
    final out = <Reminder>[];
    for (final doc in store.ofKind(InvoiceKind.invoice)) {
      if (doc.status(now) != InvoiceStatus.overdue) continue;
      final lh = _letterhead(doc.letterhead);
      final next = doc.reminderLevel + 1;
      if (next > lh.reminderDays.length) continue;
      if (doc.daysOverdue(now) < lh.reminderDays[next - 1]) continue;
      out.add(Reminder.of(doc, next, now, lh, store.customerOf(doc)));
    }
    return out;
  }

  /// Records that [reminder] was sent.
  void sent(Reminder reminder) => reminder.invoice.events
      .add(DocumentEvent(reminder.date, DocumentEventKind.reminded, value: reminder.level));

  /// Records a payment of [cents] on [invoice]; returns the journal line
  /// (receivable → bank) when its letterhead books and has a bank account.
  List<JrlLine> pay(Invoice invoice, int cents, {DateTime? date, String note = '', Book? book}) {
    final st = invoice.status();
    if (invoice.kind != InvoiceKind.invoice || st == InvoiceStatus.draft || st == InvoiceStatus.cancelled) {
      throw StateError('${invoice.number} cannot be paid');
    }
    final d = date ?? DateTime.now();
    invoice.events.add(DocumentEvent(d, DocumentEventKind.paid, value: cents, note: note));
    final lh = _letterhead(invoice.letterhead);
    if (book == null || !lh.books || !lh.bookAccounts.containsKey('bank')) return const [];
    Konto account(String role) {
      final k = book.kpl.get(lh.bookAccounts[role]!);
      if (k == null || !k.valid()) throw StateError('$role account ${lh.bookAccounts[role]} is not in the plan');
      return k;
    }

    return [
      JrlLine(datum: d, kmin: account('receivable'), kplu: account('bank'),
          desc: 'Paiement ${invoice.number}${note.isEmpty ? '' : ' $note'}', valuta: cents),
    ];
  }
}
