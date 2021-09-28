import 'dart:io';

import 'package:nohfibu/settings.dart';
import 'package:nohfibu/nohfibu.dart';
import 'package:nohfibu/csv_handler.dart';
import 'package:intl/intl.dart';

/// The launcher for the converter.
///
/// converts following atm 3 different scemas the old datafiles to the new ones
class WbConvert {
  bool strict = false;
  KontoPlan kpl = KontoPlan();
  late Journal jrl;

  WbConvert({strict}) {
    if (strict) this.strict = true;
    jrl = Journal(kpl);
  }

  KontoPlan convert(String rawinput) {
    //print("incoming : $rawinput\n");
    kpl.clear();
    //kpl.add(Konto(number : 1,name: "", plan : kpl, title : "Aktiva" )) ;
    //kpl.add(Konto(number : 1,name: "", plan : kpl, title : "Aktiva" )) ;
    List<String> perLine = rawinput.split("\n");
    //print("splitted : $perLine\n");
    Konto? last;
    String toplvl = "";
    Map<int, List<int>> wbcols = {
      87: [2, 8, 58, 62, 75],
      71: [2, 7, 56, 60, 72],
    };
    for (String line in perLine) {
      if (line.isEmpty) continue;
      String ktoName = "";
      String budget = "";
      String valuta = "0";
      String w = "";
      String desc = "";
      try {
        if (strict) {
          if (line == "/*EOF") break;
          //sscanf(zk,"%c %4d %49c%3c%12c", &kplc->seite,&kplc->knr,kplc->titel,&kplc->wn,tmpStr);
          List<int> cols = (line.length <= 80) ? wbcols[71]! : wbcols[87]!;
          //print("used cols : $cols");
          //print("parsing $line  of ${line.length}");
          ktoName = line.substring(cols[0], cols[1]).trim();
          desc = line.substring(cols[1], cols[2]).trim();
          w = line.substring(cols[2], cols[3]).trim();
          budget = line.substring(cols[3], cols[4]).trim();
          valuta = (line.length > cols[4])
              ? line.substring(cols[4], line.length).trim()
              : "0";
          //print("extracted  '$ktoName'  '$desc' '$w' '$budget' '$valuta'");
        } else {
          //print("processing '$line'");
          final pattern = RegExp('\\s+');
          line = line.replaceAll(pattern, " ").trim();
          List<String> spcRm = line.split(" ");
          if (spcRm.length < 4) {
            print("reject line $line");
            continue;
          }
          ktoName = spcRm.removeAt(0);
          budget = spcRm.removeLast();
          w = spcRm.removeLast();
          try {
            if (double.parse(w) >= 0) {
              valuta = budget;
              budget = w;
              w = spcRm.removeLast();
            }
          } catch (e) {
            //print("$w not a double...");
          }
          desc = spcRm.join(" ");
        }
        //print("extracted +$ktoName+  -$desc- ,=$w=,  '$budget' #$valuta#");
        //print("trying kto $ktoName");
        int kto = int.parse(ktoName);
        int bval = (NumberFormat.currency().parse(budget) * 100).toInt();
        int vval = (NumberFormat.currency().parse(valuta) * 100).toInt();
        if (kto == 0) {
          //last.desc = desc;
          kpl.get(toplvl)!.desc = desc;
          //print("set caption of block $toplvl to ${kpl.get(toplvl)}");
        } else {
          toplvl = ktoName[0];
          //print("set topvö to $toplvl");
          Konto start = Konto(
              number: toplvl,
              name: ktoName,
              plan: kpl,
              desc: desc,
              cur: w,
              budget: bval,
              valuta: vval);
          kpl.put(ktoName, start);
          //print("filled kto : $start");
        }
      } catch (e) {
        print(
            "Error: wbconvert. line '$line' failed :+$ktoName+  -$desc- ,=$w=,  '$budget' #$valuta#");
        print("Error, something went wrong with  => $e");
      }
    }

    //print("kpl so far : ${kpl.asList(all:true)}");
    print("kpl so far : ${kpl}");
    return kpl;
  }

  Journal convertJrl(String rawinput) {
    //print("incoming : $rawinput\n");
    jrl.clear();
    List<String> perLine = rawinput.split("\n");
    //print("splitted : $perLine\n");
    Map<int, List<int>> wbcols = {
      80: [0, 9, 14, 19, 64, 69],
      71: [0, 9, 14, 19, 63, 68],
    };
    for (String line in perLine) {
      if (line.isEmpty) continue;
      //01.01.95 1001 0    Riporto Cassa                                ITL            0·
      //sscanf(zk,"%8c %4d %4d %44c%3c%12c",

      //print("parsing $line  of ${line.length}");

      String datum = "";
      String kplus, kminus;
      String valuta = "0";
      String w = "";
      String desc = "";
      try {
        if (strict) {
          if (line == "/*EOF") break; //end parsing
          //sscanf(zk,"%c %4d %49c%3c%12c", &kplc->seite,&kplc->knr,kplc->titel,&kplc->wn,tmpStr);
          //print("line $line length = ${line.length}");
          List<int> cols = (line.length >= 80) ? wbcols[80]! : wbcols[71]!;

          datum = line.substring(cols[0], cols[1]).trim();
          kplus = line.substring(cols[1], cols[2]).trim();
          kminus = line.substring(cols[2], cols[3]).trim();
          desc = line.substring(cols[3], cols[4]).trim();
          w = line.substring(cols[4], cols[5]).trim();
          valuta = line.substring(cols[5], line.length).trim();
          //print("= '$datum' '$kminus' '$kplus' '$desc' '$w' '$valuta'");
        } else {
          if (line == "/*EOF") continue; //ignore this one
          final pattern = RegExp('\\s+');
          line = line.replaceAll(pattern, " ").trim();
          List<String> spcRm = line.split(" ");
          if (spcRm.length < 6) {
            print("reject line $line");
            continue;
          }
          datum = spcRm.removeAt(0);
          kminus = spcRm.removeAt(0);
          kplus = spcRm.removeAt(0);
          valuta = spcRm.removeLast();
          w = spcRm.removeLast();
          desc = spcRm.join(" ");
        }
        DateFormat format = DateFormat("dd.MM.yy");
        //print("extracted so far +$datum+ -$kminus- -$kplus- -$desc- ,=$w=, #$valuta#");
        var pdate = format.parse(datum);
        //print("extracted date +$pdate+ -$kminus- -$kplus- -$desc- ,=$w=, #$valuta#\n");
        //DateFormat format = DateFormat();
        //double vval = (double.tryParse(valuta) != null)?double.tryParse(valuta):;
        int vval = (NumberFormat.currency().parse(valuta) * 100).toInt();
        //print("extracted valuta loc:  as num +$valuta+ vs #$vval#");
        //print("extracted valuta +$pdate+ -$kminus- -$kplus- -$desc- ,=$w=, #$vval#\n");
        Konto? kp = kpl.get(kplus);
        Konto? km = kpl.get(kminus);
        if (kp == null) {
          if (kplus.length == 1) //single digit? main account...
          {
            kp = Konto(number: kplus);
            kpl.put(kplus, kp);
          } else if (kplus.length > 0) {
            print("ERROR didn't find $kplus ${kplus.length}....");
          }
        }
        if (km == null) {
          if (kminus.length == 1) //single digit? main account...
          {
            km = Konto(number: kminus);
            kpl.put(kminus, km);
          } else if (kminus.length > 0) {
            print("ERROR didn't find $kminus ${kminus.length}....");
          }
        }
        //print("jrline got for $kminus $km and $kplus $kp\n");
        JrlLine li = JrlLine(
            datum: pdate,
            kmin: kpl.get(kminus),
            kplu: kpl.get(kplus),
            desc: desc,
            cur: w,
            valuta: vval);
        print("added $li");
        jrl.add(li);
        //print("added to jrl\n");
        //jrl.add(JrlLine(datum: pdate, kmin: kminus, kplu: kplus, desc: desc, cur:w, valuta: vval));
      } catch (e) {
        print(
            "Error, parsing jrlline +$datum+  -$desc- ,=$w=,  #$valuta# => $e");
      }
    }
    return jrl;
  }
}

main(List<String> arguments) //async
{
  //print("incoming : $arguments");
  Settings settings = Settings();
  settings.init(arguments);

  //print("result of arg run... : ${argResults["help"]}\n");
  //print("result of arg run... : ${argResults["help"]} sh: ${argResults["\?"]}\n");

  if (settings["help"] || settings["error"]) {
    print(settings.usage);
    exit(0);
  }
  KontoPlan? plan;
  Journal? jrl;
  if (settings["base"] != null && settings["base"] != "") {
    //print("opening file ${settings["base"]}");
    String basename = settings["base"];
    String fname = basename + ".kpl";
    print("trying to fetch kpl file $fname");
    var srcFile = File(fname);
    WbConvert converter = WbConvert(strict: settings["strict"]);
    if (srcFile.existsSync()) {
      //print("file exists\n");
      String rawTxt = srcFile.readAsStringSync();
      //print("got file $rawTxt");
      plan = converter.convert(rawTxt);
      //print("retrieved kpl= \n$plan\n");
    } else {
      print("kpl file doesn't exist");
    }
    fname = basename + ".jrl";
    print("trying to fetch jrl file $fname");
    srcFile = File(fname);
    if (srcFile.existsSync()) {
      //print("file exists\n");
      String rawTxt = srcFile.readAsStringSync();
      //print("got file $rawTxt");
      jrl = converter.convertJrl(rawTxt);
      //print("retrieved jrl= \n$jrl\n");
    } else {
      print("jrl file doesn't exist");
    }

    if (plan != null && jrl != null) {
      CsvHandler().save(kpl: plan, jrl: jrl, conf: settings);
    } else {
      print("Error: conversion failed.....");
    }
  } else
    print(
        "nothing to do, did you forget to provide an input file wth -b <file> ?");
}
