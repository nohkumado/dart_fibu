// to run this :!dart test test/operation.dart --chain-stack-traces
import 'package:test/test.dart';
import 'package:nohfibu/settings.dart';
import 'package:nohfibu/nohfibu.dart';
import 'package:nohfibu/ops_handler.dart';

void main() {
  Settings regl = Settings();
  setUp(()
      {
	var incoming = ["-b", "assets/wbsamples/me2000.csv", "-s", "-l" , "de", "-o","test.csv"];
	regl.init(incoming);
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
	  var book = Book();
	  test('instantiating and toString', () {
	    List<String> actLine = defs[0];
	    DateTime point = (actLine[1]!= null && actLine[1].isNotEmpty)?DateTime.parse(actLine[1]):DateTime.parse("2021-09-21");
	    Operation anOp = Operation(name: actLine[0], date: point,cplus: actLine[2],cminus: actLine[3],desc: actLine[4],cur: actLine[5], valuta:  actLine[6], mod:actLine[7]);
	    expect(anOp.toString(), equals("AUCHAN,21-09-2021,1000-1003,1999,Courses Auchan,,#payement, \n"));
	  });
	  test('batch load', () {
	    for(List<String> actLine  in defs)
	    {
	      DateTime point = (actLine[1]!= null && actLine[1].isNotEmpty)?DateTime.parse(actLine[1]):DateTime.parse("2021-09-21");
	      if(ops[actLine[0]] == null) ops[actLine[0]] = Operation(name: actLine[0]);
	      Operation anOp = ops[actLine[0]]!;
	      anOp.add(date: point,cplus: actLine[2],cminus: actLine[3],desc: actLine[4],cur: actLine[5], valuta:  actLine[6], mod:actLine[7]);
	    } 

	    String should = 'MERCH,21-09-2021,400-499,100-104,Contribution #merchant,,#payement, \n'+
		              'MERCH,21-09-2021,100-103,400-499,Contribution #merchant,,, multi\n';

	    expect("${ops['MERCH']}", equals(should));
	  });

      });



}
