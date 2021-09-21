How to run wbconvert on a raspberry pi (arm64)

wget https://storage.googleapis.com/dart-archive/channels/stable/release/2.14.2/sdk/dartsdk-linux-arm64-release.zip
unzip dartsdk-linux-arm64-release.zip 
rm dartsdk-linux-arm64-release.zip 
dart-sdk/bin/dart --version # check that the dart interpreter is working
export PATH=$PATH:`pwd`/dart-sdk/bin # to enable dart locally in the actual shell
#git clone /media/omv/git/flutter/nohfibu/ .
cd projects/fibu/ # or wherever you store your stuff
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
