import 'package:args/args.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';

class Settings
{
  Map<String,dynamic> data = {};
  List<String> rest = [];
  String usage = "";
  Settings init(List<String> arguments)
  {
    data = {};
    final parser = ArgParser()
	..addOption('lang', abbr: 'l', defaultsTo: 'de', help: "Language setting")
	..addOption('base', abbr: 'b', help: "Basename of the dataset, to set the type add the suffix, eg acc.kpl")
	..addOption('output', abbr: 'o', help: "output name")
	..addFlag('help', abbr: '\?', defaultsTo: false, help: "Help about the options")
	..addFlag('strict', abbr: 's', defaultsTo: false, help: "enforce old WB-Style parsing");
    usage = parser.usage;
    data["error"]  = false;

    try
    {
      var argResults = parser.parse(arguments);
      //print("applying args: lang:${argResults["lang"]} base:${argResults["base"]} out:${argResults["output"]} help:${argResults["help"]} strict:${argResults["strict"]}  rest: ${argResults.rest}");
      argResults.options.forEach((key) {
	var val = argResults[key];
	data["$key"] = (val == null)? "null":val;
      });
      rest = argResults.rest;
      //postprocessing
      if(data.containsKey("base") && data["base"].isNotEmpty) 
      {
	//ok... we have a filled in base....
	var splitted = data["base"].split(".");
	if(splitted.length >= 2)
	{
	  data["type"]  = splitted.removeLast();
	  data["base"]  = splitted.join(".");
	}
	if(data["type"] == "kpl" || data["type"]== "jrl") data["type"] = "wbstyle";
	//print("match! splitted ${data["base"]} from ${data["type"]}");

      }
    }
    catch(e)
    {
      //print("unknown arguments, please stick to:\n"+parser.usage);
      data["error"]  = true;
    }
    if(data.containsKey("lang"))
    {
      if(["lang"].length == 2) data["lang"] = data["lang"].toLowerCase()+"_"+data["lang"].toUpperCase();
      if(data["lang"].length == 2) data["lang"] = data["lang"].toLowerCase()+"_"+data["lang"].toUpperCase();
      //print("default locale: ${data["lang"]}");
      Intl.defaultLocale = data["lang"];
    }
    initializeDateFormatting(Intl.defaultLocale);
    return this;
  }
  dynamic operator [](String key)
  {
    if(data == null) return "";
    String result = "";
    try
    {
      return data[key];
    }
    catch(e) {}
    return result;
  }
  void operator []=(String key, dynamic val)
  {
    if(data == null) data = {};
      data[key] = val;
  }
}
