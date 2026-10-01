import 'dart:async';
import 'dart:io';

import '../../nohfibu.dart';

/// A device syncing with the hub of [invitation]: like git fetch + push —
/// tell what it has, take what it lacks, send what the hub lacks.
class SyncClient {
  final SyncInvitation invitation;

  /// This device's name (the change files are per device).
  final String device;

  const SyncClient(this.invitation, this.device);

  /// Syncs [graph] with the hub; the new changes are in [graph] afterwards.
  Future<SyncResult> sync(ChangeGraph graph, {Duration timeout = const Duration(seconds: 30)}) async {
    final cipher = LedgerCipher(invitation.key);
    final socket = await WebSocket.connect(invitation.endpoint.toString()).timeout(timeout);
    final messages = StreamIterator<dynamic>(socket);
    try {
      socket.add(await SyncMessage('hello', device: device, have: graph.ids).seal(cipher));
      if (!await messages.moveNext().timeout(timeout)) throw const SocketException('the hub hung up');
      final reply = await SyncMessage.open('${messages.current}', cipher);
      final received = reply.changes.where(graph.add).length;
      final toHub = graph.missingFor(reply.have);
      socket.add(await SyncMessage('changes', device: device, changes: toHub).seal(cipher));
      if (!await messages.moveNext().timeout(timeout)) throw const SocketException('the hub hung up');
      final done = await SyncMessage.open('${messages.current}', cipher);
      return SyncResult(received, done.added);
    } finally {
      await socket.close();
    }
  }
}
