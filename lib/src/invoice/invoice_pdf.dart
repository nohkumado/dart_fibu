import 'dart:io';
import 'dart:typed_data';

import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../../nohfibu.dart';

/// An [Invoice] under its [Letterhead] as an A4 PDF: issuer and logo,
/// customer, heading with number and dates, the items, net / VAT / gross,
/// the VAT note when there is no VAT, the bank details and the footer.
class InvoicePdf {
  const InvoicePdf._();

  static const _accent = PdfColor.fromInt(0xff1f4e79);

  /// Sans fonts with the € sign, regular and bold, tried in order.
  static const _systemFonts = [
    ['/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf', '/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf'],
    ['/usr/share/fonts/truetype/liberation2/LiberationSans-Regular.ttf', '/usr/share/fonts/truetype/liberation2/LiberationSans-Bold.ttf'],
    ['/usr/share/fonts/truetype/liberation/LiberationSans-Regular.ttf', '/usr/share/fonts/truetype/liberation/LiberationSans-Bold.ttf'],
    ['/usr/share/fonts/truetype/noto/NotoSans-Regular.ttf', '/usr/share/fonts/truetype/noto/NotoSans-Bold.ttf'],
  ];

  /// The letterhead's font, else the first system font found; null when
  /// there is none (the PDF's built-in Helvetica has no € sign).
  static pw.ThemeData? _theme(Letterhead letterhead) {
    final candidates = [
      if (letterhead.font.isNotEmpty)
        [letterhead.font, letterhead.font.replaceFirst(RegExp(r'(-Regular)?\.ttf$'), '-Bold.ttf')],
      ..._systemFonts,
    ];
    for (final pair in candidates) {
      if (!File(pair[0]).existsSync()) continue;
      final base = pw.Font.ttf(ByteData.sublistView(File(pair[0]).readAsBytesSync()));
      final bold = File(pair[1]).existsSync() ? pw.Font.ttf(ByteData.sublistView(File(pair[1]).readAsBytesSync())) : base;
      return pw.ThemeData.withFont(base: base, bold: bold);
    }
    return null;
  }

  static Future<Uint8List> render(Invoice invoice, Letterhead letterhead) async {
    final t = InvoiceTexts.of(invoice.lang);
    final theme = _theme(letterhead);
    final locale = switch (invoice.lang) { 'de' => 'de_DE', 'en' => 'en_GB', _ => 'fr_FR' };
    final money = NumberFormat.currency(locale: locale, symbol: theme == null ? 'EUR' : '€');
    String eur(int cents) => money.format(cents / 100);
    final day = DateFormat('dd.MM.yyyy');
    final qty = NumberFormat.decimalPattern(locale);

    pw.ImageProvider? logo;
    if (letterhead.logo.isNotEmpty && File(letterhead.logo).existsSync()) {
      logo = pw.MemoryImage(File(letterhead.logo).readAsBytesSync());
    }

    final doc = pw.Document(title: '${invoice.kind == InvoiceKind.estimate ? t.estimate : t.invoice} ${invoice.number}');
    final small = pw.TextStyle(fontSize: 8, color: PdfColors.grey700);
    doc.addPage(pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      theme: theme,
      margin: const pw.EdgeInsets.fromLTRB(48, 40, 48, 40),
      footer: (context) => pw.Column(children: [
        pw.Divider(color: PdfColors.grey400),
        pw.Text(
          [
            letterhead.name,
            if (letterhead.siret.isNotEmpty) 'SIRET ${letterhead.siret}',
            if (letterhead.vatId.isNotEmpty) '${t.vat} ${letterhead.vatId}',
            if (letterhead.footer.isNotEmpty) letterhead.footer,
          ].join(' · '),
          style: small,
          textAlign: pw.TextAlign.center,
        ),
      ]),
      build: (context) => [
        // issuer (and logo) left, customer right
        pw.Row(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
          pw.Expanded(
            child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
              if (logo != null) pw.Image(logo, width: 110),
              pw.Text(letterhead.name, style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 12)),
              for (final l in letterhead.address) pw.Text(l),
              if (letterhead.phone.isNotEmpty) pw.Text(letterhead.phone),
              if (letterhead.email.isNotEmpty) pw.Text(letterhead.email),
            ]),
          ),
          pw.Container(
            width: 200,
            margin: const pw.EdgeInsets.only(top: 60),
            padding: const pw.EdgeInsets.all(10),
            decoration: pw.BoxDecoration(border: pw.Border.all(color: PdfColors.grey400)),
            child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
              for (final l in invoice.address) pw.Text(l),
            ]),
          ),
        ]),
        pw.SizedBox(height: 28),
        pw.Text('${invoice.kind == InvoiceKind.estimate ? t.estimate : t.invoice} ${t.number} ${invoice.number}',
            style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold, color: _accent)),
        pw.SizedBox(height: 4),
        pw.Text('${invoice.kind == InvoiceKind.estimate ? t.date : t.dateOfIssue} : ${day.format(invoice.date)}    ${t.dueDate} : ${day.format(invoice.payDate)}'),
        if (invoice.title.isNotEmpty) ...[pw.SizedBox(height: 10), pw.Text(invoice.title)],
        pw.SizedBox(height: 16),
        pw.TableHelper.fromTextArray(
          headers: [t.designation, t.quantity, t.unitPrice, t.total],
          data: [
            for (final i in invoice.items) [i.denomination, qty.format(i.quantity), eur(i.unitPriceCents), eur(i.totalCents)],
          ],
          headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white),
          headerDecoration: const pw.BoxDecoration(color: _accent),
          cellAlignments: {1: pw.Alignment.centerRight, 2: pw.Alignment.centerRight, 3: pw.Alignment.centerRight},
          columnWidths: {0: const pw.FlexColumnWidth(4.6), 1: const pw.FlexColumnWidth(1.8), 2: const pw.FlexColumnWidth(2), 3: const pw.FlexColumnWidth(2)},
        ),
        pw.SizedBox(height: 10),
        pw.Align(
          alignment: pw.Alignment.centerRight,
          child: pw.SizedBox(
            width: 230,
            child: pw.Column(children: [
              _sum(t.totalNet, eur(invoice.netCents)),
              if (invoice.vatRate != 0)
                _sum('${t.vat} ${qty.format(invoice.vatRate * 100)} %', eur(invoice.vatCents)),
              pw.Divider(color: PdfColors.grey600),
              _sum(t.totalGross, eur(invoice.grossCents), bold: true),
            ]),
          ),
        ),
        if (invoice.vatRate == 0 && letterhead.vatNote.isNotEmpty) ...[
          pw.SizedBox(height: 6),
          pw.Text(letterhead.vatNote, style: small),
        ],
        if (invoice.kind == InvoiceKind.invoice && letterhead.iban.isNotEmpty) ...[
          pw.SizedBox(height: 22),
          pw.Text(t.transfer.replaceAll('{amount}', eur(invoice.grossCents))),
          pw.SizedBox(height: 6),
          pw.Container(
            padding: const pw.EdgeInsets.all(8),
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: _accent),
              borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
            ),
            child: pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceAround, children: [
              if (letterhead.bankName.isNotEmpty) pw.Text(letterhead.bankName),
              pw.Text('IBAN ${letterhead.iban}'),
              if (letterhead.bic.isNotEmpty) pw.Text('BIC ${letterhead.bic}'),
            ]),
          ),
        ],
      ],
    ));
    return doc.save();
  }

  static pw.Widget _sum(String label, String value, {bool bold = false}) {
    final style = pw.TextStyle(fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal);
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 2),
      child: pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [
        pw.Text(label, style: style),
        pw.Text(value, style: style),
      ]),
    );
  }
}
