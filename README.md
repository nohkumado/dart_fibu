# Dart Fi(nanz) Bu(chhaltung)

Dart implementation for financial accounting, according to the principle of the double account processing 
first described in 1445 by Luca Paciolo.


## Getting Started

## dart installation
### How to install dart on a raspberry pi (arm64)

> **WARNING**: if not otherwise specified, never execute anything as root user,
> 
> if you do, be prepared for a hell of pain! 
> **you are warned!**

```bash
$ cd projects # or wherever you store your stuff
$ wget https://storage.googleapis.com/dart-archive/channels/stable/release/2.14.2/sdk/dartsdk-linux-arm64-release.zip
$ unzip dartsdk-linux-arm64-release.zip 
$ rm dartsdk-linux-arm64-release.zip 
$ dart-sdk/bin/dart --version # check that the dart interpreter is working
$ export PATH=$PATH:`pwd`/dart-sdk/bin # to enable dart locally in the actual shell
```

### How to install dart on an android tablet (arm64)

you will need a working termux environment:  https://play.google.com/store/apps/details?id=com.termux

once up and  running, hit

```bash
pkg install dart
```

and you are good
You probably want to install also vim (+dart pugins), git and you other usual tools.


## source managment
### How to fetch the sources from git

### first time for public, non contributing users
```bash
$ cd projects # or wherever you store your stuff
$ git clone https://github.com/nohkumado/dart_fibu.git .
$ cd dart_fibu/ # or wherever you store your stuff
$ dart run bin/wbconvert.dart --help
```

The last line is to check that all went well and the thing is working

### first time for contributing users with configured (ssh keys!) git account
```bash
$ cd projects # or wherever you store your stuff
$ git clone igit@github.com:nohkumado/dart_fibu.git .
$ cd dart_fibu/ # or wherever you store your stuff
$ dart run bin/wbconvert.dart --help
```

The last line is to check that all went well and the thing is working

### to refresh/resync the sources with the git version

afterwards if you want to update the project to the actual active version you just need to 
```
git pull
```

> **WARNING**: if you modified the source you will perhaps need to fix some merge errors!

### Installation/activation

Once this runs, you can activate the project, for this you have to be in the root dir of the project:
> **You need to repeat this after updates  if some binaries are missing!**


### Activation from the sources
```bash
$ dart pub global activate --source path `pwd`
```

### Activation from the pub.dev
using the the https://pub.dev/packages/nohfibu version.
```bash
$ dart pub global activate nohfibu
```

and after adding (don't forget the dart sdk path if you installed it locally)
`  export PATH="$PATH":"$HOME/.pub-cache/bin"`
to your `~/.bashrc` you can simply run e.g.

`wbconvert -f modell -s`

#### Precompilation

instead of activating the project, you can also precompile them, which makes them way faster!

```bash
mkdir ~/bin
dart compile exe  bin/nohfibu.dart -o ~/bin/fibu
dart compile exe  bin/wbconvert.dart -o ~/bin/fibuwbconvert # to avoid name conflicts...
```

You don't have to take my word for it, here an example of the speed up (on a raspberry pi, on my main comp, the times are all 0....):

```bash
bboett@videolan:~/projects/dart_fibu $ time ~/bin/fibu -r -b assets/wbsamples/me2000.csv 
trying to fetch book from file assets/wbsamples/me2000.csv
load Book: assets/wbsamples/me2000 csv  
write seems successful, please check assets/wbsamples/me2000.lst

real    0m0.819s
user    0m0.732s
sys     0m0.114s
bboett@videolan:~/projects/dart_fibu $ time dart run bin/fibu.dart -r -b assets/wbsamples/me2000.csv 
trying to fetch book from file assets/wbsamples/me2000.csv
load Book: assets/wbsamples/me2000 csv  
write seems successful, please check assets/wbsamples/me2000.lst

real    0m15.438s
user    0m22.081s
sys     0m2.265s
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
$ dart run bin/nohfibu.dart --help # to test directly from the source dir
$ nohfibu --help # if you have activated the project, or precompiled
$ nohfibu -r -b assets/wbsamples/sample # will analyze the .csv file and produce a .lst result file
$ nohfibu  -b assets/wbsamples/sample -f MERCH# will try to fill in new journal lines following the 
                                              # MERCH receipe (in the .csv file under OPS)
```

at the moment issues only to read in csv file, but will be extended in a future version


## Documentation

the documentation written for the C wb fibu, one day soon, hopefully, i will extend it to include the 
dart version, https://www.nohkumado.eu/nohfibu/ still logic and theory will be the same, so please 
adapt as fit, but its still usable.

