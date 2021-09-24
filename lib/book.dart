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
  String toString()
  {
    String result  ="";
    if(kpl != null) result += kpl.toString()+"\n";
    if(jrl != null) result += jrl.toString();
    return result;
  }
}//class Book
