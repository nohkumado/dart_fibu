import 'dart:collection';

import 'package:expressions/expressions.dart';
import 'package:intl/intl.dart';

import '../nohfibu.dart';

/// A stored operation ("fast op"): named template lines for a movement that
/// comes back often, e.g. a shopping trip split over several accounts.
///
/// Each template line has a minus and a plus account — an account number, a
/// range (`2100-2200`: chosen when booking) or empty —, a description that
/// may hold `#variables`, and an amount that is a number, a `#variable` or an
/// expression over variables (`(#payement - #montant)`).
///
/// Booking one: [questions] says what is still needed (date, accounts to
/// choose, amounts, texts), [fill] turns the answers into journal lines. The
/// older [prepare] / `op[i]` / [eval] interface stays for existing callers.
class Operation extends Object with IterableMixin<JrlLine> {
  /// The book whose account plan the accounts come from.
  late Book book;

  /// Name (tag) of the operation, e.g. FUJI.
  String name = "tag";

  /// The template lines, column by column (as in the book's OPS section).
  /// Template dates; null when the template has none (today when booked).
  List<DateTime?> datum = [];
  List<String> cplus = [], cminus = [], desc = [], cur = [], mod = [], valuta = [];

  /// Journal lines built by [prepare], one per template line.
  List<JrlLine> preparedLines = [];

  /// Variables of the templates (name → value; the name until given one).
  Map<String, dynamic> vars = {};

  /// Expressions of the templates (source → parsed expression).
  Map<String, dynamic> expressions = {};

  /// What [prepare] could not resolve (unknown accounts, bad expressions).
  List<String> problems = [];

  List<JrlLine> _backupLines = [];

  static final _variable = RegExp(r"#(\w+)");
  static final _range = RegExp(r"^(\d+)\s*-\s*(\d+)$");

  /// An operation of [book]; with [cplus] given, its first template line.
  Operation(book, {name, date, cplus, cminus, desc, cur, valuta, mod}) {
    this.name = (name != null && "$name".trim().isNotEmpty) ? clean(name) : "unknowntag";
    this.book = (book != null) ? book : Book();
    if (cplus != null) {
      add(date: date, cplus: cplus, cminus: cminus, desc: desc, cur: cur, valuta: valuta, mod: mod);
    }
  }

  /// A field as the book file gave it: trimmed, without surrounding quotes
  /// (a space after the comma leaves them in: `"1999",  "3500"`).
  static String clean(dynamic value) {
    var s = (value == null) ? "" : "$value".trim();
    while (s.length >= 2 && s.startsWith('"') && s.endsWith('"')) {
      s = s.substring(1, s.length - 1).trim();
    }
    return s;
  }

  /// Number of template lines prepared.
  @override
  int get length => preparedLines.length;

  /// Prepared line [i], its description and amount filled from [vars].
  JrlLine operator [](int i) {
    final line = preparedLines[i];
    line.desc = _substitute(desc[i]);
    if (line.valexp != null) {
      final evaled = eval(exp: line.valexp);
      if (evaled is num && evaled >= 0) line.valuta = evaled.toInt();
    }
    return line;
  }

  operator []=(int i, JrlLine value) => preparedLines[i] = value;

  @override
  Iterator<JrlLine> get iterator => preparedLines.iterator;

  /// Adds a template line.
  Operation add({date, cplus, cminus, desc, cur, valuta, mod}) {
    datum.add(date is DateTime ? date : FibuDate.parse(clean(date)));
    final plus = clean(cplus), minus = clean(cminus);
    this.cplus.add(plus.isEmpty && cplus == null ? "none" : plus);
    this.cminus.add(minus.isEmpty && cminus == null ? "none" : minus);
    final d = clean(desc);
    this.desc.add(d.isEmpty && desc == null ? "none" : d);
    final c = clean(cur);
    this.cur.add(c.isEmpty ? (cur == null ? "EUR" : "") : c);
    this.valuta.add(clean(valuta));
    this.mod.add(clean(mod));
    return this;
  }

  /// One line per template line: name,date,+:plus,-:minus,desc,cur,amount, mode
  @override
  String toString() {
    final formatter = DateFormat('dd-MM-yyyy');
    final result = StringBuffer();
    for (int i = 0; i < cplus.length; i++) {
      final d = datum[i];
      result.write("$name,${d == null ? '' : formatter.format(d)},+:${cplus[i]},-:${cminus[i]},"
          "${desc[i]},${cur[i]},${valuta[i]}, ${mod[i]}\n");
    }
    return result.toString();
  }

  /// The template lines as rows of the book's OPS section:
  /// tag, date, minus, plus, description, currency, amount, mode — the
  /// order [CsvHandler] reads them in.
  void asList(List<List> data) {
    final formatter = DateFormat('yyyy-MM-dd');
    for (int i = 0; i < cplus.length; i++) {
      final d = datum[i];
      data.add([name, d == null ? "" : formatter.format(d), cminus[i], cplus[i], desc[i], cur[i], valuta[i], mod[i]]);
    }
  }

  /// Builds one journal line per template line: accounts looked up (ranges
  /// become constraints), variables and expressions collected. Nothing is
  /// dropped: what cannot be resolved lands in [problems] and is asked.
  void prepare() {
    _backupLines = List.from(preparedLines);
    preparedLines = [];
    vars = {};
    expressions = {};
    problems = [];
    for (int i = 0; i < cplus.length; i++) {
      final line = JrlLine(datum: datum[i] ?? DateTime.now(), cur: cur[i].isEmpty ? "EUR" : cur[i]);
      _side(line, cminus[i], minus: true);
      _side(line, cplus[i], minus: false);
      for (final v in _variablesIn(desc[i])) {
        vars.putIfAbsent(v, () => v);
      }
      line.desc = desc[i];
      final amount = valuta[i];
      if (amount.contains("(")) {
        _parseExpression(line, amount);
        line.valuta = -1;
      } else if (amount.contains("#")) {
        final names = _variablesIn(amount);
        for (final v in names) {
          vars.putIfAbsent(v, () => v);
        }
        line.valname = names.isEmpty ? null : names.first;
        line.valuta = -1;
      } else {
        line.valuta = Amount.parseCents(amount) ?? -1;
      }
      if (mod[i].isNotEmpty) line.addConstraint("mode", mode: mod[i]);
      preparedLines.add(line);
    }
  }

  /// What is needed to book this operation; call [prepare] first.
  List<OpQuestion> questions() {
    final out = <OpQuestion>[
      OpQuestion("date", OpQuestionKind.date, "Date", defaultValue: FibuDate.show(DateTime.now())),
    ];
    final amountVars = <String>{};
    for (int i = 0; i < preparedLines.length; i++) {
      final line = preparedLines[i];
      for (final minus in [true, false]) {
        final spec = minus ? cminus[i] : cplus[i];
        final konto = minus ? line.kminus : line.kplus;
        if (spec.isEmpty || spec == "none" || konto.valid()) continue;
        final choices = _choices(spec);
        out.add(OpQuestion("line$i.${minus ? 'minus' : 'plus'}", OpQuestionKind.account,
            "${desc[i]}: account ${minus ? '-' : '+'} ($spec)",
            defaultValue: choices.isEmpty ? "" : choices.first.name, choices: choices));
      }
      if (line.valname != null) amountVars.add(line.valname!);
      if (line.valexp != null) amountVars.addAll(_variablesIn(valuta[i]));
    }
    // variables in the order they appear; amounts first where they are used
    for (final v in vars.keys) {
      out.add(amountVars.contains(v)
          ? OpQuestion(v, OpQuestionKind.amount, v, defaultValue: "0")
          : OpQuestion(v, OpQuestionKind.text, v));
    }
    for (int i = 0; i < preparedLines.length; i++) {
      final line = preparedLines[i];
      if (line.valname == null && line.valexp == null && line.valuta < 0) {
        out.add(OpQuestion("line$i.amount", OpQuestionKind.amount, "${desc[i]}: amount", defaultValue: "0"));
      }
    }
    return out;
  }

  /// The journal lines booked with [answers] (keys of [questions]); lines
  /// whose amount comes out as zero are left out. Throws [FormatException]
  /// naming every answer that is missing or wrong.
  List<JrlLine> fill(Map<String, String> answers) {
    final errors = <String>[];
    final date = FibuDate.parse(answers["date"] ?? "") ?? DateTime.now();
    final values = <String, dynamic>{};
    final questionsByKey = {for (final q in questions()) q.key: q};
    for (final q in questionsByKey.values) {
      if (q.kind == OpQuestionKind.amount && !q.key.startsWith("line")) {
        final cents = Amount.parseCents(answers[q.key] ?? q.defaultValue);
        if (cents == null) errors.add("${q.key}: '${answers[q.key]}' is no amount");
        values[q.key] = cents ?? 0;
      } else if (q.kind == OpQuestionKind.text) {
        values[q.key] = answers[q.key] ?? "";
      }
    }
    final result = <JrlLine>[];
    for (int i = 0; i < preparedLines.length; i++) {
      final template = preparedLines[i];
      final line = JrlLine(datum: date, cur: template.cur, kmin: template.kminus, kplu: template.kplus);
      for (final minus in [true, false]) {
        final key = "line$i.${minus ? 'minus' : 'plus'}";
        if (!questionsByKey.containsKey(key)) continue;
        final chosen = book.kpl.get(clean(answers[key] ?? questionsByKey[key]!.defaultValue));
        final allowed = questionsByKey[key]!.choices;
        if (chosen == null || (allowed.isNotEmpty && !allowed.any((k) => k.name == chosen.name))) {
          errors.add("$key: '${answers[key]}' is not one of ${allowed.map((k) => k.name).join(', ')}");
        } else if (minus) {
          line.kminus = chosen;
        } else {
          line.kplus = chosen;
        }
      }
      line.desc = desc[i].replaceAllMapped(_variable, (m) {
        final v = values[m.group(1)];
        if (v is int) return NumberFormat("#,##0.00", "fr").format(v / 100);
        return (v == null || "$v".isEmpty) ? m.group(0)! : "$v";
      });
      if (template.valexp != null) {
        try {
          final r = const ExpressionEvaluator().eval(template.valexp!, values);
          line.valuta = (r as num).toInt();
        } catch (e) {
          errors.add("${desc[i]}: ${valuta[i]} cannot be computed ($e)");
          line.valuta = 0;
        }
      } else if (template.valname != null) {
        line.valuta = values[template.valname] as int? ?? 0;
      } else if (template.valuta >= 0) {
        line.valuta = template.valuta;
      } else {
        final cents = Amount.parseCents(answers["line$i.amount"] ?? "0");
        if (cents == null) errors.add("line$i.amount: '${answers["line$i.amount"]}' is no amount");
        line.valuta = cents ?? 0;
      }
      if (line.valuta != 0) result.add(line);
    }
    if (errors.isNotEmpty) throw FormatException(errors.join("\n"));
    return result;
  }

  /// Evaluates [exp], or the expression stored under [key], with [vars];
  /// -1 when there is none or it cannot be computed.
  dynamic eval({String key = "", Expression? exp}) {
    final Expression? torun = exp ?? (expressions[key] is Expression ? expressions[key] : null);
    if (torun == null) return -1;
    try {
      return const ExpressionEvaluator().eval(torun, vars);
    } catch (_) {
      return -1;
    }
  }

  /// The prepared lines with an amount.
  List<JrlLine> result() => preparedLines.where((line) => line.valuta > 0).toList();

  /// True when every prepared line has both accounts and an amount.
  bool validate() => preparedLines.every((l) => l.kminus.valid() && l.kplus.valid() && l.valuta >= 0);

  /// Back to the lines before the last [prepare].
  void undo() {
    preparedLines = List.from(_backupLines);
  }

  /// Sets one side of [line] from [spec]: a range becomes a constraint, an
  /// account number the account; an unknown one is noted in [problems].
  void _side(JrlLine line, String spec, {required bool minus}) {
    if (spec.isEmpty || spec == "none") return;
    final range = _range.firstMatch(spec);
    if (range != null) {
      line.addConstraint(minus ? "kmin" : "kplu", boundaries: [range.group(1)!, range.group(2)!]);
      return;
    }
    final konto = book.kpl.get(spec);
    if (konto == null || !konto.valid()) {
      problems.add("$name: account $spec unknown");
    } else if (minus) {
      line.kminus = konto;
    } else {
      line.kplus = konto;
    }
  }

  /// The accounts a side may take: those of a range, or all of the plan.
  List<Konto> _choices(String spec) {
    final range = _range.firstMatch(spec);
    if (range == null) return book.kpl.getRange({"min": spec, "max": spec});
    return book.kpl.getRange({"min": range.group(1)!, "max": range.group(2)!});
  }

  void _parseExpression(JrlLine line, String source) {
    for (final match in RegExp(r"(\(.*\))").allMatches(source)) {
      final text = match.group(1)!;
      for (final v in _variablesIn(text)) {
        vars.putIfAbsent(v, () => v);
      }
      try {
        final expression = Expression.parse(text.replaceAll("#", ""));
        expressions[text] = expression;
        line.valexp = expression;
      } catch (e) {
        problems.add("$name: expression '$text' cannot be read");
      }
    }
  }

  String _substitute(String template) =>
      template.replaceAllMapped(_variable, (m) => "${vars[m.group(1)] ?? m.group(0)}");

  static List<String> _variablesIn(String text) =>
      [for (final m in _variable.allMatches(text)) m.group(1)!];
}
