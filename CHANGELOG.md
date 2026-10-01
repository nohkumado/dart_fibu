# Unreleased

  * facture -B <book>: archive and book from the book's history, every
    command recorded as a change (bookings go into the same history). With
    a history the numbers come from the documents themselves, in the
    device's series (`LedgerRepo.series`: none for the device that started
    the history, else its name — PHONE-2026-0001; set in <base>/series), so
    two devices never give the same number. Tried end to end: desktop offer
    → invoice → booking, phone paired, phone invoice PHONE-2026-0001 booked
    offline, synced back, one history.
  * `LedgerRepo`: one book as encrypted history on this device
    (<base>/books/<book>/, the key in <base>/keys/<book>.key, the device's
    name in <base>/device). `LedgerDiff`: what an action changed (journal
    lines, accounts, ops, customers, documents and their events, deletions)
    as ops to record — commands and screens keep working on book and archive.
  * CLI `ledger -B <book>`: init (import a CSV book, an invoice archive,
    letterheads), status, conflicts, export (CSV / JSON / YAML views),
    serve (the hub; the pairing QR code in the terminal), sync <invitation>
    (pairs on first use), backup / restore (passphrase). Tried with two
    devices over the real network: paired, synced, exported the same book.
  * The CSV writes account names unpadded (`436`, was `" 436"` — the old
    4-character width belongs to the listing). me2000 sample saved through
    the writer.
  * Sync on the local network, the desktop as hub: `SyncInvitation` (what
    the hub's QR code carries — address, book, a pairing token and the
    book's key: pairing hands the key over screen to camera), `SyncServer`
    (WebSocket; a device without token and key is hung up on) and
    `SyncClient` — like git fetch + push: say what you have, take what you
    lack, send what the hub lacks; every message sealed with the book's
    key. Tested: phone, co-worker and hub working offline at the same time
    end up on the same history.
  * The history encrypted at rest: `LedgerKey` (32 random bytes per book;
    on the desktop a key file readable by its owner only, mode 600; the app
    keeps it in the phone's secure storage), `LedgerCipher` (AES-256-GCM per
    line, the device's name bound in), `ChangeFiles` (one encrypted file per
    device, written whole and renamed into place; lines that do not open are
    named, never silently dropped; a line moved into another device's file
    is refused). `LedgerBackup`: the whole history in one file under a
    passphrase (PBKDF2-SHA256, 600 000 rounds — about 2 s on the desktop),
    independent of the device keys, so it restores on a new device.
  * History as changesets, the base for syncing devices and co-workers
    (lib/src/sync): `Change` — what a device recorded, on top of the
    changes it knew (parents), its id the hash of its content (an altered
    change is refused); `ChangeGraph` — the history as a graph like git's:
    record, merge (union, changes waiting for missing parents), ancestry,
    one replay order for all devices; `Ledger` — book, offers/invoices and
    letterheads rebuilt from it, with `conflicts` where two changes set the
    same thing without knowing each other (the later counts, the other is
    kept for a person to confirm); additions (journal lines, document
    events) never conflict. `Ledger.snapshot` imports a CSV book and the
    invoice archive as a first change (lossless: tested on compta2018 and
    me2000). Documents carry a stable `uid` (drafts have no number yet).
  * `Letterhead.parse` (from text), `toYaml` and `save`: letterheads can be
    written back (the app's settings editor), readable by hand.
  * facture CLI on the workflow: `-s factures.json` and the commands status,
    customer add/list, offer, invoice, accept, refuse, invoice-offer,
    reminders [--send], pay, pdf, import (the old CSV archive); `--book`
    books issued invoices and payments (book saved with .bak), `--date`
    for the date of the action. The example letterhead shows the tax regime,
    reminder settings and the bank account for bookings.
  * Invoices, stage C — the letters. `LetterFrame`: German and English
    letters in DIN 5008 Form B (return line and address field from 45 mm,
    window left, information block at 125 mm, subject at 98.5 mm, fold
    marks at 105/210 mm, hole mark at 148.5 mm); French letters with the
    window on the right and fold marks at 99/198 mm (DL); the issuer's legal
    details in the footer of every page. `InvoicePdf` on it: information
    block (dates, service date — Leistungsdatum —, customer, both VAT ids,
    the offer), items, totals, the tax note, payment or acceptance terms,
    the late-payment mentions for businesses (FR art. L441-10, DE § 288
    BGB), the bank box. `ReminderPdf`: levels 1–3 in the customer's
    language with interest and fee. German offers are "Angebot". Letterheads
    may carry a German tax number. tool/sample_letters.dart writes samples.
  * Invoices, stage B — the workflow (`InvoiceDesk`): drafts of offers and
    invoices (tax from issuer, customer and category, language from the
    customer); issuing gives the number — offers D2026-0001, invoices
    2026-0001, continuous in the order of issue —; an offer's answer
    (accepted / refused); an accepted offer becomes its invoice (linked
    both ways); `remindersDue` lists the overdue invoices with the level
    now due (letterhead delays, one level at a time), `Reminder` adds late
    interest (letterhead rate, from level 2) and the recovery fee for
    businesses; payments (partial too). For booking letterheads: issuing
    books revenue and VAT → receivable, a payment receivable → bank.
  * Invoices, stage A — the model for the offer → invoice workflow:
    `Customer` (business or private, country, VAT id, language, envelope
    window: by the letter's language, fr right, else left), documents with
    a history (`DocumentEvent`: issued, accepted, refused, invoiced,
    reminded, paid, cancelled) and a status from it (`InvoiceStatus`, with
    overdue and partial payments), a category per document, the service
    date. Tax by issuer, customer and category: `TaxProfile` in the
    letterhead (franchise or VAT, rates by category, reverse charge by
    category), `TaxTreatment` (franchise with art. 293 B, reverse charge —
    autoliquidation / Steuerschuldnerschaft des Leistungsempfängers —, or
    the rate), notes in fr/de/en. Letterheads also carry reminder delays,
    late-payment rate and recovery fee. `InvoiceStore`: one versioned JSON
    file (customers + documents); facture's old CSV archive is read as
    format 1 (documents issued, and paid unless told otherwise).
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
