// to run this :!dart test test/operation.dart --chain-stack-traces
import 'package:nohfibu/csv_handler.dart';
import 'package:test/test.dart';
import 'package:nohfibu/settings.dart';
import 'package:nohfibu/nohfibu.dart';
import 'package:nohfibu/ops_handler.dart';
import 'package:expressions/expressions.dart';

void main() {
	Settings regl = Settings();
	Book book = Book();
	setUp(()
	{
		var incoming = ["-b", "assets/wbsamples/me2000.csv", "-s", "-l" , "de", "-o","test.csv"];
		regl.init(incoming);
		var handler = CsvHandler();
		handler.load(book: book, conf: regl);
		//print("kpl so far: ${book.kpl}");
	});
	group('Operations', ()
	{
		Map<String,Operation> ops = {};
		List<List<String>> defs = [
			["AUCHAN","","1000-1003", "1999",  "Courses Auchan", "","#payement", ""],
			["AUCHAN","","1999",      "2011",  "Vêtements achetés chez Auchan", "", "", ""],
			["AUCHAN","","1999",      "3080",  "Couches bébé ", "", "#couches",""],
			["AUCHAN","","1999",      "3080",  "Divers bébé (#objet)", "", "#divers",""],
			["AUCHAN","","1999",      "3011",  "Bouffe achetée chez Auchan EUR (#payement - #montant - #couches - #divers)", "", "(#payement - #montant - #couches - #divers)",""],
			["MERCH","", "400-499","100-104",  "Contribution #merchant", "", "#payement",""],
			["MERCH","", "100-103","400-499",  "#construction for #planet", "", "","multi",""]
		];
		test('instantiating and toString', () {
			List<String> actLine = defs[0];
			DateTime point = (actLine[1]!= null && actLine[1].isNotEmpty)?DateTime.parse(actLine[1]):DateTime.parse("2021-09-21");
			Operation anOp = Operation(book,name: actLine[0], date: point,cplus: actLine[2],cminus: actLine[3],desc: actLine[4],cur: actLine[5], valuta:  actLine[6], mod:actLine[7]);
			expect(anOp.toString(), equals("AUCHAN,21-09-2021,1000-1003,1999,Courses Auchan,,#payement, \n"));
		});
		test('batch load', () {
			//print("kpl so far: ${book.kpl}");
			for(List<String> actLine  in defs)
			{
				DateTime point = (actLine[1]!= null && actLine[1].isNotEmpty)?DateTime.parse(actLine[1]):DateTime.parse("2021-09-21");
				if(ops[actLine[0]] == null) ops[actLine[0]] = Operation(book,name: actLine[0]);
				Operation anOp = ops[actLine[0]]!;
				anOp.add(date: point,cplus: actLine[2],cminus: actLine[3],desc: actLine[4],cur: actLine[5], valuta:  actLine[6], mod:actLine[7]);
			}

			String should = 'MERCH,21-09-2021,400-499,100-104,Contribution #merchant,,#payement, \n'+
					'MERCH,21-09-2021,100-103,400-499,#construction for #planet,,, multi\n';

			expect("${ops['MERCH']}", equals(should));
			Operation anOp = ops['MERCH']!;
			anOp.book = book; //somehow....
			//print("anOp no book no kpl : ${anOp.book.kpl}");
			anOp.prepare();
			expect(anOp.preparedLines.length, equals(2));
			expect(anOp.vars.keys.toList(), equals(['merchant','payement','construction', 'planet']));

			//TODO need to check complex case Bouffe achetée chez Auchan EUR (#payement - #montant - #couches - #divers)", "", "(#payement - #montant - #couches - #divers)",""
			anOp = ops['AUCHAN']!;
			anOp.expressions["test"] ="(toto - titi -argh";
			anOp.book = book; //somehow....
			anOp.prepare();
			expect(anOp.vars.length, equals(5));
			List<JrlLine> preJrl = anOp.preparedLines;
			print("vars ${anOp.vars}");
			print("expressions ${anOp.expressions}");
			Expression expression = anOp.expressions[anOp.expressions.keys.last];
			var context = {'payement': 100, 'montant': 10, 'couches': 5, 'divers': 9};

			final evaluator = const ExpressionEvaluator();
			var r = evaluator.eval(expression, context);
			print("result = $r");
			expect(r, equals(76));

		  //	print("jrl Lines");
		  //	for (var line in preJrl) {
		  //		print("${line.desc} ");
		  //	}


		});

	});
}
