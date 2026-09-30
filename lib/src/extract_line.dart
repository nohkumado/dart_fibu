import 'package:intl/intl.dart';
import 'package:sprintf/sprintf.dart';

import '../nohfibu.dart';

/// Represents one line in an extract journal.
class ExtractLine extends JrlLine {
  int actSum = 0; //to store the intermediate sum of the account

  /// Constructor for initializing an extract line.
  /// The fields are optional, if omitted they will be filled with defaults.
  ExtractLine({JrlLine? line, int sumup = 0}) {
    if (line != null) {
      datum = line.datum;
      kplus = line.kplus;
      kminus = line.kminus;
      desc = line.desc;
      cur = line.cur;
      valuta = line.valuta;
      limits = line.limits;
    }
    actSum = sumup;
  }

  /// Returns a string representation of the extract line.
  @override
  String toString() {
    var f = NumberFormat.currency(symbol: cur2sym(cur));
    String result = "${super.toString()} ${sprintf("%12s", [
          f.format((actSum / 100).toDouble())
        ])}";
    return result;
  }

  /// Converts the extract line to a list format.
  /// This is useful for exporting or processing the data.
  void asList(List<List> data, {bool formatted = false}) {
    final DateFormat formatter = DateFormat('yyyy-MM-dd');
    final String date = formatter.format(datum);
    var f = NumberFormat.currency(symbol: cur2sym(cur));
    var valutaS =
        (formatted) ? "${sprintf("%12s", [f.format(valuta / 100)])}" : valuta;
    var actSumS =
        (formatted) ? "${sprintf("%12s", [f.format(actSum / 100)])}" : actSum;
    data.add([
      date,
      kminus.printname(),
      kplus.printname(),
      "$desc",
      cur,
      valutaS,
      actSumS
    ]);
  }
}
