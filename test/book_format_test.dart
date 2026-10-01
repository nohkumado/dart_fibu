import 'dart:io';

import 'package:nohfibu/csv_handler.dart';
import 'package:nohfibu/fibusettings.dart';
import 'package:nohfibu/nohfibu.dart';
import 'package:test/test.dart';

Book load(String path) {
  final book = Book();
  CsvHandler().load(book: book, conf: FibuSettings()..init(["-b", path]));
  return book;
}

void main() {
  test('a book without version row is format 1: roles by block, block lines are headings', () {
    final book = load('assets/wbsamples/compta2018.csv');
    expect(book.formatVersion, 1);
    expect(book.kpl.get("1001")!.accountType, AccountType.Actif);
    expect(book.kpl.get("2001")!.accountType, AccountType.Passif);
    expect(book.kpl.get("3600")!.accountType, AccountType.Charge);
    expect(book.kpl.get("4410")!.accountType, AccountType.Produit);
    expect(book.kpl.get("1")!.heading, isTrue);
    expect(book.kpl.accounts().map((k) => k.name), isNot(contains("1")));
  });

  test('saved, it is format 2 — version row, role column — and reads back the same', () async {
    final old = load('assets/wbsamples/compta2018.csv');
    final dir = Directory.systemTemp.createTempSync('fibu');
    final file = await CsvHandler().save(
        book: old, conf: FibuSettings()..init(["-b", "${dir.path}/b.csv", "-o", "${dir.path}/b"]));
    final lines = file.readAsLinesSync();
    expect(lines.first, "FORMAT,nohfibu,${BookFormat.current},${BookFormat.software}");
    expect(lines[2], "kto,dsc,cur,budget,valuta,role");
    expect(lines.where((l) => l.startsWith("1,")).single, endsWith(",heading"));
    final again = load(file.path);
    expect(again.formatVersion, BookFormat.current);
    expect(again.writtenBy, "nohfibu ${BookFormat.software}");
    for (final k in old.kpl.accounts()) {
      expect(again.kpl.get(k.name)!.accountType, k.accountType, reason: k.name);
    }
    expect(again.kpl.get("1")!.heading, isTrue);
    dir.deleteSync(recursive: true);
  });

  test('format 2 with explicit roles: a chart where 6 is expenses and 7 income', () {
    final dir = Directory.systemTemp.createTempSync('fibu');
    final file = File("${dir.path}/pcg.csv")
      ..writeAsStringSync("""FORMAT,nohfibu,2,0.2.0
KPL
kto,dsc,cur,budget,valuta,role
5,Comptes financiers,EUR,0,0,heading
512,Banque,EUR,0,0,actif
6,Charges,EUR,0,0,heading
606,Achats,EUR,0,0,charge
7,Produits,EUR,0,0,heading
706,Prestations,EUR,0,0,produit
101,Capital,EUR,0,0,passif
JRL
date,ktominus,ktoplus,desc,cur,valuta
2026-01-10,101,512,Apport,EUR,100000
2026-02-01,706,512,Facture 2026-0001,EUR,30000
2026-02-03,512,606,Fournitures,EUR,5000
""");
    final book = load(file.path);
    expect(book.kpl.get("606")!.accountType, AccountType.Charge);
    expect(book.kpl.get("706")!.accountType, AccountType.Produit);
    expect(book.kpl.withRole(AccountType.Charge).map((k) => k.name), ["606"]);
    book.execute();
    final analysis = book.kpl.analysis();
    expect(analysis, contains("Achats"));
    expect(analysis, contains("Prestations"));
    // income 300 - expenses 50 = 250; assets 1250 - liabilities -1000 → the two agree
    expect(book.kpl.get("512")!.valuta, 125000);
    final zero = Konto().numFormat(0).trimRight();
    final surplus = Konto().numFormat(25000).trimRight();
    expect(RegExp("Ueberschuss +${RegExp.escape(surplus)}").allMatches(analysis), hasLength(2),
        reason: "balance sheet and income statement agree: 250");
    expect(analysis, matches(RegExp("Gueltigkeit \\(muss 0 sein\\) +${RegExp.escape(zero)}")));
    dir.deleteSync(recursive: true);
  });

  test('the version written into files is the package version', () {
    final pubspec = File('pubspec.yaml').readAsStringSync();
    expect(RegExp(r'^version: (\S+)', multiLine: true).firstMatch(pubspec)!.group(1), BookFormat.software);
  });

  test('me2000 (corrected: your convention, planets as assets) balances', () {
    final book = load('assets/wbsamples/me2000.csv');
    expect(book.formatVersion, 2);
    expect(book.kpl.get("231")!.accountType, AccountType.Actif, reason: "a planet is a possession");
    book.execute();
    int total(AccountType role) => book.kpl.withRole(role).fold(0, (s, k) => s + k.balance);
    expect(total(AccountType.Actif), 601133911);
    expect(total(AccountType.Passif), 0);
    expect(total(AccountType.Produit) - total(AccountType.Charge),
        total(AccountType.Actif) - total(AccountType.Passif));
    // every booking +x on one account, -x on the other
    expect(book.kpl.accounts().fold(0, (s, k) => s + k.valuta), 0);
  });
}

