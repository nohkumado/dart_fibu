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
    print("ktop get for $ktoName");
    if(konten.containsKey(ktoName))  return konten[ktoName];
    print("ktop seems we need to recurse");
    //but maybe we must recurse?
    if(ktoName.length >1)
    {
      print("name is long enough....");
      String key = ktoName[0];
      if(konten.containsKey(key))  return konten[key]!.get(ktoName.substring(1));
      print("ktop but konten doesn't contain $key");
      return null;
    }
      print("ktop far enough no lolly");
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

  /**
    CTOR where you can specify 
       the number of the account, 
       its name (the number is recursively consumed) 
       to which account plan it relates
       valute the actual value in the account
       budget a theoretical value that lapsed should generate warnings

    */
  Konto({number,name= "kein Name", desc, plan, valuta, cur, budget})
  {
    //set(number,name, plan, desc, valuta, cur, budget);
    if(number != null) this.number = number;
    if(name != null && name != "kein Name") this.name = name;
    if(desc != null) this.desc = desc;
    if(cur != null) this.cur = cur;
    if(valuta != null) this.valuta =valuta;
    if(budget != null) this.budget = budget;
  }
  /**
    setter for the values concerning this object
       the number of the account, 
       its name (the number is recursively consumed) 
       to which account plan it relates
       valute the actual value in the account
       budget a theoretical value that lapsed should generate warnings

    */
  Konto set({number,name= "kein Name", plan, desc, valuta, cur, budget})
  {
    if(number != null) this.number = number;
    if(name != null && name != "kein Name") this.name = name;
    if(desc != null) this.desc = desc;
    if(cur != null) this.cur = cur;
    if(valuta != null) this.valuta =valuta;
    if(budget != null) this.budget = budget;
    return this;
  }

  /**
    get the target account, by descending into the tree of accounts
    null safe, if no account was found a dummy one is generated
    */
  Konto get(String ktoName, {String orgName: "undef"})
  {
    if(orgName == "undef") orgName = ktoName;
    if(name == ktoName )
    {
      return this;
    }
    else if(children.containsKey(ktoName))
    {
      return children[ktoName]!;
    }
    else if(!children.containsKey(ktoName) && ktoName.length > 1)
    {
      //maybe recurse?
      String key = ktoName[0];
      String rest = ktoName.substring(1);
      if(ktoName.startsWith(name)) 
      {
	rest = ktoName.substring(name.length);
      key = rest[0];
      rest = rest.substring(1);
      if(rest.length <= 0)
      {
      children[key] = Konto(number: key, name: orgName);
      return children[key]!;
      }
      }
      if(children.containsKey(key)) return children[key]!.get(rest, orgName: orgName);
      // if(key !=number) //study more, o how to cope with unrelated names
      // {
      //   //orgName = name+orgName;
      // print("ehm  $ktoName differs from me ($number) .... rewriting orgName to $orgName" );
      // }
      children[key] = Konto(number: key);
      return children[key]!.get(ktoName.substring(1), orgName: orgName);
    }
    children[ktoName] = Konto(number: ktoName, name:orgName);
    return children[ktoName]!;
  }

  /**
    create a String representation of  this object, eventually
    by recursing through the sub accounts below this one
    */
  @override
  String toString({String indent: "", bool debug: false})
  {
    String result = "";
    var f = NumberFormat.currency(symbol: cur2sym(cur));
    result = (debug)?"$indent$number. +$name+  -$desc- ,=$cur=,  '$budget' #$valuta#":
      "$indent${sprintf("%#4s", [name])}  ${sprintf("%-49s", [desc])} ${f.format(budget )}  ${f.format(valuta)}";
	
	;
    if(recursive)
    {
      //var f = NumberFormat("###,###,###.00", "de_DE");
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

  /**
    pretty print the account name, olb WB style fibu had 4 char wide account fields...
    */
  printname()
  {
    String fn = (name == "no name")? "0":name;
    return(sprintf("%#4s", [fn]));
  }

  /**
    return this thins as a list, recurse through the tree
    preparation for e.g. csv conversion
    */
  void asList(List<List> asList)
  {
    //print("$number $name $desc tries to add to list");
    if(name == "no name" && desc.length >0) asList.add([number,desc,cur,budget,valuta]);
    else if(desc.length >0) asList.add([name,desc,cur,budget,valuta]);
    else  asList.add([name,desc,cur,budget,valuta]);
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
