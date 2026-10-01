import 'dart:io';
import 'dart:typed_data';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../../nohfibu.dart';

/// The page of a business letter on A4, shared by offers, invoices and
/// reminders:
///
/// * window on the left — DIN 5008 Form B (German and English letters):
///   return line and address field from 45 mm (address from 62.7 mm, text
///   at 25 mm), information block at 125 mm from 50 mm, subject at
///   98.5 mm, fold marks at 105 and 210 mm, hole mark at 148.5 mm;
/// * window on the right (French letters): the address field at 110 mm,
///   the information block on the left, fold marks at 99 and 198 mm (A4
///   in three for DL window envelopes).
///
/// The footer carries the issuer's legal details on every page.
class LetterFrame {
  final Letterhead letterhead;
  final Customer recipient;

  /// "left" or "right" (see [Customer.windowSide]).
  final String window;

  /// Label → value rows of the information block (number, dates, ids…).
  final List<(String, String)> info;

  final pw.ThemeData? theme;

  LetterFrame(this.letterhead, this.recipient, this.info, {String? window})
      : window = window ?? recipient.windowSide,
        theme = _theme(letterhead);

  static const _accent = PdfColor.fromInt(0xff1f4e79);
  static double mm(double v) => v * PdfPageFormat.mm;

  // page margins: content from 25 mm left, 20 mm right
  static final _left = mm(25), _right = mm(20), _top = mm(12), _bottom = mm(22);

  /// Where the body starts on the first page (DIN 5008: 98.46 mm).
  static final _bodyTop = mm(98.46);

  bool get _din => window != 'right';

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
      return pw.ThemeData.withFont(base: base, bold: bold).copyWith(defaultTextStyle: pw.TextStyle(font: base, fontBold: bold, fontSize: 9.5));
    }
    return null;
  }

  /// Whether amounts can use the € sign (a font with it was found).
  bool get euroSign => theme != null;

  /// A document with [subject] as heading and [body] below it.
  Future<Uint8List> render({required String title, required String subject, required List<pw.Widget> body, required String pageLabel}) async {
    final doc = pw.Document(title: title, author: letterhead.name);
    final small = const pw.TextStyle(fontSize: 7, color: PdfColors.grey700);
    pw.ImageProvider? logo;
    if (letterhead.logo.isNotEmpty && File(letterhead.logo).existsSync()) {
      logo = pw.MemoryImage(File(letterhead.logo).readAsBytesSync());
    }
    doc.addPage(pw.MultiPage(
      pageTheme: pw.PageTheme(
        pageFormat: PdfPageFormat.a4,
        theme: theme,
        margin: pw.EdgeInsets.fromLTRB(_left, _top, _right, _bottom),
        buildBackground: (context) => pw.FullPage(ignoreMargins: true, child: _marks()),
      ),
      header: (context) => context.pageNumber == 1
          ? _firstPageHead(logo, small)
          : pw.Padding(
              padding: pw.EdgeInsets.only(bottom: mm(6)),
              child: pw.Text('$title — $pageLabel ${context.pageNumber}', style: small)),
      footer: (context) => _footer(small, context, pageLabel),
      build: (context) => [
        pw.Text(subject, style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold, color: _accent)),
        pw.SizedBox(height: mm(6)),
        ...body,
      ],
    ));
    return doc.save();
  }

  /// Fold marks and the hole mark, on the left edge.
  pw.Widget _marks() {
    final folds = _din ? [105.0, 210.0] : [99.0, 198.0];
    pw.Widget line(double y, double length) => pw.Positioned(
          left: mm(3),
          top: mm(y),
          child: pw.Container(width: mm(length), height: 0.4, color: PdfColors.grey600),
        );
    return pw.Stack(children: [for (final f in folds) line(f, 5), line(148.5, 7)]);
  }

  /// Issuer, return line, address field and information block, placed in
  /// millimetres; the body follows at [_bodyTop].
  pw.Widget _firstPageHead(pw.ImageProvider? logo, pw.TextStyle small) {
    final height = _bodyTop - _top;
    double x(double pageMm) => mm(pageMm) - _left;
    double y(double pageMm) => mm(pageMm) - _top;
    final addressX = _din ? x(25) : x(115);
    final infoX = _din ? x(125) : x(25);
    final returnLine = [letterhead.name, ...letterhead.address].join(' · ');
    return pw.SizedBox(
      height: height,
      child: pw.Stack(children: [
        // the issuer, top left (top right with the window on the right? no: top left in both)
        pw.Positioned(
          left: 0,
          top: 0,
          child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
            pw.Text(letterhead.name, style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 12, color: _accent)),
            for (final l in letterhead.address) pw.Text(l),
            if (letterhead.phone.isNotEmpty) pw.Text(letterhead.phone),
            if (letterhead.email.isNotEmpty) pw.Text(letterhead.email),
          ]),
        ),
        if (logo != null) pw.Positioned(right: 0, top: 0, child: pw.Image(logo, width: mm(40))),
        // return line (in the window, above the address)
        pw.Positioned(
          left: addressX,
          top: y(47),
          child: pw.SizedBox(
            width: mm(80),
            child: pw.Text(returnLine, style: small.copyWith(decoration: pw.TextDecoration.underline), maxLines: 1),
          ),
        ),
        // the address
        pw.Positioned(
          left: addressX,
          top: y(62.7),
          child: pw.SizedBox(
            width: mm(80),
            child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
              for (final l in recipient.addressBlock) pw.Text(l, style: const pw.TextStyle(fontSize: 10.5)),
            ]),
          ),
        ),
        // information block
        pw.Positioned(
          left: infoX,
          top: y(50),
          child: pw.SizedBox(
            width: mm(75),
            child: pw.Table(columnWidths: {0: const pw.FlexColumnWidth(4), 1: const pw.FlexColumnWidth(5)}, children: [
              for (final (label, value) in info)
                pw.TableRow(children: [
                  pw.Padding(padding: const pw.EdgeInsets.only(bottom: 1.5), child: pw.Text(label, style: small)),
                  pw.Text(value),
                ]),
            ]),
          ),
        ),
      ]),
    );
  }

  pw.Widget _footer(pw.TextStyle small, pw.Context context, String pageLabel) => pw.Column(children: [
        pw.Divider(color: PdfColors.grey400, thickness: 0.5),
        pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
          pw.Expanded(
            child: pw.Text(
              [
                letterhead.name,
                if (letterhead.siret.isNotEmpty) 'SIRET ${letterhead.siret}',
                if (letterhead.taxNumber.isNotEmpty) 'St.-Nr. ${letterhead.taxNumber}',
                if (letterhead.vatId.isNotEmpty) 'TVA/USt-IdNr. ${letterhead.vatId}',
                if (letterhead.iban.isNotEmpty) 'IBAN ${letterhead.iban}${letterhead.bic.isEmpty ? '' : ' · BIC ${letterhead.bic}'}',
                if (letterhead.footer.isNotEmpty) letterhead.footer,
              ].join(' · '),
              style: small,
            ),
          ),
          pw.Text('$pageLabel ${context.pageNumber}/${context.pagesCount}', style: small),
        ]),
      ]);
}
