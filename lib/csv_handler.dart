import 'dart:io';
import 'package:csv/csv.dart';
import 'package:nohfibu/nohfibu.dart';
import 'package:nohfibu/settings.dart';
import 'package:nohfibu/ops_handler.dart';

/// Helper class to load and save the data in csv format.

class CsvHandler {
  Settings settings = Settings();
  bool loading = false;

  /// save a book.
  void save({Book? book, KontoPlan? kpl, Journal? jrl, Settings? conf}) {
    if (book == null) book = Book();
    if (kpl != null) book.kpl = kpl;
    if (jrl != null) book.jrl = jrl;
    if (conf != null) settings = conf;

    ///Save the operations
    List<List<dynamic>> fibuAsList = book.kpl.asList();
    fibuAsList = book.jrl.asList(fibuAsList);
    if(book.ops != null) {
    fibuAsList.add(["OPS"]);
    fibuAsList.add(["tag","date","compte_accredite","compte_retrait","description","monnaie","montant","modif"]);
      book.ops.forEach((key,val)=>(val as Operation).asList(fibuAsList));
    }

    final res = const ListToCsvConverter().convert(fibuAsList);

    print("retrieved list\n$fibuAsList\n");
    print("retrieved csv\n$res\n");

    print("check settings output = ${settings['output']}");
    String fname =
        ((settings["output"]) != null && (settings["output"].isNotEmpty))
            ? settings["output"]
            : settings["base"] + ".csv";
    print("created fname = $fname");
    File(fname).writeAsString(res).then((file) {
      print("write seems successful, please check $fname");
    });
  }

  /// load a book.
  void load({Book? book, Settings? conf}) {
    if (book == null) book = Book();
    if (conf != null) settings = conf;
    if (conf != null) settings = conf;
    if (settings["type"] != "csv") {
      print("Error: csv handler can't read  '${settings["type"]}' only .csv");
      return;
    }
    print("load Book: ${settings["base"]} ${settings["type"]}  ");
    var srcFile = File(settings["base"] + "." + settings["type"]);
    if (srcFile.existsSync()) {
      //print("file exists\n");
      String rawTxt = srcFile.readAsStringSync();
      //print("got file $rawTxt");
      List<List<dynamic>> rowsAsListOfValues =
          const CsvToListConverter().convert(rawTxt);
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
          if (actLine[0] == "KPL")
            mode = "kpl";
          else if (actLine[0] == "JRL")
            mode = "jrl";
          else if (actLine[0] == "OPS")
            mode = "ops";
          else {
            print("Error , unknown type: ${actLine[0]}");
            mode = "none";
          }
          i++;
          header = rowsAsListOfValues[i];
          desc = (header.indexOf("desc") >= 0)
              ? header.indexOf("desc")
              : header.indexOf("dsc");
          valuta = header.indexOf("valuta");
          cur = header.indexOf("cur");
          if (mode == "kpl") {
            name = header.indexOf("kto");
            budget = header.indexOf("budget");
          } else if (mode == "jrl") ;
          {
            datum = header.indexOf("date");
            kplu = header.indexOf("ktoplus");
            kmin = header.indexOf("ktominus");
          }
        } else {
          //print("treating[$mode] ${actLine}");
          if (mode == "kpl") {
            if (book.kpl == null)
              print("treating[$mode] ${actLine} ${book.kpl}");
            Konto res = book.kpl.put(
                "${actLine[name]}",
                Konto(
                    name: "${actLine[name]}",
                    desc: actLine[desc],
                    plan: book.kpl,
                    valuta: actLine[valuta],
                    cur: actLine[cur],
                    budget: actLine[budget]));
            //print("added [$res]");
          } else if (mode == "jrl") {
            //print("treating[$mode] ${actLine}");
            DateTime point = DateTime.parse(actLine[datum]);
            Konto? minus = book.kpl.get("${actLine[kmin]}");
            Konto? plus = book.kpl.get("${actLine[kplu]}");
            //num vval = num.parse(actLine[valuta]);
            num vval = actLine[valuta];
            JrlLine res = book.jrl.add(JrlLine(
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
            try
            {
              //"tag","date","compte_accredite","compte_retrait","description","monnaie","montant","modif"
              if(book.ops[actLine[0]] == null )
                {
                  book.ops[actLine[0]] = Operation(book,name: actLine[0], date: point,cplus: actLine[2],cminus: actLine[3],desc: actLine[4],cur: actLine[5], valuta:  actLine[6], mod:actLine[7]);
                  //print("created   ${book.ops[actLine[0]]}");
                }
              else
              {
                Operation anOp = book.ops[actLine[0]] as Operation;
                anOp.add(date: point,cplus: actLine[2],cminus: actLine[3],desc: actLine[4],cur: actLine[5], valuta:  actLine[6], mod:actLine[7]);
                //print("modified   ${book.ops[actLine[0]]}");
              }
            }
            catch(e) {
              print("failed to parse $actLine $e");
            }
          }
        }
      }
    } else {
      print("book file doesn't exist");
    }
  }
}
