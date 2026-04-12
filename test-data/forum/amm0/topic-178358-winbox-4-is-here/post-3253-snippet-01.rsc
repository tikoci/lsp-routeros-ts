# Source: https://forum.mikrotik.com/t/winbox-4-is-here/178358/3253
# Topic: 📣 WinBox 4 is here 📣
# Source archive: mcp-discourse SQLite (source_name=amm0)
# Extracted from: code-block

-------------------------------------
Translated Report (Full Report Below)
-------------------------------------

Process:               WinBox [96905]
Path:                  /Applications/WinBox.app/Contents/MacOS/WinBox
Identifier:            com.mikrotik.winbox
Version:               4.0.98044 (4.0.98044)
Code Type:             X86-64 (Native)
Parent Process:        launchd [1]
User ID:               506

Date/Time:             2026-01-02 13:56:14.4639 -0800
OS Version:            macOS 15.6.1 (24G90)
Report Version:        12
Bridge OS Version:     9.6 (22P6083)
Anonymous UUID:        86ACF646-12D5-4059-5A43-605C0F154657

Sleep/Wake UUID:       C49F2F39-4731-4E38-9F65-5B249391FAD8

Time Awake Since Boot: 1500000 seconds
Time Since Wake:       18149 seconds

System Integrity Protection: enabled

Crashed Thread:        0  Dispatch queue: com.apple.main-thread

Exception Type:        EXC_BAD_ACCESS (SIGSEGV)
Exception Codes:       KERN_INVALID_ADDRESS at 0x0000000000000008
Exception Codes:       0x0000000000000001, 0x0000000000000008

Termination Reason:    Namespace SIGNAL, Code 11 Segmentation fault: 11
Terminating Process:   exc handler [96905]

VM Region Info: 0x8 is not in any region.  Bytes before following region: 4540801016
      REGION TYPE                    START - END         [ VSIZE] PRT/MAX SHRMOD  REGION DETAIL
      UNUSED SPACE AT START
--->  
      __TEXT                      10ea72000-110cf6000    [ 34.5M] r-x/r-x SM=COW  /Applications/WinBox.app/Contents/MacOS/WinBox

Thread 0 Crashed::  Dispatch queue: com.apple.main-thread
0   WinBox                        	       0x110322ef2 Handler::sendCmd(unsigned int, HPath const&, nv::message&) + 610
1   WinBox                        	       0x11031a773 0x10ea72000 + 25855859
2   WinBox                        	       0x110323ffc IHandlerMngr::msgRx(nv::message) + 1212
3   WinBox                        	       0x11018fc51 0x10ea72000 + 24239185
4   WinBox                        	       0x110191d3b 0x10ea72000 + 24247611
5   WinBox                        	       0x10fdacafa 0x10ea72000 + 20163322
6   WinBox                        	       0x10fdacafa 0x10ea72000 + 20163322
7   WinBox                        	       0x10f5b9bf2 0x10ea72000 + 11828210
8   WinBox                        	       0x10f5c20dd 0x10ea72000 + 11862237
9   WinBox                        	       0x10fd6c248 0x10ea72000 + 19898952
10  WinBox                        	       0x10fd6bfce 0x10ea72000 + 19898318
11  WinBox                        	       0x10fe9a8df 0x10ea72000 + 21137631
12  CoreFoundation                	    0x7ff8117befb3 __CFSocketPerformV0 + 951
13  CoreFoundation                	    0x7ff811798ab0 __CFRUNLOOP_IS_CALLING_OUT_TO_A_SOURCE0_PERFORM_FUNCTION__ + 17
14  CoreFoundation                	    0x7ff811798a52 __CFRunLoopDoSource0 + 157
15  CoreFoundation                	    0x7ff81179880d __CFRunLoopDoSources0 + 203
16  CoreFoundation                	    0x7ff811797476 __CFRunLoopRun + 973
17  CoreFoundation                	    0x7ff811796a72 CFRunLoopRunSpecific + 536
18  HIToolbox                     	    0x7ff81d2880d4 RunCurrentEventLoopInMode + 281
19  HIToolbox                     	    0x7ff81d28af97 ReceiveNextEventCommon + 499
20  HIToolbox                     	    0x7ff81d41419a _BlockUntilNextEventMatchingListInModeWithFilter + 63
21  AppKit                        	    0x7ff8151fbdb1 _DPSNextEvent + 912
22  AppKit                        	    0x7ff815c8a137 -[NSApplication(NSEventRouting) _nextEventMatchingEventMask:untilDate:inMode:dequeue:] + 1263
23  AppKit                        	    0x7ff8151ece99 -[NSApplication run] + 610
24  WinBox                        	       0x10eac9349 0x10ea72000 + 357193
25  WinBox                        	       0x10fd73746 0x10ea72000 + 19928902
26  WinBox                        	       0x10fd6c368 0x10ea72000 + 19899240
27  WinBox                        	       0x1101627f5 main + 19749
28  dyld                          	    0x7ff81130a530 start + 3056

Thread 1:: QQmlThread
0   libsystem_kernel.dylib        	    0x7ff8116748f2 poll + 10
1   WinBox                        	       0x10feade7f 0x10ea72000 + 21216895
2   WinBox                        	       0x10feb18f3 0x10ea72000 + 21231859
3   WinBox                        	       0x10fd73746 0x10ea72000 + 19928902
4   WinBox                        	       0x10fe2b629 0x10ea72000 + 20682281
5   WinBox                        	       0x10feaf8eb 0x10ea72000 + 21223659
6   libsystem_pthread.dylib       	    0x7ff8116afe59 _pthread_start + 115
7   libsystem_pthread.dylib       	    0x7ff8116ab857 thread_start + 15

Thread 2:: QNetworkAccessManager thread
0   libsystem_kernel.dylib        	    0x7ff8116748f2 poll + 10
1   WinBox                        	       0x10feade7f 0x10ea72000 + 21216895
2   WinBox                        	       0x10feb18f3 0x10ea72000 + 21231859
3   WinBox                        	       0x10fd73746 0x10ea72000 + 19928902
4   WinBox                        	       0x10fe2b629 0x10ea72000 + 20682281
5   WinBox                        	       0x10feaf8eb 0x10ea72000 + 21223659
6   libsystem_pthread.dylib       	    0x7ff8116afe59 _pthread_start + 115
7   libsystem_pthread.dylib       	    0x7ff8116ab857 thread_start + 15

Thread 3:: com.apple.CFSocket.private
0   libsystem_kernel.dylib        	    0x7ff8116769fe __select + 10
1   CoreFoundation                	    0x7ff8117bd10c __CFSocketManager + 671
2   libsystem_pthread.dylib       	    0x7ff8116afe59 _pthread_start + 115
3   libsystem_pthread.dylib       	    0x7ff8116ab857 thread_start + 15

Thread 4:: QSGRenderThread
0   libsystem_kernel.dylib        	    0x7ff8116706f6 __psynch_cvwait + 10
1   libsystem_pthread.dylib       	    0x7ff8116b0302 _pthread_cond_wait + 988
2   WinBox                        	       0x10febc1db 0x10ea72000 + 21275099
3   WinBox                        	       0x10febc134 0x10ea72000 + 21274932
4   WinBox                        	       0x10f073c14 0x10ea72000 + 6298644
5   WinBox                        	       0x10f073d06 0x10ea72000 + 6298886
6   WinBox                        	       0x10f07422c 0x10ea72000 + 6300204
7   WinBox                        	       0x10feaf8eb 0x10ea72000 + 21223659
8   libsystem_pthread.dylib       	    0x7ff8116afe59 _pthread_start + 115
9   libsystem_pthread.dylib       	    0x7ff8116ab857 thread_start + 15

Thread 5:: com.apple.NSEventThread
0   libsystem_kernel.dylib        	    0x7ff81166db4a mach_msg2_trap + 10
1   libsystem_kernel.dylib        	    0x7ff81167c704 mach_msg2_internal + 83
2   libsystem_kernel.dylib        	    0x7ff811674bc3 mach_msg_overwrite + 574
3   libsystem_kernel.dylib        	    0x7ff81166de3b mach_msg + 19
4   CoreFoundation                	    0x7ff811798bf2 __CFRunLoopServiceMachPort + 145
5   CoreFoundation                	    0x7ff81179763f __CFRunLoopRun + 1430
6   CoreFoundation                	    0x7ff811796a72 CFRunLoopRunSpecific + 536
7   AppKit                        	    0x7ff8153509cf _NSEventThread + 127
8   libsystem_pthread.dylib       	    0x7ff8116afe59 _pthread_start + 115
9   libsystem_pthread.dylib       	    0x7ff8116ab857 thread_start + 15

Thread 6:
0   libsystem_pthread.dylib       	    0x7ff8116ab834 start_wqthread + 0

Thread 7:
0   libsystem_pthread.dylib       	    0x7ff8116ab834 start_wqthread + 0

Thread 8:
0   libsystem_pthread.dylib       	    0x7ff8116ab834 start_wqthread + 0

Thread 9:
0   libsystem_pthread.dylib       	    0x7ff8116ab834 start_wqthread + 0

Thread 10:
0   libsystem_pthread.dylib       	    0x7ff8116ab834 start_wqthread + 0

Thread 11:: CVDisplayLink
0   libsystem_kernel.dylib        	    0x7ff8116706f6 __psynch_cvwait + 10
1   libsystem_pthread.dylib       	    0x7ff8116b0335 _pthread_cond_wait + 1039
2   CoreVideo                     	    0x7ff81b1c6f09 CVDisplayLink::waitUntil(unsigned long long) + 375
3   CoreVideo                     	    0x7ff81b1c5ea0 CVDisplayLink::runIOThread() + 524
4   libsystem_pthread.dylib       	    0x7ff8116afe59 _pthread_start + 115
5   libsystem_pthread.dylib       	    0x7ff8116ab857 thread_start + 15


Thread 0 crashed with X86 Thread State (64-bit):
  rax: 0x00006000006591e0  rbx: 0x00007ff7b148b330  rcx: 0x0000000111088400  rdx: 0x0000000111088000
  rdi: 0x0000000000000002  rsi: 0x0000600000658000  rbp: 0x00007ff7b148b260  rsp: 0x00007ff7b148b220
   r8: 0x0000000000000008   r9: 0x000000006be2e800  r10: 0x00000000001ff800  r11: 0x0000000000000030
  r12: 0x0000600001397cc0  r13: 0x000060000065bc90  r14: 0x0000000000000000  r15: 0x0000000000000008
  rip: 0x0000000110322ef2  rfl: 0x0000000000010216  cr2: 0x0000000000000008
  
Logical CPU:     8
Error Code:      0x00000004 (no mapping for user data read)
Trap Number:     14

Thread 0 instruction stream:
  8b 23 4d 8b 6c 24 20 4d-85 ed 74 23 4c 89 e8 66  .#M.l$ M..t#L..f
  66 66 66 66 66 2e 0f 1f-84 00 00 00 00 00 81 38  fffff..........8
  02 00 ff 88 74 31 48 8b-40 08 48 85 c0 75 ef bf  ....t1H.@.H..u..
  28 00 00 00 e8 99 89 75-fe c7 00 02 00 ff 88 0f  (......u........
  57 c0 0f 11 40 10 48 c7-40 20 00 00 00 00 4c 89  W...@.H.@ ....L.
  68 08 49 89 44 24 20 48-83 c0 10 4c 39 f8 74 1a  h.I.D$ H...L9.t.
 [49]8b 76 08 49 8b 56 10-48 89 d1 48 29 f1 48 c1  I.v.I.V.H..H).H.	<==
  f9 02 48 89 c7 e8 24 fb-f3 ff 49 8b 7e 20 48 8b  ..H...$...I.~ H.
  07 48 89 de ff 50 10 48-83 c4 18 5b 41 5c 41 5d  .H...P.H...[A\A]
  41 5e 41 5f 5d c3 eb 00-48 89 c3 48 8b 7d c0 48  A^A_]...H..H.}.H
  85 ff 74 09 48 89 7d c8-e8 07 89 75 fe 48 89 df  ..t.H.}....u.H..
  e8 19 87 75 fe 66 0f 1f-84 00 00 00 00 00 55 48  ...u.f........UH

Binary Images:
       0x10ea72000 -        0x110cf5fff com.mikrotik.winbox (4.0.98044) <5fbbe0e4-0fc1-3aed-910f-1158fe462ca9> /Applications/WinBox.app/Contents/MacOS/WinBox
       0x11428c000 -        0x1142a2fff com.apple.security.csparser (3.0) <cbad8bc8-7a41-3852-bf3e-f32fb787dff0> /System/Library/Frameworks/Security.framework/Versions/A/PlugIns/csparser.bundle/Contents/MacOS/csparser
       0x11df22000 -        0x11df2efff libobjc-trampolines.dylib (*) <fc1d5fa4-f762-3c6a-bdff-bc47152fb2de> /usr/lib/libobjc-trampolines.dylib
    0x7ff81171d000 -     0x7ff811bd1fe2 com.apple.CoreFoundation (6.9) <e07800d9-4e39-3c3c-852c-6620a2ae4070> /System/Library/Frameworks/CoreFoundation.framework/Versions/A/CoreFoundation
    0x7ff81d1e0000 -     0x7ff81d4c16ed com.apple.HIToolbox (2.1.1) <cace9f6b-e827-3cc3-8613-47743a3c458c> /System/Library/Frameworks/Carbon.framework/Versions/A/Frameworks/HIToolbox.framework/Versions/A/HIToolbox
    0x7ff8151bc000 -     0x7ff81670d493 com.apple.AppKit (6.9) <fe1f4402-834c-30cb-b66b-ccec88c1dc60> /System/Library/Frameworks/AppKit.framework/Versions/C/AppKit
    0x7ff811304000 -     0x7ff81139e6c7 dyld (*) <c6e52c5e-d1d2-354c-a4ec-069f8d5baafe> /usr/lib/dyld
               0x0 - 0xffffffffffffffff ??? (*) <00000000-0000-0000-0000-000000000000> ???
    0x7ff81166d000 -     0x7ff8116a9b4f libsystem_kernel.dylib (*) <a0701b73-99d9-31f3-babf-51c65e53ebbd> /usr/lib/system/libsystem_kernel.dylib
    0x7ff8116aa000 -     0x7ff8116b5faf libsystem_pthread.dylib (*) <2f5f8bae-cebe-30d8-83e3-eca5a30ea39d> /usr/lib/system/libsystem_pthread.dylib
    0x7ff81b1c4000 -     0x7ff81b217913 com.apple.CoreVideo (1.8) <ab5d4910-4b00-301c-b99e-2cc2097655b5> /System/Library/Frameworks/CoreVideo.framework/Versions/A/CoreVideo

External Modification Summary:
  Calls made by other processes targeting this process:
    task_for_pid: 0
    thread_create: 0
    thread_set_state: 0
  Calls made by this process:
    task_for_pid: 0
    thread_create: 0
    thread_set_state: 0
  Calls made by all processes on this machine:
    task_for_pid: 8
    thread_create: 0
    thread_set_state: 419

VM Region Summary:
ReadOnly portion of Libraries: Total=1.2G resident=0K(0%) swapped_out_or_unallocated=1.2G(100%)
Writable regions: Total=2.7G written=0K(0%) resident=0K(0%) swapped_out=0K(0%) unallocated=2.7G(100%)

                                VIRTUAL   REGION 
REGION TYPE                        SIZE    COUNT (non-coalesced) 
===========                     =======  ======= 
Accelerate framework               256K        2 
Activity Tracing                   256K        1 
CG image                          32.1M        6 
ColorSync                          252K       31 
CoreAnimation                      184K       17 
CoreGraphics                        12K        2 
CoreUI image data                 1192K        9 
Foundation                          40K        2 
IOKit                             15.5M        2 
JS VM Gigacage                    16.0M        4 
JS VM Isolated Heap               6416K        5 
Kernel Alloc Once                    8K        1 
MALLOC                             2.6G      139 
MALLOC guard page                   72K       18 
STACK GUARD                       56.0M       12 
Stack                             21.1M       13 
VM_ALLOCATE                        848K      109 
__CTF                               824        1 
__DATA                            32.9M      919 
__DATA_CONST                     102.0M      941 
__DATA_DIRTY                      2576K      337 
__FONT_DATA                        2352        1 
__INFO_FILTER                         8        1 
__LINKEDIT                       163.0M        5 
__OBJC_RO                         61.3M        1 
__OBJC_RW                         2396K        2 
__TEXT                             1.1G      958 
__TPRO_CONST                         16        2 
mapped file                      231.0M       75 
shared memory                     1312K       19 
===========                     =======  ======= 
TOTAL                              4.4G     3635
