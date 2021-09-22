import 'package:intl/intl.dart';
import 'package:sprintf/sprintf.dart';
String cur2sym(String name)
{

  String sym = "€";
  switch(name)
  {
    case 'EUR': sym = "€ "; break;
    case 'LIR': sym = "£ "; break;
    case 'YEN': sym = "¥ "; break;
    case 'POU': sym = "£ "; break;
    case 'DOL': sym = "\$ "; break;
    default: sym = "€ "; break;
  }
  return sym;
}
class KontoPlan
{
  //bestandsKonten
  //List<Konto> aktivKonten = [Konto(name: "soll"),Konto(name: "haben")], passivKonten= [Konto(name: "soll"),Konto(name: "haben")]; //jeweils gespalten in soll (vermehrung) und haben (verminderung)
  Map<String, Konto> konten = {};
   //List<Konto> aktivKonten = [], passivKonten= []; //jeweils gespalten in soll (vermehrung) und haben (verminderung)

  void clear()
  {
    //aktivKonten = [Konto(name: "soll", plan: this),Konto(name: "haben", plan: this)];
    //passivKonten= [Konto(name: "soll", plan: this),Konto(name: "haben", plan: this)];
    konten.clear();
  }

  void add(Konto konto) {}

  Konto? get(String ktoName)
  {
   if(konten.containsKey(ktoName))  return konten[ktoName];
   //but maybe we must recurse?
   if(ktoName.length >1)
     {
       String key = ktoName[0];
       if(konten.containsKey(key))  return konten[key]!.get(ktoName.substring(1));
       return null;
     }
   return null;
  }
  Konto put(String ktoName, Konto kto)
  {
    konten[ktoName] = kto;
    return kto;
  }
  @override
  String toString()
  {
    String result = "              Konto Plan \n";
    konten.forEach((key, kto)
    {
     kto.recursive = true;
     result += kto.toString()+"\n";
     kto.recursive = false;
    });
    result += "         Ende Konto Plan \n";
    //print("extracted +$ktoName+  -$desc- ,=$w=,  '$budget' #$valuta#\n");
    //return "$number $name $desc $cur $valuta $budget";
    return(result);
  }

  List<List<dynamic>> asList()
  {
    List<List<dynamic>> asList = [["KPL"], ["kto","dsc","cur","budget","valuta"]];
    konten.forEach((key, value) { value.asList(asList);});
    return asList;
  }
}

class Konto
{
  String number  ="-1";
  String desc  ="";
  KontoPlan plan = KontoPlan();
  String cur = "EUR"; //currency
  double valuta = 0;
  double budget = 0;
  Map<String,Konto> children = {};

  String name = "no name";

  bool recursive = false;

  Konto({number,name= "kein Name", plan, valuta, cur, budget})
  {
    if(number != null) this.number = number;
    if(name != null) this.name = name;
    if(desc != null) this.desc = desc;
    if(cur != null) this.cur = cur;
    if(valuta != null) this.valuta =valuta;
    if(budget != null) this.budget = budget;
  }
  Konto set({number,name= "kein Name", plan, valuta, cur, budget})
  {
    if(number != null) this.number = number;
    if(desc != null) this.desc = desc;
    if(cur != null) this.cur = cur;
    if(valuta != null) this.valuta =valuta;
    if(budget != null) this.budget = budget;
    return this;
  }

  Konto get(String ktoName)
  {
    if(!children.containsKey(ktoName) && ktoName.length > 1)
    {
      //maybe recurse?
      String key = ktoName[0];
      if(children.containsKey(key)) return children[key]!.get(ktoName.substring(1));
    }
    else if(!children.containsKey(ktoName)) children[ktoName] = Konto(number: ktoName);

    return children[ktoName]!;
  }
  @override
  String toString({String indent: ""})
  {
    String result = "$indent$number. +$name+  -$desc- ,=$cur=,  '$budget' #$valuta#";
    if(recursive)
    {
      //var f = NumberFormat("###,###,###.00", "de_DE");
      var f = NumberFormat.currency(symbol: cur2sym(cur));
      result = "$indent${sprintf("%#4s", [name])}  ${sprintf("%-49s", [desc])} ${f.format(budget )}  ${f.format(valuta)}";
      result += "\n";
      children.forEach((key, kto)
      {
      kto.recursive = true;
       result += kto.toString(indent:indent+" ");
       kto.recursive = false;
      });
    }
      //print("extracted +$ktoName+  -$desc- ,=$w=,  '$budget' #$valuta#\n");
      return(result);
    }

  printname()
  {
    String fn = (name == "no name")? "0":name;
    return(sprintf("%#4s", [fn]));
  }

  void asList(List<List> asList)
  {
    //print("$number $name $desc tries to add to list");
    if(name == "no name" && desc.length >0) asList.add([number,desc,cur,budget,valuta]);
    else if(desc.length >0) asList.add([name,desc,cur,budget,valuta]);
    children.forEach((key, value) { value.asList(asList);});
  }
    //return "$number $name $desc $cur $valuta $budget";
}

class KontoEintrag
{
  String name  ="";
  KontoPlan plan = KontoPlan();
  String titel = "kein  Titel";
  //Waehrung wert;
  //Waehrung budget;
  //private Jrl myJournal;
  //private ArrayList<BilanzLinie> block = new ArrayList<BilanzLinie>();
  KontoEintrag({name, plan, titel})
  {
  }
}
