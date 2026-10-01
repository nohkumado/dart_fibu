import 'dart:typed_data';

import 'package:intl/intl.dart';
import 'package:pdf/widgets.dart' as pw;

import '../../nohfibu.dart';

/// A [Reminder] as a business letter in the customer's language: level 1
/// friendly, 2 with late interest and the recovery fee, 3 final notice —
/// the invoice concerned, the open amount, the charges, the total, the
/// bank details.
class ReminderPdf {
  const ReminderPdf._();

  static Future<Uint8List> render(Reminder reminder, Letterhead letterhead, Customer customer) async {
    final invoice = reminder.invoice;
    final t = InvoiceTexts.of(customer.lang);
    final day = DateFormat('dd.MM.yyyy');
    final level = reminder.level.clamp(1, 3);
    final subject = t.reminderSubject[level - 1];
    final frame = LetterFrame(letterhead, customer, [
      (t.date, day.format(reminder.date)),
      ('${t.invoice} ${t.number}', invoice.number),
      (t.dateOfIssue, day.format(invoice.date)),
      (t.dueDate, day.format(invoice.payDate)),
      if (customer.id.isNotEmpty) (t.customerNumber, customer.id),
    ]);
    final locale = switch (customer.lang) { 'de' => 'de_DE', 'en' => 'en_GB', _ => 'fr_FR' };
    final money = NumberFormat.currency(locale: locale, symbol: frame.euroSign ? '€' : 'EUR');
    String eur(int cents) => money.format(cents / 100);
    pw.Widget row(String label, String value, {bool bold = false}) {
      final style = pw.TextStyle(fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal);
      return pw.Padding(
        padding: const pw.EdgeInsets.symmetric(vertical: 1.5),
        child: pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [
          pw.Text(label, style: style),
          pw.Text(value, style: style),
        ]),
      );
    }

    return frame.render(
      title: '$subject ${invoice.number}',
      subject: '$subject — ${t.invoice} ${t.number} ${invoice.number}',
      pageLabel: t.page,
      body: [
        pw.Text(t.greeting),
        pw.SizedBox(height: 6),
        pw.Text(t.reminderText[level - 1].replaceAll('{due}', day.format(invoice.payDate))),
        pw.SizedBox(height: 12),
        pw.SizedBox(
          width: 300,
          child: pw.Column(children: [
            row('${t.reminderTable}: ${invoice.number} (${day.format(invoice.date)})', eur(invoice.grossCents)),
            if (invoice.paidCents > 0) row('−', eur(invoice.paidCents)),
            row(t.openAmount, eur(invoice.openCents)),
            if (reminder.interestCents > 0) row(t.interest, eur(reminder.interestCents)),
            if (reminder.feeCents > 0) row(t.recoveryFee, eur(reminder.feeCents)),
            pw.Divider(thickness: 0.5),
            row(t.amountDue, eur(reminder.totalCents), bold: true),
          ]),
        ),
        if (letterhead.iban.isNotEmpty) ...[
          pw.SizedBox(height: 12),
          pw.Text(t.transfer.replaceAll('{amount}', eur(reminder.totalCents))),
          pw.SizedBox(height: 4),
          InvoicePdf.bankBox(letterhead),
        ],
        pw.SizedBox(height: 14),
        pw.Text(t.closing),
        pw.SizedBox(height: 18),
        pw.Text(letterhead.name),
      ],
    );
  }
}
