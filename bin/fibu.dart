import 'dart:io';

import 'package:nohfibu/settings.dart';
import 'package:nohfibu/book.dart';
import 'package:nohfibu/csv_handler.dart';

class Fibu
{
  bool strict = false;
  Book book = Book();


  Fibu({strict:false})
  {
    if(strict) this.strict = true;
  }



}
main(List<String> arguments) //async
{
  //print("incoming : $arguments");
  Settings settings = Settings();
  settings.init(arguments);
  Fibu fibu = Fibu();

  //print("result of arg run... : ${argResults["help"]}\n");
  //print("result of arg run... : ${argResults["help"]} sh: ${argResults["\?"]}\n");

  if(settings["help"]||settings["error"])
  {
    print(settings.usage);
    exit(0);
  }

  if(settings["base"] != "" )
  {
    //print("opening file ${settings["base"]}");
    String basename = settings["base"];
    String fname = basename +".csv";
    print("trying to fetch book from file $fname");
    var handler = CsvHandler();
    handler.load(book: fibu.book, conf: settings );
      print("book so far: ${fibu.book}");
  }
  else print("no file to load");
  print("end of processing");
}
