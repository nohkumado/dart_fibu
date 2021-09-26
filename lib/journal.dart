import 'package:intl/intl.dart';
import 'package:nohfibu/kto_plan.dart';
import 'package:sprintf/sprintf.dart';

/**
This class hold a list of lines, each caracterising an entry in an accounting journal
  */
class Journal
{
  late KontoPlan kpl;
  String caption = "Journal";
  String endcaption = "Journal End";

  Journal(KontoPlan kplan, {caption: "Journal", String end: "End"}) 
  {
    kpl = kplan; 
    //if(caption != null) 
    //{
      this.caption = caption;
      if(end == "End") endcaption = "$caption $end";
      else  endcaption = "$end";
    //}
  }
  List<JrlLine> journal = [];
  /**
    empty the journal
    */
  void clear()
  {
     journal = [];
  }

  /**
    add a line
    */
  JrlLine add(JrlLine jrlLine)
  {
    journal.add(jrlLine);
    return jrlLine;
  }
  /**
    pretty print this journal
    */
  @override
  String toString()
  {
    String result = "$caption\n";
    for (var line in journal) { result += "$line\n";}
    result += endcaption;
    return result;
  }

  /**
    return the journal as a list
    */
  List<List> asList(List<List> data)
  {
    data = (data==null)? []: data;
    
    data.add(["JRL"]);
  data.add(["date","ktominus","ktoplus","desc","cur","valuta"]);
  journal.forEach((line) {line.asList(data); });
    return data;
  }
  /** return the number of entries in this journal
    */
  int count() => journal.length;
  /** execute the accounting process, creating the subjournals, the account extracts for 
    each account update the valutas of each account
    */
  Journal execute()
  {
    DateTime minTime = DateTime.now();
    DateTime maxTime = DateTime.now().subtract(const Duration(days: 365));
    journal.forEach((line) 
	{ 
	  //print("excuting exe for $line");
	  if(line.datum.compareTo(minTime) < 0) minTime = line.datum;
	  if(line.datum.compareTo(maxTime)>0) maxTime = line.datum;
	  line.execute(); 
	});
    caption  =  "Journal from $minTime to $maxTime";
    return this;
  }
}

/** one line in an accounting journal*/
class JrlLine
{
  late DateTime datum; /// the date of the transaction
  late Konto kplus; /// the account to be taken from
  late Konto kminus; /// tghe account to be credited
  late String desc; ///  description of the transaction
  late String cur; /// the currency of the transaction
  late num valuta; /// the value of the transaction

  /** CTOR
    the fields are optional, if omitted they will be filled with defaults
    */
 JrlLine({datum, kmin, kplu, desc, cur, valuta})
 {
  // print("jline incoming +$datum+ -$kmin- -$kplu- -$desc- ,=$cur=, #$valuta#\n");
   kplus =(kplu != null)?  kplu:Konto();
   kminus = (kmin != null)? kmin:Konto();
   this.desc = (desc != null)? desc: "none";
   this.datum = (datum  != null )? datum: DateTime.now();
   this.cur= (cur    != null )? cur :"EUR";
   this.valuta =(valuta != null )? valuta: 0;
 }

 /**
   pretty print this thing
   */
 @override
 String toString()
 {
   final DateFormat formatter = DateFormat('dd-MM-yyyy');
   final String formatted = formatter.format(datum);
   var f = NumberFormat.currency(symbol: cur2sym(cur));

   String result = "$formatted ${kminus.printname()} ${kplus.printname()} ${sprintf("%-49s", [desc])} ${sprintf("%12s", [f.format(valuta)])}";
   return result;
 }

 /** return a list abstraction model of this object
   */
  void asList(List<List> data)
  {
    final DateFormat formatter = DateFormat('yyyy-MM-dd');
    final String date = formatter.format(datum);
    data.add([date,kminus.printname(), kplus.printname(),"$desc",cur,valuta]);
  }

  /** ask the 2 accounts to add this line to their extracts
    */
  JrlLine execute()
  {
    kminus.action(this,mode:"sub");
    kplus.action(this,mode:"add");
    return this;
  }
}
/** one line in an extract journal*/
class ExtractLine implements JrlLine 
{
  DateTime get datum => values.datum; /// the date of the transaction
  void set datum(value)=> values.datum = value; /// the date of the transaction
  Konto  get kplus    => values.kplus  ; /// the account to be taken from
  void  set kplus(value)    => values.kplus = value  ; /// the account to be taken from
  Konto  get kminus   => values.kminus ; /// tghe account to be credited
  void  set kminus(value)   => values.kminus = value ; /// tghe account to be credited
  String get desc     => values.desc   ; ///  description of the transaction
  void set desc(value)     => values.desc = value   ; ///  description of the transaction
  String get cur      => values.cur    ; /// the currency of the transaction
  void set cur(value)      => values.cur  = value   ; /// the currency of the transaction
  num get valuta     => valuta; /// the value of the transaction
  void set valuta(value)     => valuta = value; /// the value of the transaction
  double actSum = 0; //to store the intermediate sum of the account
  late JrlLine values; /// the value of the transaction

  /** CTOR
    the fields are optional, if omitted they will be filled with defaults
    */
 ExtractLine({JrlLine? line, double sumup: 0})
 {
   values = (line == null)? JrlLine():line;
   actSum = (sumup != null)? sumup:0;
 }

 /**
   pretty print this thing
   */
 @override
 String toString()
 {
   var f = NumberFormat.currency(symbol: cur2sym(cur));
   String result = "${values.toString()} ${sprintf("%12s", [f.format(actSum)])}";
   return result;
 }
  void asList(List<List> data) => values.asList(data);
  JrlLine execute() => values.execute();
}


