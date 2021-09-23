import 'dart:io';
import 'package:csv/csv.dart';

import 'package:nohfibu/journal.dart';
import 'package:nohfibu/kto_plan.dart';
import 'package:args/args.dart';
import 'package:intl/intl.dart';

main(List<String> arguments) //async
{
  final parser = ArgParser()
    ..addOption('lang', abbr: 'l', defaultsTo: 'de', help: "Language setting")
    ..addOption('base', abbr: 'b', help: "Basename of the dataset")
    //..addOption('output', abbr: 'o', help: "output name")
    ..addFlag('help', abbr: '\?', defaultsTo: false, help: "Help about the options")
    //..addFlag('strict', abbr: 's', defaultsTo: false, help: "enforce old WB-Style parsing")
    ;

  final argResults = parser.parse(arguments);
  print("applying args: lang:${argResults["lang"]} base:${argResults["base"]} help:${argResults["help"]}  rest: ${argResults.rest}");
  //print("result of arg run... : ${argResults["help"]}\n");
  //print("result of arg run... : ${argResults["help"]} sh: ${argResults["\?"]}\n");

  if(argResults["help"])
  {
    print(parser.usage);
    exit(0);
  }
  KontoPlan? plan ;
  Journal? jrl;
  String basename = "";
  String suffix = "";
  if(argResults["base"] != null )
  {
    print("received base ${argResults["base"]}");
    //var myDir = Directory('.');
    //  await for (var entity in myDir.list(recursive: false, followLinks: false))
    //{
    //  print(entity.path);
    //}
    String basename = argResults["base"];
    String suffix = "";
    if(basename.isNotEmpty)
    {
      //if(basename.endsWith("\.kpl")) basename = basename;
      //else
      if(basename.endsWith(".???"))
      {
        suffix = basename.substring(basename.length-3);
        basename = basename.substring(0,basename.length-4);
      }
    }
    print("opening base $basename of type $suffix");
    String fname = basename +".kpl";
    print("trying to fetch kpl file $fname");
    var srcFile = File(fname);
    if(srcFile.existsSync())
    {
      //print("file exists\n");
      String rawTxt = srcFile.readAsStringSync();
      //print("got file $rawTxt");
      //plan = converter.convert(rawTxt);
      //print("retrieved kpl= \n$plan\n");
    }
    else
      {
      print("base source $basename doesn't exist\n");
    }

    //if(plan != null && jrl != null)
    //    {
    //      List<List<dynamic>> fibuAsList = plan.asList();
    //      fibuAsList = jrl.asList(fibuAsList);

    //      final res = const ListToCsvConverter().convert(fibuAsList);

    //      //print("retrieved list\n$fibuAsList\n");
    //      //print("retrieved csv\n$res\n");

    //      String fname = (argResults["output"] != null && argResults["output"].isNotEmpty())?argResults["output"]:basename+".csv";
    //      File(fname).writeAsString(res).then((file)
    //      {
    //        print("write seems successful, please check $fname\n");
    //        return null;
    //      });
    //    }
    //else
    //{
    //  print("Error: conversion failed.....\n");
    //}
  }
  else
  {
    print("You need to provide at least a base!\n"+parser.usage);
    exit(0);
  }



}
