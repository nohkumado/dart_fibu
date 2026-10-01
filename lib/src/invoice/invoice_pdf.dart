import 'dart:typed_data';

import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../../nohfibu.dart';

/// An offer or invoice as an A4 business letter ([LetterFrame]: DIN 5008
/// or the French window): information block, items, net / VAT / gross, the
/// tax note, the payment or acceptance terms, the late-payment mentions for
/// businesses and the bank details.
class InvoicePdf {
  const InvoicePdf._();

  static const _accent = PdfColor.fromInt(0xff1f4e79);

  /// The PDF of [invoice] under [letterhead], to [customer] (default: the
  /// address lines the document carries).
  static Future<Uint8List> render(Invoice invoice, Letterhead letterhead, {Customer? customer}) async {
    final lines = invoice.address;
    final to = customer ??
        Customer(
          id: '',
          name: lines.isEmpty ? '' : lines.first,
          address: lines.length > 1 ? lines.sublist(1) : const [],
          lang: invoice.lang,
        );
    final t = InvoiceTexts.of(invoice.lang);
    final offer = invoice.kind == InvoiceKind.estimate;
    final heading = offer ? t.estimate : t.invoice;
    final day = DateFormat('dd.MM.yyyy');
    final locale = switch (invoice.lang) { 'de' => 'de_DE', 'en' => 'en_GB', _ => 'fr_FR' };
    final qty = NumberFormat.decimalPattern(locale);

    final frame = LetterFrame(letterhead, to, [
      ('$heading ${t.number}', invoice.number.isEmpty ? '—' : invoice.number),
      (offer ? t.date : t.dateOfIssue, day.format(invoice.date)),
      (offer ? t.validUntil : t.dueDate, day.format(invoice.payDate)),
      if (invoice.serviceDate != null) (t.serviceDate, day.format(invoice.serviceDate!)),
      if (to.id.isNotEmpty) (t.customerNumber, to.id),
      if (letterhead.vatId.isNotEmpty) (t.ourVatId, letterhead.vatId),
      if (to.vatId.isNotEmpty) (t.customerVatId, to.vatId),
      if (invoice.source.isNotEmpty) ('${t.estimate} ${t.number}', invoice.source),
    ]);
    final money = NumberFormat.currency(locale: locale, symbol: frame.euroSign ? '€' : 'EUR');
    String eur(int cents) => money.format(cents / 100);
    final small = const pw.TextStyle(fontSize: 8, color: PdfColors.grey800);

    return frame.render(
      title: '$heading ${invoice.number}',
      subject: '$heading ${t.number} ${invoice.number}',
      pageLabel: t.page,
      body: [
        if (invoice.title.isNotEmpty) ...[pw.Text(invoice.title), pw.SizedBox(height: 8)],
        pw.TableHelper.fromTextArray(
          headers: [t.designation, t.quantity, t.unitPrice, t.total],
          data: [
            for (final i in invoice.items) [i.denomination, qty.format(i.quantity), eur(i.unitPriceCents), eur(i.totalCents)],
          ],
          border: const pw.TableBorder(
              bottom: pw.BorderSide(color: PdfColors.grey500, width: 0.5),
              horizontalInside: pw.BorderSide(color: PdfColors.grey300, width: 0.5)),
          headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white),
          headerDecoration: const pw.BoxDecoration(color: _accent),
          cellAlignments: {1: pw.Alignment.centerRight, 2: pw.Alignment.centerRight, 3: pw.Alignment.centerRight},
          columnWidths: {0: const pw.FlexColumnWidth(4.6), 1: const pw.FlexColumnWidth(1.8), 2: const pw.FlexColumnWidth(2), 3: const pw.FlexColumnWidth(2)},
        ),
        pw.SizedBox(height: 8),
        pw.Align(
          alignment: pw.Alignment.centerRight,
          child: pw.SizedBox(
            width: 220,
            child: pw.Column(children: [
              _sum(t.totalNet, eur(invoice.netCents)),
              if (invoice.vatRate != 0) _sum('${t.vat} ${qty.format(invoice.vatRate * 100)} %', eur(invoice.vatCents)),
              pw.Divider(color: PdfColors.grey600, thickness: 0.5),
              _sum(t.totalGross, eur(invoice.grossCents), bold: true),
            ]),
          ),
        ),
        if (invoice.taxNote.isNotEmpty) ...[pw.SizedBox(height: 6), pw.Text(invoice.taxNote, style: small)],
        pw.SizedBox(height: 14),
        pw.Text((offer ? t.offerAcceptance : t.paymentTerms)
            .replaceAll('{due}', day.format(invoice.payDate))
            .replaceAll('{valid}', day.format(invoice.payDate))),
        if (!offer && to.business && letterhead.penaltyRate > 0) ...[
          pw.SizedBox(height: 4),
          pw.Text(
              t.latePaymentB2B
                  .replaceAll('{rate}', qty.format(letterhead.penaltyRate * 100))
                  .replaceAll('{fee}', eur(letterhead.recoveryFeeCents)),
              style: small),
        ],
        if (!offer && letterhead.iban.isNotEmpty) ...[
          pw.SizedBox(height: 12),
          pw.Text(t.transfer.replaceAll('{amount}', eur(invoice.grossCents))),
          pw.SizedBox(height: 4),
          bankBox(letterhead),
        ],
      ],
    );
  }

  /// The bank details in a rounded frame.
  static pw.Widget bankBox(Letterhead letterhead) => pw.Container(
        padding: const pw.EdgeInsets.all(7),
        decoration: pw.BoxDecoration(
          border: pw.Border.all(color: _accent, width: 0.8),
          borderRadius: const pw.BorderRadius.all(pw.Radius.circular(5)),
        ),
        child: pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceAround, children: [
          if (letterhead.bankName.isNotEmpty) pw.Text(letterhead.bankName),
          pw.Text('IBAN ${letterhead.iban}'),
          if (letterhead.bic.isNotEmpty) pw.Text('BIC ${letterhead.bic}'),
        ]),
      );

  static pw.Widget _sum(String label, String value, {bool bold = false}) {
    final style = pw.TextStyle(fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal);
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 1.5),
      child: pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [
        pw.Text(label, style: style),
        pw.Text(value, style: style),
      ]),
    );
  }
}
