import 'dart:io';
import 'package:csv/csv.dart';
import 'package:nohfibu/nohfibu.dart';
import 'package:nohfibu/fibusettings.dart';

/// Helper class to load and save the data in csv format.

class CsvHandler {
  FibuSettings settings = FibuSettings();
  bool loading = false;

  /// save a book.
  /// Writes the book; the Future completes once it is on disk.
  Future<File> save({Book? book, KontoPlan? kpl, Journal? jrl, FibuSettings? conf}) {
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

    final res = Csv(autoDetect: false).encode(fibuAsList);

    //print("retrieved list\n$fibuAsList\n");
    //print("retrieved csv\n$res\n");

    //print("check settings output = ${settings['output']}");
    String fname =
        ((settings["output"]) != null && (settings["output"].isNotEmpty))
        ? settings["output"] + ".csv"
        : settings["base"] + ".csv";
    //print("created fname = $fname");
    return File(fname).writeAsString(res).then((file) {
      print("write seems successful, please check $fname");
      return file;
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
      // csv 8 finds the line ends itself; numbers parsed as before
      List<List<dynamic>> rowsAsListOfValues =
          Csv(autoDetect: false, dynamicTyping: true).decode(rawTxt);
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
        List actLine = rowsAsListOfValues[i];
        for(var field = 0; field < actLine.length; field++)if(actLine[field] is String  && actLine[field].isNotEmpty ) actLine[field] = actLine[field].trim();

        if (actLine.length == 1) {
          String tag = actLine[0].trim();
          if(tag.isEmpty)continue;
          if (tag == "KPL")
            mode = "kpl";
          else if (tag == "JRL")
            mode = "jrl";
          else if (tag == "OPS")
            mode = "ops";
          else {
            print("Error, unknown type: '${tag}' in '$actLine'");
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
                    desc: _text(actLine[desc]),
                    plan: book.kpl,
                    valuta: _number(actLine[valuta]),
                    cur: _text(actLine[cur]),
                    budget: _number(actLine[budget])),
                  debug: false);//("${actLine[name]}" =="4400")?true:false
                                //print("added kplline [$res]");
            Konto check =book.kpl.get("${actLine[name]}")??Konto();
            if(!check.equals(res) || check.isNotValid()) {
              print("ERROR CSVLOAD '${check.name}' does not match '${actLine[name]}' whilst parsing: ${res.number},${res.name}, ${res.desc}, ${res.valuta} vs $check");
              check = book.kpl.get("${actLine[name]}", debug: true)??Konto();
              print("NO  ${actLine[name]} in ${book.kpl.toString(astree: true,recursive: true)}");
            }

          } else if (mode == "jrl") {
            //print("treating[$mode] ${actLine}");
            DateTime point = DateTime.parse(_text(actLine[datum]));
            Konto? minus = book.kpl.get("${actLine[kmin]}");
            Konto? plus = book.kpl.get("${actLine[kplu]}");
            if("${minus?.name}" != "${actLine[kmin]}" ) {
              print("csvhandler[jrl.minus] error ${minus?.name} does not match ${actLine[kmin]} check manually for $actLine");
              book.kpl.put("${actLine[kmin]}", Konto(name: "${actLine[kmin]}", desc: "unknown check manually  for $actLine"));
              //minus = book.kpl.get("${actLine[kmin]}", debug: true);
            }
            if("${plus?.name}" != "${actLine[kplu]}") {
              print("csvhandler[jrl.plus] error ${plus?.name} does not match ${actLine[kplu]} check manually for $actLine");
              book.kpl.put("${actLine[kplu]}", Konto(name: "${actLine[kplu]}", desc: "unknown check manually  for $actLine"));
              //plus = book.kpl.get("${actLine[kplu]}", debug: true);
            }
            //print("treating[$mode] ${actLine}\n search ${actLine[kmin]} and ${actLine[kplu]} ${minus?.name},${minus?.number} and ${plus?.name},${plus?.number}");
            //num vval = num.parse(actLine[valuta]);
            num vval = _number(actLine[valuta]);
            JrlLine res =
            book.jrl.add(JrlLine(
                datum: point,
                kmin: minus,
                kplu: plus,
                desc: _text(actLine[desc]),
                cur: _text(actLine[cur]),
                valuta: vval));
            //print("added [$res]");
            if(res.isNotValid()) print("CSVHANDLER: error invalid jrlLine: $actLine vs $res");
          } else if (mode == "ops") {
            // tag, date, minus account, plus account, description, currency,
            // amount, mode — the order Operation.asList writes
            final String tag = Operation.clean(actLine[0]);
            final String date = Operation.clean(actLine.length > 1 ? actLine[1] : "");
            String col(int i) => actLine.length > i ? Operation.clean(actLine[i]) : "";
            {
              if(book.ops[tag] == null )
              {
                book.ops[tag] = Operation(book, name: tag);
              }
              {
                Operation anOp = book.ops[tag] as Operation;
                anOp.add(date: date, cminus: col(2), cplus: col(3), desc: col(4), cur: col(5), valuta: col(6), mod: col(7));
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



  /// A text field (csv parses numbers even when quoted).
  static String _text(dynamic value) => Operation.clean(value);

  /// A numeric field: numbers as they are, text parsed (0 when empty).
  static num _number(dynamic value) {
    if (value is num) return value;
    final text = Operation.clean(value);
    return num.tryParse(text) ?? 0;
  }
}
