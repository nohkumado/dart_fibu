import 'package:test/test.dart';
import 'package:nohfibu/kto_plan.dart';
import 'package:nohfibu/journal.dart';

void main() {
  late KontoPlan kpl;
  late Journal jrl;
  setUp(()
      {
	kpl = KontoPlan();
	  jrl = Journal( kpl);
      });
  group('Konto', () {
    // 
    //Konto set({number,name= "kein Name", plan, valuta, cur, budget})
    //Konto get(String ktoName)
    //String toString({String indent: ""})
    //printname()
    //void asList(List<List> asList)
    test('Konto ', () {
      var kto = Konto(number : "1",name: "1001", plan: kpl, valuta:10000.99, cur:"EUR", budget:999.12);
      kto.recursive = true;
      print("kto : $kto");
      expect(kto.name, equals("1001"));
    });

    //test('.trim() removes surrounding whitespace', () {
    //  var string = '  foo ';
    //  expect(string.trim(), equals('foo'));
    //});
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
