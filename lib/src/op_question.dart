import '../nohfibu.dart';

/// One thing a stored [Operation] needs before it can be booked; the CLI
/// asks them one after the other, the app shows them as a form.
class OpQuestion {
  /// The answer's key for [Operation.fill]: `date`, a variable name,
  /// `line2.minus`, `line2.plus` or `line2.amount`.
  final String key;
  final OpQuestionKind kind;

  /// What to show the person.
  final String label;

  /// The answer offered.
  final String defaultValue;

  /// The accounts to choose from ([OpQuestionKind.account]).
  final List<Konto> choices;

  const OpQuestion(this.key, this.kind, this.label,
      {this.defaultValue = '', this.choices = const []});

  @override
  String toString() => '$key ($kind): $label [$defaultValue]';
}
