import 'dart:convert';
import 'dart:io';

import '../../nohfibu.dart';

/// A book's history on disk: one file per device, `<device>.jsonl`, one
/// encrypted change per line, in the device's order. A device only ever
/// appends to its own file, so a shared folder (Nextcloud, Syncthing) never
/// sees two writers on one file; a hub keeps everyone's files.
class ChangeFiles {
  final Directory dir;
  final LedgerCipher cipher;

  ChangeFiles(this.dir, this.cipher);

  File _file(String device) => File('${dir.path}/$device.jsonl');

  /// Reads every device's file. Lines that do not open or do not match
  /// their content are left out and named in [problems].
  Future<ChangeGraph> load({List<String>? problems}) async {
    final graph = ChangeGraph();
    if (!dir.existsSync()) return graph;
    for (final f in dir.listSync().whereType<File>().where((f) => f.path.endsWith('.jsonl'))) {
      final device = f.uri.pathSegments.last.replaceAll(RegExp(r'\.jsonl$'), '');
      var n = 0;
      for (final line in f.readAsLinesSync()) {
        n++;
        if (line.trim().isEmpty) continue;
        try {
          final change = Change.fromJson(jsonDecode(await cipher.open(line, aad: device)) as Map<String, dynamic>);
          if (change.device != device) throw const FormatException('in the file of another device');
          graph.add(change);
        } catch (e) {
          problems?.add('${f.path}:$n: $e');
        }
      }
    }
    return graph;
  }

  /// Writes the files of [graph]'s devices (only [devices] when given),
  /// each completely and then renamed into place — never half a file.
  Future<void> save(ChangeGraph graph, {Iterable<String>? devices}) async {
    dir.createSync(recursive: true);
    final byDevice = <String, List<Change>>{};
    for (final c in graph.changes) {
      (byDevice[c.device] ??= []).add(c);
    }
    for (final device in devices ?? byDevice.keys) {
      final changes = (byDevice[device] ?? [])..sort((a, b) => a.seq.compareTo(b.seq));
      final lines = [for (final c in changes) await cipher.seal(jsonEncode(c.toJson()), aad: device)];
      final tmp = File('${_file(device).path}.tmp')..writeAsStringSync('${lines.join('\n')}\n');
      tmp.renameSync(_file(device).path);
    }
  }
}
