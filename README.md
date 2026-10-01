# Dart Fi(nanz) Bu(chhaltung)

Dart implementation for financial accounting, according to the principle of the double account processing 
first described by Luca Paciolo further [reading](doc/HISTORY.md)


## Getting Started

After choosing one of the many ways to [install nohfibu](doc/INSTALLING.md), you can invoque it:

### Usage

#### The converter 

this converter has the function to convert our old data into csv that will be imported into the new
dart fibu

```bash
dart run bin/wbconvert.dart --help
##### sample output #################################
###  bboett@videopi:fibu$ dart run bin/wbconvert.dart --help
###  bin/wbconvert.dart: Warning: Interpreting this as package URI, 'package:nohfibu/wbconvert.dart'.
###  applying args: lang:de base:null out:null help:true strict:false  rest: []
###  -l, --lang           Language setting
###  		     (defaults to "de")
###  -f, --file           Basename of the dataset
###  -o, --output         output name
###  -?, --[no-]help      Help about the options
###  -s, --[no-]strict    enforce old WB-Style parsing
#to really convert something: relative paths don't work, absolute do
# easiest go to where the data is and call the script from there....
dart run bin/wbconvert.dart -f <your kpl file> -s
# this will generate a csv that can be further processed
```

#### fibu 

```bash
$ dart run bin/nohfibu.dart --help # to test directly from the source dir
$ nohfibu --help # if you have activated the project, or precompiled
$ nohfibu -r -b assets/wbsamples/sample # will analyze the .csv file and produce a .lst result file
$ nohfibu  -b assets/wbsamples/sample -f MERCH# will try to fill in new journal lines following the 
                                              # MERCH receipe (in the .csv file under OPS)
```

at the moment the data-source is only in a (local) csv file, but will be extended in a future versions.


#### Stored operations (fast ops)

A book's OPS section holds named templates for movements that come back
often: accounts (or ranges to choose from), descriptions with `#variables`,
amounts as numbers, variables or expressions (`(#payement - #montant)`).

    dart run nohfibu -b compta2018.csv --list      # the ops of the book
    dart run nohfibu -b compta2018.csv -f FUJI     # book one: asks date,
                                                   # accounts, amounts, texts

The answers are checked as they come, the journal lines shown before
booking, the book saved back (previous version as `.bak`). In code:
`Operation.questions()` and `Operation.fill(answers)`; flutter_fibu shows
them as a form.

#### Offers and invoices (facture)

The PHP facture of 2005 lives on, grown into the whole workflow: offer →
accepted (or refused) → invoice → reminders → payment, booked into the
accounts when you want. One archive (JSON) per issuer holds the customers
and the documents with their history.

    F="dart run nohfibu:facture -s factures.json"
    $F customer add                  # business or private, country, VAT id, language
    $F offer                         # asks, issues D2026-0001, writes the PDF
    $F accept D2026-0001
    $F invoice-offer D2026-0001 --book compta2026.csv   # 2026-0001, booked
    $F status                        # open offers, overdue invoices, reminders due
    $F reminders --send              # writes the reminder letters (levels 1-3)
    $F pay 2026-0001 240 --book compta2026.csv          # booked receivable → bank
    $F import ~/www/facture/base.csv # the old CSV archive

Letterheads — one per business you issue under (micro-entreprise,
entreprise individuelle, association…) — live in
`~/.config/nohfibu/letterheads/<id>.yaml` (outside git: they hold your bank
details); start from `assets/invoice/letterhead.example.yaml`. Each carries
its tax regime: franchise or VAT, rates by category, the categories under
reverse charge. The tax of a document follows from the letterhead, the
customer (business or private, country, VAT id) and the document's category
(e.g. `3dprint` under reverse charge for a German business: "Steuerschuld-
nerschaft des Leistungsempfängers"; `cours` at French or German VAT).

The letters are in the customer's language: German and English in DIN 5008
Form B (window left), French with the window on the right; fold marks and
the hole mark on the edge. `dart run tool/sample_letters.dart /tmp/letters`
writes samples.

## Documentation

- concerning the fast operations, read the [docu](doc/FASTOPS.md)
- if you are interested on a [speed comparision](doc/TIMINGS.md) on different platforms. 
- the documentation written for the C wb fibu, one day soon, hopefully, i will extend it to include the 
dart version, https://www.nohkumado.eu/nohfibu/ still logic and theory will be the same, so please 
adapt as fit, but its still usable.

