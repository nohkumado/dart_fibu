import 'package:intl/intl.dart';
import 'package:sprintf/sprintf.dart';
import 'package:nohfibu/journal.dart';
/**
  a helper to add to currencies the right utf symbol
  */
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


/** the account plan
  */
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

  /** return the asked account null if not found (BEWARE!!)
    */
  Konto? get(String ktoName)
  {
    //print("ktop get for $ktoName");
    if(konten.containsKey(ktoName))  return konten[ktoName];
    //print("ktop seems we need to recurse");
    //but maybe we must recurse?
    if(ktoName.length >1)
    {
      //print("name is long enough....");
      String key = ktoName[0];
      if(konten.containsKey(key))  return konten[key]!.get(ktoName.substring(1));
      //print("ktop but konten doesn't contain $key");
      return null;
    }
      //print("ktop far enough no lolly");
    return null;
  }

  /** set at ktoName (Treewise) the data if kto (kto will be discarded afterwards) 
    create the account if needed
    */
  Konto put(String ktoName, Konto kto)
  {
    if(ktoName.length < 1) print("Error, KPL, don't know how to add $kto @ $ktoName");
    else if(ktoName.length == 1) konten[ktoName] = kto;
    else
    {
      String key = ktoName[0];
      String rest = ktoName.substring(1, ktoName.length);
      if(!konten.containsKey(key)) konten[key] = Konto(number: key,  plan:this);

      //fetch the account, creating it on the way
      var locK = konten[key]!.get(rest,  orgName: ktoName);
      locK.name =  kto.name;
      locK.plan =  this;
      locK.desc =  kto.desc;
      locK.cur =  kto.cur;
      locK.budget =  kto.budget;
      locK.valuta =  kto.valuta;
      kto = locK;
    }
    return kto;
  }
  /**
    pretty print this thing
    */
  @override
  String toString({bool extracts: false})
  {
    String result = "              Konto Plan \n";
    konten.forEach((key, kto)
    {
     result += kto.toString(recursive: true, extracts: extracts)+"\n";
    });
    result += "         Ende Konto Plan \n";
    //print("extracted +$ktoName+  -$desc- ,=$w=,  '$budget' #$valuta#\n");
    //return "$number $name $desc $cur $valuta $budget";
    return(result);
  }

  /**
    return this as a list
    used for exporting the data
    */
  List<List<dynamic>> asList({bool all: false})
  {
    List<List<dynamic>> asList = [["KPL"], ["kto","dsc","cur","budget","valuta"]];
    konten.forEach((key, value) { value.asList(asList: asList, all:all);});
    return asList;
  }
}

/**
  one account
  */
class Konto
{
  String number  ="-1";
  String desc  ="";
  KontoPlan plan = KontoPlan();
  String cur = "EUR"; //currency
  int valuta = 0;
  int budget = 0;
  Map<String,Konto> children = {};

  String name = "no name";
  late Journal extract;


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
    if(this.number == null) this.number = name[name.length-1];
    extract = Journal(this.plan, caption: "Extract for ${this.name}");
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
    if(this.number == null) this.number = name[name.length-1];
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
      children[key] = Konto(number: key, plan:this);
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
  String toString({String indent: "", bool debug: false,bool recursive = false, empty: false,bool extracts: false})
  {
    String result = "";
    if(extracts) 
    {
      //print("trying to add '${extract.toString()}'");
      if(empty) result += extract.toString();
      else if(extract.journal.length >0) 
      {
	result += extract.toString()+"\n";
	//String pff=  extract.toString();
	//if(pff.isNotEmpty) { print("adding ### $pff ####");result += pff;}
	//else print("rejecting $pff");
      }
    }
    else
    {
      var f = NumberFormat.currency(symbol: cur2sym(cur));
      double valAsd = valuta/100;
      double budAsd = budget/100;
      String pname = (name == "no name")? "$number": name;
      result = (debug)?"$indent$number. +$pname+  -$desc- ,=$cur=,  '$budget' #$valuta#\n":
	  (recursive && !empty && desc.length <=0)?"":  "$indent${sprintf("%#4s", [pname])}  ${sprintf("%-49s", [desc])} ${sprintf("%12s", [f.format(budAsd)])}  ${sprintf("%12s", [f.format(valAsd)])}\n";
    }
    ;

    if(recursive)
    {
      //var f = NumberFormat("###,###,###.00");
      //result += (desc.length >0 || empty)?"##$empty\n":"";
      children.forEach((key, kto)
	  {
	    //result += kto.toString(indent:indent+"$number"); //debug, just to check depth
	    String sres = kto.toString(indent:indent+" ", recursive: true, debug: debug, empty: empty, extracts: extracts);
	    if(sres.trim().isNotEmpty) result += "$sres";
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
  List<List> asList( {List<List> asList : const [], bool all: false})
  {
    if(asList == null) asList = [];
    //print("$number $name $desc tries to add to list");
    if(name == "no name" && desc.length >0) asList.add([number,desc,cur,budget,valuta]);
    else if(desc.length >0) asList.add([name,desc,cur,budget,valuta]);
    if(all) asList.add([name,desc,cur,budget,valuta]);
    children.forEach((key, value) { value.asList(asList: asList);});
    return asList;
  }
  /** 
    add a journal line to our account extract, update the valuta
    */
  Konto action(JrlLine line, {String mode: "add"})
  {
    if(mode == "add") valuta += line.valuta;
    else valuta -= line.valuta;
    //print("action for  $name ($mode) add line ${line.desc} and $valuta");
    ExtractLine sline = new ExtractLine(line: line, sumup: valuta);
    //print("$name adding to $extract \n $sline");
    extract.add(new ExtractLine(line: line, sumup: valuta));
    var f = NumberFormat.currency(symbol: cur2sym(cur));
    String title = "  Extract for $name  ";
    int tofill =  ((95 - title.length)/2).toInt();
    extract.caption = "-"*tofill+title+"-"*tofill;
    extract.endcaption = "_"*60+"Sum:  "+"_"*18+sprintf("%12s", [f.format((valuta/100).toDouble())]);

    return this;
  }
}
