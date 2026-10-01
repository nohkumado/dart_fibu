# Unreleased

  * Balances shown in each account's normal direction (`Konto.balance`):
    assets and expenses as debit balance, liabilities and income as credit
    balance — positive as usual, negative only when something is unusual.
    The analysis reads assets − liabilities = income − expenses; the check
    line must read 0. The booked values (`valuta`) keep one sign rule (the
    plus side gains), all accounts together exactly 0.
  * me2000 sample corrected and turned into a format-2 book: its journal
    was written "put into, taken from" — swapped to the book's convention
    "date, taken from, put into, description, amount"; the planets (230–249)
    are assets (role actif), not liabilities as their block said. It now
    balances: assets 6 011 339,11 = income − expenses, liabilities 0.
  * The analysis banner was printed twice.

# 0.2.0

  * Book format 2: the file starts with `FORMAT,nohfibu,<format>,<software>`
    (BookFormat) — a later nohfibu reads every file the way it was written.
    A file without it is format 1 and still read as before; saving always
    writes the current format, so old books are upgraded on their next save.
  * Account roles explicit: the KPL has a `role` column (actif, passif,
    charge, produit — German and English words accepted); format 1 keeps
    the block rule (first digit). The old block lines ("1,*** fine degli
    conti attivi ***") are headings (role `heading`): shown, never booked,
    not summed. The analysis and the year closing select accounts by role,
    so charts like the French PCG (6 charges, 7 produits) work. The role
    does not change the booking arithmetic (one sign rule for all accounts,
    as before).
  * Analysis fixed: it summed the assets twice (`sumPassiva =
    activa.sum()`) and its check could not reach 0 with the book's sign rule;
    now both results agree and the check is the sum of all balances.
  * facture: no archive given → a message and the usage, no stack trace.

  * Invoices (the PHP facture of 2005, merged): `InvoiceArchive` reads and
    writes its CSV layout, `Letterhead` from YAML (address, legal ids, VAT
    note, bank, footer, logo, font), `InvoiceNumbering` YYYY-NNNN,
    `InvoicePdf` (A4, fr/de/en, net/VAT/gross, bank box; € with an embedded
    TrueType font), `InvoiceBooking` — configurable per letterhead (a
    `book:` block with the accounts): revenue and VAT → receivable. CLI
    `facture` (--list, --pdf, --new, --book). Examples in assets/invoice/.
  * Stored operations (fast ops) work: `Operation.questions()` says what a
    booking needs (date, accounts of a range, amounts, texts),
    `Operation.fill(answers)` makes the journal lines (expressions computed,
    zero lines left out, every wrong answer named). `nohfibu -f OP` asks
    them one by one, checks each answer, shows the lines, books them and
    saves into the book (previous version kept as .bak).
  * Fixed on the way: OPS fields kept their quotes when the file has spaces
    after the commas (`"1999",  "3500"`) — no account was found; the first
    line of an op was read minus/plus, the others plus/minus, and saving
    wrote plus/minus: one order now, minus then plus, like the journal;
    lines with a range on the minus side or an unknown account were
    dropped; reading a line replaced its variables for good; template dates
    became today's on saving.
  * csv 8 parses quoted numbers too: the loader converts every field
    explicitly (text or number) — ops failed to load since the upgrade.
  * A journal line with an unknown plus account created an account named
    `{[…][kmin]}` (string interpolation typo).
  * `JrlLine.setValuta("12")` is 12 € (was 12 cents): `Amount.parseCents`
    reads "12", "12,50", "1.234,56 €", "1,234.56".
  * `FibuDate.parse` for the usual date forms (was four nested try/catch).
  * `CsvHandler.save` returns its Future (callers can wait for the file).
  * test/operation.dart and test/book.dart never ran (no _test suffix):
    renamed, they pass. New: stored_ops_test (FUJI of compta2018 end to
    end, save and reload).
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
