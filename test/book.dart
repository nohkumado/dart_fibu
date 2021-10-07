// to run this :!dart test test/kpl_test.dart --chain-stack-traces
import 'package:test/test.dart';
import 'package:nohfibu/settings.dart';
import 'package:nohfibu/nohfibu.dart';
import 'package:nohfibu/csv_handler.dart';

void main() {
  Settings regl = Settings();
  setUp(()
      {
      var incoming = ["-b", "assets/wbsamples/me2000.csv", "-s", "-l" , "de", "-o","test.csv"];
      regl.init(incoming);
      });
  group('Book', ()
      {
	var book = Book();
	test('loading', () {
	  var handler = CsvHandler();
	  handler.load(book: book, conf: regl ) ;
	  expect(book.jrl.count(), equals(1152));
	  book.clear();
	  regl["base"] = "assets/wbsamples/sample";
	  handler.load(book: book, conf: regl ) ;
	  expect(book.jrl.count(), equals(16));
	  book.execute();
	  //print("after  execute : \n${book.kpl.get("3300")!.extract.toString()}");
	  expect(book.kpl.get("1200")!.valuta, equals(203767));
	  expect(book.kpl.get("1600")!.valuta, equals(20593));
	  expect(book.kpl.get("2300")!.valuta, equals(-224360));
	  expect(book.kpl.get("2500")!.valuta, equals(0));
	  expect(book.kpl.get("2530")!.valuta, equals(000));
	  expect(book.kpl.get("3050")!.valuta, equals(593));
	  expect(book.kpl.get("3250")!.valuta, equals(9000));
	  expect(book.kpl.get("3300")!.valuta, equals(11000));
	  expect(book.kpl.get("4999")!.valuta, equals(-20593));
	  expect(book.kpl.get("3040")!.valuta, equals(0000));
	  expect(book.kpl.get("3060")!.valuta, equals(0000));
	  expect(book.kpl.get("3070")!.valuta, equals(0000));
	  expect(book.kpl.get("3080")!.valuta, equals(0000));
	  expect(book.kpl.get("3702")!.valuta, equals(0000));
	  expect(book.kpl.get("3801")!.valuta, equals(0000));
	  expect(book.kpl.get("3802")!.valuta, equals(0000));
	  expect(book.kpl.get("3902")!.valuta, equals(0000));
	  expect(book.kpl.get("4100")!.valuta, equals(0000));
	  expect(book.kpl.get("4200")!.valuta, equals(000));
	 	List<Konto>list = book.kpl.getRange({"min":"3000", "max": "3009"} );
	 	expect(list.length, equals(2));
		//print("using kpl ${book.kpl}");
		//List<Konto>
		list = book.kpl.getRange({"min":"2200", "max": "2500"} );
		//print("list got back $list");
		expect(list.length, equals(4));
		expect(list[0].desc, equals("Patrimoine"));
		regl["base"] = "assets/wbsamples/me2000";
		book.clear();
		handler.load(book: book, conf: regl ) ;
		//print("using kpl ${book.kpl}");
		//List<Konto>
		list = book.kpl.getRange({"min":"400", "max": "499"} );
		//print("list got back \n$list");
		expect(list.length, equals(27));
		expect(list[2].desc, equals("Contribution of Lasade"));
	});

      });



}
