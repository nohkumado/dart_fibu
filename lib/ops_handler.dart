import 'dart:collection';

import 'package:expressions/expressions.dart';
import 'package:intl/intl.dart';
import 'nohfibu.dart';
/// an Operation class
///
///allows to store often used account movements
class Operation extends Object with IterableMixin<JrlLine>
{
  late Book book;
  List<DateTime> datum = [];
  String name = "tag";List<String> cplus = [],cminus =[],desc = [],cur = [],mod = [],valuta = [];
  List<JrlLine> preparedLines = [];
  Map<String, dynamic> vars = {};
  Map<String, dynamic> expressions = {};
  //CTOR
  Operation(book, {name,date,cplus,cminus,desc,cur,valuta, mod})
  {
    this.name = (name != null && name.isNotEmpty) ? name : "unknowntag";
    this.book = (book != null) ? book : Book();
    //assume we got a oneliner!
    if((cplus != null))
      add(date: date, cplus:cplus, cminus:cminus, desc:desc, cur:cur, valuta:valuta, mod:mod);
  }

  ///letting opshandler look like an array
  get length => preparedLines.length;
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
  operator []=(int i,JrlLine value) => preparedLines[i] = value; // set
  /// creates an iterable object so we can do a forEach on it
  @override
  Iterator<JrlLine> get iterator => preparedLines.iterator;

  /// batch setter
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

  ///pretty print this
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
  void asList(List<List> data) {
    final DateFormat formatter = DateFormat('yyyy-MM-dd');
    for(int i = 0; i < cplus.length; i++)
    {
      final String date = formatter.format(datum[i]);
      data.add( [name, date, cplus[i], cminus[i], "${desc[i]}", cur[i], valuta[i], mod[i]]);
    }
  }
  ///extract the needed vars 
  void prepare()
  {
    vars = {};//reset the variables
    expressions = {};
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
      else line.kminus=book.kpl.get(cminus[i])!;
      if(cplus[i].contains("-"))
      {
        var splitted = cplus[i].split("-");
        //print("+ range!! ${cplus[i]} $splitted");
        line.addConstraint("kplu",boundaries: splitted);
      }
      else if(cplus[i].isEmpty) {}//do nothing
      else line.kplus=book.kpl.get(cplus[i])!;
      if(line.kminus.number != "-1" && line.kminus.desc.isEmpty) print("Warning!! minus(${cminus[i]},${line.kminus.name},${line.kminus.number}) account probably erroneaous");
      if(line.kplus.number != "-1" &&line.kplus.desc.isEmpty) print("Warning!! plus(${cplus[i]},${line.kplus.name},${line.kminus.number}) account probably erroneaous");
      //print("set c+ to ${line.kplus} c- to ${line.kminus}");
      if(desc[i].contains("#"))
      {
        //check if it can be evaluated with expressions: ^0.2.3:
        //we need to extract the variables
        RegExp rex = RegExp(r"#(\w+)");
        //print("found matches for vars in desc: $rex");
        rex.allMatches(desc[i]).forEach((match)
        {
          //vars[match.group(1)!] = match.group(1);
          line.vars["desc"] ??= {};//initialise if needed
          if(!vars.containsKey(match.group(1))) line.vars["desc"][match.group(1)!] = match.group(1); //add only if not allready present?
        });
        //print("extracted varaibles : $vars");
      }

      RegExp expPresent = RegExp(r'[()]+');
      //print("checking for presence of $expPresent in ${desc[i]}");
      if(desc[i].contains(expPresent)) parseExpression(line,desc[i], expPresent);
      line.desc = desc[i];
      //print("ops perparer valuta '${valuta[i]}'");
      //valuta is either a vairable name or an expression can't be both....
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
      }
      else  if(valuta[i].isNotEmpty) line.setValuta(valuta[i]);
      if(mod[i].isNotEmpty) line.addConstraint("mode", mode:mod[i]);

      //print("added $line");
      preparedLines.add(line);
      //data.add( [name, date, cplus[i], cminus[i], "${desc[i]}", cur[i], valuta[i], mod[i]]);
    }
  }

  ///check if it can be evaluated with expressions: ^0.2.3:
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
  dynamic eval( {String key : "",Expression? exp})
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

  List<JrlLine>result() {
    List<JrlLine> res = [];
    preparedLines.forEach((line)
    {
      if(line.valuta > 0) res.add(line);});
    return res;
  }

}
