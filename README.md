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

#### Invoices (facture)

The PHP facture of 2005 lives on here: an archive in its CSV layout,
letterheads as YAML, PDFs made in Dart (no LaTeX needed).

    dart run nohfibu:facture -a factures.csv --list
    dart run nohfibu:facture -a factures.csv --pdf 2026-0001
    dart run nohfibu:facture -a factures.csv --new [--book compta2026.csv]

Letterheads live in `~/.config/nohfibu/letterheads/<id>.yaml` (outside git:
they hold your bank details); start from
`assets/invoice/letterhead.example.yaml`. The archive's `config` column
names the letterhead. Numbers are `YYYY-NNNN`, continuous within the year
(the last one kept in `<archive>.number`). A letterhead with a `book:` block
(receivable, revenue, VAT accounts) also books issued invoices into the book
given with `--book`; without it, invoices are only made.

## Documentation

- concerning the fast operations, read the [docu](doc/FASTOPS.md)
- if you are interested on a [speed comparision](doc/TIMINGS.md) on different platforms. 
- the documentation written for the C wb fibu, one day soon, hopefully, i will extend it to include the 
dart version, https://www.nohkumado.eu/nohfibu/ still logic and theory will be the same, so please 
adapt as fit, but its still usable.

