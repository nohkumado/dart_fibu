// to run this :!dart test test/kpl_test.dart --chain-stack-traces
import 'package:test/test.dart';
import 'package:nohfibu/nohfibu.dart';

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
  group('Konto', () {
    var kto = Konto(number : "1",name: "1001", desc: "test account", plan: book.kpl, valuta:1000099, cur:"EUR", budget:99912);
    test('Konto ', () {
      //kto.recursive = true;
      //print("kto : $kto");
      expect(kto.name, equals("1001"));
    });
    test('Setter ', () {
      kto.set(name:"oyoyoy", valuta: 1111199);
      expect(kto.name, equals("oyoyoy"));
      expect(kto.valuta, equals(1111199));
    });

    test('Getter ', () {
      Konto secd = kto.get("oyoyoy");
      expect(secd.name, equals("oyoyoy"));
      kto.set(name:"1001", valuta: 1111199);
      secd = kto.get("10010");
      expect(secd.name, equals("10010"));
      secd = kto.get("oyoyoy");

      //kto.recursive = true;
      //print("wild stuff check $kto");
      //kto.recursive = false;
      expect(secd.name, equals("oyoyoy"));
    });
    test('toString ', () {
      kto.set(name:"1001",valuta: 1000099);
      expect(kto.toString(), equals("1001  test account                                          € 999.12   € 10,000.99\n"));
      kto = Konto(number : "1",name: "1001", plan: book.kpl, valuta:1000099, cur:"EUR", budget:99912);
      //Konto sk =
      kto.get("10010");
      //print("kto sk = $sk");
      String target=  '''1001                                                        € 999.12   € 10,000.99
      1                                                          € 0.00        € 0.00
       0                                                          € 0.00        € 0.00
        0                                                          € 0.00        € 0.00
         1                                                          € 0.00        € 0.00
       10010                                                          € 0.00        € 0.00\n''';
      expect(normalize(kto.toString(recursive: true,empty:true)), equals(normalize(target)));
    });
    test('printname ', () {
      expect(kto.printname(), equals("1001"));
    });
    //void asList(List<List> )
    test('asList ', () {
      kto.set(desc:"top account");
      kto.get("10010").set(desc:"bottom  account");
      //print("kto check $kto");
      List<List<dynamic>>  res = [];
      kto.asList(asList: res);
      //print("asList returned $res");
      expect(res, equals([["1001", "top account", "EUR", 99912, 1000099], ["10010", "bottom  account", "EUR", 00, 00]]));
    });
    test('Initialization with default values', () {
      Konto defaultKonto = Konto();
      expect(defaultKonto.name, equals('no name'));
      expect(defaultKonto.cur, equals('EUR'));
      expect(defaultKonto.valuta, equals(0));
      expect(defaultKonto.budget, equals(0));
    });
    test('Nested account handling', () {
      Konto parent = Konto(number: '1', name: '1000', plan: book.kpl);
      Konto child = Konto(number: '2', name: '1001', plan: book.kpl);
      parent.put('2', child);

      expect(parent.children['2']!.name, equals('1001'));
      expect(parent.children['2']!.number, equals('2'));

      Konto retrieved = parent.get('2');
      expect(retrieved.name, equals('1001'));
    });
    test('Sum of valuta with children', () {
      Konto parent = Konto(number: '1', name: '1000', valuta: 5000, plan: book.kpl);
      Konto child1 = Konto(number: '2', name: '1001', valuta: 3000, plan: book.kpl);
      Konto child2 = Konto(number: '3', name: '1002', valuta: 2000, plan: book.kpl);

      parent.put('2', child1);
      parent.put('3', child2);

      int totalSum = parent.sum();
      expect(totalSum, equals(10000));  // 5000 + 3000 + 2000
    });
    test('Action method (add and subtract valuta)', () {
      Konto kto = Konto(number: '1', name: '1000', valuta: 10000, plan: book.kpl);
      JrlLine addLine = JrlLine(valuta: 5000, cur: 'EUR');
      JrlLine subLine = JrlLine(valuta: 2000, cur: 'EUR');

      kto.action(addLine, mode: Mode.add);
      expect(kto.valuta, equals(15000));

      kto.action(subLine, mode: Mode.sub);
      expect(kto.valuta, equals(13000));
    });
    test('Handling edge cases in account names', () {
      Konto emptyNameKonto = Konto(name: '', plan: book.kpl);
      expect(emptyNameKonto.name, equals(''));

      Konto longNameKonto = Konto(name: 'A' * 255, plan: book.kpl);
      expect(longNameKonto.name.length, equals(255));
    });
    test('Currency conversion in numFormat', () {
      Konto kto = Konto(cur: 'EUR', plan: book.kpl);
      String formattedValue = kto.numFormat(1234567);
      expect(formattedValue, contains('€ 12,345.67'));

      kto.cur = 'EUR';
      formattedValue = kto.numFormat(1234567);
      expect(formattedValue, contains('€ 12,345.67'));
    });
    test('asList with nested accounts', () {
      Konto parent = Konto(number: '1', name: '1000', desc: 'a parent?', plan: book.kpl);
      Konto child1 = Konto(number: '2', name: '1001', desc: 'Child 1', plan: book.kpl);
      Konto child2 = Konto(number: '3', name: '1002', desc: 'Child 2', plan: book.kpl);

      parent.put('2', child1);
      parent.put('3', child2);

      List<List<dynamic>> res = [];
      parent.asList(asList: res);
      expect(res.length, equals(3));  // Parent + 2 children
      expect(res[0][0], equals('1000'));
      expect(res[1][0], equals('1001'));
      expect(res[2][0], equals('1002'));
    });

  });
}
