/// Versions of the book file, so that an older file is read the way it was
/// written — and saved again in the current format — instead of failing.
///
/// The first row of a file is `FORMAT,nohfibu,<format>,<software>`; a file
/// without it is format 1.
///
/// * 1 — no version row; an account's role from its block (first digit).
/// * 2 — the version row; the KPL has a `role` column (see [AccountType]).
class BookFormat {
  const BookFormat._();

  /// The format this software writes.
  static const current = 2;

  /// The software version written into the file (keep it equal to the
  /// pubspec version — a test checks it).
  static const software = '0.2.0';

  /// The first row of a file written now.
  static List<Object> get row => ['FORMAT', 'nohfibu', current, software];

  /// The format of [row] when it is a version row, else null.
  static int? versionOf(List<dynamic> row) {
    if (row.length < 3 || '${row[0]}'.trim() != 'FORMAT') return null;
    return int.tryParse('${row[2]}'.trim());
  }
}
