import '../../nohfibu.dart';

/// Two changes that set the same thing without knowing each other: the
/// later one counts, the other is kept here so a person can confirm it.
class LedgerConflict {
  /// What both set, e.g. `customer:assoc`.
  final String entity;
  final Change kept;
  final Change replaced;

  /// The data the replaced change had set.
  final Map<String, dynamic> replacedData;

  const LedgerConflict(this.entity, this.kept, this.replaced, this.replacedData);

  @override
  String toString() => '$entity: ${kept.device} (${kept.time}) over ${replaced.device} (${replaced.time})';
}
