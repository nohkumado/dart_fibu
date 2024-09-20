import 'package:expressions/expressions.dart';
import 'package:intl/intl.dart';
import 'package:sprintf/sprintf.dart';
import 'dart:collection';

//Enum to set mode
enum Mode {add,sub}
/// Converts currency code to its corresponding symbol.
/// Supported currencies include EUR, GBP, USD, YEN, and LIR.
/// Defaults to € if the currency is unrecognized.
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

/// Represents the account plan in the accounting system.
/// It organizes accounts and allows for tree-like structures of accounts.
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

  /// Retrieves the account by its name.
  /// Supports recursive lookup based on the tree structure.
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

  /// Adds or updates an account in the plan.
  /// The account is added to the tree structure.
  /// set at ktoName (Treewise) the data if kto (kto will be discarded afterwards) create the account if needed .
  Konto put(String ktoName, Konto kto,{debug =false}) {
    if(debug) print("KPL:PUT DEBUG FOR $ktoName and $kto ");
    if (ktoName.length < 1)
      print("Error, KPL, don't know how to add $kto @ $ktoName");
    else if (ktoName.length == 1) {
      if(debug)print("KPL: single digit name, adding to $ktoName $kto to ${konten.keys}");
      konten[ktoName] = kto;
      if(kto.number == "-1") kto.number = ktoName;
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
      if(kto.number == "-1") kto.number = kto.name; //this is now a valid account!
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

  /// Returns a string representation of the account plan.
  /// Can print the accounts recursively or non-recursively.
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

  /// Exports the account plan as a list, useful for CSV export.
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

  /// Analyzes the account plan, comparing different account groups.
  /// Ensures that the data is consistent across activas, passivas, incomes, and costs.
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
  /// Retrieves a range of accounts based on the provided `min` and `max` boundaries.
  /// This is useful for exporting or processing a subset of accounts.
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

  KontoPlan clone({bool resetValuta = false})
  {
    KontoPlan result = KontoPlan();
    konten.forEach((key, value) {
      result.konten[key] = value.clone(plan:result, resetValuta: resetValuta);
    });
    return result;

  }
}

/// one account .
/// Represents an account in the accounting system.
/// Each account has properties such as a name, valuta (amount), and a budget.
class Konto {
  String number = "-1"; /// The account number.
  String prefix = ""; /// The prefix for the account (used in hierarchical accounts).
  String desc = ""; /// The description of the account.
  KontoPlan plan = KontoPlan(); /// The associated account plan.
  String cur = "EUR"; /// The currency for the account (e.g., EUR).
  int valuta = 0; /// The current balance of the account.
  int budget = 0; /// The budget allocated to the account.
  SplayTreeMap<String, Konto> children = SplayTreeMap<String, Konto>(); /// The children accounts under this account (for tree-like structures).

  String name = "no name"; /// The name of the account, usually the number in string format
  late Journal extract; /// The account's extract (journal of transactions for this account).

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
      //return children[key]!.get(ktoName.substring(1), orgName: orgName,debug: debug);
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

  /// pretty print the account name, old WB style fibu had 4 char wide account fields...  .
  printname() {
    String fn = (name == "no name") ? "0" : name;
    return (sprintf("%#4s", [fn]));
  }

  /// return this thins as a list, recurse through the tree
  ///preparation for e.g. csv conversion .
  List<List> asList({List<List>? asList, bool all = false, formatted =false}) {
    if(asList == null) asList = [];
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
  Konto action(JrlLine line, {Mode mode = Mode.add}) {
    //ggnint oldval = valuta;
    if (mode == Mode.add)
      valuta += line.valuta;
    else
      valuta -= line.valuta;
    //print("Line s valuta : ${line.valuta} valuta went from $oldval to $valuta");
    //print("action for  $name ($mode) add line ${line.desc} and $valuta : $line");
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

  /// Formats a number into a currency string.
  String numFormat(int toConvert) {
    var f = NumberFormat.currency(symbol: cur2sym(cur));
    double valAsd = toConvert / 100;
    String result = "${sprintf("%12s", [f.format(valAsd)])}\n";
    return result;
  }

  /// Recursively sums up the valutas of the account and all its subaccounts.
  int sum() {
    int mysum = valuta;
    children.forEach((key, value) {
      mysum += value.sum();
    });
    return mysum;
  }
  
  /// Returns a list of accounts in the given range, all by default
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

  ///add an account to the children
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
/// Returns true if the accunt is valid
  bool valid({bool debug = false})
  {
    bool valid = true;
    if (number == "-1") {
      if(debug) print("Kto number not valid");
      valid = false;
    }
    if (name == "no name" || name == "kein Name") {
      if(debug) print("Kto name not valid");
      valid = false;
    }
    if (valuta ==  JrlLine.maxValue) {
      if(debug) print("Kto valuta not valid");
      valid = false;
    }
    return valid;
  }

  bool isNotValid({bool debug = false}) => !valid(debug:debug);

  ///Returns true if this Konto has the same name and description as the other one
  bool equals(Konto other)
  {
    if(isNotValid()) return false; //invalidate all non-valid accounts
    if (name != other.name) return false;
    if (number != other.number) return false;
    if (desc != other.desc) return false;
    //if (valuta != other.valuta) return false;
    return true;

  }
/// Creates a deep copy of the current `Konto` object.
///
/// If a new `plan` is provided, the cloned `Konto` will use it; otherwise, it will use the existing plan.
///
/// The method also recursively clones all child `Konto` objects, if any.
  Konto clone({KontoPlan? plan, bool resetValuta = false})
  {
    Konto clone = Konto(number: number, name: name, desc: desc, valuta: resetValuta?0:valuta, plan: (plan != null)?plan:this.plan);
    // Using forEach for iterating over children
    children.forEach((childName, child) {
      clone.children[childName] = child.clone(plan: plan, resetValuta: resetValuta);
    });
    return  clone;
  }
  Konto getSmallest()
  {
    if(children.isEmpty) return this;
    return children.entries.first.value.getSmallest();
  }
}

/// This class hold a list of lines, each caracterising an entry in an accounting journal.
class Journal {
  late KontoPlan kpl;/// The associated account plan.
  String caption = "Journal"; /// The caption for the journal.
  String endcaption = "Journal End"; /// The ending caption for the journal.
  List<JrlLine> journal = []; /// The list of journal entries.

  /// Constructor for initializing a journal with an account plan.
  Journal(this.kpl, {caption = "Journal", String end = "End"}) {
    //kpl = kpl;
    //if(caption != null)
    //{
    this.caption = caption;
    if (end == "End")
      endcaption = "$caption $end";
    else
      endcaption = "$end";
    //}
  }

  /// empty the journal.
  void clear() {
    journal.clear();
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
  final formatter = DateFormat('yyyy-MM-dd');
    caption = "Journal from ${formatter.format(minTime)} to ${formatter.format(maxTime)}";
    return this;
  }
}

/// Represents one line in an accounting journal.
class JrlLine {
  static const int maxValue = -1 >>> 1;
  late DateTime datum; /// the date of the transaction
  late Konto _kplus; /// the account to be taken from
  late Konto _kminus; /// the account to be credited
  late String desc; ///  description of the transaction
  late String cur; /// the currency of the transaction
  late int valuta; /// the value of the transaction
  Map? limits; ///eventual constraints on the input to the journal
  Map<String, dynamic> vars = {}; /// Stores additional variables for the transaction.
  Expression? valexp ; /// An optional expression for evaluating the value.
  String? valname; /// The tag for the expression (if any).

  /// Constructor for initializing a journal line.
  /// Optional fields will be filled with default values if omitted.
  JrlLine({DateTime? datum, Konto? kmin, Konto? kplu, String? desc, String? cur, valuta}) {
    // print("jline incoming +$datum+ -$kmin- -$kplu- -$desc- ,=$cur=, #$valuta#\n");
    _kplus = (kplu != null) ? kplu : Konto();
    _kminus = (kmin != null) ? kmin : Konto();
    this.desc = (desc != null) ? desc : "none";
    this.datum = (datum != null) ? datum : DateTime.now();
    this.cur = (cur != null) ? cur : "EUR";

    if(valuta == null) this.valuta = maxValue;
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
       if(this.valuta == -1 ) this.valuta = maxValue;
         break;
      default: print("dont know how to handle valuta ${valuta.runtimeType}");
      this.valuta = maxValue;
    }
    if(this.valuta == -1 && "${this.valuta}" != "$valuta") print("JrLine ERROR in parsing valuta!! $valuta unparsable");
    //this.valuta = (valuta != null) ? (valuta is double)? valuta.toInt():valuta : 0;
  }
  /// Gets the account to be debited (kminus).
  Konto get kminus  => _kminus;
  /// Gets the account to be credited (kplus).
  Konto get kplus  => _kplus;
  /// Sets the account to be debited (kminus) after validating constraints.
  /// we need to check if we have the right to change the account, otherwise leave it as is, in the framework you need to check if the value changed....
  set kminus (Konto other)
  {
    if(_isWithinRange(other, 'kmin')) {
      _kminus = other;
    } else
    {
      print("Error setting kminus :(${other.name}) invalid range ... unchanged ${_kminus.name}");
      //throw Exception('kminus is out of range.');
    }
  }
  /// Sets the account to be credited (kplus) after validating constraints.
  set kplus (Konto other)
  {
    if(_isWithinRange(other, 'kplu')) _kplus = other;
    else
    {
      print("Error setting kplus :(${other.name}) invalid range ... unchanged ${_kplus.name}");
      //throw Exception('kminus is out of range.');
    }
  }

  /// Sets the `valuta` of the transaction by parsing a string input.
  void setValuta(String toParse, {bool debug = false})
  {
    toParse = toParse.trim().replaceAll('\.', '');
    if(debug)print("aboutto number parse '$toParse' ser");

    valuta = (toParse.isNotEmpty)?(NumberFormat.currency().tryParse(toParse)??0 * 100).toInt():maxValue;
    if(valuta == maxValue) print("SetValuta parse error... shopuld thorw an exception here... :$toParse");
  }

  /// pretty print this thing .
 // @override
 // String toString() {
 //   final DateFormat formatter = DateFormat('dd-MM-yyyy');
 //   final String formatted = formatter.format(datum);
 //   var f = NumberFormat.currency(symbol: cur2sym(cur));
 //   double valAsd = valuta / 100;
 //
 //   String result =
 //       "$formatted ${_kminus.printname()} ${_kplus.printname()} ${sprintf("%-49s", [ desc ])} ${sprintf("%12s", [f.format(valAsd)])}";
 //   return result;
 // }
  /// Returns a string representation of the journal line.
  @override
  String toString() {
    final DateFormat formatter = DateFormat('dd-MM-yyyy');
    return _formattedDate(formatter) +
        _formattedAccounts() +
        _formattedDesc() +" " +
        _formattedValuta();
  }

  String _formattedDate(DateFormat formatter) {
    return formatter.format(datum) + ' ';
  }

  String _formattedAccounts() {
    return '${_kminus.printname()} ${_kplus.printname()} ';
  }

  String _formattedDesc() {
    return sprintf("%-49s", [desc]);
  }

  String _formattedValuta() {
    var f = NumberFormat.currency(symbol: cur2sym(cur));
    double valAsd = valuta / 100;
    return sprintf("%12s", [f.format(valAsd)]);
  }

  /// Converts the journal line to a list format.
  /// This is useful for exporting or processing the data.
  void asList(List<List> data,{bool formatted = false}) {
    final DateFormat formatter = DateFormat('yyyy-MM-dd');
    final String date = formatter.format(datum);
    var f = NumberFormat.currency(symbol: cur2sym(cur));

    var valutaS = (formatted)? "${sprintf("%12s", [f.format(valuta/100)])}": valuta;
    data.add(
        [date, _kminus.printname(), _kplus.printname(), "$desc", cur, valutaS]);
  }

  /// Executes the transaction by updating the accounts (`kminus` and `kplus`).
  ///
  /// The `valuta` value is added to `kplus` and subtracted from `kminus`.
  /// ask the 2 accounts to add this line to their extracts.
  /// Returns the `JrlLine` instance for chaining.
  JrlLine execute() {
    if(isNotValid()) {
      print("JrlLine exe Error: ${_kminus.printname()} ${_kplus.printname()} invalid:\n$_kminus\n$_kplus ${isNotValid(debug:true)}");
      throw Exception('kminus or kplus is not valid');
    }
    _kminus.action(this, mode: Mode.sub);
    _kplus.action(this, mode: Mode.add);
    return this;
  }
  /// Adds constraints to the transaction.
  void addConstraint(String key,{ List<String> boundaries = const [], String mode = ""})
  {
    if(limits == null) limits = {"kmin": {"min": "-1", "max": "1000000"},"kplu": {"min": "-1", "max": "1000000"}};

    if(key == "kmin"||key == "kplu") {
      if (boundaries.length == 0 || boundaries.length < 2) {
        print("boundaries($boundaries) needs to hold to vals, min, max");
        //consider  throw ArgumentError("Boundaries should contain at least two values, min and max");
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
  ///check if the konto is within the range
  bool _isWithinRange(Konto konto, String key) {
    //print("checking range: $limits vs ${konto.name}");
  if (limits == null) return true;
  int kontoValue = int.tryParse(konto.name) ?? 0;
  int min = int.tryParse(limits![key]["min"]) ?? 0-kontoValue;
  int max = int.tryParse(limits![key]["max"]) ?? kontoValue+100000;
    //print("limits found... cparoing $kontoValue inside $min and $max = ${(min <= kontoValue && max >= kontoValue)?'true':'false'}");
  return min <= kontoValue && max >= kontoValue;
}

  bool valid({bool debug=false}) {
    if(_kminus.isNotValid() || _kplus.isNotValid() || valuta == maxValue ) {
      if(debug) {
        if (_kminus.isNotValid(debug: true)) print("kminus is faulty");
        if (_kplus.isNotValid(debug: true)) print("kminus is faulty");
      }
      return false;
    }
    return true;
  }

  bool isNotValid({bool debug = false}) => !valid(debug: debug);
}

/// Represents one line in an extract journal.
class ExtractLine extends JrlLine {
  int actSum = 0; //to store the intermediate sum of the account

  /// Constructor for initializing an extract line.
  /// The fields are optional, if omitted they will be filled with defaults.
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

  /// Returns a string representation of the extract line.
  @override
  String toString() {
    var f = NumberFormat.currency(symbol: cur2sym(cur));
    String result = "${super.toString()} ${sprintf("%12s", [
      f.format((actSum / 100).toDouble())
    ])}";
    return result;
  }
  /// Converts the extract line to a list format.
  /// This is useful for exporting or processing the data.
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
