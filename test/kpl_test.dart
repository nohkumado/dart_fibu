// to run this :!dart test test/kpl_test.dart --chain-stack-traces
import 'package:test/test.dart';
import 'package:nohfibu/kto_plan.dart';
import 'package:nohfibu/journal.dart';
import 'package:nohfibu/book.dart';
import 'package:nohfibu/csv_handler.dart';

void main() {
  Book book  = new Book();
  setUp(()
      {
	//book = new Book();
    //print("in setup generated kpl : $book.kpl and book.jrl : $book.jrl");
      });
  group('Konto', () {
      var kto = Konto(number : "1",name: "1001", plan: book.kpl, valuta:10000.99, cur:"EUR", budget:999.12);
    test('Konto ', () {
      //kto.recursive = true;
      //print("kto : $kto");
      expect(kto.name, equals("1001"));
    });
    test('Setter ', () {
      kto.set(name:"oyoyoy", valuta: 11111.99);
      expect(kto.name, equals("oyoyoy"));
      expect(kto.valuta, equals(11111.99));
    });

    test('Getter ', () {
      Konto secd = kto.get("oyoyoy");
      expect(secd.name, equals("oyoyoy"));
      kto.set(name:"1001", valuta: 11111.99);
      secd = kto.get("10010");
      expect(secd.name, equals("10010"));
      secd = kto.get("oyoyoy");

      //kto.recursive = true;
      //print("wild stuff check $kto");
      //kto.recursive = false;
      expect(secd.name, equals("oyoyoy"));
    });
    test('toString ', () {
      kto.set(name:"1001",valuta: 10000.99);
      expect(kto.toString(), equals("1001                                                    € 999.12  € 10,000.99"));
      kto = Konto(number : "1",name: "1001", plan: book.kpl, valuta:10000.99, cur:"EUR", budget:999.12);
      Konto sk =  kto.get("10010");
      String target = "1001                                                    € 999.12  € 10,000.99\n"+
	  ' 10010                                                    € 0.00  € 0.00\n';
      expect(kto.toString(recursive: true,empty:true), equals(target));
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
      expect(res, equals([["1001", "top account", "EUR", 999.12, 10000.99], ["10010", "bottom  account", "EUR", 0.0, 0.0]]));
    });
  });




  group('Journal', ()
  {
      var kto1 = Konto(number : "1",name: "1001", plan: book.kpl, valuta:10000.99, cur:"EUR", budget:999.12);
      var kto2 = Konto(number : "2",name: "2002", plan: book.kpl, valuta:80000.99, cur:"EUR", budget:888.12);
    test('Journal Eintrag', () {
      //print("global journal: ${book.jrl}");
      var line = JrlLine(datum: DateTime.parse("2021-09-01"), kmin:kto1, kplu:kto2, desc: "test line", cur:"EUR", valuta: 88888);
      expect(line.desc, equals("test line"));
      expect(line.toString(), equals("01-09-2021 1001 2002 test line                                         € 88,888.00"));
      List<List> data = [];
      line.asList(data);
      expect(data, equals([['2021-09-01', '1001', '2002', 'test line', 'EUR', 88888]]));
    });



    test('Journal Eintrag', () {
      //print("global journal: ${book.jrl}");
      var line = JrlLine(datum: DateTime.parse("2021-09-01"), kmin:kto1, kplu:kto2, desc: "test line", cur:"EUR", valuta: 88888);
      List<List> data = [];
  book.jrl.asList(data);
      expect(data, equals([['JRL'], ['date', 'ktominus', 'ktoplus', 'desc', 'cur', 'valuta']]));
      data = [];
  book.jrl.add(line);
  book.jrl.asList(data);
      expect(data.length == 3 && data[2][0] == '2021-09-01', equals(true));



  book.jrl.clear();
      data = [];
  book.jrl.asList(data);
      expect(data.length == 2, equals(true));
  book.jrl.add(line);
  String result = '            Journal\n'+ '01-09-2021 1001 2002 test line                                         € 88,888.00\n'+ '          Journal End';
      expect(book.jrl.toString(), equals(result));
    });
  });
}
