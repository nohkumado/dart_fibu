import 'dart:io' show Platform;

import 'package:posix/posix.dart';
import 'package:args/args.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';

/// Settings adapter reads in the arguments and allows for a central repository where to fetch data from
class FibuSettings {
  Map<String, dynamic> data = {};
  List<String> rest = [];
  String usage = "";
  final parser = ArgParser();



  FibuSettings() {
    parser
      ..addOption('lang', abbr: 'l', defaultsTo: 'de', help: "Language setting")
      ..addOption('base',
          abbr: 'b',
          help:
              "Basename of the dataset, to set the type add the suffix, eg acc.kpl")
      ..addOption('output', abbr: 'o', help: "output name")
      ..addFlag('help',
          abbr: 'h', defaultsTo: false, help: "Help about the options")
      ..addFlag('strict',
          abbr: 's', defaultsTo: false, help: "enforce old WB-Style parsing")
    ..addFlag('version',
    abbr: 'v', defaultsTo: false, help: "Version info");
  }

  /// launch the process here feeding typically the command line arguments
  FibuSettings init(List<String> arguments) {
    data = {};
    usage = parser.usage;
    data["error"] = false;

    try {
      var argResults = parser.parse(arguments);
      //print("applying args: lang:${argResults["lang"]} base:${argResults["base"]} out:${argResults["output"]} help:${argResults["help"]} strict:${argResults["strict"]}  rest: ${argResults.rest}");
      argResults.options.forEach((key) {
        var val = argResults[key];
        data["$key"] = (val == null) ? "null" : val;
      });
      rest = argResults.rest;
      //postprocessing
      data["type"] = "csv"; //csv is default
      if (data.containsKey("base") && data["base"].isNotEmpty) {
        //ok... we have a filled in base....
        var splitted = data["base"].split(".");
        if (splitted.length >= 2) {
          data["type"] = splitted.removeLast();
          data["base"] = splitted.join(".");
        }
        if (data["type"] == "kpl" || data["type"] == "jrl")
          data["type"] = "wbstyle";
        //print("match! splitted ${data["base"]} from ${data["type"]}");
        if (data["output"] == null) data["output"] = data["base"] + ".lst";
      }
    } catch (e) {
      //print("unknown arguments, please stick to:\n"+parser.usage);
      data["error"] = true;
    }
    if (data.containsKey("lang")) {
      if (["lang"].length == 2)
        data["lang"] =
            data["lang"].toLowerCase() + "_" + data["lang"].toUpperCase();
      if (data["lang"].length == 2)
        data["lang"] =
            data["lang"].toLowerCase() + "_" + data["lang"].toUpperCase();
      //print("default locale: ${data["lang"]}");
      Intl.defaultLocale = data["lang"];
    }
    initializeDateFormatting(Intl.defaultLocale);
    return this;
  }

  /// to be able to get the data like from a map
  dynamic operator [](String key) {
    String result = "";
    try {
      return data[key];
    } catch (e) {}
    return result;
  }

  /// the setter to set the data if needed
  void operator []=(String key, dynamic val) {
    data[key] = val;
     }
  String tildeExpansion(String path){
    if(path.startsWith('~'))
    {
      String separator = Platform.pathSeparator;
      List<String> parts = path.split(separator);
      if(parts[0] == '~') parts[0] = ((Platform.environment.containsKey('HOME'))?Platform.environment['HOME']:"")!;
      else {
        String user = parts[0].replaceAll('~', '');
        try {
          parts[0] = getpwnam(user).homePathTo;
        }
        catch(e){
          //print("failed to find user $user");
        }
      }
      path = parts.join(separator);
    }
    return path;
  }

  @override
  String toString() {
    return 'FibuSettings{data: $data}';
  }
  bool empty() => data.isEmpty;
}
