import 'dart:io';
import 'package:intl/intl.dart';

import 'package:nohfibu/settings.dart';
import 'package:nohfibu/csv_handler.dart';
import 'package:nohfibu/nohfibu.dart';
import 'package:nohfibu/ops_handler.dart';

/// Launcher for the accounting analysis
///
/// -r launches the analysys
/// -b <name> set the base name to work on
///
/// Issues a result file with the accounting analysis
class Fibu {
  bool strict = false;
  Book book = Book();

  Fibu({strict = false}) {
    if (strict) this.strict = true;
  }

  String execute() {
    print("asked to run!");
    book.execute(); //TODO we should report if there were errors....

    String result = book.toString() + "\n";
    result += book.kpl.toString(extracts: true);
    result += "=" * 20 + "    Analysis    " + "=" * 20 + "\n";
    //result += "Aktiva    \n"+ (book.kpl.get("1")).toString(recursive: true)+"\n";
    result += book.kpl.analysis();
    return result;
  }
  ///Execute a preprared statement
  void opExe(String key)
	{
	  Map<String,dynamic> storedVars = {};
		print("we need to call on fast op ${key}");
		Operation? actOp = book.ops[key];
		if(actOp == null) print("Fast op '${key}' unknown, plese check the name");
		else
		{
			print("Found fast op '${actOp}' ");
			actOp.prepare();
			actOp.preparedLines.forEach((line)
			{
				print("to fill $line");
				selectDate(line);
				selectAccount(line, minus:true);
				selectAccount(line, minus:false);
				selectDescription(line, storedVars);
				selectCurrency(line);
				selectValuta(line,storedVars);
			}
			);
		}
	}
	///select a date, had to implement the different shortcuts that are usual
	void selectDate(JrlLine line) {
		final DateFormat formatter = DateFormat('dd-MM-yyyy');
		final String formatted = formatter.format(line.datum);
		print("Date[$formatted]");
		bool invalid = true;
		while(invalid)
		{
			String? answer = stdin.readLineSync();
			answer ??= "";
			if( answer.isNotEmpty)
			{
				print("answered: '$answer'");
				try
				{
					//DateTime point = DateTime.parse(answer);
					DateFormat format = DateFormat("dd-MM-yyyy");
					//print("extracted so far +$datum+ -$kminus- -$kplus- -$desc- ,=$w=, #$valuta#");
					var point = format.parse(answer);
					line.datum = point;
					invalid =false;
				}
				catch(e)
				{
					//print("couldn*t undestand the date....");
					try
					{
						//DateTime point = DateTime.parse(answer);
						DateFormat format = DateFormat("dd-MM-yy");
						//print("extracted so far +$datum+ -$kminus- -$kplus- -$desc- ,=$w=, #$valuta#");
						var point = format.parse(answer);
						line.datum = point;
						invalid =false;
					}
					catch(e) {
						try
						{
							//DateTime point = DateTime.parse(answer);
							DateFormat format = DateFormat("dd.MM.yyyy");
							//print("extracted so far +$datum+ -$kminus- -$kplus- -$desc- ,=$w=, #$valuta#");
							var point = format.parse(answer);
							line.datum = point;
							invalid =false;
						}
						catch(e) {
							try
							{
								//DateTime point = DateTime.parse(answer);
								DateFormat format = DateFormat("dd.MM.yy");
								//print("extracted so far +$datum+ -$kminus- -$kplus- -$desc- ,=$w=, #$valuta#");
								var point = format.parse(answer);
								line.datum = point;
								invalid =false;
							}
							catch(e) {print("couldn't understand the date....");}
						}
					}
				}
			}
			else invalid =false;
		}
	}
	///select an account, per default the minus account with minus to false the plus account
	void selectAccount(JrlLine line, {bool minus:true})
	{
		String defaultKtoName =(minus)?line.kminus.printname().trim():line.kplus.printname().trim();
		late List<Konto> ktoList;
		String setKey = (minus)? "kmin":"kplu";
		if(line.limits != null && line.limits!.containsKey(setKey))
		{
			var limits = line.limits![setKey];
			//print("retrieved + [${limits}]");
			ktoList = book.kpl.getRange(limits);
			//defaultKtoName =limits["min"]; //lower limit? or
			defaultKtoName =ktoList.first.name;//first valid account?
			print("selecting from :\n $ktoList");
		}
		print("kto"+((minus)?"-":"+")+"[${defaultKtoName}]");

		bool invalid = true;
		while(invalid)
		{
			String? answer = stdin.readLineSync();
			answer ??= defaultKtoName;
			//print("answer is '$answer'");
			if(answer.isEmpty) answer = defaultKtoName;
			Konto ? selected =book.kpl.get(answer.trim());
			//print("found Konto is '$selected");
			if(selected != null)
			{
				if(minus) {
					line.kminus = selected;
					if (line.kminus.name == selected.name)
						invalid = false;
					else
						print("Account not existent,try again");
				}
				else{
					line.kplus = selected;
					if (line.kplus.name == selected.name)
						invalid = false;
					else
						print("Account not existent,try again");
				}
			}
			else print("please select from : \n$ktoList\nkto-[${defaultKtoName}]");
		}
	}

	///input a description, if variables are in it store them and expand
  void selectDescription(JrlLine line, Map<String, dynamic> storedVars)
	{
		print("desc [${line.desc}] ");
		String tmpDesc =line.desc;
		if(line.vars != null && line.vars.containsKey("desc"))
		{
			var locVars = line.vars["desc"]!;
			//print("local variables: $locVars");
			locVars.keys.forEach((key)
			{
				print("please provide data for $key:");
				String? answer = stdin.readLineSync();
				answer ??= "";
				locVars[key] = answer;
				tmpDesc = tmpDesc.replaceAll("#$key", answer);
			});
			line.desc = tmpDesc; //ask for confirmation?
		}
	}

  void selectCurrency(JrlLine line)
	{
		print("currency [${line.cur}] ");
		String? answer = stdin.readLineSync();
		answer ??= "";
		if(answer.isNotEmpty)line.cur = answer;
	}

  void selectValuta(JrlLine line, Map<String, dynamic> storedVars)
	{
		print("valuta [${line.valuta}]");
	}
}

main(List<String> arguments) //async
{
	//print("incoming : $arguments");
  Settings settings = Settings();
  settings..parser.addFlag('run',
      abbr: 'r', defaultsTo: false, help: "run the accounting process")
      ..parser.addFlag('list',
	  defaultsTo: false, help: "list the available fast ops")

      ..parser.addOption('fastop',
	  abbr: 'f',  help: "call fast operation <name>");
  settings.init(arguments);
  Fibu fibu = Fibu();

  //print("result of arg run... : ${argResults["help"]}\n");
  //print("result of arg run... : ${argResults["help"]} sh: ${argResults["\?"]}\n");

  if (settings["help"] || settings["error"]) {
    print(settings.usage);
    exit(0);
  }

  if (settings["base"] != null && settings["base"].isNotEmpty) {
    //print("opening file ${settings["base"]}");
    String basename = settings["base"];
    String fname = basename + ".csv";
    print("trying to fetch book from file $fname");
    var handler = CsvHandler();
    handler.load(book: fibu.book, conf: settings);
    if (settings["run"]) {
      String result = fibu.execute();
      fname = (settings["output"].isNotEmpty)
	  ? settings["output"]
	  : basename + ".lst";
      //print ("retrieved\n$result");
      File(fname).writeAsString(result).then((file) {
	print("write seems successful, please check $fname");
      });
    } else if (settings["list"]) {
      print("Available fast operations:");
      fibu.book.ops.forEach((key, val)=>print("$key"));
      print("End of List");
    }
    else if (settings["fastop"].isNotEmpty) {
      fibu.opExe(settings["fastop"]);
    } else
      print("book so far: ${fibu.book}");
  } else
    print("no file to load");
  print("end of processing");
}
