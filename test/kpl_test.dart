// to run this :!dart test test/kpl_test.dart --chain-stack-traces
import 'package:test/test.dart';
import 'package:nohfibu/kto_plan.dart';
import 'package:nohfibu/journal.dart';

void main() {
  //late KontoPlan kpl;
  KontoPlan kpl= KontoPlan();
  late Journal jrl;
  setUp(()
      {
	kpl = KontoPlan();
	  jrl = Journal( kpl);
    //print("in setup generated kpl : $kpl and jrl : $jrl");
      });
  group('Konto', () {
    //printname()
    //void asList(List<List> asList)
      var kto = Konto(number : "1",name: "1001", plan: kpl, valuta:10000.99, cur:"EUR", budget:999.12);
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
      kto = Konto(number : "1",name: "1001", plan: kpl, valuta:10000.99, cur:"EUR", budget:999.12);
       kto.get("10010");
      kto.recursive = true;
      String target = "1001                                                    € 999.12  € 10,000.99\n"+
	  ' 10010                                                    € 0.00  € 0.00\n';
      expect(kto.toString(), equals(target));
    });
    test('printname ', () {
      //kto.set(name:"1001",valuta: 10000.99);
      //print("kto check $kto");
      expect(kto.printname(), equals("1001"));
    });
  });

  //group('int', ()
  //{
  //  test('.remainder() returns the remainder of division', () {
  //    expect(11.remainder(3), equals(2));
  //  });

  //  test('.toRadixString() returns a hex string', () {
  //    expect(11.toRadixString(16), equals('b'));
  //  });
  //});
}
