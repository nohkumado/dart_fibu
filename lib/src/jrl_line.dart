import 'package:expressions/expressions.dart';
import 'package:intl/intl.dart';
import 'package:sprintf/sprintf.dart';

import '../nohfibu.dart';

/// Represents one line in an accounting journal.
class JrlLine {
  static const int maxValue = -1 >>> 1;
  late DateTime datum;

  /// the date of the transaction
  late Konto _kplus;

  /// the account to be taken from
  late Konto _kminus;

  /// the account to be credited
  late String desc;

  ///  description of the transaction
  late String cur;

  /// the currency of the transaction
  late int valuta;

  /// the value of the transaction
  Map? limits;

  ///eventual constraints on the input to the journal
  Map<String, dynamic> vars = {};

  /// Stores additional variables for the transaction.
  Expression? valexp;

  /// An optional expression for evaluating the value.
  String? valname;

  /// The tag for the expression (if any).

  /// Constructor for initializing a journal line.
  /// Optional fields will be filled with default values if omitted.
  JrlLine(
      {DateTime? datum,
      Konto? kmin,
      Konto? kplu,
      String? desc,
      String? cur,
      valuta}) {
    // print("jline incoming +$datum+ -$kmin- -$kplu- -$desc- ,=$cur=, #$valuta#\n");
    _kplus = (kplu != null) ? kplu : Konto();
    _kminus = (kmin != null) ? kmin : Konto();
    this.desc = (desc != null) ? desc : "none";
    this.datum = (datum != null) ? datum : DateTime.now();
    this.cur = (cur != null) ? cur : "EUR";

    if (valuta == null)
      this.valuta = maxValue;
    else
      switch (valuta.runtimeType) {
        case int:
          this.valuta = valuta;
          break;
        case double:
          if (valuta != valuta.roundToDouble()) {
            this.valuta = (valuta * 100)
                .toInt(); //if there is a decimal point in, the user went wrong and didn't give centsbut euros
          } else {
            this.valuta = valuta.toInt();
          }
          break;
        case String:
          double tmpVal = (double.tryParse(valuta.replaceAll(",", "")) ?? -1);
          if (tmpVal != tmpVal.roundToDouble()) {
            this.valuta = (tmpVal * 100)
                .toInt(); //if there is a decimal point in, the user went wrong and didn't give centsbut euros
          } else {
            this.valuta = tmpVal.toInt();
          }
          if (this.valuta == -1) this.valuta = maxValue;
          break;
        default:
          print("dont know how to handle valuta ${valuta.runtimeType}");
          this.valuta = maxValue;
      }
    if (this.valuta == -1 && "${this.valuta}" != "$valuta")
      print("JrLine ERROR in parsing valuta!! $valuta unparsable");
    //this.valuta = (valuta != null) ? (valuta is double)? valuta.toInt():valuta : 0;
  }

  /// Gets the account to be debited (kminus).
  Konto get kminus => _kminus;

  /// Gets the account to be credited (kplus).
  Konto get kplus => _kplus;

  /// Sets the account to be debited (kminus) after validating constraints.
  /// we need to check if we have the right to change the account, otherwise leave it as is, in the framework you need to check if the value changed....
  set kminus(Konto other) {
    if (_isWithinRange(other, 'kmin')) {
      _kminus = other;
    } else {
      print(
          "Error setting kminus :(${other.name}) invalid range ... unchanged ${_kminus.name}");
      //throw Exception('kminus is out of range.');
    }
  }

  /// Sets the account to be credited (kplus) after validating constraints.
  set kplus(Konto other) {
    if (_isWithinRange(other, 'kplu'))
      _kplus = other;
    else {
      print(
          "Error setting kplus :(${other.name}) invalid range ... unchanged ${_kplus.name}");
      //throw Exception('kminus is out of range.');
    }
  }

  /// Sets the `valuta` of the transaction by parsing a string input.
  /// Sets the amount from text as a person types it ("12", "12,50",
  /// "1.234,56 €"; see [Amount.parseCents]); empty leaves it unset
  /// ([maxValue]), text that is no amount gives 0.
  void setValuta(String toParse, {bool debug = false}) {
    if (toParse.trim().isEmpty) {
      valuta = maxValue;
      return;
    }
    valuta = Amount.parseCents(toParse) ?? 0;
    if (debug) print("setValuta '$toParse' → $valuta");
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
        _formattedDesc() +
        " " +
        formattedValuta();
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

  String formattedValuta({int? value}) {
    value = value ?? valuta;
    var f = NumberFormat.currency(symbol: cur2sym(cur));
    double valAsd = value / 100;
    return sprintf("%12s", [f.format(valAsd)]);
  }

  /// Converts the journal line to a list format.
  /// This is useful for exporting or processing the data.
  void asList(List<List> data, {bool formatted = false}) {
    final DateFormat formatter = DateFormat('yyyy-MM-dd');
    final String date = formatter.format(datum);
    var f = NumberFormat.currency(symbol: cur2sym(cur));

    var valutaS =
        (formatted) ? "${sprintf("%12s", [f.format(valuta / 100)])}" : valuta;
    data.add(
        [date, _kminus.printname(), _kplus.printname(), "$desc", cur, valutaS]);
  }

  /// Executes the transaction by updating the accounts (`kminus` and `kplus`).
  ///
  /// The `valuta` value is added to `kplus` and subtracted from `kminus`.
  /// ask the 2 accounts to add this line to their extracts.
  /// Returns the `JrlLine` instance for chaining.
  JrlLine execute() {
    if (isNotValid()) {
      print(
          "JrlLine exe Error: ${_kminus.printname()} ${_kplus.printname()} invalid:\n$_kminus\n$_kplus ${isNotValid(debug: true)}");
      throw Exception('kminus or kplus is not valid');
    }
    _kminus.action(this, mode: Mode.sub);
    _kplus.action(this, mode: Mode.add);
    return this;
  }

  /// Adds constraints to the transaction.
  void addConstraint(String key,
      {List<String> boundaries = const [], String mode = ""}) {
    if (limits == null)
      limits = {
        "kmin": {"min": "-1", "max": "1000000"},
        "kplu": {"min": "-1", "max": "1000000"}
      };

    if (key == "kmin" || key == "kplu") {
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
      } else if (key == "kplu") {
        limits!["kplu"]["min"] = boundaries[0];
        limits!["kplu"]["max"] = boundaries[1];
      }
    } else if (key == "mode") this.vars["mode"] = mode;
  }

  ///check if the konto is within the range
  bool _isWithinRange(Konto konto, String key) {
    //print("checking range: $limits vs ${konto.name}");
    if (limits == null) return true;
    int kontoValue = int.tryParse(konto.name) ?? 0;
    int min = int.tryParse(limits![key]["min"]) ?? 0 - kontoValue;
    int max = int.tryParse(limits![key]["max"]) ?? kontoValue + 100000;
    //print("limits found... cparoing $kontoValue inside $min and $max = ${(min <= kontoValue && max >= kontoValue)?'true':'false'}");
    return min <= kontoValue && max >= kontoValue;
  }

  bool valid({bool debug = false}) {
    if (_kminus.isNotValid() || _kplus.isNotValid() || valuta == maxValue) {
      if (debug) {
        if (_kminus.isNotValid(debug: true)) print("kminus is faulty");
        if (_kplus.isNotValid(debug: true)) print("kminus is faulty");
      }
      return false;
    }
    return true;
  }

  bool isNotValid({bool debug = false}) => !valid(debug: debug);

  /// Checks if the transaction's date is the current date.'
  bool needsDate() {
    final now = DateTime.now();
    return now.year == datum.year &&
        now.month == datum.month &&
        now.day == datum.day;
  }

  bool needsAccount({String accountType = "minus"}) {
    assert(accountType == "minus" || accountType == "plus",
        "Invalid accountType specified");
    String setKey = (accountType == "minus") ? "kmin" : "kplu";
    // Check if there are account limits and if the account is pre-set
    //print("checking if accounts[$accountType] need user input: \n   $kminus   $kplus");
    if (limits != null && limits!.containsKey(setKey)) {
      //print("found limits: ${this.limits![setKey]}");
      var limits = this.limits![setKey]!;
      if (limits["min"] != "-1") {
        List<Konto> ktoList = kplus.plan.getRange(limits);

        ///either lto has access to the plan
        // If the first account is already assigned, no need for user input
        if (ktoList.length > 1) return true;
        return false;
      } else
        print("min limit -1 what did that mean?");
    }
    //else print("no limits, but are the accounts valid?"); //TODO we need more range checks

    // Return true if the account still needs user input
    return false;
  }
}
