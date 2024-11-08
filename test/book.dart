// to run this :!dart test test/kpl_test.dart --chain-stack-traces
import 'package:test/test.dart';
import 'package:nohfibu/fibusettings.dart';
import 'package:nohfibu/nohfibu.dart';
import 'package:nohfibu/csv_handler.dart';

void main() {
	FibuSettings regl = FibuSettings();
	setUp(()
	{
		var incoming = ["-b", "assets/wbsamples/me2000.csv", "-s", "-l" , "de", "-o","test.csv"];
		regl.init(incoming);
	});
	group('Book', ()
	{
		var book = Book();
		test('Book initialization without parameters', () {
			var book = Book();
			expect(book.kpl.konten.isEmpty, isTrue);
			expect(book.jrl.journal.isEmpty, isTrue);
		});

		test('loading', () {
			var handler = CsvHandler();
			book.kpl.put("0",Konto(name: '0', desc: 'buggy', valuta: 0));
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
	test('Adding and retrieving accounts from KontoPlan', () {
		var book = Book();
		book.kpl.put('1000', Konto(name: 'Cash', valuta: 10000));

		Konto? retrieved = book.kpl.get('1000');
		expect(retrieved, isNotNull);
		expect(retrieved!.name, equals('Cash'));
		expect(retrieved.valuta, equals(10000));
	});
	test('Book toString with extracts', () {
		var book = Book();
		Konto ret = book.kpl.put('1000', Konto(name : '1000',desc: 'Cash', valuta: 10000));
		book.kpl.put('2000', Konto(name : '2000',desc: 'Expenses', valuta: -5000));
		book.jrl.add(JrlLine(kmin: book.kpl.get('2000'), kplu: book.kpl.get('1000'), valuta: 5000));

		String output = book.toString(extracts: true);
		expect(output.contains('Cash'), isTrue);
		expect(output.contains('Expenses'), isTrue);
	});

	test('Executing an empty Journal', () {
		var book = Book();
		book.execute();
		expect(book.jrl.journal.isEmpty, isTrue); // No changes should have occurred
	});

	test('Handling non-existent account retrieval', () {
		var book = Book();
		Konto? retrieved = book.kpl.get('9999');
		expect(retrieved, isNull); // Should return null
	});

	test('Adding a JrlLine with invalid data', () {
		var book = Book();
		var invalidLine = JrlLine(kmin: null, kplu: null, valuta: 5000);
		expect(() => book.jrl.add(invalidLine), returnsNormally);
	});

	test('KontoPlan with nested accounts', () {
		var book = Book();
		var parent = Konto(desc: 'Parent', name: '1000');
		var child = Konto(desc: 'Child', name: '1001');

		book.kpl.put('1000', parent);
		book.kpl.put('1001', child);

		expect(book.kpl.get('1000'), equals(parent));
		expect(book.kpl.get('1001'), equals(child));
		parent =book.kpl.get('100')??parent;
		expect(parent.children['1'], equals(child));
	});

	test('Handling edge cases in Konto and JrlLine', () {
		var book = Book();

		// Test empty account name
		var emptyNameAccount = Konto(name: '', valuta: 1000);
		book.kpl.put('2000', emptyNameAccount);
		expect(book.kpl.get('2000')!.name, equals(''));

		// Test zero valuta
		var zeroValutaLine = JrlLine(kmin: book.kpl.get('1000'), kplu: book.kpl.get('2000'), valuta: 0);
		book.jrl.add(zeroValutaLine);
		expect(zeroValutaLine.valuta, equals(0));

		// Test overlapping ranges
		List<Konto> rangeList = book.kpl.getRange({'min': '1000', 'max': '2000'});
		expect(rangeList.isNotEmpty, isTrue);
	});

	test('Book clear method', () {
		var book = Book();
		// Populate the book
		book.kpl.put('1000', Konto(name: 'Cash'));
		book.jrl.add(JrlLine(desc: 'Initial Entry'));

		// Clear the book
		book.clear();

		expect(book.kpl.konten.isEmpty, isTrue);
		expect(book.jrl.journal.isEmpty, isTrue);
	});




}
