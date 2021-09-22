import 'package:intl/intl.dart';
import 'package:nohfibu/kto_plan.dart';
import 'package:sprintf/sprintf.dart';

class Journal
{
  late KontoPlan kpl;

  Journal(KontoPlan kplan ) {kpl = kplan;}
  List<JrlLine> journal = [];
  void clear()
  {
     journal = [];
  }

  void add(JrlLine jrlLine)
  {
    journal.add(jrlLine);
  }
  @override
  String toString()
  {
    String result = "            Journal\n";
    for (var line in journal) { result += "$line\n";}
    result += "          Journal End";
    return result;
  }

  List<List> asList(List<List> data)
  {
    data = (data==null)? []: data;
    data.add(["JRL"]);
  data.add(["date","ktominus","ktoplus","desc","cur","valuta"]);
  journal.forEach((line) {line.asList(data); });
    return data;
  }
}

class JrlLine
{
  late Konto kplus;
  late Konto kminus;
  late String desc;
  late DateTime datum;
  late String cur;
  late int valuta;

 JrlLine({datum, kmin, kplu, desc, cur, valuta})
 {
   //print("jline incoming +$datum+ -$kmin- -$kplu- -$desc- ,=$cur=, #$valuta#\n");
   kplus =(kplu != null)?  kplu:Konto();
   kminus = (kmin != null)? kmin:Konto();
   this.desc = (desc != null)? desc: "none";
   this.datum = (datum  != null )? datum: DateTime.now();
   this.cur= (cur    != null )? cur :"EUR";
   this.valuta =(valuta != null )? valuta: 0;
 }

 @override
 String toString()
 {
   final DateFormat formatter = DateFormat('dd-MM-yyyy');
   final String formatted = formatter.format(datum);
   var f = NumberFormat.currency(symbol: cur2sym(cur));

   String result = "$formatted ${kminus.printname()} ${kplus.printname()} ${sprintf("%-49s", [desc])} ${f.format(valuta)}";
   return result;
 }

  void asList(List<List> data)
  {
    final DateFormat formatter = DateFormat('yyyy-MM-dd');
    final String date = formatter.format(datum);
    data.add([date,kminus.printname(), kplus.printname(),"$desc",cur,valuta]);
  }

}