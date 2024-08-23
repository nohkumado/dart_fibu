#!/bin/bash
mkdir ~/bin
dart pub get
dart compile exe  bin/nohfibu.dart -o ~/bin/fibu
dart compile exe  bin/wbconvert.dart -o ~/bin/fibuwbconvert # to avoid name conflicts...
