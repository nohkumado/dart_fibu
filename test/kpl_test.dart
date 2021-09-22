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
    //String toString({String indent: ""})
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
      print("retrieved  $secd");
      expect(secd.name, equals("oyoyoy"));
      kto.set(name:"1001", valuta: 11111.99);
      secd = kto.get("10010");
      expect(secd.name, equals("10010"));
      print("getting oyooyo from $kto");
      secd = kto.get("oyoyoy");
      expect(secd.name, equals("oyoyoy"));
    });
    test('toString ', () {
      kto.set(valuta: 10000.99);
      expect(kto.toString(), equals("oyoyoy"));
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
