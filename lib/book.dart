import 'package:nohfibu/kto_plan.dart';
import 'package:nohfibu/journal.dart';


class Book
{
  KontoPlan kpl = KontoPlan();
  late Journal jrl;
  Book({kpl,jrl})
  {
    if(kpl != null) this.kpl = kpl;
    if(jrl == null) this.jrl = Journal(this.kpl);
  }
  @override
  String toString({bool extracts: false})
  {
    String result  ="";
    if(kpl != null) result += kpl.toString()+"\n";
    if(jrl != null) result += jrl.toString();
    if(kpl != null && extracts)
    {
      result += "\n";
      result += kpl.toString(extracts: true)+"\n";

    }
    return result;
  }
  Book clear()
  {
    kpl.clear();
    jrl.clear();
    return this;
  }
  Book execute()
  {
    jrl.execute();
    return this;
  }
}//class Book
