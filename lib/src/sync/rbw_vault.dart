import 'dart:io';

import '../../nohfibu.dart';

/// A book's key in Bitwarden, through the rbw command line: the login
/// "nohfibu <book>" (user `ledger-key`, folder `nohfibu`), the key as its
/// password. rbw unlocks the vault itself (it asks for the master
/// password when needed).
class RbwVault {
  final String rbw;

  const RbwVault({this.rbw = 'rbw'});

  static String entry(String book) => 'nohfibu $book';
  static const user = 'ledger-key';

  /// Whether rbw is installed.
  bool get available {
    try {
      return Process.runSync(rbw, ['--version']).exitCode == 0;
    } on ProcessException {
      return false;
    }
  }

  /// The key kept for [book], or null when there is none.
  LedgerKey? get(String book) {
    final r = Process.runSync(rbw, ['get', entry(book), user]);
    if (r.exitCode != 0) return null;
    final text = '${r.stdout}'.trim();
    return text.isEmpty ? null : LedgerKey.fromBase64(text);
  }

  /// Keeps [key] for [book] (adds the entry, or replaces its password).
  /// rbw takes a password only through an editor: a one-time script plays
  /// the editor, the key reaches it through the environment (not the
  /// command line, so `ps` never shows it), and is removed afterwards.
  Future<void> put(String book, LedgerKey key) async {
    final dir = Directory.systemTemp.createTempSync('nohfibu-rbw');
    try {
      final editor = File('${dir.path}/editor.sh')
        ..writeAsStringSync('#!/bin/sh\nprintf \'%s\\n\\n%s\\n\' "\$NOHFIBU_KEY" "\$NOHFIBU_NOTE" > "\$1"\n');
      Process.runSync('chmod', ['700', editor.path]);
      final exists = get(book) != null;
      final process = await Process.start(
        rbw,
        exists ? ['edit', entry(book), user] : ['add', '--folder', 'nohfibu', entry(book), user],
        environment: {
          'EDITOR': editor.path,
          'VISUAL': editor.path,
          'NOHFIBU_KEY': key.toBase64(),
          'NOHFIBU_NOTE': 'nohfibu ledger key of the book "$book". '
              'Restore: ledger -B $book key --from-rbw (desktop), or paste it in the app.',
        },
        mode: ProcessStartMode.inheritStdio,
      );
      if (await process.exitCode != 0) throw StateError('rbw could not keep the key');
      if (get(book)?.toBase64() != key.toBase64()) throw StateError('rbw did not keep the key as given');
    } finally {
      dir.deleteSync(recursive: true);
    }
  }
}
