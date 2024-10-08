import 'dart:collection';
import 'dart:io';

import 'package:expressions/expressions.dart';
import 'package:intl/intl.dart';
import 'nohfibu.dart';
////// An Operation class that stores predefined or commonly used account movements.
///
/// The class provides a batch operation interface to create multiple journal entries
/// (represented as `JrlLine` objects) that can later be executed in bulk.
class Operation extends Object with IterableMixin<JrlLine>
{
  late Book book;/// The book to which the operation is tied.
  List<DateTime> datum = [];/// List of dates associated with the operation entries.
  String name = "tag";/// Name of the operation (e.g., a tag to identify the operation).
  List<String> cplus = [],cminus =[],desc = [],cur = [],mod = [],valuta = [];// Lists that store different attributes of the operation.
  List<JrlLine> preparedLines = [];/// List of prepared journal lines that can be executed.
  Map<String, dynamic> vars = {};/// Map of variables used in the operation for templating and expressions.
  Map<String, dynamic> expressions = {};/// Map of expressions tied to the operation for dynamic evaluation.
  List<JrlLine> _backupLines = []; //for the undo function
  /// Constructor to initialize the operation.
  ///
  /// Takes a `Book` and optional parameters like name, date, and other attributes.
  Operation(book, {name,date,cplus,cminus,desc,cur,valuta, mod})
  {
    this.name = (name != null && name.isNotEmpty) ? name : "unknowntag";
    this.book = (book != null) ? book : Book();
    //assume we got a oneliner!
    if((cplus != null))
      add(date: date, cplus:cplus, cminus:cminus, desc:desc, cur:cur, valuta:valuta, mod:mod);
  }

  ///letting opshandler look like an array,Returns the length of prepared journal lines.
  get length => preparedLines.length;
  /// Getter to access individual `JrlLine` entries in `preparedLines` by index.
  /// Replaces template variables in descriptions and evaluates expressions if any.
  operator [](int i) {
    JrlLine line = preparedLines[i]; // get
    //print("######     in line getter $line with ${line.valexp}");
    vars.forEach((key, value)
    {
      print("replacing : #$key with $value");
      line.desc = line.desc.replaceAll("#$key", "$value");
    });
    var evaled = eval(exp : line.valexp);
    if(evaled is int && evaled >=0) line.valuta = evaled;
    return line;
  }
  /// Setter to access individual `JrlLine` entries in `preparedLines` by index.
  operator []=(int i,JrlLine value) => preparedLines[i] = value; // set
  /// creates an iterable object so we can do a forEach on it
  @override
  Iterator<JrlLine> get iterator => preparedLines.iterator;

  /// batch setterr
  /// Adds a batch of attributes to the operation (e.g., date, account, description, etc.).
  ///
  /// This allows adding multiple journal lines in one go.
  Operation add ({date,cplus,cminus,desc,cur,valuta, mod})
  {
    if(date != null)
    {
      if(date is String) this.datum.add(DateTime.parse(date));
      else if(date is DateTime) this.datum.add(date);
      else this.datum.add(DateTime.now());
    }
    this.cplus.add( (cplus != null) ? "$cplus".trim() : "none");
    this.cminus.add( (cminus != null) ? "$cminus".trim() : "none");
    this.desc.add( (desc != null) ? desc.trim() : "none");
    this.cur.add( (cur != null) ? cur : "EUR");
    this.valuta.add( (valuta != null) ? valuta : "");
    this.mod.add((mod != null) ? mod : "");
    //print("incoming : $date,$cplus,$cminus,$desc,$cur,$valuta. $mod gives "+toString());
    return this;
  }

  /// Returns a string representation of the operation.
  /// Formats the entries in a human-readable format, listing each attribute.
  @override
  String toString()
  {
    String result = "";
    final DateFormat formatter = DateFormat('dd-MM-yyyy');
    for(int i = 0; i < cplus.length; i++)
    {
      final String formatted = formatter.format(datum[i]);
      //var f = NumberFormat.currency(symbol: cur2sym(cur[i]));
      // "$formatted ${kminus.printname()} ${kplus.printname()} ${sprintf("%-49s", [ desc ])} ${sprintf("%12s", [f.format(valAsd)])}";
      result += "${name},${formatted},+:${cplus[i]},-:${cminus[i]},${desc[i]},${cur[i]},${valuta[i]}, ${mod[i]}\n";
    }
    return result;
  }
  /// return a list abstraction model of this object .
  /// Converts the operation into a list format, suitable for CSV or other structured outputs.
  void asList(List<List> data) {
    final DateFormat formatter = DateFormat('yyyy-MM-dd');
    for(int i = 0; i < cplus.length; i++)
    {
      final String date = formatter.format(datum[i]);
      data.add( [name, date, cplus[i], cminus[i], "${desc[i]}", cur[i], valuta[i], mod[i]]);
    }
  }
  ///Prepares the operation by converting attributes into `JrlLine` objects.
  /// This method sets up constraints, evaluates expressions, and fills in variables where necessary.
  void prepare()
  {
    _backupLines = List.from(preparedLines);  // Store the current state
    vars = {};//reset the variables
    //print("preparing $name, +:$cplus, -:$cminus, dsc: $desc, cur: $cur, val: $valuta");
    expressions = {};
    //the data is stored in the different array, they should all have the same length so we take anyones length to iterate over all the jrl lines
    for(int i = 0; i < cplus.length; i++)
    {
      JrlLine line = JrlLine(datum: datum[i]);
      if(cminus[i].contains("-"))
      {
        var splitted = cminus[i].split("-");
        //print("- range!! ${cminus[i]} $splitted");
        line.addConstraint("kmin",boundaries: splitted);
      }
      else if(cplus[i].isEmpty) {}//do nothing
      else
        {
          Konto? minus = book.kpl.get(cminus[i]);
          if(minus != null) line.kminus=minus;
          else
          {
            print("Prepare PROBLEM c- (${cminus[i]}) is null: ${book.kpl}");
          }



          print("Op trying to analyse cplus:  ${cplus[i]}");
          if(cplus[i].contains("-"))
          {
            var splitted = cplus[i].split("-");
            print("+ range!! ${cplus[i]} $splitted");
            line.addConstraint("kplu",boundaries: splitted);
          }
          else if(cplus[i].isEmpty) {}//do nothing
          else
          {

            Konto? plus = book.kpl.get(cplus[i]);
            if(plus != null) line.kplus=plus;
            else
            {
              print("Prepare PROBLEM c+ (${cplus[i]})is null: ${book.kpl}");
            }

            // Check and warn if the account is erroneous.
            if(line.kminus.number != "-1" && line.kminus.desc.isEmpty)
            {
              print("Warning!! minus(${cminus[i]},${line.kminus.name},${line.kminus.number}) account probably erroneous");
            }
            if(line.kplus.number != "-1" &&line.kplus.desc.isEmpty) print("Warning!! plus(${cplus[i]},${line.kplus.name},${line.kminus.number}) account probably erroneous");
            //print("set c+ to ${line.kplus} c- to ${line.kminus}");
            if(desc[i].contains("#"))
            {
              //_extractVariablesFromDescription(line, desc[i]); //TODO check if really apllicable

              //check if it can be evaluated with expressions: ^0.2.3:
              //we need to extract the variables
              RegExp rex = RegExp(r"#(\w+)");
              final matches = rex.allMatches(desc[i]);
              // Print all groups found
              final extractedVariables = matches.map((match) => match.group(1)).toList();
              // Update line.vars dictionary (optional)
              line.vars["desc"] ??= {}; // Initialize if needed
              for (final variable in extractedVariables)
              {
                if (!vars.containsKey(variable)) {
                  vars[variable!] = variable;  // Add only if not already present
                }
              }
            }

            RegExp expPresent = RegExp(r'[()]+');
            //print("checking for presence of $expPresent in ${desc[i]}");
            if(desc[i].contains(expPresent)) parseExpression(line,desc[i], expPresent);
            line.desc = desc[i];
            //print("ops preparer valuta '${valuta[i]}'");
            //valuta is either a variable name or an expression can't be both....
            if(valuta[i].contains(expPresent)) parseExpression(line,valuta[i], expPresent);
            else if(valuta[i].contains("#"))
            {
              //we need to extract the variables
              RegExp rex = RegExp(r"#(\w+)");
              //print("matching ${rex.allMatches(valuta[i]).length}");
              rex.allMatches(valuta[i]).forEach((match)
              {
                vars[match.group(1)!] = match.group(1);
                line.valname = match.group(1);
              });
              line.valuta =-1;//force invalid value
              //_extractVariablesFromValuta(line, valuta[i]);
            }
            else  if(valuta[i].isNotEmpty) line.setValuta(valuta[i]);
            if(mod[i].isNotEmpty) line.addConstraint("mode", mode:mod[i]);

            //print("added $line");
            preparedLines.add(line);
          }
        }
      //data.add( [name, date, cplus[i], cminus[i], "${desc[i]}", cur[i], valuta[i], mod[i]]);
    }
  }
  /// Helper method to extract variables from the description.
  void _extractVariablesFromDescription(JrlLine line, String desc) {
    RegExp rex = RegExp(r"#(\w+)");
    final matches = rex.allMatches(desc);
    final extractedVariables = matches.map((match) => match.group(1)).toList();

    // Store extracted variables in line.vars and the operation's `vars`.
    for (final variable in extractedVariables) {
      if (!vars.containsKey(variable)) {
        vars[variable!] = variable;
      }
    }
  }

  /// Helper method to extract variables from the `valuta` field.
  void _extractVariablesFromValuta(JrlLine line, String valuta) {
    RegExp rex = RegExp(r"#(\w+)");
    rex.allMatches(valuta).forEach((match) {
      vars[match.group(1)!] = match.group(1);
      line.valname = match.group(1);
    });
    line.valuta = -1; // Force invalid value until evaluation
  }
  ///check if it can be evaluated with expressions: ^0.2.3:
  ///Parses expressions within the description or valuta fields.
  /// These expressions are stored in `expressions` and evaluated later.
  void parseExpression(JrlLine line,String source, RegExp expPresent) {
    //we need to extract the variables
    RegExp rex = RegExp(r"(\(.*\))");
    rex.allMatches(source).forEach((match)
    {
      String testExp = match.group(1).toString();
      testExp = testExp.replaceAll("#", "");
      try {
        Expression expression = Expression.parse(testExp);
        expressions[match.group(1)!] = expression;
        //print("adding expression ${match.group(1)} with $expression");
        //line.valexp =expression ?? new Expression();//force invalid value
        line.valexp =expression;//force invalid value
      }
      catch(e){
        print("error parsing expression '$testExp'");
      }
    });
  }
  /// Evaluates an expression using the current variables.
  /// If `exp` is provided, it evaluates that specific expression, otherwise it uses the `key` to look up an expression.d to extract variables from the `valuta` field.
  dynamic eval( {String key = "",Expression? exp})
  {
    late Expression torun;
    if(exp != null) { torun = exp; }
    else if(expressions.containsKey(key)) { torun = expressions[key];}
    else {
      //print("neither $key nor $exp bailing");
      return(-1);
    }

      final evaluator = const ExpressionEvaluator();
      var r = evaluator.eval(torun, vars);
      print("evaled result = '$r'");
      return(r);
  }
  /// Returns the list of `JrlLine` entries that have a valid `valuta` value.
  List<JrlLine>result() {
    List<JrlLine> res = [];
    preparedLines.forEach((line)
    {
      if(line.valuta > 0) res.add(line);});
    return res;
  }
  bool validate() {
    bool isValid = true;

    for (JrlLine entry in preparedLines) {
      if (!entry.kminus.valid() || !entry.kplus.valid()) {
        print("Error: Account information missing for operation ${entry.desc}");
        isValid = false;
      }
      if (entry.valuta < 0) {
        print("Error: Valuta information missing for operation ${entry.desc}");
        isValid = false;
      }
    }

    return isValid;
  }
  void undo() {
    preparedLines = List.from(_backupLines);  // Restore the previous state
  }
  void parseExpression2(JrlLine line, String source) {
    RegExp varExp = RegExp(r"#(\w+)");  // Matches variables
    RegExp expressionExp = RegExp(r"\(([^)]+)\)");  // Matches expressions inside parentheses
    Map<String, dynamic> locvars = {};/// Map of variables used in the operation for templating and expressions.
    Map<String, dynamic> locexpressions = {};/// Map of expressions tied to the operation for dynamic evaluation.

    // Parse variables first
    varExp.allMatches(source).forEach((match) {
      String variable = match.group(1)!;
      if (!locvars.containsKey(variable)) {
        locvars[variable] = variable;
      }
    });

    // Parse expressions
    expressionExp.allMatches(source).forEach((match) {
      String expressionStr = match.group(1)!;
      try {
        Expression expression = Expression.parse(expressionStr);
        locexpressions[match.group(1)!] = expression;
        //line.valexp = expression;//TODO activat ewhen validated
      } catch (e) {
        print("Error parsing expression: $expressionStr");
      }
    });
    print("ilocal variables $locvars and expressions $locexpressions");
  }
}

///Operation needs to be filled, buit the way to fill is not the same in GUI or shell context
abstract class UserInteraction {
  // Method to prompt the user for an account selection
  Future<String> promptForAccountSelection(String message, List<String> options);

  // Method to prompt the user for text input, e.g., comment or description
  Future<String> promptForTextInput(String message, {String defaultValue = ""});

  // Method to prompt for a numerical input like a value or amount
  Future<int> promptForValueInput(String message, {int defaultValue = 0});
}

/// The default implementation of `UserInteraction`on CLI level
class CLIInteraction implements UserInteraction {
  @override
  Future<String> promptForAccountSelection(String message, List<String> options) async {
    print(message);
    for (int i = 0; i < options.length; i++) {
      print("${i + 1}. ${options[i]}");
    }

    // Read user's selection and validate input
    int choice = -1;
    while (choice < 1 || choice > options.length) {
      stdout.write("Enter choice [1-${options.length}]: ");
      choice = int.parse(stdin.readLineSync()!);
    }

    return options[choice - 1];
  }

  @override
  Future<String> promptForTextInput(String message, {String defaultValue = ""}) async {
    stdout.write("$message (default: $defaultValue): ");
    String input = stdin.readLineSync()!;
    return input.isNotEmpty ? input : defaultValue;
  }

  @override
  Future<int> promptForValueInput(String message, {int defaultValue = 0}) async {
    stdout.write("$message (default: $defaultValue): ");
    String input = stdin.readLineSync()!;
    return input.isNotEmpty ? int.parse(input) : defaultValue;
  }
}


