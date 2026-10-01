import '../../nohfibu.dart';

/// One dated step in the life of an offer or invoice; the list of them is
/// its history and decides its [InvoiceStatus].
class DocumentEvent {
  final DateTime date;
  final DocumentEventKind kind;

  /// Reminder level (reminded) or amount in cents (paid); 0 otherwise.
  final int value;

  /// Free text: the invoice an offer became, a payment's reference…
  final String note;

  const DocumentEvent(this.date, this.kind, {this.value = 0, this.note = ''});

  Map<String, dynamic> toJson() => {
        'date': date.toIso8601String().substring(0, 10),
        'kind': kind.name,
        if (value != 0) 'value': value,
        if (note.isNotEmpty) 'note': note,
      };

  factory DocumentEvent.fromJson(Map<String, dynamic> j) => DocumentEvent(
        DateTime.parse('${j['date']}'),
        DocumentEventKind.values.byName('${j['kind']}'),
        value: (j['value'] as num?)?.toInt() ?? 0,
        note: '${j['note'] ?? ''}',
      );
}
