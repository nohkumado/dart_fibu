import 'package:intl/intl.dart';
import 'package:sprintf/sprintf.dart';
import 'dart:collection';

import '../nohfibu.dart';

/// one account .
/// Represents an account in the accounting system.
/// Each account has properties such as a name, valuta (amount), and a budget.
class Konto {
  String number = "-1";

  /// The account number.
  String prefix = "";

  /// The prefix for the account (used in hierarchical accounts).
  String desc = "";

  /// The description of the account.
  KontoPlan plan = KontoPlan();

  /// The associated account plan.
  String cur = "EUR";

  /// The currency for the account (e.g., EUR).
  int valuta = 0;

  /// The current balance of the account.
  int budget = 0;

  /// The budget allocated to the account.
  SplayTreeMap<String, Konto> children = SplayTreeMap<String, Konto>();

  /// The children accounts under this account (for tree-like structures).

  String name = "no name";

  /// The name of the account, usually the number in string format
  late Journal extract;

  /// The account's extract (journal of transactions for this account).
  /// The account's role (asset, liability, expense, income).
  late AccountType accountType;

  /// A heading of the plan (the old format's block lines like
  /// "1,*** fine degli conti attivi ***"): shown, never booked, not summed.
  bool heading = false;
  ///CTOR where you can specify
  ///   the number of the account,
  ///   its name (the number is recursively consumed)
  ///   to which account plan it relates
  ///   valute the actual value in the account
  ///   budget a theoretical value that lapsed should generate warnings .
  Konto(
      {number,
      name = "kein Name",
      desc,
      plan,
      valuta,
      cur,
      budget,
      String prefix = "",
      AccountType? accountType,
      bool debug = false}) {
    //set(number,name, plan, desc, valuta, cur, budget);
    if (number != null)
      this.number = number;
    else if (name != "kein Name") this.number = name;
    if (prefix.isNotEmpty) {
      //print("set prefix for $number/$name as $prefix");
      this.prefix = prefix;
    }
    if (name != null && name != "kein Name") this.name = name;
    if (desc != null) this.desc = desc;
    if (cur != null) this.cur = cur;
    if (valuta != null)
      this.valuta = (valuta is double) ? valuta.toInt() : valuta;
    if (budget != null)
      this.budget = (budget is double) ? budget.toInt() : budget;
    if (this.number.isEmpty) {
      if (name.length > 1)
        this.number = name[name.length - 1];
      else
        this.number = name;
    }
    // not given: the old block rule (first digit)
    this.accountType = accountType ?? AccountType.fromBlock(this.name == "no name" ? this.number : this.name);
    if (plan != null && plan is KontoPlan) this.plan = plan;
    //this.plan.check(this, debug: debug);
    //print("actual KPL: ${this.plan.toString(astree: true)}");
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
  Konto get(String ktoName,
      {String orgName = "undef", debug = false, Konto? kto}) {
    if (orgName == "undef") orgName = ktoName;
    if (name.length == 1 && (name == ktoName && orgName == name)) {
      if (debug) print("returning myself");
      return this;
    } else if (children.containsKey(ktoName)) {
      if (debug) print("found key in children, returning child");
      return children[ktoName]!;
    } else if (!children.containsKey(ktoName) && ktoName.length > 1) {
      //maybe recurse?
      String key = ktoName[0];
      String rest = ktoName.substring(1);
      if (debug) print("$ktoName not found, split $key and $rest recurse?");
      if (!children.containsKey(key)) {
        if (debug) print("created 2 $key  ");
        children[key] = Konto(number: key, plan: this);
      }
      if (debug) print("child found $key  in recursing");
      return children[key]!.get(rest, orgName: orgName, debug: debug);
      // if(key !=number) //study more, o how to cope with unrelated names
      // {
      //   //orgName = name+orgName;
      // print("ehm  $ktoName differs from me ($number) .... rewriting orgName to $orgName" );
      // }
      //return children[key]!.get(ktoName.substring(1), orgName: orgName,debug: debug);
    }
    if (debug) print("created 3 $ktoName  $orgName");
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
      bool extracts = false,
      astree = false}) {
    String result = "";
    if (astree) result += "{name}";
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
      // in the account's normal direction: no minus on liabilities/income
      double valAsd = balance / 100;
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

  /// The balance in the account's normal direction, as a person reads it:
  /// assets and expenses as debit balance, liabilities and income as credit
  /// balance — both positive when things are as usual; negative means the
  /// unusual side (an overdrawn bank account, a refund larger than the
  /// income). [valuta] keeps the booked sign (plus side gains), where all
  /// accounts together make exactly 0.
  int get balance => accountType.debitSide ? valuta : -valuta;

  /// The KPL's role column: the role, or `heading`.
  String get roleKey => heading ? "heading" : accountType.key;

  /// pretty print the account name, old WB style fibu had 4 char wide account fields...  .
  printname() {
    String fn = (name == "no name") ? "0" : name;
    return (sprintf("%#4s", [fn]));
  }

  /// return this thins as a list, recurse through the tree
  ///preparation for e.g. csv conversion .
  List<List> asList({List<List>? asList, bool all = false, formatted = false}) {
    if (asList == null) asList = [];
    //print("$number $name $desc tries to add to list");
    var f = NumberFormat.currency(symbol: cur2sym(cur));

    var budgetS =
        (formatted) ? "${sprintf("%12s", [f.format(budget / 100)])}" : budget;
    var valutaS =
        (formatted) ? "${sprintf("%12s", [f.format(valuta / 100)])}" : valuta;
    if (name == "no name" && desc.length > 0)
      asList.add([number, desc, cur, budgetS, valutaS, roleKey]);
    else if (desc.length > 0) asList.add([name, desc, cur, budgetS, valutaS, roleKey]);
    if (all) asList.add([name, desc, cur, budgetS, valutaS, roleKey]);
    children.forEach((key, value) {
      value.asList(asList: asList, formatted: formatted);
    });
    return asList;
  }

  /// Books [amount] on this account with the book's one sign rule: the
  /// plus side gains, the minus side loses — whatever the account's role.
  /// The role ([accountType]) only says how reports read the balance;
  /// changing the arithmetic by role would change every existing book.
  void updateBalance(int amount, {bool isAddition = true}) {
    valuta += isAddition ? amount : -amount;
  }

  /// add a journal line to our account extract, update the valuta .
  Konto action(JrlLine line, {Mode mode = Mode.add}) {
    //ggnint oldval = valuta;
    if (mode == Mode.add) {
      updateBalance(line.valuta, isAddition: true);
    } else {
      updateBalance(line.valuta, isAddition: false);
    }
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
  List<Konto> getRange(String min, String max, {List<Konto>? passthrough}) {
    List<Konto> result = (passthrough != null) ? passthrough : [];
    //print("searching for $min to $max in $name/$children");
    if (children.length == 0) {
      //print("ehm.... '$name,$desc'  missed something somewhere..... adding ourselves??");
      result.add(this);
    } else if (min.length == 1) {
      children.forEach((key, val) {
        if ((key.compareTo(min) >= 0) &&
            (max == "all" || key.compareTo(max) <= 0)) {
          result.add(val);
          //print("added direct ${val.desc}");
        }
      });
    } else if (min == "all") {
      //print("adding all children ");
      children.forEach((key, val) {
        if (max == "all" || key.compareTo(max) <= 0) {
          if (val.children.length <= 0) {
            //print("val has no children adding $key ${val.desc}");
            result.add(val);
          } else {
            //print("val has  ${val.children} diving from ${val.desc}");
            val.getRange("all", "all", passthrough: result);
          }
        }
      });
    } else if (min.length > 1) {
      String keyMin = min[0];
      String keyMax = max[0];
      String restMin = min.substring(1);
      String restMax = max.substring(1);
      //print("$name need to recurse deeper [$keyMin, $keyMax] [$restMin, $restMax]...");
      children.forEach((key, val) {
        if (key.compareTo(keyMin) == 0) {
          //print("entering $key for $restMin to all");
          val.getRange(restMin, "all", passthrough: result);
        } else if (key.compareTo(keyMin) > 0 && key.compareTo(keyMax) < 0) {
          //print("entering $key for all");
          val.getRange("all", "all", passthrough: result);
        } else if (key.compareTo(keyMin) > 0 && key.compareTo(keyMax) == 0) {
          //print("entering $key for all to $restMax");
          val.getRange("all", restMax, passthrough: result);
        }
        //else print("should bee: $key < $min or $key > $max, so ignore it");
      });
    } else
      print("Konto Error, nevershould be here");
    return result;
  }

  ///add an account to the children
  Konto put(String ktoName, Konto kto, {debug = false, String prefix = ""}) {
    if (debug) print("KTO[${name}] PUT DEBUG FOR $ktoName and $kto");
    if (ktoName.length < 1)
      print("Error, KTO, don't know how to add $kto @ $ktoName");
    else if (ktoName.length == 1) {
      if (debug)
        print(
            "KTO single digit name, atting to $ktoName $kto children now: $children");
      children[ktoName] = kto;
      if (debug) print("KTO children added: $children");
    } else {
      String key = ktoName[0];
      prefix += key;
      String rest = ktoName.substring(1, ktoName.length);
      if (debug) print("split name, to $key and $rest");
      if (!children.containsKey(key)) {
        children[key] = Konto(number: key, name: prefix, plan: this);
        if (debug) print("adding new intermediary Kto $key : ${children[key]}");
      }
      if (debug) print("should be calling on $key put for $rest");
      children[key]!.put(rest, kto, debug: debug, prefix: prefix);
    }
    return kto;
  }

  /// Returns true if the accunt is valid
  bool valid({bool debug = false}) {
    bool valid = true;
    if (number == "-1") {
      if (debug) print("Kto number not valid");
      valid = false;
    }
    if (name == "no name" || name == "kein Name") {
      if (debug) print("Kto name not valid");
      valid = false;
    }
    if (valuta == JrlLine.maxValue) {
      if (debug) print("Kto valuta not valid");
      valid = false;
    }
    return valid;
  }

  bool isNotValid({bool debug = false}) => !valid(debug: debug);

  ///Returns true if this Konto has the same name and description as the other one
  bool equals(Konto other) {
    if (isNotValid()) return false; //invalidate all non-valid accounts
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
  Konto clone({KontoPlan? plan, bool resetValuta = false}) {
    Konto clone = Konto(
        number: number,
        name: name,
        desc: desc,
        valuta: resetValuta ? 0 : valuta,
        plan: (plan != null) ? plan : this.plan);
    // Using forEach for iterating over children
    children.forEach((childName, child) {
      clone.children[childName] =
          child.clone(plan: plan, resetValuta: resetValuta);
    });
    return clone;
  }

  Konto getSmallest() {
    if (children.isEmpty) return this;
    return children.entries.first.value.getSmallest();
  }
}
