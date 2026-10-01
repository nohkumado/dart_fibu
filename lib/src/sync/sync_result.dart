/// What a sync did: how many changes came in, how many went out.
class SyncResult {
  final int received;
  final int sent;

  const SyncResult(this.received, this.sent);

  @override
  String toString() => 'received $received, sent $sent';
}
