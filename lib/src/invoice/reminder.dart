import '../../nohfibu.dart';

/// A reminder for an unpaid invoice: its level (1 friendly, 2 with late
/// interest, 3 final notice) and what it adds to the open amount.
class Reminder {
  final Invoice invoice;
  final int level;
  final DateTime date;

  /// Late interest from the due date to [date], in cents (level 2 and up,
  /// at the letterhead's yearly rate).
  final int interestCents;

  /// The fixed recovery fee for businesses, in cents (level 2 and up).
  final int feeCents;

  const Reminder(this.invoice, this.level, this.date, {this.interestCents = 0, this.feeCents = 0});

  /// What is owed with this reminder.
  int get totalCents => invoice.openCents + interestCents + feeCents;

  /// The reminder of [level] for [invoice] on [date], charges included
  /// from level 2.
  factory Reminder.of(Invoice invoice, int level, DateTime date, Letterhead letterhead, Customer customer) {
    if (level < 2) return Reminder(invoice, level, date);
    final days = invoice.daysOverdue(date);
    final interest = (invoice.openCents * letterhead.penaltyRate * days / 365).round();
    return Reminder(invoice, level, date,
        interestCents: interest, feeCents: customer.business ? letterhead.recoveryFeeCents : 0);
  }
}
