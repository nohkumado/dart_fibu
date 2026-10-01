/// One change inside a [Change]: what kind and its data.
///
/// Changes to a thing that has one current state (an account, a stored
/// operation, a customer, a letterhead, a document) carry the thing's
/// [entity] key; two such changes made without knowing each other are a
/// conflict. Additions (a journal line, a document event) never conflict.
class ChangeOp {
  /// account.put, journal.add, op.put, customer.put, letterhead.put,
  /// document.put, document.event.
  final String type;
  final Map<String, dynamic> data;

  const ChangeOp(this.type, this.data);

  /// The thing this op sets (e.g. `account:1001`), null for additions.
  String? get entity => switch (type) {
        'account.put' => 'account:${data['name']}',
        'op.put' => 'op:${data['name']}',
        'customer.put' => 'customer:${data['id']}',
        'letterhead.put' => 'letterhead:${data['id']}',
        'document.put' => 'document:${data['uid']}',
        _ => null,
      };

  Map<String, dynamic> toJson() => {'type': type, 'data': data};

  factory ChangeOp.fromJson(Map<String, dynamic> j) =>
      ChangeOp('${j['type']}', Map<String, dynamic>.from(j['data'] as Map));
}
