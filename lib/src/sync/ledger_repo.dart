import 'dart:io';

import '../../nohfibu.dart';

/// One book kept as an encrypted history on this device:
/// `<base>/books/<book>/` (one file per device), its key in
/// `<base>/keys/<book>.key`, this device's name in `<base>/device`.
/// Base: ~/.config/nohfibu on the desktop, the app's directory on a phone.
class LedgerRepo {
  final Directory base;
  final String book;
  final String device;
  final LedgerKey key;

  late ChangeGraph graph;

  /// Lines of the history files that did not open (named, not hidden).
  final List<String> problems = [];

  LedgerRepo._(this.base, this.book, this.device, this.key);

  Directory get historyDir => Directory('${base.path}/books/$book');
  ChangeFiles get files => ChangeFiles(historyDir, LedgerCipher(key));

  /// Opens [book] under [base] (key made on first use; [key] given: a
  /// paired device or a restore).
  static Future<LedgerRepo> open(Directory base, String book, {LedgerKey? key, String? device}) async {
    final keyFile = File('${base.path}/keys/$book.key');
    if (key != null && !keyFile.existsSync()) {
      keyFile.parent.createSync(recursive: true);
      keyFile.writeAsStringSync('${key.toBase64()}\n');
      if (!Platform.isWindows) Process.runSync('chmod', ['600', keyFile.path]);
    }
    final repo = LedgerRepo._(base, book, device ?? deviceName(base), key ?? LedgerKey.inFile(keyFile));
    repo.graph = await repo.files.load(problems: repo.problems);
    return repo;
  }

  /// This device's name, kept in `<base>/device` (the host name at first).
  static String deviceName(Directory base) {
    final f = File('${base.path}/device');
    if (f.existsSync()) return f.readAsStringSync().trim();
    final name = Platform.localHostname.toLowerCase().replaceAll(RegExp(r'[^a-z0-9-]+'), '-');
    base.createSync(recursive: true);
    f.writeAsStringSync('$name\n');
    return name;
  }

  /// This device's invoice number series: `<base>/series` when set; else
  /// none for the device that started the history, the device's name for
  /// the others (PHONE-2026-0001) — two devices never give the same number.
  String get series {
    final f = File('${base.path}/series');
    if (f.existsSync()) return f.readAsStringSync().trim();
    final first = graph.ordered().firstOrNull;
    return first == null || first.device == device ? '' : '${device.toUpperCase()}-';
  }

  /// The book, archive and letterheads as the history says now.
  Ledger get ledger => Ledger.replay(graph);

  /// Records [ops] as a change of this device and saves its file.
  Future<Change?> record(List<ChangeOp> ops) async {
    if (ops.isEmpty) return null;
    final change = graph.record(device, ops);
    await files.save(graph, devices: [device]);
    return change;
  }

  /// Saves the files of every device (after a sync brought changes).
  Future<void> saveAll() => files.save(graph);
}
