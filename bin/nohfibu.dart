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


				//fill in kto -
				//print("constraints -[${line.limits}]");

				String defaultKtoName =line.kminus.printname().trim();
				late List<Konto> ktoList;
				if(line.limits != null && line.limits!.containsKey("kmin"))
				{
					var limits = line.limits!["kmin"];
					ktoList = book.kpl.getRange(limits);
					defaultKtoName =limits["min"];
					print("selecting from :\n $ktoList");
				}
				print("kto-[${defaultKtoName}]");

				invalid = true;
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
						line.kminus = selected;
						if(line.kminus.name ==selected.name) invalid =false;
						else print("Account not existent,try again");
					}
					else print("please select from : \n$ktoList\nkto-[${defaultKtoName}]");
				}


				//fill in kto +
				//print("constraints -[${line.limits}]");

				print("constraints -[${line.limits}]");
				defaultKtoName =line.kplus.printname().trim();
				if(line.limits != null && line.limits!.containsKey("kplu"))
				{
					var limits = line.limits!["kplu"];
					print("retrieved + [${limits}]");
					ktoList = book.kpl.getRange(limits);
					defaultKtoName =limits["min"];
					print("selecting [$defaultKtoName]from : '$ktoList'");
				}
				print("kto+[${defaultKtoName}]");

				invalid = true;
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
						line.kplus = selected;
						if(line.kplus.name ==selected.name) invalid =false;
						else print("Account not existent,try again");
					}
					else print("please select from : \n$ktoList\nkto-[${defaultKtoName}]");
				}


				print("desc [${line.desc}]");
				print("cur [${line.cur}]");
				print("valuta [${line.valuta}]");
			}
			);
		}
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
