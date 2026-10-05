import 'dart:io';

import 'package:nohfibu/nohfibu.dart';
import 'package:test/test.dart';

/// A stand-in for rbw (never the real vault): add/edit run $EDITOR on a
/// temporary file and keep its first line, get prints it; every command
/// line is logged so the test can check the key never appears in one.
void main() {
  late Directory dir;
  late File fake;

  setUp(() {
    dir = Directory.systemTemp.createTempSync('rbwfake');
    fake = File('${dir.path}/rbw')
      ..writeAsStringSync('''#!/bin/sh
store="${dir.path}/store"
echo "\$*" >> "${dir.path}/argv.log"
case "\$1" in
  --version) echo "rbw 1.15.0" ;;
  get) [ -f "\$store" ] && head -1 "\$store" || exit 1 ;;
  add|edit) tmp="${dir.path}/edit.tmp"; : > "\$tmp"; \$EDITOR "\$tmp" || exit 1; cp "\$tmp" "\$store" ;;
  *) exit 2 ;;
esac
''');
    Process.runSync('chmod', ['755', fake.path]);
  });
  tearDown(() => dir.deleteSync(recursive: true));

  test('the key goes into the vault and comes back, never on a command line', () async {
    final vault = RbwVault(rbw: fake.path);
    expect(vault.available, isTrue);
    expect(vault.get('compta'), isNull);
    final key = LedgerKey.generate();
    await vault.put('compta', key);
    expect(vault.get('compta')!.toBase64(), key.toBase64());
    expect(File('${dir.path}/argv.log').readAsStringSync(), isNot(contains(key.toBase64())));
    expect(File('${dir.path}/argv.log').readAsStringSync(), contains('add --folder nohfibu nohfibu compta ledger-key'));
    // a second time: the entry is edited, not added again
    final other = LedgerKey.generate();
    await vault.put('compta', other);
    expect(vault.get('compta')!.toBase64(), other.toBase64());
    expect(File('${dir.path}/argv.log').readAsStringSync(), contains('edit nohfibu compta ledger-key'));
  });

  test('no rbw: said so', () {
    expect(const RbwVault(rbw: '/nonexistent/rbw').available, isFalse);
  });
}
