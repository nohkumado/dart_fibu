/// What happened to an offer or an invoice.
enum DocumentEventKind {
  /// Written, not sent yet.
  created,

  /// Sent to the customer (the number is final from here on).
  issued,

  /// An offer the customer accepted.
  accepted,

  /// An offer the customer turned down.
  refused,

  /// An accepted offer that became an invoice (the event names it).
  invoiced,

  /// A reminder sent for an unpaid invoice (level 1, 2, 3).
  reminded,

  /// A payment received (amount in cents; several make up the total).
  paid,

  /// Cancelled (an invoice is cancelled by a credit note, never deleted).
  cancelled,
}
