/// What an [OpQuestion] asks for.
enum OpQuestionKind {
  /// The booking date (once per operation).
  date,

  /// An account, chosen among [OpQuestion.choices].
  account,

  /// An amount (a `#variable` used as amount, or a line without one).
  amount,

  /// A text for the description (a `#variable` used only in texts).
  text,
}
