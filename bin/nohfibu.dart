import 'dart:io';

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
   else if (settings["fastop"]) {
      print("we need to call on fast op ${settings['run']}");
    Operation? actOp = fibu.book.ops[settings['run']];
    if(actOp == null)
    {
      print("Fast op '${settings['run']}' unknown, plese check the name");
    }
    else
    {
      print("Found fast op '${actOp}' ");
      actOp.prepare();
      actOp.preparedLines.forEach((line) => print("to fill $line"));
    }
    } else
      print("book so far: ${fibu.book}");
  } else
    print("no file to load");
  print("end of processing");
}
