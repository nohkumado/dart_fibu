# TODO List
* ich möchte die FastOps die ich in der perl-fibu habe hierher portieren
* das prettyprint im .lst kann noch verbessert werden
* man könnte im gleichen csv die Geschichte der veränderungen speichern um ein undo/redo zu erlauben
* man könnte mal schauen wie das geht eine Web servierte Datei zu öffnen, dann könnte man die csv Datei irgendwo auf einem Cloud Speicher haben, denn dann kann man  mit mehreren Clients/Personen darauf zugreifen dazu müsste dann locking, user tracking und undo implementiert werden.
* Wenn Du die gleiche Funktionalität wie das wb fibu willst, muss ein KPL/JRL Editor her, wobei ich ehrlich gesagt mit fastops und vim glücklicher bin....
* mit flutter ein graphisches Interface dazu machen, dann hätten wir mit dem gleichen Programm Consolen-, Graphik-, Android- und Webappmodus


#Wish list

## Book file format

- [ ] Format version in the saved file (e.g. a first row
  `FORMAT;nohfibu;2`): the loader reads by version, a file without one is
  version 1 (today's layout); every format change bumps it and keeps a
  reader for the older ones.
- [ ] Account role explicit instead of by the account plan's block (first
  digit 1 asset, 2 liability, 3 expense, 4 income): an optional role column
  in the KPL section (AccountType: Actif, Passif, Charge, Produit), used
  when present, the block rule as fallback — old books keep working, modern
  charts (e.g. the French PCG: 6 charges, 7 produits) become possible.

## Invoices

- [ ] Reminders (rappel, pénalité, arrêt) as in facture's LaTeX template:
  texts per level, late-payment penalty (ECB rate + 7 points)
- [ ] Invoices in flutter_fibu (list, new, PDF preview/share)
- [ ] Estimates: "valid until" instead of the due date; turn an estimate
  into an invoice
- [ ] Paying an invoice: a stored op receivable → bank, found by number

