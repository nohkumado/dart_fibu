import 'dart:convert';
import 'dart:io';

import '../../nohfibu.dart';

/// The offers, invoices and customers of one issuer, as a versioned JSON
/// file (`{"format": 2, "software": …, "customers": […], "documents": […]}`),
/// so that a later facture reads it the way it was written.
///
/// Format 1 is facture's CSV archive of 2005 ([InvoiceArchive]): it is read
/// too and saved as format 2.
class InvoiceStore {
  static const format = 2;

  final Map<String, Customer> customers;
  final List<Invoice> documents;

  /// The format the file was read in (1: the old CSV archive).
  int readFormat = format;

  InvoiceStore({Map<String, Customer>? customers, List<Invoice>? documents})
      : customers = customers ?? {},
        documents = documents ?? [];

  /// The document of [kind] numbered [number], or null.
  Invoice? find(String number, {InvoiceKind? kind}) {
    for (final d in documents) {
      if (d.number == number && (kind == null || d.kind == kind)) return d;
    }
    return null;
  }

  /// The documents of [kind].
  List<Invoice> ofKind(InvoiceKind kind) => documents.where((d) => d.kind == kind).toList();

  /// The customer of [doc]: from the register, else built from the old
  /// address lines (first line as name).
  Customer customerOf(Invoice doc) {
    final c = customers[doc.customerId];
    if (c != null) return c;
    final lines = doc.address;
    return Customer(
      id: '',
      name: lines.isEmpty ? '' : lines.first,
      address: lines.length > 1 ? lines.sublist(1) : const [],
      lang: doc.lang,
    );
  }

  /// Reads [text]: the JSON store, or facture's old CSV archive. Old
  /// documents count as issued on their date; with [assumePaid] (the
  /// default) also as paid — they predate payment tracking, and would
  /// otherwise all show as overdue.
  factory InvoiceStore.parse(String text, {bool assumePaid = true}) {
    final t = text.trimLeft();
    if (t.startsWith('{')) {
      final j = jsonDecode(t) as Map<String, dynamic>;
      final store = InvoiceStore(
        customers: {
          for (final c in (j['customers'] as List?) ?? const [])
            '${c['id']}': Customer.fromJson(Map<String, dynamic>.from(c as Map)),
        },
        documents: [
          for (final d in (j['documents'] as List?) ?? const []) Invoice.fromJson(Map<String, dynamic>.from(d as Map)),
        ],
      );
      store.readFormat = (j['format'] as num?)?.toInt() ?? format;
      return store;
    }
    final old = InvoiceArchive.parse(text);
    final store = InvoiceStore(documents: [
      for (final i in old.invoices)
        Invoice(
          kind: i.kind,
          lang: i.lang,
          letterhead: i.letterhead,
          name: i.name,
          title: i.title,
          date: i.date,
          payDate: i.payDate,
          number: i.number,
          address: i.address,
          vatRate: i.vatRate,
          taxKind: i.vatRate == 0 ? TaxKind.franchise : TaxKind.standard,
          items: i.items,
          events: [
            DocumentEvent(i.date, DocumentEventKind.issued, note: 'imported from the CSV archive'),
            if (assumePaid && i.kind == InvoiceKind.invoice)
              DocumentEvent(i.payDate, DocumentEventKind.paid,
                  value: i.grossCents, note: 'imported, payment not tracked'),
          ],
        ),
    ]);
    store.readFormat = 1;
    return store;
  }

  /// Reads [file]; an empty store when it does not exist yet.
  factory InvoiceStore.load(File file, {bool assumePaid = true}) =>
      file.existsSync() ? InvoiceStore.parse(file.readAsStringSync(), assumePaid: assumePaid) : InvoiceStore();

  String encode() => const JsonEncoder.withIndent('  ').convert({
        'format': format,
        'software': 'nohfibu ${BookFormat.software}',
        'customers': [for (final c in customers.values) c.toJson()],
        'documents': [for (final d in documents) d.toJson()],
      });

  /// Writes the store to [file] (always the current format).
  void save(File file) => file.writeAsStringSync('${encode()}\n');
}
