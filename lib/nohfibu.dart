import 'dart:math';
import 'package:intl/intl.dart';
import 'package:sprintf/sprintf.dart';
import 'dart:collection';

/// a helper to add to currencies the right utf symbol .
String cur2sym(String name) {
  String sym = "€";
  switch (name) {
    case 'EUR':
      sym = "€ ";
      break;
    case 'LIR':
      sym = "£ ";
      break;
    case 'YEN':
      sym = "¥ ";
      break;
    case 'POU':
      sym = "£ ";
      break;
    case 'DOL':
      sym = "\$ ";
      break;
    default:
      sym = "€ ";
      break;
  }
  return sym;
}

/// the account plan .
class KontoPlan {
  //bestandsKonten
  //List<Konto> aktivKonten = [Konto(name: "soll"),Konto(name: "haben")], passivKonten= [Konto(name: "soll"),Konto(name: "haben")]; //jeweils gespalten in soll (vermehrung) und haben (verminderung)
  SplayTreeMap<String, Konto> konten = SplayTreeMap<String, Konto>();
  //List<Konto> aktivKonten = [], passivKonten= []; //jeweils gespalten in soll (vermehrung) und haben (verminderung)

  void clear() {
    //aktivKonten = [Konto(name: "soll", plan: this),Konto(name: "haben", plan: this)];
    //passivKonten= [Konto(name: "soll", plan: this),Konto(name: "haben", plan: this)];
    konten.clear();
  }

  /// return the asked account null if not found (BEWARE!!) .
  Konto? get(String ktoName) {
    //print("ktop get for $ktoName");
    if (konten.containsKey(ktoName)) return konten[ktoName];
    //print("ktop seems we need to recurse");
    //but maybe we must recurse?
    if (ktoName.length > 1) {
      //print("name is long enough....");
      String key = ktoName[0];
      if (konten.containsKey(key))
        return konten[key]!.get(ktoName.substring(1));
      //print("ktop but konten doesn't contain $key");
      return null;
    }
    //print("ktop far enough no lolly");
    return null;
  }

  /// set at ktoName (Treewise) the data if kto (kto will be discarded afterwards) create the account if needed .
  Konto put(String ktoName, Konto kto) {
    if (ktoName.length < 1)
      print("Error, KPL, don't know how to add $kto @ $ktoName");
    else if (ktoName.length == 1)
      konten[ktoName] = kto;
    else {
      String key = ktoName[0];
      String rest = ktoName.substring(1, ktoName.length);
      if (!konten.containsKey(key))
        konten[key] = Konto(number: key, plan: this);

      //fetch the account, creating it on the way
      var locK = konten[key]!.get(rest, orgName: ktoName);
      locK.name = kto.name;
      locK.plan = this;
      locK.desc = kto.desc;
      locK.cur = kto.cur;
      locK.budget = kto.budget;
      locK.valuta = kto.valuta;
      kto = locK;
    }
    return kto;
  }

  /// pretty print this thing .
  @override
  String toString({bool extracts = false}) {
    String result = "              Konto Plan \n";
    konten.forEach((key, kto) {
      result += kto.toString(recursive: true, extracts: extracts) + "\n";
    });
    result += "         Ende Konto Plan \n";
    //print("extracted +$ktoName+  -$desc- ,=$w=,  '$budget' #$valuta#\n");
    //return "$number $name $desc $cur $valuta $budget";
    return (result);
  }

  /// return this as a list
  ///  used for exporting the data .
  List<List<dynamic>> asList({bool all = false}) {
    List<List<dynamic>> asList = [
      ["KPL"],
      ["kto", "dsc", "cur", "budget", "valuta"]
    ];
    konten.forEach((key, value) {
      value.asList(asList: asList, all: all);
    });
    return asList;
  }

  /// run the analysis, comparing the 4 blocs against each other to see if the data is valid
  String analysis() {
    String result = "=" * 30 + "    Analysis    " + "=" * 30 + "\n";
    Konto activa = get("1")!;
    Konto passiva = get("2")!;
    Konto costs = get("3")!;
    Konto incomes = get("4")!;
    result += "Aktiva    \n" + activa.toString(recursive: true) + "\n";
    int sumActiva = activa.sum();
    result +=
        " " * 60 + "Aktiva insgesamt " + activa.numFormat(sumActiva) + "\n";
    result += "Passiva    \n" + passiva.toString(recursive: true) + "\n";
    int sumPassiva = activa.sum();
    result +=
        " " * 60 + "Passiva insgesamt " + passiva.numFormat(sumPassiva) + "\n";
    result += " " * 60 +
        "Ueberschuss " +
        passiva.numFormat(sumActiva - sumPassiva) +
        "\n";
    result += "Kosten    \n" + costs.toString(recursive: true) + "\n";
    int sumKosten = costs.sum();
    result +=
        " " * 60 + "Kosten insgesamt " + activa.numFormat(sumKosten) + "\n";
    result += "Einnahmen    \n" + incomes.toString(recursive: true) + "\n";
    int sumEinnahmen = incomes.sum();
    result += " " * 60 +
        "Einnahmen insgesamt " +
        passiva.numFormat(sumEinnahmen) +
        "\n";
    result += " " * 60 +
        "Ueberschuss " +
        passiva.numFormat(sumEinnahmen - sumKosten) +
        "\n";
    result += " " * 50 +
        "Gueltigkeit (muss 0 sein) " +
        passiva
            .numFormat((sumEinnahmen - sumKosten) + (sumActiva - sumPassiva)) +
        "\n";
    //print("retrieved : ${activa.toString(recursive: true)}");
    return result;
  }
}

/// one account .
class Konto {
  String number = "-1";
  String desc = "";
  KontoPlan plan = KontoPlan();
  String cur = "EUR"; //currency
  int valuta = 0;
  int budget = 0;
  Map<String, Konto> children = {};

  String name = "no name";
  late Journal extract;

  ///CTOR where you can specify
  ///   the number of the account,
  ///   its name (the number is recursively consumed)
  ///   to which account plan it relates
  ///   valute the actual value in the account
  ///   budget a theoretical value that lapsed should generate warnings .
  Konto({number, name = "kein Name", desc, plan, valuta, cur, budget}) {
    //set(number,name, plan, desc, valuta, cur, budget);
    if (number != null) this.number = number;
    if (name != null && name != "kein Name") this.name = name;
    if (desc != null) this.desc = desc;
    if (cur != null) this.cur = cur;
    if (valuta != null) this.valuta = valuta;
    if (budget != null) this.budget = budget;
    if (this.number == null) this.number = name[name.length - 1];
    extract = Journal(this.plan, caption: "Extract for ${this.name}");
  }

  /// setter for the values concerning this object
  ///    the number of the account,
  ///    its name (the number is recursively consumed)
  ///    to which account plan it relates
  ///    valute the actual value in the account
  ///    budget a theoretical value that lapsed should generate warnings .
  Konto set({number, name = "kein Name", plan, desc, valuta, cur, budget}) {
    if (number != null) this.number = number;
    if (name != null && name != "kein Name") this.name = name;
    if (desc != null) this.desc = desc;
    if (cur != null) this.cur = cur;
    if (valuta != null) this.valuta = valuta;
    if (budget != null) this.budget = budget;
    if (this.number == null) this.number = name[name.length - 1];
    return this;
  }

  /// get the target account, by descending into the tree of accounts
  /// null safe, if no account was found a dummy one is generated .
  Konto get(String ktoName, {String orgName = "undef"}) {
    if (orgName == "undef") orgName = ktoName;
    if (name == ktoName) {
      return this;
    } else if (children.containsKey(ktoName)) {
      return children[ktoName]!;
    } else if (!children.containsKey(ktoName) && ktoName.length > 1) {
      //maybe recurse?
      String key = ktoName[0];
      String rest = ktoName.substring(1);
      if (ktoName.startsWith(name)) {
        rest = ktoName.substring(name.length);
        key = rest[0];
        rest = rest.substring(1);
        if (rest.length <= 0) {
          children[key] = Konto(number: key, name: orgName);
          return children[key]!;
        }
      }
      if (children.containsKey(key))
        return children[key]!.get(rest, orgName: orgName);
      // if(key !=number) //study more, o how to cope with unrelated names
      // {
      //   //orgName = name+orgName;
      // print("ehm  $ktoName differs from me ($number) .... rewriting orgName to $orgName" );
      // }
      children[key] = Konto(number: key, plan: this);
      return children[key]!.get(ktoName.substring(1), orgName: orgName);
    }
    children[ktoName] = Konto(number: ktoName, name: orgName);
    return children[ktoName]!;
  }

  /// create a String representation of  this object, eventually
  ///by recursing through the sub accounts below this one .
  @override
  String toString(
      {String indent = "",
      bool debug = false,
      bool recursive = false,
      empty = false,
      bool extracts = false}) {
    String result = "";
    if (extracts) {
      //print("trying to add '${extract.toString()}'");
      if (empty)
        result += extract.toString();
      else if (extract.journal.length > 0) {
        result += extract.toString() + "\n";
        //String pff=  extract.toString();
        //if(pff.isNotEmpty) { print("adding ### $pff ####");result += pff;}
        //else print("rejecting $pff");
      }
    } else {
      var f = NumberFormat.currency(symbol: cur2sym(cur));
      double valAsd = valuta / 100;
      double budAsd = budget / 100;
      String pname = (name == "no name") ? "$number" : name;
      result = (debug)
          ? "$indent$number. +$pname+  -$desc- ,=$cur=,  '$budget' #$valuta#\n"
          : (recursive && !empty && desc.length <= 0)
              ? ""
              : "$indent${sprintf("%#4s", [pname])}  ${sprintf("%-49s", [
                      desc
                    ])} ${sprintf("%12s", [
                      f.format(budAsd)
                    ])}  ${sprintf("%12s", [f.format(valAsd)])}\n";
    }
    ;

    if (recursive) {
      //var f = NumberFormat("###,###,###.00");
      //result += (desc.length >0 || empty)?"##$empty\n":"";
      children.forEach((key, kto) {
        //result += kto.toString(indent:indent+"$number"); //debug, just to check depth
        String sres = kto.toString(
            indent: indent + " ",
            recursive: true,
            debug: debug,
            empty: empty,
            extracts: extracts);
        if (sres.trim().isNotEmpty) result += "$sres";
      });
    }
    //print("extracted +$ktoName+  -$desc- ,=$w=,  '$budget' #$valuta#\n");
    return (result);
  }

  /// pretty print the account name, olb WB style fibu had 4 char wide account fields...  .
  printname() {
    String fn = (name == "no name") ? "0" : name;
    return (sprintf("%#4s", [fn]));
  }

  /// return this thins as a list, recurse through the tree
  ///preparation for e.g. csv conversion .
  List<List> asList({List<List> asList = const [], bool all = false}) {
    if (asList == null) asList = [];
    //print("$number $name $desc tries to add to list");
    if (name == "no name" && desc.length > 0)
      asList.add([number, desc, cur, budget, valuta]);
    else if (desc.length > 0) asList.add([name, desc, cur, budget, valuta]);
    if (all) asList.add([name, desc, cur, budget, valuta]);
    children.forEach((key, value) {
      value.asList(asList: asList);
    });
    return asList;
  }

  /// add a journal line to our account extract, update the valuta .
  Konto action(JrlLine line, {String mode = "add"}) {
    if (mode == "add")
      valuta += line.valuta;
    else
      valuta -= line.valuta;
    //print("action for  $name ($mode) add line ${line.desc} and $valuta");
    ExtractLine sline = ExtractLine(line: line, sumup: valuta);
    //print("$name adding to $extract \n $sline");
    extract.add(ExtractLine(line: line, sumup: valuta));
    var f = NumberFormat.currency(symbol: cur2sym(cur));
    String title = "  Extract for $name  ";
    int tofill = ((95 - title.length) / 2).toInt();
    extract.caption = "-" * tofill + title + "-" * tofill;
    extract.endcaption = "_" * 60 +
        "Sum:  " +
        "_" * 18 +
        sprintf("%12s", [f.format((valuta / 100).toDouble())]);

    return this;
  }

  /// pretty print a number as currency
  String numFormat(int toConvert) {
    var f = NumberFormat.currency(symbol: cur2sym(cur));
    double valAsd = toConvert / 100;
    String result = "${sprintf("%12s", [f.format(valAsd)])}\n";
    return result;
  }

  /// sum up the sub accounts below this one
  int sum() {
    int mysum = valuta;
    children.forEach((key, value) {
      mysum += value.sum();
    });
    return mysum;
  }
}

/// This class hold a list of lines, each caracterising an entry in an accounting journal.
class Journal {
  late KontoPlan kpl;
  String caption = "Journal";
  String endcaption = "Journal End";

  /// CTOR.
  Journal(KontoPlan kplan, {caption = "Journal", String end = "End"}) {
    kpl = kplan;
    //if(caption != null)
    //{
    this.caption = caption;
    if (end == "End")
      endcaption = "$caption $end";
    else
      endcaption = "$end";
    //}
  }
  List<JrlLine> journal = [];

  /// empty the journal.
  void clear() {
    journal = [];
  }

  /// add a line.
  JrlLine add(JrlLine jrlLine) {
    journal.add(jrlLine);
    return jrlLine;
  }

  /// pretty print this journal.
  @override
  String toString() {
    String result = "$caption\n";
    for (var line in journal) {
      result += "$line\n";
    }
    result += endcaption;
    return result;
  }

  /// return the journal as a list .
  List<List> asList(List<List> data) {
    data = (data == null) ? [] : data;

    data.add(["JRL"]);
    data.add(["date", "ktominus", "ktoplus", "desc", "cur", "valuta"]);
    journal.forEach((line) {
      line.asList(data);
    });
    return data;
  }

  /// return the number of entries in this journal.
  int count() => journal.length;

  /// execute the accounting process, creating the subjournals, the account extracts for
  ///  each account update the valutas of each account.
  Journal execute() {
    DateTime minTime = DateTime.now();
    DateTime maxTime = DateTime.now().subtract(const Duration(days: 365));
    journal.forEach((line) {
      //print("excuting exe for $line");
      if (line.datum.compareTo(minTime) < 0) minTime = line.datum;
      if (line.datum.compareTo(maxTime) > 0) maxTime = line.datum;
      line.execute();
    });
    caption = "Journal from $minTime to $maxTime";
    return this;
  }
}

/// one line in an accounting journal.
class JrlLine {
  /// the date of the transaction
  late DateTime datum;

  /// the account to be taken from
  late Konto kplus;

  /// the account to be credited
  late Konto kminus;

  ///  description of the transaction
  late String desc;

  /// the currency of the transaction
  late String cur;

  /// the value of the transaction
  late int valuta;
  ///eventual constraints on the input to the journal
  Map? limits;

  /// CTOR the fields are optional, if omitted they will be filled with defaults .
  JrlLine({datum, kmin, kplu, desc, cur, valuta}) {
    // print("jline incoming +$datum+ -$kmin- -$kplu- -$desc- ,=$cur=, #$valuta#\n");
    kplus = (kplu != null) ? kplu : Konto();
    kminus = (kmin != null) ? kmin : Konto();
    this.desc = (desc != null) ? desc : "none";
    this.datum = (datum != null) ? datum : DateTime.now();
    this.cur = (cur != null) ? cur : "EUR";
    this.valuta = (valuta != null) ? valuta : 0;
  }

  /// pretty print this thing .
  @override
  String toString() {
    final DateFormat formatter = DateFormat('dd-MM-yyyy');
    final String formatted = formatter.format(datum);
    var f = NumberFormat.currency(symbol: cur2sym(cur));
    double valAsd = valuta / 100;

    String result =
        "$formatted ${kminus.printname()} ${kplus.printname()} ${sprintf("%-49s", [ desc ])} ${sprintf("%12s", [f.format(valAsd)])}";
    return result;
  }

  /// return a list abstraction model of this object .
  void asList(List<List> data) {
    final DateFormat formatter = DateFormat('yyyy-MM-dd');
    final String date = formatter.format(datum);
    data.add(
        [date, kminus.printname(), kplus.printname(), "$desc", cur, valuta]);
  }

  /// ask the 2 accounts to add this line to their extracts.
  JrlLine execute() {
    kminus.action(this, mode: "sub");
    kplus.action(this, mode: "add");
    return this;
  }
  void addContraint(String key,List<String> boundaries)
  {
    if(limits == null) limits = {"kmin": {"min": 0, "max": 1000000},"kplu": {"min": 0, "max": 1000000}};

    if(boundaries == null || boundaries.length <2 ) { print("boundaries needs to hold to vals, min, max"); return; }
    if(key == "kmin") {
      limits!["kmin"]["min"] = boundaries[0];
      limits!["kmin"]["max"] = boundaries[1];
    }
    else if(key == "kplu") {
      limits!["kplu"]["min"] = boundaries[0];
      limits!["kmiplu"]["max"] = boundaries[1];
    }
  }
}

/// one line in an extract journal.
class ExtractLine extends JrlLine {
  /// the value of the transaction
  int actSum = 0; //to store the intermediate sum of the account

  /// CTOR the fields are optional, if omitted they will be filled with defaults .
  ExtractLine({JrlLine? line, int sumup = 0}) {
    if(line != null) {
      datum = line.datum;
      kplus = line.kplus;
      kminus = line.kminus;
      desc = line.desc;
      cur = line.cur;
      valuta = line.valuta;
      limits = line.limits;
    }
    actSum = (sumup != null) ? sumup : 0;
  }

  /// pretty print this thing .
  @override
  String toString() {
    var f = NumberFormat.currency(symbol: cur2sym(cur));
    String result = "${super.toString()} ${sprintf("%12s", [
          f.format((actSum / 100).toDouble())
        ])}";
    return result;
  }

}

/// Book class, holds an accountplan and a journal.
///
/// Is able to propagate the analysis aof the account data
/// groups together the toString to be able to print everything directly from here

class Book {
  KontoPlan kpl = KontoPlan();
  late Journal jrl;
  Map<String,dynamic> ops = {};

  ///CTOR if no accountplan is given initializes with aen empty one
  Book({kpl, jrl}) {
    if (kpl != null) this.kpl = kpl;
    if (jrl == null) this.jrl = Journal(this.kpl);
  }

  /// toString.
  ///
  ///when extracts is activated, prints out all the extracts for the plan,
  /// otherwise prints plan and journal.
  @override
  String toString({bool extracts = false}) {
    String result = "";
    if (kpl != null) result += kpl.toString() + "\n";
    if (jrl != null) result += jrl.toString();
    if (kpl != null && extracts) {
      result += "\n";
      result += kpl.toString(extracts: true) + "\n";
    }
    return result;
  }

  ///clear.
  ///
  /// empties the book.
  Book clear() {
    kpl.clear();
    jrl.clear();
    return this;
  }

  /// launches the analyze of the data.
  Book execute() {
    jrl.execute();
    return this;
  }
} //class Book
