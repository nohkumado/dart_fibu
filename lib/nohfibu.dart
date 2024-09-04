import 'package:expressions/expressions.dart';
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
  Konto? get(String ktoName,{debug = false}) {
    if(debug) {print("kto: get for '$ktoName'"); throw Exception("Arghhh....");}
    if (konten.containsKey(ktoName)) {
      if(debug) print("direct match $ktoName returning ${konten[ktoName]}");
      return konten[ktoName];
    }
    if(debug) print("kto get no $ktoName in ${konten.keys.toList()}");
    //but maybe we must recurse?
    if (ktoName.length > 1) {
      String key = ktoName[0];
      String subkey = ktoName.substring(1);
      if(debug) print("name is long enough.... extracted key $key and $subkey");
      if (konten.containsKey(key)) {
        if(debug) print("returning ${konten[key]!.get(subkey,debug:debug)}");
        return konten[key]!.get(subkey);
      }
      else
      {
        if(debug) print("no $key in  ${konten.keys.toList()}");

      }
      if(debug) print("ktop but konten doesn't contain $key");
      return null;
    }
    if(debug) print("kto far enough no lolly");
    return null;
  }

  /// set at ktoName (Treewise) the data if kto (kto will be discarded afterwards) create the account if needed .
  Konto put(String ktoName, Konto kto,{debug =false}) {
    if(debug) print("KPL:PUT DEBUG FOR $ktoName and $kto ");
    if (ktoName.length < 1)
      print("Error, KPL, don't know how to add $kto @ $ktoName");
    else if (ktoName.length == 1) {
      if(debug)print("KPL: single digit name, adding to $ktoName $kto to ${konten.keys}");
      konten[ktoName] = kto;
    }
    else {
      String key = ktoName[0];
      String rest = ktoName.substring(1, ktoName.length);
      if(debug)print("KPL:split name, to $key and $rest");
      if (!konten.containsKey(key)) {
        if(debug)print("KPL: adding new intermediary Kto $key");
        konten[key] = Konto(number: key, name: '$key', plan: this,prefix:"");
      }
      konten[key]!.put(rest,kto,debug:debug, prefix:"$key");
      ////fetch the account, creating it on the way
      //if(debug)print("going into get $key, rest ");
      //var locK = konten[key]!.get(rest, orgName: ktoName, debug: debug,kto:kto);
      //locK.name = kto.name;
      //locK.plan = this;
      //locK.desc = kto.desc;
      //locK.cur = kto.cur;
      //locK.budget = kto.budget;
      //locK.valuta = kto.valuta;
      //kto = locK;
    }
    return kto;
  }

  /// pretty print this thing .
  @override
  String toString({bool extracts = false,astree =false, recursive =true}) {
    String result = "              Konto Plan \n";
    konten.forEach((key, kto) {
      result += kto.toString(recursive: true, extracts: extracts,astree:astree) + "\n";
    });
    result += "         Ende Konto Plan \n";
    //print("extracted +$ktoName+  -$desc- ,=$w=,  '$budget' #$valuta#\n");
    //return "$number $name $desc $cur $valuta $budget";
    return (result);
  }

  /// return this as a list
  ///  used for exporting the data .
  List<List<dynamic>> asList({bool all = false, bool silent = false, formatted =false}) {
    List<List<dynamic>> asList = (silent)? []:[
      ["KPL"],
      ["kto", "dsc", "cur", "budget", "valuta"]
    ];
    konten.forEach((key, value) {
      value.asList(asList: asList, all: all, formatted: formatted);
    });
    return asList;
  }

  /// run the analysis, comparing the 4 blocs against each other to see if the data is valid
  String analysis() {
    if(get("1") == null ||get("2")== null ||get("3")== null ||get("4")== null) throw Exception("Invalid account plan, no analysis possible");

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
  List<Konto> getRange(Map<String,String> minmax,{List<Konto>? passthrough} )
  {
    List<Konto> result = (passthrough != null)? passthrough:[];
    String min =(minmax.containsKey("min"))?minmax["min"]!.trim():"0";
    String max =(minmax.containsKey("max"))?minmax["max"]!.trim():"0";
    //print("in getRange : $minmax, '$min'-'$max' from ${konten.keys}");
    //select common part
    int n =0;
    while(min[n] == max[n]) n++;
    String common = min.substring(0,n);
    Konto parent = (get(common)==null)?Konto():get(common)!;
    //print("common : $n=> '$common'; kto: ${parent.desc} ${parent.children.keys}");
    parent.getRange(min.substring(n),max.substring(n),passthrough:result);
    return result;
  }
}

/// one account .
class Konto {
  String number = "-1";
  String prefix = "";
  String desc = "";
  KontoPlan plan = KontoPlan();
  String cur = "EUR"; //currency
  int valuta = 0;
  int budget = 0;
  SplayTreeMap<String, Konto> children = SplayTreeMap<String, Konto>();

  String name = "no name";
  late Journal extract;

  ///CTOR where you can specify
  ///   the number of the account,
  ///   its name (the number is recursively consumed)
  ///   to which account plan it relates
  ///   valute the actual value in the account
  ///   budget a theoretical value that lapsed should generate warnings .
  Konto({number, name = "kein Name", desc, plan, valuta, cur, budget, String prefix =""}) {
    //set(number,name, plan, desc, valuta, cur, budget);
    if (number != null) this.number = number;
    if (prefix.isNotEmpty ) {
      //print("set prefix for $number/$name as $prefix");
      this.prefix = prefix;
    }
    if (name != null && name != "kein Name") this.name = name;
    if (desc != null) this.desc = desc;
    if (cur != null) this.cur = cur;
    if (valuta != null) this.valuta = (valuta is double)? valuta.toInt():valuta;
    if (budget != null) this.budget = (budget is double)? budget.toInt():budget;
    if (this.number.isEmpty) this.number = name[name.length - 1];
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
    if (this.number.isEmpty) this.number = name[name.length - 1];
    return this;
  }

  /// get the target account, by descending into the tree of accounts
  /// null safe, if no account was found a dummy one is generated .
  Konto get(String ktoName, {String orgName = "undef",debug = false, Konto? kto}) {
    if (orgName == "undef") orgName = ktoName;
    if (name.length == 1 && (name == ktoName && orgName == name)) {
      if(debug) print("returning myself");
      return this;
    } else if (children.containsKey(ktoName)) {
      if(debug) print("found key in children, returning child");
      return children[ktoName]!;
    } else if (!children.containsKey(ktoName) && ktoName.length > 1) {
      //maybe recurse?
      String key = ktoName[0];
      String rest = ktoName.substring(1);
      if(debug) print("$ktoName not found, split $key and $rest recurse?");
      if (!children.containsKey(key)) {
        if(debug) print("created 2 $key  ");
        children[key] = Konto(number: key, plan: this);
      }
      if(debug) print("child found $key  in recursing");
      return children[key]!.get(rest, orgName: orgName,debug: debug);
      // if(key !=number) //study more, o how to cope with unrelated names
      // {
      //   //orgName = name+orgName;
      // print("ehm  $ktoName differs from me ($number) .... rewriting orgName to $orgName" );
      // }
      return children[key]!.get(ktoName.substring(1), orgName: orgName,debug: debug);
/*
      if (ktoName.startsWith(name)) {
        rest = ktoName.substring(name.length);
        key = rest[0];
        rest = rest.substring(1);
        if(debug) print("$ktoName starts with name, trying with $key and $rest");
        if (rest.length <= 0) {
          if(debug) print("created $key  name=$orgName");
          children[key] = Konto(number: key, name: orgName);
          return children[key]!;
        }
      }
*/
    }
    if(debug) print("created 3 $ktoName  $orgName");
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
        bool extracts = false, astree = false}) {
    String result = "";
    if(astree) result += "{name}";
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
          : (recursive && !empty && desc.isEmpty)
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
  List<List> asList({List<List> asList = const [], bool all = false, formatted =false}) {
    //print("$number $name $desc tries to add to list");
    var f = NumberFormat.currency(symbol: cur2sym(cur));

    var budgetS = (formatted)? "${sprintf("%12s", [f.format(budget/100)])}": budget;
    var valutaS = (formatted)? "${sprintf("%12s", [f.format(valuta/100)])}": valuta;
    if (name == "no name" && desc.length > 0)
      asList.add([number, desc, cur, budgetS, valutaS]);
    else if (desc.length > 0) asList.add([name, desc, cur, budgetS, valutaS]);
    if (all) asList.add([name, desc, cur, budgetS, valutaS]);
    children.forEach((key, value) {
      value.asList(asList: asList, formatted: formatted);
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
    //ExtractLine sline = ExtractLine(line: line, sumup: valuta);
    //print("$name adding to $extract \n $sline");
    extract.add(ExtractLine(line: line, sumup: valuta));
    var f = NumberFormat.currency(symbol: cur2sym(cur));
    String title = "  Extract for $name  ";
    int tofill = (95 - title.length) ~/ 2;
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
  List<Konto> getRange(String min,String max,{List<Konto>? passthrough} )
  {
    List<Konto> result = (passthrough!= null)?passthrough:[];
    //print("searching for $min to $max in $name/$children");
    if(children.length == 0) {
      //print("ehm.... '$name,$desc'  missed something somewhere..... adding ourselves??");
      result.add(this);
    }
    else if(min.length == 1)
    {
      children.forEach((key, val) { if((key.compareTo(min) >=0) && (max == "all" || key.compareTo(max) <=0))
      {
        result.add(val);
        //print("added direct ${val.desc}");
      }});
    }
    else if(min =="all" )
    {
      //print("adding all children ");
      children.forEach((key, val) { if(max == "all" || key.compareTo(max) <=0) {if(val.children.length <=0)
      {
        //print("val has no children adding $key ${val.desc}");
        result.add(val);
      }
      else
      {
        //print("val has  ${val.children} diving from ${val.desc}");
        val.getRange("all","all",passthrough:result);
      }}});
    }
    else if(min.length > 1)
    {
      String keyMin = min[0];
      String keyMax = max[0];
      String restMin = min.substring(1);
      String restMax = max.substring(1);
      //print("$name need to recurse deeper [$keyMin, $keyMax] [$restMin, $restMax]...");
      children.forEach((key, val)
      {
        if(key.compareTo(keyMin) ==0) {
          //print("entering $key for $restMin to all");
          val.getRange(restMin,"all",passthrough:result);}
        else if(key.compareTo(keyMin) >0 && key.compareTo(keyMax) <0){
          //print("entering $key for all");
          val.getRange("all","all",passthrough:result);}
        else if(key.compareTo(keyMin) >0 && key.compareTo(keyMax) ==0){
          //print("entering $key for all to $restMax");
          val.getRange("all",restMax,passthrough:result);}
        //else print("should bee: $key < $min or $key > $max, so ignore it");
      }

      );
    }
    else
      print("Konto Error, nevershould be here");
    return result;
  }

  Konto put(String ktoName, Konto kto, {debug =false, String prefix =""}) {

    if(debug) print("KTO[${name}] PUT DEBUG FOR $ktoName and $kto");
    if (ktoName.length < 1)
      print("Error, KTO, don't know how to add $kto @ $ktoName");
    else if (ktoName.length == 1) {
      if(debug)print("KTO single digit name, atting to $ktoName $kto children now: $children");
      children[ktoName] = kto;
      if(debug)print("KTO children added: $children");
    }
    else {
      String key = ktoName[0];
      prefix += key;
      String rest = ktoName.substring(1, ktoName.length);
      if(debug)print("split name, to $key and $rest");
      if (!children.containsKey(key)) {
        children[key] = Konto(number: key, name: prefix,plan: this);
        if(debug)print("adding new intermediary Kto $key : ${children[key]}");
      }
      if(debug) print("should be calling on $key put for $rest");
      children[key]!.put(rest,kto,debug:debug,prefix: prefix);
    }
    return kto;
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
  List<List> asList(List<List> data, { bool silent = false, bool formatted = false}) {
    if(!silent)data.add(["JRL"]);
    if(!silent)data.add(["date", "ktominus", "ktoplus", "desc", "cur", "valuta", "actSum"]);
    journal.forEach((line) {
      line.asList(data, formatted: formatted);
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
      //print("executing exe for $line");
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
  late Konto _kplus;

  /// the account to be credited
  late Konto _kminus;

  ///  description of the transaction
  late String desc;

  /// the currency of the transaction
  late String cur;

  /// the value of the transaction
  late int valuta;
  ///eventual constraints on the input to the journal
  Map? limits;

  Map<String, dynamic> vars = {};

  Expression? valexp ;

  String? valname;

  /// CTOR the fields are optional, if omitted they will be filled with defaults .
  JrlLine({datum, kmin, kplu, desc, cur, valuta}) {
    // print("jline incoming +$datum+ -$kmin- -$kplu- -$desc- ,=$cur=, #$valuta#\n");
    _kplus = (kplu != null) ? kplu : Konto();
    _kminus = (kmin != null) ? kmin : Konto();
    this.desc = (desc != null) ? desc : "none";
    this.datum = (datum != null) ? datum : DateTime.now();
    this.cur = (cur != null) ? cur : "EUR";

    if(valuta == null) this.valuta = 0;
    else
    switch(valuta.runtimeType)
    {
      case int: this.valuta = valuta;break;
      case double:
        if(valuta != valuta.roundToDouble()) {
          this.valuta = (valuta*100).toInt(); //if there is a decimal point in, the user went wrong and didn't give centsbut euros
        } else {
          this.valuta = valuta.toInt();
        }
        break;
      case String:
       double tmpVal = (double.tryParse(valuta.replaceAll(",", ""))??-1);
       if(tmpVal != tmpVal.roundToDouble()) {
         this.valuta = (tmpVal*100).toInt(); //if there is a decimal point in, the user went wrong and didn't give centsbut euros
       } else {
         this.valuta = tmpVal.toInt();
       }
         break;
      default: print("dont know how to handle valuta ${valuta.runtimeType}");
    }
    if(this.valuta == -1 && "${this.valuta}" != "$valuta") print("JrLine ERROR in parsing valuta!! $valuta unparsable");
    //this.valuta = (valuta != null) ? (valuta is double)? valuta.toInt():valuta : 0;
  }

  /// pretty print this thing .
  @override
  String toString() {
    final DateFormat formatter = DateFormat('dd-MM-yyyy');
    final String formatted = formatter.format(datum);
    var f = NumberFormat.currency(symbol: cur2sym(cur));
    double valAsd = valuta / 100;

    String result =
        "$formatted ${_kminus.printname()} ${_kplus.printname()} ${sprintf("%-49s", [ desc ])} ${sprintf("%12s", [f.format(valAsd)])}";
    return result;
  }

  /// return a list abstraction model of this object .
  void asList(List<List> data,{bool formatted = false}) {
    final DateFormat formatter = DateFormat('yyyy-MM-dd');
    final String date = formatter.format(datum);
    var f = NumberFormat.currency(symbol: cur2sym(cur));

    var valutaS = (formatted)? "${sprintf("%12s", [f.format(valuta/100)])}": valuta;
    data.add(
        [date, _kminus.printname(), _kplus.printname(), "$desc", cur, valutaS]);
  }

  /// ask the 2 accounts to add this line to their extracts.
  JrlLine execute() {
    _kminus.action(this, mode: "sub");
    _kplus.action(this, mode: "add");
    return this;
  }
  void addConstraint(String key,{ List<String> boundaries = const [], String mode = ""})
  {
    if(limits == null) limits = {"kmin": {"min": "-1", "max": "1000000"},"kplu": {"min": "-1", "max": "1000000"}};

    if(key == "kmin"||key == "kplu") {
      if (boundaries.length == 0 || boundaries.length < 2) {
        print("boundaries($boundaries) needs to hold to vals, min, max");
        return;
      }

      if (key == "kmin") {
        //limits!["kmin"]["min"] = int.parse(boundaries[0]);
        // //limits!["kmin"]["max"] = int.parse(boundaries[1]);
        limits!["kmin"]["min"] = boundaries[0];
        limits!["kmin"]["max"] = boundaries[1];
      }
      else if (key == "kplu") {
        limits!["kplu"]["min"] = boundaries[0];
        limits!["kplu"]["max"] = boundaries[1];
      }
    }
    else if(key == "mode") this.vars["mode"] = mode;
  }
  /// getter for kminus and kplus
  Konto get kminus  => _kminus;
  Konto get kplus  => _kplus;
  /// we need to check if we have the right to change the account, otherwise leave it as is, in the framework you need to check if the value changed....
  set kminus (Konto other)
  {
    if(limits== null ) _kminus = other;
    else
    {
      int otherint = (int.tryParse(other.name) != null)?int.tryParse(other.name)!:0;
      int min = (limits!["kmin"].containsKey("min"))?int.tryParse(limits!["kmin"]["min"])!:0;
      int max = (limits!["kmin"].containsKey("max"))?int.tryParse(limits!["kmin"]["max"])!:0;

      if(min<= 0 && max >=1000000 ) _kminus = other;//{print("invalid ranges : changing value");}
      else if(min<= otherint && max >=otherint ) _kminus = other;//{print("inside range, change!");}
      else print("Error setting kminus :invalid range... unchanged");
    }
  }
  set kplus (Konto other)
  {
    if(limits== null ) _kplus = other;
    else
    {
      int otherint = (int.tryParse(other.name) != null)?int.tryParse(other.name)!:0;
      int min = (limits!["kplu"].containsKey("min"))?int.tryParse(limits!["kplu"]["min"])!:0;
      int max = (limits!["kplu"].containsKey("max"))?int.tryParse(limits!["kplu"]["max"])!:0;

      if(min== 0 && max ==1000000 ) _kplus = other;//{print("invalid ranges : changing value");}
      else if(min<= otherint && max >=otherint ) _kplus = other;//{print("inside range, change!");}
      else print("Error setting kplus :invalid range... unchanged");
    }
  }

  void setValuta(String toParse, {bool debug = false})
  {
    toParse = toParse.trim().replaceAll('\.', '');
    if(debug)print("aboutto number parse '$toParse' ser");

    valuta = (toParse.isNotEmpty)?(NumberFormat.currency().tryParse(toParse)??0 * 100).toInt():0;
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
    actSum =  sumup ;
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
  /// return a list abstraction model of this object .
  void asList(List<List> data,{bool formatted = false}) {
    final DateFormat formatter = DateFormat('yyyy-MM-dd');
    final String date = formatter.format(datum);
    var f = NumberFormat.currency(symbol: cur2sym(cur));
    var valutaS = (formatted)? "${sprintf("%12s", [f.format(valuta/100)])}": valuta;
    var actSumS = (formatted)? "${sprintf("%12s", [f.format(actSum/100)])}": actSum;
    data.add(
        [date, _kminus.printname(), _kplus.printname(), "$desc", cur, valutaS,actSumS]);
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

  String name = "a Book";

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
    result += kpl.toString() + "\n";
    result += jrl.toString();
    if (extracts) {
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
