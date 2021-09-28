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
	  expect(book.jrl.count(), equals(999));
	  book.clear();
	  regl["base"] = "assets/wbsamples/sample";
	  handler.load(book: book, conf: regl ) ;
	  expect(book.jrl.count(), equals(16));
	  book.execute();
	  print("after  execute : \n${book.kpl.get("3300")!.extract.toString()}");
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
	});

      });



}
