import 'dart:io';

import 'package:nohfibu/fibusettings.dart';
import 'package:nohfibu/csv_handler.dart';
import 'package:nohfibu/nohfibu.dart';

/// Launcher for the accounting analysis
///
/// -r launches the analysis
/// -b <name> set the base name to work on
///
/// Issues a result file with the accounting analysis
class Fibu {
  bool strict = false;

  ///book holds the accounting plan and the journal
  Book book = Book();

  ///CTOR
  Fibu({strict = false}) {
    if (strict) this.strict = true;
  }

  /// launch the financial analysis, meaning, making the account extracts, fill in the final state
  /// of the accounts, and compare the 4 blocks of account (aktiva/passiva, expenses/income)
  /// to validate the accounting period
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

///to have a command line version of this program
main(List<String> arguments) //async
{
  //print("incoming : $arguments");
  ///add command line argument parsing
  FibuSettings settings = FibuSettings();
  settings.parser.addFlag('run',
      abbr: 'r', defaultsTo: false, help: "run the accounting process");
  settings.init(arguments);
  Fibu fibu = Fibu();

  //print("result of arg run... : ${argResults["help"]}\n");
  //print("result of arg run... : ${argResults["help"]} sh: ${argResults["\?"]}\n");

  if (settings["help"] || settings["error"]) {
    print(settings.usage);
    exit(0);
  }

  ///provided a basename was given, a file with the data can be loaded , the CsvHandler class, reads in the csv
  /// and fills the book
  if (settings["base"] != null && settings["base"].isNotEmpty) {
    //print("opening file ${settings["base"]}");
    String basename = settings["base"];
    String fname = basename + ".csv";
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
    } else
      print("book so far: ${fibu.book} you need to set run if you want a compilation");
  } else
    print("no file to load");
  print("end of processing");
}
