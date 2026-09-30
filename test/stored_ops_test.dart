import 'dart:io';

import 'package:nohfibu/csv_handler.dart';
import 'package:nohfibu/fibusettings.dart';
import 'package:nohfibu/nohfibu.dart';
import 'package:test/test.dart';

/// The FUJI op of the compta2018 sample, booked the way the CLI and the app
/// do it: questions() → answers → fill().
void main() {
  late Book book;
  late Operation fuji;

  setUp(() {
    final settings = FibuSettings()..init(["-b", "assets/wbsamples/compta2018.csv"]);
    book = Book();
    CsvHandler().load(book: book, conf: settings);
    fuji = book.ops["FUJI"] as Operation;
    fuji.prepare();
  });

  test('the book file is read cleanly: accounts without quotes, all lines', () {
    expect(fuji.cminus, ["1000-1100", "1999", "1999", "1999", "1999"]);
    expect(fuji.cplus, ["1999", "2100-2200", "3500", "3600", "3500"]);
    expect(fuji.preparedLines, hasLength(5));
    expect(fuji.problems, isEmpty);
  });

  test('questions: date, the two ranges, amounts, then the text variable', () {
    final q = fuji.questions();
    expect(q.map((q) => q.key),
        ["date", "line0.minus", "line1.plus", "payement", "montant", "materiel", "objet", "divers"]);
    final byKey = {for (final x in q) x.key: x};
    expect(byKey["line0.minus"]!.choices.map((k) => k.name), containsAll(["1001", "1010", "1100"]));
    expect(byKey["line1.plus"]!.choices.map((k) => k.name), containsAll(["2100", "2101"]));
    expect(byKey["objet"]!.kind, OpQuestionKind.text);
    expect(byKey["payement"]!.kind, OpQuestionKind.amount);
  });

  test('fill: the lines, the remainder computed, zero lines left out', () {
    final lines = fuji.fill({
      "date": "15.10.2018",
      "line0.minus": "1001",
      "line1.plus": "2100",
      "payement": "100",
      "montant": "30",
      "materiel": "20",
      "objet": "sabre",
      "divers": "0",
    });
    String row(JrlLine l) => "${l.kminus.name}>${l.kplus.name} ${l.valuta} ${l.desc}";
    expect(lines.map(row), [
      "1001>1999 10000 Courses Fuji",
      "1999>2100 3000 Vêtements achetés chez Fuji",
      "1999>3500 2000 Materiel",
      // divers 0: its line is left out
      "1999>3500 5000 Armes achetés chez FUJI (100,00 - 30,00 - 20,00 - 0,00)",
    ]);
    expect(lines.every((l) => l.datum == DateTime(2018, 10, 15)), isTrue);
    // the template is untouched: a second booking starts from scratch
    expect(fuji.desc[3], "Divers (#objet)");
  });

  test('fill names every wrong answer', () {
    expect(
        () => fuji.fill({"line0.minus": "4400", "payement": "cent"}),
        throwsA(isA<FormatException>().having((e) => e.message, "message",
            allOf(contains("line0.minus"), contains("payement")))));
  });

  test('saving writes the columns in the order loading reads them', () {
    final rows = <List>[];
    fuji.asList(rows);
    expect(rows.first.sublist(2, 4), ["1000-1100", "1999"]);
  });

  group('Amount', () {
    test('euros and cents as people type them', () {
      expect(Amount.parseCents("12"), 1200);
      expect(Amount.parseCents("12,5"), 1250);
      expect(Amount.parseCents("1.234,56"), 123456);
      expect(Amount.parseCents("1,234.56"), 123456);
      expect(Amount.parseCents("-3 €"), -300);
      expect(Amount.parseCents("douze"), isNull);
    });
  });

  group('FibuDate', () {
    test('the usual forms', () {
      for (final s in ["15-10-2018", "15.10.2018", "15/10/18", "2018-10-15"]) {
        expect(FibuDate.parse(s), DateTime(2018, 10, 15), reason: s);
      }
      expect(FibuDate.parse("demain"), isNull);
    });
  });

  test('save and load again: the ops come back unchanged, dates still empty', () async {
    final dir = Directory.systemTemp.createTempSync('fibu');
    final settings = FibuSettings()..init(["-b", "${dir.path}/copy.csv", "-o", "${dir.path}/copy"]);
    final file = await CsvHandler().save(book: book, conf: settings);
    final again = Book();
    CsvHandler().load(book: again, conf: FibuSettings()..init(["-b", file.path]));
    final op = again.ops["FUJI"] as Operation;
    expect(op.cminus, fuji.cminus);
    expect(op.cplus, fuji.cplus);
    expect(op.valuta, fuji.valuta);
    expect(op.datum.every((d) => d == null), isTrue);
    dir.deleteSync(recursive: true);
  });
}

