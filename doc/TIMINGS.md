# Timings on different platforms

1. Raspberry pi: Linux videolan 5.10.60-v8+ #1449 SMP PREEMPT Wed Aug 25 15:01:33 BST 2021 aarch64 GNU/Linux
2. Desktop: Linux hayate 5.10.0-8-amd64 #1 SMP Debian 5.10.46-4 (2021-08-03) x86_64 GNU/Linux
3. Android Tablet:
4. JingPad: 
5. Librem5:librem5

## Runtime Test
Test-command run: 

```
bboett@[videolan,desktop, android pad, jingpad]:~/projects/dart_fibu $ time dart run bin/nohfibu.dart -b assets/wbsamples/me2000.csv  -r
```

### Debug mode

#### Raspberry pi:
real    0m22.078s user    0m29.947s sys     0m2.788s

#### Desktop:
real	0m1,826s user	0m2,517s sys	0m0,487s
bboett@hayate:~/AndroidStudioProjects/dart_fibu$ uname -a

#### Android Tablet with termux
real    1m6.049s user    1m29.900s sys     0m8.316s

#### Jinpad

real    0m12.802s user    0m18.093s sys     0m1.080s

#### Librem 5

real    3m38.662s user    5m34.640s sys     0m25.483s

### compiled mode 

```
dart compile exe  bin/wbconvert.dart -o ~/bin/fibuwbconvert # to avoid name conflicts...
```

Desktop:       real    0m01,826s
Raspberry pi4: real    0m22.078s
Android Tablet:real    1m06.049s
JingPad:       real    0m01.575s
Librem 5:      real    0m05.524s
