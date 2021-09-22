# Dart Fi(nanz) Bu(chhaltung)

Dart implementation for financial accounting, according to the principle of the double account processing 
first described in 1445 by Luca Paciolo.


## Getting Started

### How to run wbconvert 

You will need a working dart (or today, flutter) installation

### How to run wbconvert on a raspberry pi (arm64)

```bash
cd projects # or wherever you store your stuff
wget https://storage.googleapis.com/dart-archive/channels/stable/release/2.14.2/sdk/dartsdk-linux-arm64-release.zip
unzip dartsdk-linux-arm64-release.zip 
rm dartsdk-linux-arm64-release.zip 
dart-sdk/bin/dart --version # check that the dart interpreter is working
export PATH=$PATH:`pwd`/dart-sdk/bin # to enable dart locally in the actual shell
git clone https://github.com/nohkumado/dart_fibu.git .
cd dart_fibu/ # or wherever you store your stuff
```

### Usage

```bash
dart run lib/wbconvert.dart --help
##### sample output #################################
###  bboett@videopi:fibu$ dart run lib/wbconvert.dart --help
###  lib/wbconvert.dart: Warning: Interpreting this as package URI, 'package:nohfibu/wbconvert.dart'.
###  applying args: lang:de base:null out:null help:true strict:false  rest: []
###  -l, --lang           Language setting
###  		     (defaults to "de")
###  -f, --file           Basename of the dataset
###  -o, --output         output name
###  -?, --[no-]help      Help about the options
###  -s, --[no-]strict    enforce old WB-Style parsing
#to really convert something: relative pathes don't work, absolute do
# easiest go to where the data is and call the script from there....
dart run lib/wbconvert.dart -f modell -s
# this will generate a csv that can be further processed
```

### Installation/activation

Once this runs, you can activate the project:

```bash
dart pub global activate --source path ~/projects/fibu/
```

and after adding
`  export PATH="$PATH":"$HOME/.pub-cache/bin"`
to your `~/.bashrc` you can simply run 

`wbconvert -f modell -s`

## Documentation

one day soon, hopefully, i will extend https://www.nohkumado.eu/nohfibu/

