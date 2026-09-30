# Unreleased

  * One class per file: nohfibu.dart (1340 lines, 11 declarations) and
    ops_handler.dart split into lib/src/ (book, konto, konto_plan, journal,
    jrl_line, extract_line, fibu, operation, …); nohfibu.dart exports them
    all, ops_handler.dart stays for existing imports. No behaviour change.
  * ExtractLine uses JrlLine's public kminus/kplus (it read the private
    fields, possible only in the same file).

# 0.1.0

  * Dependencies at their latest majors: intl 0.20, csv 8 — `Csv().encode` /
    `Csv(dynamicTyping: true).decode` replace the removed converters (line
    ends found by csv itself, numbers parsed as before).
  * Journal caption: the range of the entries themselves; the end date no
    longer defaults to "a year ago" when every entry is older.
  * `FibuSettings.copyWith`: a new settings object per change, so the app's
    provider notices it.

# 0.0.4-alpha.

  * added additional tests and updated all dependencies

# 0.0.3-alpha.

  * addition of short operations to easy the input of new account operations by building a 
sample scaffold around them

# 0.0.2-alpha.

  * first tries with the fibu exe that compiles an account plan, lots of publish tweaking.. 

# 0.0.1-alpha.

  * first run with the converter of old style files
