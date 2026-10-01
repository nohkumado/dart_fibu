/// Where an offer or invoice stands, from its history.
enum InvoiceStatus {
  /// Written, not sent.
  draft,

  /// An offer sent, waiting for the customer's answer.
  open,

  /// An offer accepted, not invoiced yet.
  accepted,

  /// An offer turned down.
  refused,

  /// An accepted offer that became an invoice.
  invoiced,

  /// An invoice sent, not (fully) paid, not due yet.
  unpaid,

  /// An invoice past its due date and not fully paid.
  overdue,

  /// Fully paid.
  paid,

  /// Cancelled.
  cancelled,
}
