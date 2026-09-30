import 'package:intl/intl.dart';

import '../nohfibu.dart';

/// This class hold a list of lines, each caracterising an entry in an accounting journal.
class Journal {
  late KontoPlan kpl;

  /// The associated account plan.
  String caption = "Journal";

  /// The caption for the journal.
  String endcaption = "Journal End";

  /// The ending caption for the journal.
  List<JrlLine> journal = [];

  /// The list of journal entries.

  /// Constructor for initializing a journal with an account plan.
  Journal(this.kpl, {caption = "Journal", String end = "End"}) {
    //kpl = kpl;
    //if(caption != null)
    //{
    this.caption = caption;
    if (end == "End")
      endcaption = "$caption $end";
    else
      endcaption = "$end";
    //}
  }

  /// empty the journal.
  void clear() {
    journal.clear();
  }

  /// add a line.
  JrlLine add(JrlLine jrlLine) {
    journal.add(jrlLine);
    return jrlLine;
  }

  /// pretty print this journal.
  @override
  String toString() {
    String result = "$caption\n";
    for (var line in journal) {
      result += "$line\n";
    }
    result += endcaption;
    return result;
  }

  /// return the journal as a list .
  List<List> asList(List<List> data,
      {bool silent = false, bool formatted = false}) {
    if (!silent) data.add(["JRL"]);
    if (!silent)
      data.add(
          ["date", "ktominus", "ktoplus", "desc", "cur", "valuta", "actSum"]);
    journal.forEach((line) {
      line.asList(data, formatted: formatted);
    });
    return data;
  }

  /// return the number of entries in this journal.
  int count() => journal.length;

  /// execute the accounting process, creating the subjournals, the account extracts for
  ///  each account update the valutas of each account.
  Journal execute() {
    // the range of the entries themselves (today when there are none)
    DateTime? minTime;
    DateTime? maxTime;
    journal.forEach((line) {
      //print("executing exe for $line");
      if (minTime == null || line.datum.isBefore(minTime!))
        minTime = line.datum;
      if (maxTime == null || line.datum.isAfter(maxTime!)) maxTime = line.datum;
      line.execute();
    });
    minTime ??= DateTime.now();
    maxTime ??= minTime;
    final formatter = DateFormat('yyyy-MM-dd');
    caption =
        "Journal from ${formatter.format(minTime!)} to ${formatter.format(maxTime!)}";
    return this;
  }
}
