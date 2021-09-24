import 'dart:io';
import 'package:csv/csv.dart';

import 'package:nohfibu/settings.dart';
import 'package:nohfibu/journal.dart';
import 'package:nohfibu/kto_plan.dart';
import 'package:nohfibu/csv_handler.dart';
import 'package:args/args.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';

class WbConvert
{
  bool strict = false;
  KontoPlan kpl = KontoPlan();
  late Journal jrl;


  WbConvert({strict})
  {
    if(strict) this.strict = true;
    jrl = Journal(kpl);
  }


  KontoPlan convert(String rawinput)
  {
    //print("incoming : $rawinput\n");
    kpl.clear();
    //kpl.add(Konto(number : 1,name: "", plan : kpl, title : "Aktiva" )) ;
    //kpl.add(Konto(number : 1,name: "", plan : kpl, title : "Aktiva" )) ;
    List<String> perLine = rawinput.split("\n");
    //print("splitted : $perLine\n");
    Konto? last;
    String toplvl = "";
    for (String line in perLine)
    {
      if(line.isEmpty) continue;
      String ktoName;
      String budget;
      String valuta = "0";
      String w ;
      String desc;
      if(strict)
      {
	//sscanf(zk,"%c %4d %49c%3c%12c", &kplc->seite,&kplc->knr,kplc->titel,&kplc->wn,tmpStr);
	ktoName = line.substring(2,6).trim();
	desc = line.substring(8,56).trim();
	w = line.substring(58,61).trim();
	//budget = line.substring(61).trim();
	budget = line.substring(61,74).trim();
	valuta = line.substring(75,88).trim();
      }
      else
      {
	//print("processing '$line'");
	final pattern = RegExp('\\s+');
	line = line.replaceAll(pattern, " ").trim();
	List<String> spcRm = line.split(" ");
	if(spcRm.length < 4) {print("reject line $line");continue;}
	ktoName = spcRm.removeAt(0);
	budget = spcRm.removeLast();
	w = spcRm.removeLast();
	try {
	  if (double.parse(w) >=0) {
	    valuta = budget;
	    budget = w;
	    w = spcRm.removeLast();
	  }
	}
	catch(e) {
	  //print("$w not a double...");
	}
	desc = spcRm.join(" ");
      }
      //print("extracted +$ktoName+  -$desc- ,=$w=,  '$budget' #$valuta#");
      try
      {
	//print("trying kto $ktoName");
	int kto =int.parse(ktoName);
	double bval =double.parse(budget);
	num vval = NumberFormat.currency().parse(valuta);
	if(kto == 0)
	{
	  //last.desc = desc;
	  kpl.get(toplvl)!.desc = desc;
	  //print("set caption of block $toplvl to ${kpl.get(toplvl)}");
	}
	else
	{
	  toplvl = ktoName[0];
	  //print("set topvö to $toplvl");
	  Konto start= Konto(number: toplvl, name: ktoName, plan:  kpl, desc: desc, cur: w, budget: bval, valuta: vval.toDouble()) ;
	  kpl.put(ktoName,start);
	  //print("filled kto : $start");
	}
      }
      catch(e) {
	print("Error, something went wrong with +$ktoName+  -$desc- ,=$w=,  '$budget' #$valuta# => $e");
      }
    }

	      //print("kpl so far : ${kpl.asList(all:true)}");
	      print("kpl so far : ${kpl}");
    return kpl;
  }

  Journal convertJrl(String rawinput)
  {
    //print("incoming : $rawinput\n");
    jrl.clear();
    List<String> perLine = rawinput.split("\n");
    //print("splitted : $perLine\n");
    for (String line in perLine)
    {
      if(line.isEmpty) continue;
      //01.01.95 1001 0    Riporto Cassa                                ITL            0·
      //sscanf(zk,"%8c %4d %4d %44c%3c%12c",

      //print("parsing $line  of ${line.length}");

      String datum;
      String kplus, kminus;
      String valuta = "0";
      String w ;
      String desc;
      if(strict)
      {
	//sscanf(zk,"%c %4d %49c%3c%12c", &kplc->seite,&kplc->knr,kplc->titel,&kplc->wn,tmpStr);
	datum = line.substring(0,8).trim();
	kminus = line.substring(9,13).trim();
	kplus = line.substring(14,18).trim();
	desc = line.substring(19,64).trim();
	w = line.substring(64,68).trim();
	valuta = line.substring(69,80).trim();
      }
      else
      {
	final pattern = RegExp('\\s+');
	line = line.replaceAll(pattern, " ").trim();
	List<String> spcRm = line.split(" ");
	if(spcRm.length < 6) {print("reject line $line");continue;}
	datum = spcRm.removeAt(0);
	kminus = spcRm.removeAt(0);
	kplus = spcRm.removeAt(0);
	valuta = spcRm.removeLast();
	w = spcRm.removeLast();
	desc = spcRm.join(" ");
      }
      try
      {
	DateFormat format = new DateFormat("dd.MM.yy");
	//print("extracted so far +$datum+ -$kminus- -$kplus- -$desc- ,=$w=, #$valuta#");
	var pdate = format.parse(datum);
	//print("extracted date +$pdate+ -$kminus- -$kplus- -$desc- ,=$w=, #$valuta#\n");
	//DateFormat format = DateFormat();
	//double vval = (double.tryParse(valuta) != null)?double.tryParse(valuta):;
	num vval = NumberFormat.currency().parse(valuta);
	//print("extracted valuta loc:  as num +$valuta+ vs #$vval#");
	//print("extracted valuta +$pdate+ -$kminus- -$kplus- -$desc- ,=$w=, #$vval#\n");
	Konto? kp = kpl.get(kplus);
	Konto? km = kpl.get(kminus);
	if(kp == null)
	{
	  if(kplus.length == 1) //single digit? main account...
	  {
	    kp =  Konto(number: kplus);
	    kpl.add(kp);
	  }
	  else if(kplus.length >0)
	  {
	    print("ERROR didn't find $kplus ${kplus.length}....");
	  }
	}
	if(km == null)
	{
	  if(kminus.length == 1) //single digit? main account...
	  {
	    km =  Konto(number: kminus);
	    kpl.add(km);
	  }
	  else if(kminus.length >0)
	  {
	    print("ERROR didn't find $kminus ${kminus.length}....");
	  }
	}
	//print("jrline got for $kminus $km and $kplus $kp\n");
	JrlLine li = JrlLine(datum: pdate, kmin: kpl.get(kminus), kplu: kpl.get(kplus), desc: desc, cur:w, valuta: vval);
	print("added $li");
	jrl.add(li);
	//print("added to jrl\n");
	//jrl.add(JrlLine(datum: pdate, kmin: kminus, kplu: kplus, desc: desc, cur:w, valuta: vval));
      }
      catch(e) {
	print("Error, parsing jrlline +$datum+  -$desc- ,=$w=,  #$valuta# => $e");
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

  if(settings["help"]||settings["error"])
  {
    print(settings.usage);
    exit(0);
  }
  KontoPlan? plan ;
  Journal? jrl;
  if(settings["base"] != "" )
  {
    //print("opening file ${settings["base"]}");
    String basename = settings["base"];
    String fname = basename +".kpl";
    print("trying to fetch kpl file $fname");
    var srcFile = File(fname);
    WbConvert converter = WbConvert(strict: settings["strict"]);
    if(srcFile.existsSync())
    {
      //print("file exists\n");
      String rawTxt = srcFile.readAsStringSync();
      //print("got file $rawTxt");
      plan = converter.convert(rawTxt);
      //print("retrieved kpl= \n$plan\n");
    }
    else
    {
      print("kpl file doesn't exist");
    }
    fname = basename +".jrl";
    print("trying to fetch jrl file $fname");
    srcFile = File(fname);
    if(srcFile.existsSync())
    {
      //print("file exists\n");
      String rawTxt = srcFile.readAsStringSync();
      //print("got file $rawTxt");
      jrl = converter.convertJrl(rawTxt);
      //print("retrieved jrl= \n$jrl\n");
    }
    else
    {
      print("jrl file doesn't exist");
    }

    if(plan != null && jrl != null)
    {
      CsvHandler().save(kpl: plan, jrl: jrl,conf: settings);
    }
    else
    {
      print("Error: conversion failed.....");
    }
  }
}
