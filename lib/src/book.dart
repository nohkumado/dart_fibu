import '../nohfibu.dart';

/// Book class, holds an accountplan and a journal.
///
/// Is able to propagate the analysis aof the account data
/// groups together the toString to be able to print everything directly from here
class Book {
  KontoPlan kpl = KontoPlan();
  late Journal jrl;
  Map<String, dynamic> ops = {};

  String name = "a Book";

  ///CTOR if no accountplan is given initializes with aen empty one
  Book({kpl, jrl}) {
    if (kpl != null) this.kpl = kpl;
    if (jrl == null) this.jrl = Journal(this.kpl);
  }

  /// toString.
  ///
  ///when extracts is activated, prints out all the extracts for the plan,
  /// otherwise prints plan and journal.
  @override
  String toString({bool extracts = false}) {
    String result = "";
    result += kpl.toString() + "\n";
    result += jrl.toString();
    if (extracts) {
      result += "\n";
      result += kpl.toString(extracts: true) + "\n";
    }
    return result;
  }

  ///clear.
  ///
  /// empties the book.
  Book clear() {
    kpl.clear();
    jrl.clear();
    return this;
  }

  /// launches the analyze of the data.
  Book execute() {
    jrl.execute();
    return this;
  }
} //class Book
