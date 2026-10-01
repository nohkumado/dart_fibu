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
            ["kto", "dsc", "cur", "budget", "valuta", "role"]
          ];
    konten.forEach((key, value) {
      value.asList(asList: asList, all: all, formatted: formatted);
    });
    return asList;
  }

  /// Every real account of the plan (the tree's nodes with a description,
  /// headings left out), in account order.
  List<Konto> accounts() {
    final out = <Konto>[];
    void walk(Konto k) {
      if (k.desc.trim().isNotEmpty && !k.heading) out.add(k);
      for (final child in k.children.values) {
        walk(child);
      }
    }

    for (final k in konten.values) {
      walk(k);
    }
    return out;
  }

  /// The accounts with [role].
  List<Konto> withRole(AccountType role) =>
      accounts().where((k) => k.accountType == role).toList();

  /// Assets, liabilities, expenses and income by the accounts' roles, with
  /// their sums and the check that both results agree (must be 0). Works
  /// for any chart: the roles, not the blocks, decide.
  String analysis() {
    String result = "=" * 30 + "    Analysis    " + "=" * 30 + "\n";
    final format = Konto();
    int section(String title, AccountType role, String total) {
      final list = withRole(role);
      result += "$title\n";
      for (final k in list) {
        result += "${k.toString(recursive: false)}\n";
      }
      final sum = list.fold(0, (s, k) => s + k.valuta);
      result += " " * 60 + "$total ${format.numFormat(sum)}\n";
      return sum;
    }

    // one sign rule for every account (the plus side gains): liabilities
    // and income stand negative, all balances together make 0
    final sumActiva = section("Aktiva", AccountType.Actif, "Aktiva insgesamt");
    final sumPassiva = section("Passiva", AccountType.Passif, "Passiva insgesamt");
    result += " " * 60 + "Ueberschuss ${format.numFormat(sumActiva + sumPassiva)}\n";
    final sumKosten = section("Kosten", AccountType.Charge, "Kosten insgesamt");
    final sumEinnahmen = section("Einnahmen", AccountType.Produit, "Einnahmen insgesamt");
    result += " " * 60 + "Ueberschuss ${format.numFormat(-(sumEinnahmen + sumKosten))}\n";
    result += " " * 50 +
        "Gueltigkeit (muss 0 sein) ${format.numFormat(sumActiva + sumPassiva + sumKosten + sumEinnahmen)}\n";
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
