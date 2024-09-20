import 'dart:io';
import 'package:git/git.dart';
import 'package:path/path.dart' as gitweg;
import 'package:intl/intl.dart';

import 'package:nohfibu/fibusettings.dart';
import 'package:nohfibu/csv_handler.dart';
import 'package:nohfibu/nohfibu.dart';
import 'package:nohfibu/ops_handler.dart';

/// Launcher for the accounting analysis
///
/// -r launches the analysis
/// -b <name> set the base name to work on
///
/// Issues a result file with the accounting analysis
class Fibu {
  bool strict = false;
  Book book = Book();
  late FibuSettings settings;

  Fibu({strict = false, FibuSettings? settings}) {
    if (strict) this.strict = true;
		if (settings != null) this.settings = settings;
		else this.settings = FibuSettings();
	}

	///run the ledgers and fillem up from the book
  String execute() {
    print("asked to run!"+book.toString());
    book.execute(); //TODO we should report if there were errors....

    String result = book.toString() + "\n";
    result += book.kpl.toString(extracts: true);
    result += "=" * 20 + "    Analysis    " + "=" * 20 + "\n";
    //result += "Aktiva    \n"+ (book.kpl.get("1")).toString(recursive: true)+"\n";
    result += book.kpl.analysis();
    return result;
  }
	///run the ledgers and create the new period
	Book nextPeriod() {
		book.execute(); //TODO we should report if there were errors....
		Book nextExercise = Book();
		nextExercise.kpl = book.kpl.clone(resetValuta:true);// Clone the KPL with resetValuta
		Konto patrimonio = nextExercise.kpl.get("2")?.getSmallest()??Konto();// Find the "patrimonio" account, validate it
		if(patrimonio.isNotValid()) {
			print("Error!! no patrimonio found???");
			return nextExercise;  // Exit early if patrimonio is invalid
		}
		// Helper function to add journal entries
		void addJournalEntries(List<List> accounts, String reportDesc) {
			for (List actAcc in accounts) {
				nextExercise.jrl.add(
					JrlLine(
							kplu: nextExercise.kpl.get("${actAcc[0]}"),  // Get the corresponding account
							kmin: patrimonio,
							desc: "$reportDesc ${actAcc[1]}",  // Dynamic description
							cur: actAcc[2],                // Currency
							valuta: actAcc[4]              // Valuta (balance/amount)
					),
				);
			}
		}
		// Get usable aktiva accounts and add them to journal
		List<List> aktivaAccounts = book.kpl.get("1")?.asList() .where((line) => line[4] != 0).toList() ?? [];
		addJournalEntries(aktivaAccounts, "Report ");

    // Get usable passiva accounts excluding patrimonio, and add them to journal
		List<List> passivaAccounts = book.kpl.get("2")?.asList() .where((line) => line[4] != 0 && line[0] != patrimonio.name).toList() ?? [];
		addJournalEntries(passivaAccounts, "Report ");

		// Execute the next exercise
		nextExercise.execute(); //TODO we should report if there were errors....
		//identify patrimonium account, should be the first of the 2* accounts


		return nextExercise;//TODO error reporting as usual....
	}
  ///Execute a prepared statement
  void opExe(String key)
	{
		//print("we need to call on fast op ${key}");
		bool ok = true;
		while(ok)
		{
			Operation? actOp = book.ops[key];
			if(actOp == null) {print("Fast op '${key}' unknown, please check the name"); ok = false;}
			else
			{
				//print("Found fast op '${actOp}' ");
				actOp.prepare();
				bool firstLine = true;
				//actOp.preparedLines.forEach((line)
				for(int i = 0; i < actOp.length; i++)
				{
					JrlLine line  = actOp[i];
					print("to fill $line");
					if(firstLine){ selectDate(line); firstLine = false;}
					print("proceeding to acc -");
					selectAccount(line, minus:true);
					print("proceeding to acc +");
					selectAccount(line, minus:false);
					print("proceeding to desc");
					selectDescription(line, actOp);
					if(!settings["autocur"]) {
						print("proceeding to cur");
						selectCurrency(line);
					}
					print("proceeding to val");
					selectValuta(line,actOp);
				}
				//);
				print("please check new jrl lines:");
				actOp.result().forEach((line) { print("${line}" );});
				print("ok?");
				String? answer = stdin.readLineSync();
				answer ??= "";
				if( answer.isEmpty || answer.toLowerCase() == "y")
					{
						ok = false;
						actOp.result().forEach((line) { book.jrl.add(line);});
						print("jrl now: ${book.jrl}");
					}
			}
		}
	//handler.save(book: book, conf: settings);
	}
	///select a date, had to implement the different shortcuts that are usual
	void selectDate(JrlLine line) {
		final DateFormat formatter = DateFormat('dd-MM-yyyy');
		final String formatted = formatter.format(line.datum);
		bool invalid = true;
		while(invalid)
		{
			print("Date[$formatted]");
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
					//print("couldn't*t understand the date....");
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
			else
				{
					invalid =false;
					print("default answer....");
				}
		}
		print("set Date to [${formatter.format(line.datum)}]");
	}
	///select an account, per default the minus account with minus to false the plus account
	void selectAccount(JrlLine line, {bool minus =true})
	{
		String defaultKtoName =(minus)?line.kminus.printname().trim():line.kplus.printname().trim();
		String defaultKtoDesc =(minus)?line.kminus.desc.trim():line.kplus.desc.trim();
		//print("selecting for $defaultKtoName, $defaultKtoDesc prefilled: ${line}");
		late List<Konto> ktoList;
		String setKey = (minus)? "kmin":"kplu";
		//print("limits? ${line.limits}");
		if(line.limits != null && line.limits!.containsKey(setKey)&& line.limits![setKey]["min"] != "-1")
		{
			var limits = line.limits![setKey];
			//print("retrieved + [${limits}]");
			ktoList = book.kpl.getRange(limits);
			//defaultKtoName =limits["min"]; //lower limit? or
			defaultKtoName =ktoList.first.name;//first valid account?
			defaultKtoDesc =ktoList.first.desc.trim();
			print("selecting from :\n $ktoList");
		}

		bool invalid = true;
		while(invalid)
		{
			print("kto"+((minus)?"-":"+")+"[${defaultKtoName}, ${defaultKtoDesc} ]");
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
  void selectDescription(JrlLine line, Operation myOp)
	{
		print("desc [${line.desc}] ");
		String tmpDesc =line.desc;
		print("searching desc in local variables: ${line.vars}");
		if(line.vars.containsKey("desc"))
		{
			var locVars = line.vars["desc"]!;
			print("local variables: $locVars");
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

  void selectValuta(JrlLine line, Operation myOp)
	{
		print("valuta [${line.valuta}]");
		if(line.valname != null)
			{
				print("need to supply value for variable [${line.valname}] ");
				String? answer = stdin.readLineSync();
				answer ??= "0";
				line.setValuta(answer);
				myOp.vars[line.valname!] = line.valuta;
				print("stored for ${line.valname} ${line.valuta}");
			}
		else
		if(line.valexp != null)
		{
			print("need to fill with exp ");
			line.valuta = myOp.eval(exp:line.valexp);
			print("computed for ${line.valname} ${line.valuta}");
		}
		else
		{
			String? answer = stdin.readLineSync();
			answer ??= "";
			if(answer.isNotEmpty) line.setValuta(answer);
			print("inputted valuta ${line.valuta}");
		}

	}
}

main(List<String> arguments) //async
async {
	//print("incoming : $arguments");
  FibuSettings settings = FibuSettings();
  settings..parser.addFlag('run', abbr: 'r', defaultsTo: false, help: "run the accounting process")
      ..parser.addFlag('list', defaultsTo: false, help: "list the available fast ops")
		..parser.addFlag('close', abbr: 'c',defaultsTo: false, help: "closes the actual book and creates the next period")
		..parser.addFlag('autocur', defaultsTo: true, help: "leaves currency at default without asking")
		..parser.addOption('fastop', abbr: 'f',  help: "call fast operation <name>");
  settings.init(arguments);
  Fibu fibu = Fibu(settings: settings);

  //print("result of arg run... : ${argResults["help"]}\n");
  //print("result of arg run... : ${argResults["help"]} sh: ${argResults["\?"]}\n");

  if (settings["help"] || settings["error"]) {
    print(settings.usage);
    exit(0);
  }
	if (settings["version"]) {
		// Versionsnummer abrufen

		String version = "Version 0.";

		if (await GitDir.isGitDir(gitweg.current)) {
			final gitDir = await GitDir.fromExisting(gitweg.current);
			final commitCount = await gitDir.commitCount();
			version += "$commitCount";
		} else {
			print('Not a Git directory');
		}




		/*final gitDir = await GitDir.fromExisting('.git');
		final head = await gitDir.getHead();
		final revision = await head.getSha();
		*/
		print(version);

		exit(0);
	}

  if (settings["base"] != null && settings["base"].isNotEmpty) {
    //print("opening file ${settings["base"]}");
    String basename = settings["base"];
    String fname = basename + ".csv";
    print("trying to fetch book from file $fname");
var handler = CsvHandler();
    handler.load(book: fibu.book, conf: settings);
		//print("retrieved book "+fibu.book.toString());

    if (settings["run"]) {
      String result = fibu.execute();
      fname = (settings["output"].isNotEmpty)
	  ? settings["output"]
	  : basename + ".lst";
      print ("retrieved\n$result");
      File(fname).writeAsString(result).then((file) {
	print("write seems successful, please check $fname");
      });
    } else if (settings["list"]) {
      print("Available fast operations:");
      fibu.book.ops.forEach((key, val)=>print("$key"));
      print("End of List");
    }
    else if (settings["fastop"] != null && settings["fastop"].isNotEmpty) {
      fibu.opExe(settings["fastop"]);
      //settings["output"] = "assets/wbsamples/testres.csv";
			print("saving ${settings["output"]}");
			print("save (y/n)?");
			String? answer = stdin.readLineSync();
			answer ??= "";
			if(answer.toLowerCase() == "y")
			{
			  handler.save(book: fibu.book, conf: settings);
			}

			//var handler = CsvHandler();
    }
		else if (settings["close"]) {
			Book result = fibu.nextPeriod();
			/*
			fname = (settings["output"].isNotEmpty)
					? settings["output"]
					: basename;
			fname = fname.replaceAll(" ","");
			fname = incrementYearsInFileName(fname);
			String dname = gitweg.dirname(fname);
			fname = dname+"/"+gitweg.basenameWithoutExtension(fname)+".csv";
			 */
			fname =  settings["output"] ?? basename;
			fname = fname.replaceAll(RegExp(r"\s+"),"").trim();
			fname = incrementYearsInFileName(fname);
			String dname = gitweg.dirname(fname);
			fname = gitweg.join(dname,gitweg.basenameWithoutExtension(fname)+".csv");
			print("saving new exercicse to ${fname}");
			if(!File(fname).existsSync())
			File(fname).writeAsString(result.toString()).then((file) { print("write seems successful, please check $fname"); });
			else { print("file $fname already exists"); }
		}	else
      print("empty run (-h for other options) book so far: \n${fibu.book}");
  }
	else
    print("no file to load");
  print("end of processing");
}
// Function to increment years in a string
String incrementYearsInFileName(String fileName) {
	 // Use regular expressions to match 2-digit or 4-digit years
  RegExp yearPattern = RegExp(r'(\d{2,4})');
  return fileName.replaceAllMapped(yearPattern, (Match match) {
    int year = int.parse(match.group(0)!);  // Extract the year
    return (year + 1).toString();           // Increment it by 1
  });
}
