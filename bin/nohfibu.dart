import 'dart:io';
import 'package:git/git.dart';
import 'package:path/path.dart' as gitweg;

import 'package:nohfibu/fibusettings.dart';
import 'package:nohfibu/csv_handler.dart';
import 'package:nohfibu/nohfibu.dart';


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
