import 'dart:async';
import 'dart:io';

import '../../nohfibu.dart';

/// The hub (the desktop): serves one book's history on the local network.
/// A device that knows the invitation's token and key syncs like git
/// fetch + push: it says what it has, gets what it lacks, sends what the
/// hub lacks. Everything is sealed with the book's key; a device without
/// it is hung up on.
class SyncServer {
  final ChangeGraph graph;
  final SyncInvitation invitation;

  /// Called after changes came in (e.g. to save the files).
  final Future<void> Function(List<Change> added)? onChanged;
  final void Function(String)? log;

  HttpServer? _server;
  late final LedgerCipher _cipher = LedgerCipher(invitation.key);

  SyncServer(this.graph, this.invitation, {this.onChanged, this.log});

  /// Listens on all interfaces at the invitation's port (0: any free one;
  /// see [port]).
  Future<void> start() async {
    _server = await HttpServer.bind(InternetAddress.anyIPv4, invitation.port);
    _server!.listen(_handle);
    log?.call('serving ${invitation.book} on port ${_server!.port}');
  }

  int get port => _server?.port ?? invitation.port;

  Future<void> stop() async => _server?.close(force: true);

  Future<void> _handle(HttpRequest request) async {
    if (request.uri.path != '/sync/${invitation.book}' || request.uri.queryParameters['t'] != invitation.token) {
      request.response.statusCode = HttpStatus.forbidden;
      await request.response.close();
      return;
    }
    final socket = await WebSocketTransformer.upgrade(request);
    final messages = StreamIterator<dynamic>(socket);
    const wait = Duration(seconds: 30);
    try {
      // 1. hello: the device and the changes it has
      if (!await messages.moveNext().timeout(wait)) return;
      final hello = await SyncMessage.open('${messages.current}', _cipher);
      // 2. what it lacks, and what the hub has
      final toClient = graph.missingFor(hello.have);
      socket.add(await SyncMessage('changes', device: 'hub', have: graph.ids, changes: toClient).seal(_cipher));
      // 3. what the hub lacks
      if (!await messages.moveNext().timeout(wait)) return;
      final push = await SyncMessage.open('${messages.current}', _cipher);
      final added = push.changes.where(graph.add).toList();
      if (added.isNotEmpty) await onChanged?.call(added);
      socket.add(await SyncMessage('done', added: added.length).seal(_cipher));
      log?.call('${hello.device}: sent ${toClient.length}, received ${added.length}');
      await socket.close();
    } on LedgerCipherException {
      log?.call('a device without the key — hung up');
      await socket.close(WebSocketStatus.policyViolation);
    } catch (e) {
      log?.call('sync failed: $e');
      await socket.close(WebSocketStatus.internalServerError);
    }
  }
}
