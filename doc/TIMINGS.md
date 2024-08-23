# Timings on different platforms

1. Raspberry pi: Linux videolan 5.10.60-v8+ #1449 SMP PREEMPT Wed Aug 25 15:01:33 BST 2021 aarch64 GNU/Linux
2. Desktop: Linux hayate 5.10.0-8-amd64 #1 SMP Debian 5.10.46-4 (2021-08-03) x86_64 GNU/Linux
3. Android Tablet: Linux localhost 4.19.127-00093-g346b5a40acd7 #2 SMP PREEMPT Thu Apr 1 15:33:26 CST 2021 aarch64 Android
4. JingPad: Linux JingOS 4.14.133-202109280105+ #9-JingOS SMP PREEMPT Tue Sep 28 01:15:40 CST 2021 aarch64 aarch64 aarch64 GNU/Linux 
5. Librem5: Linux librem5 5.13.0-1-librem5 #1 SMP PREEMPT Wed Oct 27 08:25:29 PDT 2021 aarch64 GNU/Linux


## Runtime Test
Test-command run: 

```
bboett@[videolan,desktop, android pad, jingpad]:~/projects/dart_fibu $ time dart run bin/nohfibu.dart -b assets/wbsamples/me2000.csv  -r
```

### Debug mode

#### Raspberry pi:
|real|user|sys|
|:--- | :--- | :---|
|0m22.078s|0m29.947s|0m2.788s|

#### Desktop:
|real|user|sys|
|:--- | :--- | :---|
|0m1,826s|0m2,517s|0m0,487s|


#### Android Tablet with termux
|real|user|sys|
|:--- | :--- | :---|
|1m6.049s|1m29.900s|0m8.316s|

#### JingPad

|real|user|sys|
|:--- | :--- | :---|
|0m12.802s|0m18.093s|0m1.080s|

#### Librem 5

|real|user|sys|
|:--- | :--- | :---|
|3m38.662s|5m34.640s|0m25.483s|

### compiled mode 

```
dart compile exe  bin/wbconvert.dart -o ~/bin/fibuwbconvert # to avoid name conflicts...
```

|platform       |type   | timing |
|:--- | --- | :---|
|Desktop:       |real  |0m01,826s|
|Raspberry pi4: |real  |0m22.078s|
|Android Tablet:|real  |1m06.049s|
|JingPad:       |real  |0m01.575s|
|Librem 5:      |real  |0m05.524s|
|Librem 11:     |real  |0m00,304s|

The librem11 test was donw with a way more recent dart install, should redo all the tests,...
