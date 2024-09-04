import 'dart:io';
import 'package:csv/csv.dart';
import 'package:nohfibu/nohfibu.dart';
import 'package:nohfibu/fibusettings.dart';
import 'package:nohfibu/ops_handler.dart';

/// Helper class to load and save the data in csv format.

class CsvHandler {
  FibuSettings settings = FibuSettings();
  bool loading = false;

  /// save a book.
  void save({Book? book, KontoPlan? kpl, Journal? jrl, FibuSettings? conf}) {
    if (book == null) book = Book();
    if (kpl != null) book.kpl = kpl;
    if (jrl != null) book.jrl = jrl;
    if (conf != null) settings = conf;

    ///Save the operations
    List<List<dynamic>> fibuAsList = book.kpl.asList();
    fibuAsList = book.jrl.asList(fibuAsList);

    fibuAsList.add(["OPS"]);
    fibuAsList.add(["tag","date","compte_accredite","compte_retrait","description","monnaie","montant","modif"]);
    book.ops.forEach((key,val)=>(val as Operation).asList(fibuAsList));

    final res = const ListToCsvConverter().convert(fibuAsList);

    //print("retrieved list\n$fibuAsList\n");
    //print("retrieved csv\n$res\n");

    //print("check settings output = ${settings['output']}");
    String fname =
        ((settings["output"]) != null && (settings["output"].isNotEmpty))
        ? settings["output"] + ".csv"
        : settings["base"] + ".csv";
    //print("created fname = $fname");
    File(fname).writeAsString(res).then((file) {
      print("write seems successful, please check $fname");
    });
  }

  /// load a book.
  void load({Book? book, FibuSettings? conf, String data = ""}) {
    if (book == null) book = Book();
    if (conf != null) settings = conf;
    if (settings["type"] != "csv") {
      print("Error: csv handler can't read  '${settings["type"]}' only .csv");
      return;
    }
    //print("load Book: ${settings["base"]} ${settings["type"]}  ");

    String rawTxt = (data.isNotEmpty)? data : "";
    if(rawTxt.isEmpty)
    {
      var srcFile = File(settings["base"] + "." + settings["type"]);
      if (srcFile.existsSync()) {
        book.name = settings["base"].split("/").last;
        //print("file exists\n");
        rawTxt = srcFile.readAsStringSync();
        //print("file exists\n$rawTxt");
      }
      else {print("File ${settings["base"]}.${settings["type"]} does not exist");}
    }


    //var srcFile = File(settings["base"] + "." + settings["type"]);
    //if (srcFile.existsSync()) 
    if(rawTxt.isNotEmpty)
    {
      //book.name = settings["base"].split("/").last;
      //print("file exists\n");
      //String rawTxt = srcFile.readAsStringSync();
      String eol = detectEOL(rawTxt);

      List<List<dynamic>> rowsAsListOfValues =
          CsvToListConverter(eol: eol).convert(rawTxt);
      //print("extracted  $rowsAsListOfValues");
      String mode = "none";
      List header = [];
      int name = 0,
      desc = 0,
      valuta = 0,
      cur = 0,
      budget = 0,
      datum = 0,
      kmin = 0,
      kplu = 0;
      for (int i = 0; i < rowsAsListOfValues.length; i++) {
        var actLine = rowsAsListOfValues[i];

        if (actLine.length == 1) {
          String tag = actLine[0].trim();
          //print("check start of section : '$tag'");
          if (tag == "KPL")
            mode = "kpl";
          else if (tag == "JRL")
            mode = "jrl";
          else if (tag == "OPS")
            mode = "ops";
          else {
            print("Error, unknown type: '${tag}'");
            mode = "none";
          }
          i++;
          header = rowsAsListOfValues[i];
          desc = (header.indexOf("desc") >= 0)
              ? header.indexOf("desc")
              : header.indexOf("dsc");
          valuta = header.indexOf("valuta");
          if(valuta == -1 && mode != "ops") throw Exception("[$mode] valuta not found in $header");
          cur = header.indexOf("cur");
          if (mode == "kpl") {
            name = header.indexOf("kto");
            budget = header.indexOf("budget");
          } else if (mode == "jrl")
          {
            //print("KPL so far ${book.kpl}");
            datum = header.indexOf("date");
            kplu = header.indexOf("ktoplus");
            kmin = header.indexOf("ktominus");
          }
          //print("set node to  $mode");
        } else {
          //print("treating[$mode] ${actLine}");
          if (mode == "kpl") {
            String ktoname = "${actLine[name]}";
            //print("treating[$mode] adding $ktoname prefix = ${(ktoname.length>1)?ktoname.substring(0,ktoname.length-1):''}");
            Konto res =
                book.kpl.put(
                  ktoname,
                  Konto(
                    name: ktoname,
                    prefix: (ktoname.length>1)?ktoname.substring(0,ktoname.length-2):"",
                    desc: actLine[desc],
                    plan: book.kpl,
                    valuta: actLine[valuta],
                    cur: actLine[cur],
                    budget: actLine[budget]),
                  debug: false);//("${actLine[name]}" =="4400")?true:false
                                //print("added kplline [$res]");
            Konto? check =book.kpl.get("${actLine[name]}");
            if("${check?.name}" != "${actLine[name]}") {
              print("ERROR CSVLOAD ${check?.name} does not match ${actLine[name]}");
              check = book.kpl.get("${actLine[name]}", debug: true);
              print("NO  ${actLine[name]} in ${book.kpl.toString(astree: true,recursive: true)}");
            }

          } else if (mode == "jrl") {
            //print("treating[$mode] ${actLine}");
            DateTime point = DateTime.parse(actLine[datum]);
            Konto? minus = book.kpl.get("${actLine[kmin]}");
            Konto? plus = book.kpl.get("${actLine[kplu]}");
            if("${minus?.name}" != "${actLine[kmin]}") {
              print("csvhandler[jrl.minus] error ${minus?.name} does not match ${actLine[kmin]} check manually");
              book.kpl.put("${actLine[kmin]}", Konto(name: "${actLine[kmin]}", desc: "unknown check manually "));
              //minus = book.kpl.get("${actLine[kmin]}", debug: true);
            }
            if("${plus?.name}" != "${actLine[kplu]}") {
              print("csvhandler[jrl.plus] error ${plus?.name} does not match ${actLine[kplu]} check manually");
              book.kpl.put("{$actLine[kmin]}", Konto(name: "{$actLine[kmin]}", desc: "unknown check manually "));
              //plus = book.kpl.get("${actLine[kplu]}", debug: true);
            }
            //print("treating[$mode] ${actLine}\n search ${actLine[kmin]} and ${actLine[kplu]} ${minus?.name},${minus?.number} and ${plus?.name},${plus?.number}");
            //num vval = num.parse(actLine[valuta]);
            num vval = 0;
            try {
              vval = actLine[valuta];
            }
            catch (e) {
              print("cvshandler: error!!!  ${actLine[valuta]} not a num in ${actLine} with $e");
            }
            //JrlLine res =
            book.jrl.add(JrlLine(
                datum: point,
                kmin: minus,
                kplu: plus,
                desc: actLine[desc],
                cur: actLine[cur],
                valuta: vval));
            //print("added [$res]");
          } else if (mode == "ops") {
            DateTime point = (actLine[1]!= null && actLine[1].isNotEmpty)?DateTime.parse(actLine[1]):DateTime.now();
            //print("parsing  ops $actLine");
            //try
            {
              //"tag","date","compte_accredite","compte_retrait","description","monnaie","montant","modif"
              if(book.ops[actLine[0]] == null )
              {
                //print("adding op ${actLine[0]}  to ${book.name} with $actLine");
                book.ops[actLine[0]] = Operation(book,name: actLine[0].trim(), date: point,cplus: actLine[3],cminus: actLine[2],desc: actLine[4].trim(),cur: actLine[5].trim(), valuta:  actLine[6], mod:actLine[7].trim());
                //print("created  op  ${actLine[0]} in book ${book.ops[actLine[0]].book.name}");
              }
              else
              {
                Operation anOp = book.ops[actLine[0]] as Operation;
                anOp.add(date: point,cplus: actLine[2],cminus: actLine[3],desc: actLine[4],cur: actLine[5], valuta:  actLine[6], mod:actLine[7]);
                //print("modified   ${book.ops[actLine[0]]}");
              }
            }
            //catch(e) { print("failed to parse $actLine $e"); }
          }
        }
      }
    } else {
      print("book file doesn't exist");
    }
  }

  String detectEOL(String fileContent) 
  {
    // Check for Windows EOL
    if (fileContent.contains('\r\n')) {
      return '\r\n'; // Windows EOL sequence (CRLF)
    }
    // Check for Unix EOL
    else if (fileContent.contains('\n')) {
      return '\n'; // Unix EOL sequence (LF)
    } else {
      return 'unknown'; // No recognizable EOL sequence found
    }
  }

  bool unixEOL(String fileContent) 
  {
    if(detectEOL(fileContent) == '\n') return true;
    return false;
  }


}
