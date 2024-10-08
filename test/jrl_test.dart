import 'package:intl/intl.dart';
import 'package:nohfibu/nohfibu.dart';
import 'package:test/test.dart';

void main() {
  String normalize(String str) {
    return str.split('\n')
        .map((line) => line.trim().replaceAll(RegExp(r'\s{2,}'), ' '))
        .join('\n')
        .trim();
  }
  Book book  = new Book();
  setUp(()
  {
    //book = new Book();
    //print("in setup generated kpl : $book.kpl and book.jrl : $book.jrl");
  });
    group('JrlLine', () {
      late Konto kplus;
      late Konto kminus;

      setUp(() {
        kplus = Konto(name: '1001', plan: KontoPlan(), valuta: 10000);
        kminus = Konto(name: '2002', plan: KontoPlan(), valuta: 5000);
      });

      test('Constructor with default values', () {
        JrlLine line = JrlLine();

        expect(line.kplus.name, equals('no name')); // Assuming default Konto
        expect(line.kminus.name, equals('no name')); // Assuming default Konto
        expect(line.desc, equals('none'));
        expect(line.cur, equals('EUR'));
        expect(line.valuta, equals(JrlLine.maxValue));
        expect(line.datum.isBefore(DateTime.now().add(Duration(seconds: 1))), isTrue);
      });

      test('Constructor with provided values', () {
        DateTime date = DateTime(2023, 8, 30);
        JrlLine line = JrlLine(
          datum: date,
          kmin: kminus,
          kplu: kplus,
          desc: 'Test Transaction',
          cur: 'EUR',
          valuta: 12345,
        );

        expect(line.datum, equals(date));
        expect(line.kminus.name, equals(kminus.name));
        expect(line.kplus.name, equals(kplus.name));
        expect(line.desc, equals('Test Transaction'));
        expect(line.cur, equals('EUR'));
        expect(line.valuta, equals(12345));
      });

      test('toString() formats correctly', () {
        DateTime date = DateTime(2023, 8, 30);
        JrlLine line = JrlLine(
          datum: date,
          kmin: kminus,
          kplu: kplus,
          desc: 'Test Transaction',
          cur: 'EUR',
          valuta: 1234500,
        );

        String result = line.toString();
        expect(result.contains('30-08-2023'), isTrue);
        expect(result.contains(kminus.printname()), isTrue);
        expect(result.contains(kplus.printname()), isTrue);
        expect(result.contains('Test Transaction'), isTrue);
        expect(result.contains(r'€ 12,345.00'), isTrue); // Assuming $ as symbol for EUR
      });

      test('asList() formats correctly', () {
        DateTime date = DateTime(2023, 8, 30);
        JrlLine line = JrlLine(
          datum: date,
          kmin: kminus,
          kplu: kplus,
          desc: 'Test Transaction',
          cur: 'EUR',
          valuta: 1234500,
        );

        List<List> data = [];
        line.asList(data);

        expect(data.length, equals(1));
        expect(data[0][0], equals('2023-08-30'));
        expect(data[0][1], equals(kminus.printname()));
        expect(data[0][2], equals(kplus.printname()));
        expect(data[0][3], equals('Test Transaction'));
        expect(data[0][4], equals('EUR'));
        expect(data[0][5], equals(1234500));
      });

      test('execute() modifies Konto valutas', () {
        // Initialize accounts with initial valutas
        KontoPlan plan = KontoPlan();
        Konto kminus = Konto(name: '2002', desc: 'minus', valuta: 10000, plan: plan , debug: true);
        Konto kplus = Konto(name: '1001',  desc: 'plus',valuta: 5000, plan: plan);
        plan.check(kminus);
        plan.check(kplus);

        // Create a JrlLine with a specific valuta to transfer
        JrlLine line = JrlLine(kmin: kminus, kplu: kplus, valuta: 1500);

        // Execute the line (this should modify the valutas in kminus and kplus)
        line.execute();

        // After execution, kminus should decrease by the line's valuta
        expect(kminus.valuta, equals(8500)); // 10000 - 1500

        // After execution, kplus should increase by the line's valuta
        expect(kplus.valuta, equals(6500)); // 5000 + 1500
      });


      test('addConstraint() sets constraints correctly', () {
        JrlLine line = JrlLine();

        line.addConstraint('kmin', boundaries: ['100', '2000']);
        line.addConstraint('kplu', boundaries: ['300', '4000']);

        expect(line.limits!['kmin']!['min'], equals('100'));
        expect(line.limits!['kmin']!['max'], equals('2000'));
        expect(line.limits!['kplu']!['min'], equals('300'));
        expect(line.limits!['kplu']!['max'], equals('4000'));
      });

      test('Setter kminus within range', () {
        JrlLine line = JrlLine(kmin: Konto(name: '1500'));
        line.addConstraint('kmin', boundaries: ['1000', '2000']);

        Konto newKmin = Konto(name: '1200');
        line.kminus = newKmin;

        expect(line.kminus.name, equals('1200'));
      });

      test('Setter kminus out of range', () {
        JrlLine line = JrlLine(kmin: Konto(name: '1500'));
        line.addConstraint('kmin', boundaries: ['1000', '2000']);

        Konto newKmin = Konto(name: '500');
        line.kminus = newKmin;

        expect(line.kminus.name, equals('1500')); // Value remains unchanged
      });

      test('Setter kplus within range', () {
        JrlLine line = JrlLine(kplu: Konto(name: '3500'));
        line.addConstraint('kplu', boundaries: ['3000', '4000']);

        Konto newKplus = Konto(name: '3200');
        line.kplus = newKplus;

        expect(line.kplus.name, equals('3200'));
      });

      test('Setter kplus out of range', () {
        JrlLine line = JrlLine(kplu: Konto(name: '3500'));
        line.addConstraint('kplu', boundaries: ['3000', '4000']);

        Konto newKplus = Konto(name: '2500');
        line.kplus = newKplus;

        expect(line.kplus.name, equals('3500')); // Value remains unchanged
      });

      test('setValuta() with valid string', () {
        JrlLine line = JrlLine();
        line.setValuta('123.45');

        expect(line.valuta, equals(12345));
      });

      test('setValuta() with empty string', () {
        JrlLine line = JrlLine();
        line.setValuta('');

        expect(line.valuta, equals(JrlLine.maxValue));
      });

      test('setValuta() with invalid string', () {
        JrlLine line = JrlLine();
        line.setValuta('invalid');

        expect(line.valuta, equals(0)); // Assuming parsing fails and defaults to 0
      });

      test('Valuta conversion to integer', () {
        JrlLine line = JrlLine(valuta: 12345.67);
        expect(line.valuta, equals(1234567));

        line = JrlLine(valuta: '12345');
        expect(line.valuta, equals(12345));

        line = JrlLine(valuta: '12,345.67');
        expect(line.valuta, equals(1234567)); // Depending on locale, adjust this
      });

      test('Execute with Valuta Update', () {
        Konto kplus = Konto(name: 'kplus',desc: 'kplus', valuta: 5000);
        Konto kminus = Konto(name: 'kminus',desc: 'kminus', valuta: 10000);
        JrlLine line = JrlLine(kmin: kminus, kplu: kplus, valuta: 1500);
        print("valuta update: $kplus, ${kplus.valid()} $kminus, ${kminus.valid()}");

        line.execute();

        expect(kplus.valuta, equals(6500));
        expect(kminus.valuta, equals(8500));
      });

      test('Handling of null values in constructor', () {
        JrlLine line = JrlLine();

        expect(line.kminus, isNotNull);
        expect(line.kplus, isNotNull);
        expect(line.desc, equals('none'));
        expect(line.cur, equals('EUR'));
        expect(line.valuta, equals(JrlLine.maxValue));
      });

      test('Formatting with custom date and currency', () {
        DateTime customDate = DateTime(2020, 12, 31);
        JrlLine line = JrlLine(
          datum: customDate,
          kmin: kminus,
          kplu: kplus,
          desc: 'Year-end closing',
          cur: 'EUR',
          valuta: 100000,
        );

        String result = line.toString();
        expect(result.contains('31-12-2020'), isTrue);
        expect(result.contains('€ 1,000.00'), isTrue); // Depending on locale
      });
    });

    group('Journal', ()
  {
    var kto1 = Konto(number : "1",name: "1001", desc: "test acc1", plan: book.kpl, valuta:1000099, cur:"EUR", budget:99912);
    var kto2 = Konto(number : "2",name: "2002", desc: "test acc2",plan: book.kpl, valuta:8000099, cur:"EUR", budget:88812);

    test('Journal with Empty Entries', () {
      // Ensure the journal starts empty
      expect(book.jrl.journal.isEmpty, isTrue);

      // Execute the journal without any entries
      book.jrl.execute();

      // Check that the journal remains empty and the string representation is correct
      expect(book.jrl.journal.isEmpty, isTrue);
      expect(book.jrl.toString().replaceAll(RegExp(" from.*\n"), '\n'), equals("Journal\nJournal End"));
    });
    test('Journal Eintrag', () {
      //print("global journal: ${book.jrl}");
      var line = JrlLine(datum: DateTime.parse("2021-09-01"), kmin:kto1, kplu:kto2, desc: "test line", cur:"EUR", valuta: 8888800);
      expect(line.desc, equals("test line"));
      expect(line.toString(), equals("01-09-2021 1001 2002 test line                                          € 88,888.00"));
      List<List> data = [];
      line.asList(data);
      expect(data, equals([['2021-09-01', '1001', '2002', 'test line', 'EUR', 8888800]]));
    });



    test('Journal Eintrag', () {
      //print("global journal: ${book.jrl}");
      var line = JrlLine(datum: DateTime.parse("2021-09-01"), kmin:kto1, kplu:kto2, desc: "test line", cur:"EUR", valuta: 8888800);
      List<List> data = [];
      book.jrl.asList(data);
      expect(data, equals([['JRL'], ['date', 'ktominus', 'ktoplus', 'desc', 'cur', 'valuta','actSum']]));
      data = [];
      book.jrl.add(line);
      book.jrl.asList(data);
      expect(data.length == 3 && data[2][0] == '2021-09-01', equals(true));



      book.jrl.clear();
      data = [];
      book.jrl.asList(data);
      expect(data.length == 2, equals(true));
      book.jrl.add(line);
      String result = 'Journal\n'+ '01-09-2021 1001 2002 test line                                          € 88,888.00\n'+ 'Journal End';
      expect(book.jrl.toString().replaceAll(RegExp(" from.*\n"), '\n'), equals(result));
    });

    test('Journal Constraint', () {
      //print("global journal: ${book.jrl}");
      //var kto1 = Konto(number : "1",name: "1001", plan: book.kpl, valuta:1000099, cur:"EUR", budget:99912);
      //var kto2 = Konto(number : "2",name: "2002", plan: book.kpl, valuta:8000099, cur:"EUR", budget:88812);
      book.kpl.put("1001", kto1);
      book.kpl.put("2002", kto2);
      var line = JrlLine(datum: DateTime.parse("2021-09-01"), kmin:kto1, kplu:kto2, desc: "test line", cur:"EUR", valuta: 8888800);
      expect(line.needsAccount(accountType: "minus"), equals(false));
      line.addConstraint("kmin",boundaries:["1000","3000"]);
      expect(line.needsAccount(accountType: "minus"), equals(true));
      expect(line.needsAccount(accountType: "plus"), equals(false));
      line.kminus = book.kpl.get("2002")!;
      expect(line.kminus.printname(), equals("2002"));
      line.addConstraint("kmin",boundaries:["1000","3000"]);
      line.kminus = book.kpl.get("2002")!;
      expect(line.kminus.printname(), equals("2002"));
      line.kplus = book.kpl.get("1001")!;
      expect(line.kplus.printname(), equals("1001"));
      line.addConstraint("kplu",boundaries:["1000","3000"]);
      line.kplus = book.kpl.get("2002")!;
      expect(line.kplus.printname(), equals("2002"));
      line.kplus = book.kpl.get("2001")!;
      expect(line.kplus.printname(), equals("2002"));
      line.limits!["kplu"] = {
        "min" : "1000",
        "max": "4000"
      };
      expect(line.needsAccount(accountType: "plus"), equals(true));
    });
test('Journal Entries and Clear', () {
      var line = JrlLine(datum: DateTime.parse("2021-09-02"), kmin: kto1, kplu: kto2, desc: "another test line", cur: "EUR", valuta: 8888800);
      List<List> data = [];
      book.jrl.asList(data);
      expect(data, equals([['JRL'], ['date', 'ktominus', 'ktoplus', 'desc', 'cur', 'valuta', 'actSum'], ['2021-09-01', '1001', '2002', 'test line', 'EUR', 8888800]]));

      // Add a line to the journal
      book.jrl.add(line);
      data = [];
      book.jrl.asList(data);
      expect(data.length == 4 && data[3][0] == '2021-09-02', equals(true));

      // Clear the journal
      book.jrl.clear();
      data = [];
      book.jrl.asList(data);
      expect(data.length == 2, equals(true));

      // Add line again and check string representation
      book.jrl.add(line);
      String result = 'Journal\n02-09-2021 1001 2002 another test line                                  € 88,888.00\nJournal End';
      expect(book.jrl.toString().replaceAll(RegExp(" from.*\n"), '\n'), equals(result));
    });

    test('Journal Constraint Handling', () {
      var line = JrlLine(datum: DateTime.parse("2021-09-01"), kmin: kto1, kplu: kto2, desc: "test line", cur: "EUR", valuta: 8888800);

      // Test constraint that should fail
      line.addConstraint("kmin", boundaries: ["100", "300"]);
      line.kminus = book.kpl.get("2002")!;
      expect(line.kminus.printname(), equals("1001")); // Constraint fails, so kminus doesn't change

      // Test constraint that should pass
      line.addConstraint("kmin", boundaries: ["1000", "3000"]);
      line.kminus = book.kpl.get("2002")!;
      expect(line.kminus.printname(), equals("2002")); // Constraint passes, so kminus changes

      line.kplus = book.kpl.get("1001")!;
      expect(line.kplus.printname(), equals("1001"));

      // Test another constraint on kplus
      line.addConstraint("kplu", boundaries: ["1000", "3000"]);
      line.kplus = book.kpl.get("2002")!;
      expect(line.kplus.printname(), equals("2002")); // Constraint passes, so kplus changes

      // Test constraint that should fail for kplus
      line.kplus = book.kpl.get("2001")!;
      expect(line.kplus.printname(), equals("2002")); // Constraint fails, so kplus doesn't change
    });

    test('Journal Execution', () {
      // Add multiple lines to the journal
      book.jrl.clear();
      var line1 = JrlLine(datum: DateTime.parse("2021-09-01"), kmin: kto1, kplu: kto2, desc: "test line 1", cur: "EUR", valuta: 1000000);
      var line2 = JrlLine(datum: DateTime.parse("2021-09-02"), kmin: kto2, kplu: kto1, desc: "test line 2", cur: "EUR", valuta: 2000000);
      var line3 = JrlLine(datum: DateTime.parse("2021-09-03"), kmin: kto2, kplu: kto1, desc: "test line 3", cur: "EUR", valuta: 3000000 );

      book.jrl.add(line1);
      book.jrl.add(line2);
      book.jrl.add(line3);

      // Execute the journal to apply transactions
      book.jrl.execute();

      //var kto1 = Konto(number : "1",name: "1001", plan: book.kpl, valuta:1000099, cur:"EUR", budget:99912);
      //var kto2 = Konto(number : "2",name: "2002", plan: book.kpl, valuta:8000099, cur:"EUR", budget:88812);
      // Check the updated valutas
      expect(kto1.valuta, equals(1000099- 1000000 + 2000000+ 3000000)); // kto1: initial - line1 + line2
      expect(kto2.valuta, equals(8000099+1000000 - 2000000 -3000000)); // kto2: initial + line1 - line2

      // Verify the journal string representation after execution
      String result =
                      '01-09-2021 1001 2002 test line 1                                        € 10,000.00\n' +
                      '02-09-2021 2002 1001 test line 2                                        € 20,000.00\n' +
                      '03-09-2021 2002 1001 test line 3                                        € 30,000.00\n' +
                      'Journal End';
      expect(book.jrl.toString().replaceAll(RegExp("Journal from.*\n"), ''), equals(result));
    });


    test('Journal Formatting with Multiple Entries', () {
      book.jrl.clear();
      var line1 = JrlLine(datum: DateTime.parse("2021-09-01"), kmin: kto1, kplu: kto2, desc: "test line 1", cur: "EUR", valuta: 5000);
      var line2 = JrlLine(datum: DateTime.parse("2021-09-02"), kmin: kto2, kplu: kto1, desc: "test line 2", cur: "EUR", valuta: 10000);

      book.jrl.add(line1);
      book.jrl.add(line2);

      List<List> data = [];
      book.jrl.asList(data, formatted: true);

      expect(data[2], equals(['2021-09-01', '1001', '2002', 'test line 1', 'EUR', '     € 50.00']));
      expect(data[3], equals(['2021-09-02', '2002', '1001', 'test line 2', 'EUR', '    € 100.00']));
    });

    test('Journal Edge Cases', () {
      // Test with an empty JrlLine (no values set)
      JrlLine emptyLine = JrlLine(datum: DateTime.parse("2024-09-05"));
      book.jrl.add(emptyLine);

      expect(emptyLine.kminus.name, equals('no name'));
      expect(emptyLine.kplus.name, equals('no name'));
      expect(emptyLine.valuta, equals(JrlLine.maxValue));
      expect(emptyLine.desc, equals('none'));

      // Test journal with this empty line
      String result = 'Journal from 2021-09-01 to 2023-10-04\n' +
          '01-09-2021 1001 2002 test line 1                                            € 50.00\n' +
          '02-09-2021 2002 1001 test line 2                                           € 100.00\n' +
          '05-09-2024    0    0 none                                                    ${emptyLine.formattedValuta(value:JrlLine.maxValue)}\n' +
                      'Journal End';
      expect(book.jrl.toString(), equals(result));

      // Clear the journal for next tests
      book.jrl.clear();
    });
  });
}
