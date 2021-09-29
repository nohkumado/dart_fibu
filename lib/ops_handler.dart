import 'package:intl/intl.dart';
import 'nohfibu.dart';
/// an Operation class
///
///allows to store often used account movements
class Operation
{
  late Book book;
  List<DateTime> datum = [];
  String name = "tag";List<String> cplus = [],cminus =[],desc = [],cur = [],mod = [],valuta = [];
  List<JrlLine> preparedLines = [];
  //CTOR
  Operation(book, {name,date,cplus,cminus,desc,cur,valuta, mod})
  {
    this.name = (name != null && name.isNotEmpty) ? name : "unknowntag";
    //assume we got a oneliner!
    if((cplus != null && cplus.isNotEmpty))  
      add(date: date, cplus:cplus, cminus:cminus, desc:desc, cur:cur, valuta:valuta, mod:mod);
  }
  /// batch setter
  Operation add ({date,cplus,cminus,desc,cur,valuta, mod})
  {
    if(date != null)
    {
      if(date is String) this.datum.add(DateTime.parse(date));
      else if(date is DateTime) this.datum.add(date);
      else this.datum.add(DateTime.now());
    }
    this.desc.add( (desc != null) ? desc : "none");
    this.cplus.add( (cplus != null) ? "$cplus" : "none");
    this.cminus.add( (cminus != null) ? "$cminus" : "none");
    this.desc.add( (desc != null) ? desc : "none");
    this.cur.add( (cur != null) ? cur : "EUR");
    this.valuta.add( (valuta != null) ? valuta : "");
    this.mod.add((mod != null) ? mod : "");
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
      var f = NumberFormat.currency(symbol: cur2sym(cur[i]));
      // "$formatted ${kminus.printname()} ${kplus.printname()} ${sprintf("%-49s", [ desc ])} ${sprintf("%12s", [f.format(valAsd)])}";
      result += "${name},${formatted},${cplus[i]},${cminus[i]},${desc[i]},${cur[i]},${valuta[i]}, ${mod[i]}\n";
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

    for(int i = 0; i < cplus.length; i++)
    {
      JrlLine line = JrlLine(datum: datum[i]);
      if(cminus[i].contains("-"))
      {
	var splitted = cminus[i].split("-");
	print("range!! ${cminus[i]} $splitted");
	line.addContraint("kmin",splitted);
      }
      else if(cplus[i].isEmpty) {}//do nothing
      else line.kminus=book.kpl.get(cminus[i])!;
      if(cplus[i].contains("-"))
      {
	var splitted = cplus[i].split("-");
	print("range!! ${cplus[i]} $splitted");
	line.addContraint("kplu",splitted);
      }
      else if(cplus[i].isEmpty) {}//do nothing
      else line.kplus=book.kpl.get(cminus[i])!;
      if(desc[i].contains("#"))
      {
	//we need to extract the variables
	RegExp rex = RegExp(r"#(\w+)");
	print("found matches for vars : $rex");
      }


      //data.add( [name, date, cplus[i], cminus[i], "${desc[i]}", cur[i], valuta[i], mod[i]]);
    }

  }
}
