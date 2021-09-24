import 'dart:io';
import 'package:csv/csv.dart';
import 'package:nohfibu/journal.dart';
import 'package:nohfibu/kto_plan.dart';
import 'package:nohfibu/book.dart';
import 'package:nohfibu/settings.dart';


class CsvHandler
{

  Settings settings = Settings();
  bool loading = false;

  void save({Book? book, KontoPlan? kpl, Journal? jrl, Settings? conf})
  {
    if(book == null) book = Book();
    if(kpl != null) book.kpl = kpl;
    if(jrl != null) book.jrl = jrl;
    if(conf != null) settings= conf;

    List<List<dynamic>> fibuAsList = book.kpl.asList();
    fibuAsList = book.jrl.asList(fibuAsList);

    final res = const ListToCsvConverter().convert(fibuAsList);

    //print("retrieved list\n$fibuAsList\n");
    //print("retrieved csv\n$res\n");

    String fname = (settings["output"] != null && settings["output"].isNotEmpty())?settings["output"]:settings["base"]+".csv";
    File(fname).writeAsString(res).then((file)
	{
	  print("write seems successful, please check $fname");
	});
  }
  void load({Book? book, Settings? conf})
  {
    if(book == null) book = Book();
    if(conf != null) settings= conf;
    if(conf != null) settings= conf;
    if(settings["type"] != "csv")
    {
      print("Error: csv handler can't write something aelse as csv");
      return;
    }
    print("load Book: ${settings["base"]} ${settings["type"]}  ");
   var  srcFile = new File(settings["base"]+"."+settings["type"]);
    if(srcFile.existsSync())
    {
      //print("file exists\n");
      String rawTxt = srcFile.readAsStringSync();
      //print("got file $rawTxt");
      List<List<dynamic>> rowsAsListOfValues = const CsvToListConverter().convert(rawTxt);
      //print("extracted  $rowsAsListOfValues");
      String mode = "none";
      List header = [];
      int name = 0, desc = 0,  valuta = 0, cur = 0, budget = 0, datum = 0, kmin = 0, kplu = 0 ;
      for(int i = 0; i < rowsAsListOfValues.length; i++)
      {
	var actLine = rowsAsListOfValues[i];
	if(actLine.length == 1)
	{
	  if(actLine[0] == "KPL") mode = "kpl";
	  else if(actLine[0] == "JRL") mode = "jrl";
	  else { print("Error , unknown type: ${actLine[0]}"); mode = "none";}
	  i++;
	  header = rowsAsListOfValues[i];
	  desc = (header.indexOf("desc") >=0)?header.indexOf("desc"):header.indexOf("dsc");
	  valuta = header.indexOf("valuta");
	  cur = header.indexOf("cur");
	  if(mode == "kpl") 
	  {
	    name = header.indexOf("kto");
	    budget = header.indexOf("budget");
	  }
	  else if(mode == "jrl");
	  {
	    datum = header.indexOf("date");
	    kplu = header.indexOf("ktoplus");
	    kmin = header.indexOf("ktominus");
	  }
	}
	else
	{
	  //print("treating[$mode] ${actLine}");
	  if(mode == "kpl") 
	  {
	  //print("treating[$mode] ${actLine}");
	    Konto res = book.kpl.put("${actLine[name]}", Konto(name: "${actLine[name]}", desc:actLine[desc], plan: book.kpl, valuta:actLine[valuta], cur:actLine[cur], budget:actLine[budget]));
	  //print("added [$res]");
	  }
	  else if(mode == "jrl") 
	  {
	   //print("treating[$mode] ${actLine}");
	    DateTime point = DateTime.parse(actLine[datum]);
	    Konto? minus = book.kpl.get("${actLine[kmin]}");
	    Konto? plus = book.kpl.get("${actLine[kplu]}");
	    //num vval = num.parse(actLine[valuta]);
	    num vval = actLine[valuta];
	    JrlLine res = book.jrl.add(new JrlLine(datum: point, kmin: minus, kplu: plus, desc: actLine[desc], cur: actLine[cur], valuta: vval));
	   //print("added [$res]");
	  }
	}

      }
      print("book so far: $book");
    }
    else
    {
      print("book file doesn't exist");
    }

   
  }
}
