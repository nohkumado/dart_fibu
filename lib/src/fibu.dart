
import '../fibusettings.dart';
import '../nohfibu.dart';

/// Launcher for the accounting analysis
///
/// -r launches the analysis
/// -b <name> set the base name to work on
///
/// Issues a result file with the accounting analysis
class Fibu {
  bool strict = false;
  Book book = Book();
  late FibuSettings settings;

  InputProvider inputProvider = new CLIInputProvider();

  Fibu({strict = false, FibuSettings? settings}) {
    if (strict) this.strict = true;
    if (settings != null)
      this.settings = settings;
    else
      this.settings = FibuSettings();
  }

  ///run the ledgers and fillem up from the book
  String execute() {
    print("asked to run!" + book.toString());
    book.execute(); //TODO we should report if there were errors....

    String result = book.toString() + "\n";
    result += book.kpl.toString(extracts: true);
    result += "=" * 20 + "    Analysis    " + "=" * 20 + "\n";
    //result += "Aktiva    \n"+ (book.kpl.get("1")).toString(recursive: true)+"\n";
    result += book.kpl.analysis();
    return result;
  }

  ///run the ledgers and create the new period
  Book nextPeriod() {
    book.execute(); //TODO we should report if there were errors....
    Book nextExercise = Book();
    nextExercise.kpl =
        book.kpl.clone(resetValuta: true); // Clone the KPL with resetValuta
    Konto patrimonio = nextExercise.kpl.get("2")?.getSmallest() ??
        Konto(); // Find the "patrimonio" account, validate it
    if (patrimonio.isNotValid()) {
      print("Error!! no patrimonio found???");
      return nextExercise; // Exit early if patrimonio is invalid
    }
    // Helper function to add journal entries
    void addJournalEntries(List<List> accounts, String reportDesc) {
      for (List actAcc in accounts) {
        nextExercise.jrl.add(
          JrlLine(
              kplu: nextExercise.kpl
                  .get("${actAcc[0]}"), // Get the corresponding account
              kmin: patrimonio,
              desc: "$reportDesc ${actAcc[1]}", // Dynamic description
              cur: actAcc[2], // Currency
              valuta: actAcc[4] // Valuta (balance/amount)
              ),
        );
      }
    }

    // Get usable aktiva accounts and add them to journal
    List<List> aktivaAccounts =
        book.kpl.get("1")?.asList().where((line) => line[4] != 0).toList() ??
            [];
    addJournalEntries(aktivaAccounts, "Report ");

    // Get usable passiva accounts excluding patrimonio, and add them to journal
    List<List> passivaAccounts = book.kpl
            .get("2")
            ?.asList()
            .where((line) => line[4] != 0 && line[0] != patrimonio.name)
            .toList() ??
        [];
    addJournalEntries(passivaAccounts, "Report ");

    // Execute the next exercise
    nextExercise.execute(); //TODO we should report if there were errors....
    //identify patrimonium account, should be the first of the 2* accounts

    return nextExercise; //TODO error reporting as usual....
  }

  /// Books the stored operation [key]: asks each of its questions through
  /// [inputProvider] (checked at once), shows the resulting journal lines
  /// and adds them to the journal once confirmed. True when booked.
  bool opExe(String key) {
    final op = book.ops[key];
    if (op is! Operation) {
      print("Fast op '$key' unknown; known: ${book.ops.keys.join(', ')}");
      return false;
    }
    op.prepare();
    for (final problem in op.problems) {
      print("! $problem");
    }
    while (true) {
      final answers = <String, String>{};
      for (final q in op.questions()) {
        answers[q.key] = _ask(q);
      }
      final List<JrlLine> lines;
      try {
        lines = op.fill(answers);
      } on FormatException catch (e) {
        print(e.message);
        continue;
      }
      print("please check the new journal lines:");
      for (final line in lines) {
        print("  $line");
      }
      final answer = (inputProvider.getInput("ok? (y = book, n = again, q = cancel)", defaultValue: "y") ?? "y").trim().toLowerCase();
      if (answer == "q") return false;
      if (answer.isEmpty || answer == "y") {
        for (final line in lines) {
          book.jrl.add(line);
        }
        return true;
      }
    }
  }

  /// Asks [q] until the answer fits its kind.
  String _ask(OpQuestion q) {
    if (q.kind == OpQuestionKind.account && q.choices.isNotEmpty) {
      for (final k in q.choices) {
        print("  ${k.name.padLeft(6)} ${k.desc.trim()}");
      }
    }
    while (true) {
      final answer = (inputProvider.getInput(q.label, defaultValue: q.defaultValue) ?? q.defaultValue).trim();
      switch (q.kind) {
        case OpQuestionKind.date:
          if (FibuDate.parse(answer) != null) return answer;
          print("not a date (dd-mm-yyyy, dd.mm.yy, yyyy-mm-dd)");
        case OpQuestionKind.amount:
          if (Amount.parseCents(answer) != null) return answer;
          print("not an amount (12, 12,50, 1.234,56)");
        case OpQuestionKind.account:
          if (q.choices.isEmpty || q.choices.any((k) => k.name == answer)) return answer;
          print("choose one of: ${q.choices.map((k) => k.name).join(', ')}");
        case OpQuestionKind.text:
          return answer;
      }
    }
  }
}
