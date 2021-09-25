# Dart Fi(nanz) Bu(chhaltung)

Dart implementation for financial accounting, according to the principle of the double account processing 
first described in 1445 by Luca Paciolo.

So far only a file converter from our old file format to a more modern csv format is available

## Getting Started

### How to run wbconvert 

You will need a working dart (or today, flutter) installation

### How to run wbconvert on a raspberry pi (arm64)


> **WARNING**: if not otherwise specified, never execute anything as root user,
> 
> if you do, be prepared for a hell of pain! 
> **you are warned!**


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
$ dart run bin/fibu.dart --help # to test directly from the source dir
$ fibu --help # if you have activated the project
```

at the moment issues only to read in csv file, but will be extended in a future version

### Installation/activation

Once this runs, you can activate the project, we suppose you haven't done any cd'ing in the meantime:

```bash
$ dart pub global activate --source path `pwd`
```

and after adding (don't forget the dart sdk path if you installed it locally)
`  export PATH="$PATH":"$HOME/.pub-cache/bin"`
to your `~/.bashrc` you can simply run 

`wbconvert -f modell -s`

## Documentation

the documentation written for the C wb fibu, one day soon, hopefully, i will extend it to include the 
dart version, https://www.nohkumado.eu/nohfibu/ still logic and theory will be the same, so please 
adapt as fit, but its still usable.

