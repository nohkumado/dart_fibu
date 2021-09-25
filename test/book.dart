// to run this :!dart test test/kpl_test.dart --chain-stack-traces
import 'package:test/test.dart';
import 'package:nohfibu/settings.dart';
import 'package:nohfibu/book.dart';
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
	  regl["base"] = "assets/wbsamples/sample";
	  handler.load(book: book, conf: regl ) ;
	  expect(book.jrl.count(), equals(999));
	});

      });



}
