# Dart Fi(nanz) Bu(chhaltung)

Dart implementation for financial accounting, according to the principle of the double account processing 
first described in 1445 by Luca Paciolo.


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
#to really convert something: relative pathes don't work, absolute do
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


## Documentation

- concerning the fast operations, read the [docu](doc/FASTOPS.md)
- if you are interested on a [speed comparision](doc/TIMINGS.md) on different platforms. 
- the documentation written for the C wb fibu, one day soon, hopefully, i will extend it to include the 
dart version, https://www.nohkumado.eu/nohfibu/ still logic and theory will be the same, so please 
adapt as fit, but its still usable.

