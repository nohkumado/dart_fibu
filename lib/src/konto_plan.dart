import 'dart:collection';

import '../nohfibu.dart';

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
  Konto? get(String ktoName, {debug = false}) {
    if (debug) {
      print("kto: get for '$ktoName'");
      throw Exception("Arghhh....");
    }
    if (konten.containsKey(ktoName)) {
      if (debug) print("direct match $ktoName returning ${konten[ktoName]}");
      return konten[ktoName];
    }
    if (debug) print("kto get no $ktoName in ${konten.keys.toList()}");
    //but maybe we must recurse?
    if (ktoName.length > 1) {
      String key = ktoName[0];
      String subkey = ktoName.substring(1);
      if (debug)
        print("name is long enough.... extracted key $key and $subkey");
      if (konten.containsKey(key)) {
        if (debug) print("returning ${konten[key]!.get(subkey, debug: debug)}");
        return konten[key]!.get(subkey);
      } else {
        if (debug) print("no $key in  ${konten.keys.toList()}");
      }
      if (debug) print("ktop but konten doesn't contain $key");
      return null;
    }
    if (debug) print("kto far enough no lolly");
    return null;
  }

  /// Adds or updates an account in the plan.
  /// The account is added to the tree structure.
  /// set at ktoName (Treewise) the data if kto (kto will be discarded afterwards) create the account if needed .
  Konto put(String ktoName, Konto kto, {debug = false}) {
    if (debug) print("KPL:PUT DEBUG FOR $ktoName and $kto ");
    if (ktoName.length < 1)
      print("Error, KPL, don't know how to add $kto @ $ktoName");
    else if (ktoName.length == 1) {
      if (debug)
        print(
            "KPL: single digit name, adding to $ktoName $kto to ${konten.keys}");
      konten[ktoName] = kto;
      if (kto.number == "-1") kto.number = ktoName;
    } else {
      String key = ktoName[0];
      String rest = ktoName.substring(1, ktoName.length);
      if (debug) print("KPL:split name, to $key and $rest");
      if (!konten.containsKey(key)) {
        if (debug)
          print("KPL: adding new intermediary Kto $key ${konten[key]}");
        konten[key] = Konto(
            number: key, name: '$key', plan: this, prefix: "", debug: debug);
      }
      if (debug) print("KPL: deving into Kto $key ${rest} amd $kto");
      konten[key]!.put(rest, kto, debug: debug, prefix: "$key");
      if (kto.number == "-1")
        kto.number = kto.name; //this is now a valid account!
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
  String toString({bool extracts = false, astree = false, recursive = true}) {
    String result = "              Konto Plan \n";
    konten.forEach((key, kto) {
      result +=
          kto.toString(recursive: true, extracts: extracts, astree: astree) +
              "\n";
    });
    result += "         Ende Konto Plan \n";
    //print("extracted +$ktoName+  -$desc- ,=$w=,  '$budget' #$valuta#\n");
    //return "$number $name $desc $cur $valuta $budget";
    return (result);
  }

  /// Exports the account plan as a list, useful for CSV export.
  List<List<dynamic>> asList(
      {bool all = false, bool silent = false, formatted = false}) {
    List<List<dynamic>> asList = (silent)
        ? []
        : [
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
    if (get("1") == null ||
        get("2") == null ||
        get("3") == null ||
        get("4") == null)
      throw Exception("Invalid account plan, no analysis possible");

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
  List<Konto> getRange(Map<String, String> minmax, {List<Konto>? passthrough}) {
    List<Konto> result = (passthrough != null) ? passthrough : [];
    String min = (minmax.containsKey("min")) ? minmax["min"]!.trim() : "0";
    String max = (minmax.containsKey("max")) ? minmax["max"]!.trim() : "0";

    ///Attention if accounts are spanning blocks....!
    if (min[0] != max[0]) {
      for (String root in konten.keys) {
        // Convert strings to integers for numerical comparison
        int rootInt = int.parse(root);
        int minInt = int.parse(min[0]);
        int maxInt = int.parse(max[0]);

        if (rootInt < minInt) continue;
        if (rootInt > maxInt) break;
        Konto parent = konten[root] ?? Konto(plan: this);
        parent.getRange(min.substring(1), max.substring(1),
            passthrough: result);
      }
    } else {
      //select common part
      int n = 0;
      while (min[n] == max[n]) n++;
      String common = min.substring(0, n);
      if (common.isEmpty) common = min;
      Konto parent = (get(common) == null) ? Konto(plan: this) : get(common)!;
      parent.getRange(min.substring(n), max.substring(n), passthrough: result);
    }
    return result;
  }

  KontoPlan clone({bool resetValuta = false}) {
    KontoPlan result = KontoPlan();
    konten.forEach((key, value) {
      result.konten[key] = value.clone(plan: result, resetValuta: resetValuta);
    });
    return result;
  }

  //check the presence of an account, if not add it
  void check(Konto konto, {bool debug = false}) {
    if (debug)
      print("Checking KPL ${toString()} adding '$konto' '${get(konto.name)}'");
    if (konto.name == "no name")
      print("ERROR, can't check noname accounts!!!");
    else if (get(konto.name) == null) {
      put(konto.name, konto, debug: debug);
      if (debug) print("KPL after put ${toString()}'${konten}'");
    }
  }
}
