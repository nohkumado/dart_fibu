# installation

## dart installation

> **WARNING**: if not otherwise specified, never execute anything as root user,
>
> if you do, be prepared for a hell of pain!
> **you are warned!**
>
### Installation of the flutter framework by source

```bash
$ cd projects # or wherever you store your stuff
$ git clone https://github.com/flutter/flutter.git
$ export PATH=$PATH:`pwd`/flutter/bin # to enable dart locally in the actual shell
$ flutter doctor # check that the installation is working
$ dart --version # check that the dart interpreter is working
```

### Installing dart from image on a raspberry pi (arm64)

```bash
$ cd projects # or wherever you store your stuff
$ wget https://storage.googleapis.com/dart-archive/channels/stable/release/2.14.2/sdk/dartsdk-linux-arm64-release.zip
$ unzip dartsdk-linux-arm64-release.zip 
$ rm dartsdk-linux-arm64-release.zip 
$ dart-sdk/bin/dart --version # check that the dart interpreter is working
$ export PATH=$PATH:`pwd`/dart-sdk/bin # to enable dart locally in the actual shell
```

### Installing dart on an android tablet (arm64)

you will need a working termux environment:  https://play.google.com/store/apps/details?id=com.termux

once up and  running, hit

```bash
pkg install dart
```

and you are good
You probably want to install also vim (+dart pugins), git and you other usual tools.

### Installing dart on a linux tablet (arm64)

Follow the instructions of getting flutter through git above, if you are running a JingPad with broken
OpenGL implementation, you need to disable the OpenGl rendering and forcing , slow, software rendering by:


```bash
unset LD_LIBRARY_PATH
```

## NohFibu installation/source managment

### How to fetch the sources from git

#### first time for public, non contributing users

```bash
$ cd projects # or wherever you store your stuff
$ git clone https://github.com/nohkumado/dart_fibu.git .
$ cd dart_fibu/ # or wherever you store your stuff
$ dart run bin/wbconvert.dart --help
```

The last line is to check that all went well and the thing is working

#### first time for contributing users with configured (ssh keys!) git account

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

### Installation/activation of the NohFibu executable

Once this runs, you can activate the project, for this you have to be in the root dir of the project:
> **You need to repeat this after updates  if some binaries are missing!**


### Activation from the sources
```bash
$ dart pub global activate --source path `pwd`
```

### Activation from pub.dev

A neat thing about dart is, you don't need to fetch the sources if you only want to use the program!
In this case, you use the https://pub.dev/packages/nohfibu version directly.

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