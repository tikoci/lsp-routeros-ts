# Source: https://forum.mikrotik.com/t/amm0s-forum-plugins-tests-routeros-graphviz-diagrams-colors/261912/14
# Topic: Amm0's Forum Plugins Tests — ` ` `routeros & [graphviz] diagrams & colors
# Source archive: mcp-discourse SQLite (source_name=amm0)
# Extracted from: code-block

# version 1.2

:global PIANO do={
    # required for recussion later
    :global PIANO
    # default note time is 200ms for 1/8 note (1x)
    :local nms 200ms
    # change note  length by arg using $PIANO ms=250ms
    :if ([:typeof $ms]="str") do={:set nms [:totime "0.$ms"]}
    :if ([:typeof $ms]="time") do={:set nms $ms}
    # or, use BPM via bpm= to control the length of 1/4 note
    :local lbpm (60000 / (([:tonsec [:totime $nms]] / 1000000) * 2))
    :if ([:typeof $bpm]~"(num|str)") do={
        :set lbpm [:tonum $bpm]
        :set nms [:totime "0.$(60000 / $bpm / 2)"]
    }
    # handle silent=yes (for output recording without playing)
    :local lsilent "no"
    :if ($silent="yes") do={ :set lsilent "yes" }
    # handle 'as-value' to return array, instead of output script
    :local asvalue 0
    :if ([:tostr $1]="as-value") do={:set asvalue 1}

    # array map of keypress to the Hz values for octaves 1 to 9
    #   note: k o l are +1 octave, so those are shifted by 1
    :local scalearr {"a"=("C",33,65,131,262,523,1047,2093,4186,8372) ;
    "w"=("C#",35,69,139,277,554,1109,2217,4435,8870) ;
    "s"=("D",37,73,147,294,587,1175,2349,4699,9397) ;
    "e"=("D#",39,78,156,311,622,1245,2489,4978,9956) ;
    "d"=("E",41,82,165,330,659,1319,2637,5274,10548) ;
    "f"=("F",44,87,175,349,698,1397,2794,5588,11175) ;
    "t"=("F#",46,92,185,370,740,1480,2960,5920,11840) ;
    "g"=("G",49,98,196,392,784,1568,3136,6272,12544) ;
    "y"=("G#",52,104,208,415,831,1661,3322,6645,13290) ;
    "h"=("A",55,110,220,440,880,1760,3520,7040,14080) ;
    "u"=("A#",58,117,233,466,932,1865,3729,7459,14917) ;
    "j"=("B",62,123,247,494,988,1976,3951,7902,15804) ;
    "k"=("+C",65,131,262,523,1047,2093,4186,8372,16744) ;
    "o"=("+C#",139,277,554,1109,2217,4435,8870,17739) ;
    "l"=("+D",73,147,294,587,1175,2349,4699,9397,18795) ;
    }
    # script needs to map numeric ASCII keycode to a string type with letter
    :local asciimap {"";"";"";"";"";"";"";"";"back";"";"tab";"";"";"enter";"return";"";"";"";"";"";"";"";"";"";"";"";"";"ESC";"";"";"";"";"space";"!";"\"";"";"\$";"%";"&";"";"(";")";"*";"+";",";"-";".";"/";"0";"1";"2";"3";"4";"5";"6";"7";"8";"9";":";";";"<";"=";">";"\?";"@";"A";"B";"C";"D";"E";"F";"G";"H";"I";"J";"K";"L";"M";"N";"O";"P";"Q";"R";"S";"T";"U";"V";"W";"X";"Y";"Z";"[";"\\";"]";"^";"_";"`";"a";"b";"c";"d";"e";"f";"g";"h";"i";"j";"k";"l";"m";"n";"o";"p";"q";"r";"s";"t";"u";"v";"w";"x";"y";"z";"{";"|";"}";"~";"delete"}
    # current note size in ms - can be adjusted using 1-8 keys while playing
    :local lnms $nms
    # current octave, default is 4
    :local octave 4
    # current "eighth"
    :local neighth 1
    # store if "recording" and notes played
    :local record 1
    :local played [:toarray ""]
    # ...recording stopped when $record is set to 0, on with 1
    #    notes are pushed to a array "list"
    #    with each element in "outer" list being a list of two values:
    #    ($freq,$lnms) e.g. {(440,125),(440,125)}

    # helper function to format note as C3
    :local getnotename do={
        :local notename $2
        :if ([:len $2] != 0) do={
            :if ([:pick $notename 0 1]="+") do={
                # used higher octave keys like j i k
                :set notename "$[:pick $notename 1 8]$($1 + 1)"
            } else={
                :set notename "$notename$[:tostr $1]"
            }
        } else={:set notename ""}
        :return $notename
    }
    # helper function to print status line on update
    :local printstatus do={
        :local reconoff ""
        :local reccount ""
        # recording ON or OFF
        :if ([:tonum $3]!=0) do={:set reconoff "\1B[1;35mON "} else={:set reconoff "\1B[2;35mOFF"}
        # pretty display of record counter (length of played)
        :for lrec from=1 to=(4-[:len [:tostr [:len $4]]]) do={:set reccount "0$reccount"}
        :set reccount "$reccount$[:tostr [:len $4]]"
        :local notename $7
        # replace last status line, with new status line
        /terminal cuu
        :local notelenstr "$6/8"
        :if ("$6" = "4") do={:set notelenstr "1/2"}
        :if ("$6" = "2") do={:set notelenstr "1/4"}
        :if ("$6" = "6") do={:set notelenstr "3/4"}
        :if ("$6" = "8") do={:set notelenstr " 1 "}
        :put "\t\1B[1;34m$[:pick $2 7 16]s\1B[0m   \1B[2;31mOCTAVE\1B[0m \1B[1;31m$1\1B[0m  \1B[1;34m$notelenstr\1B[0m   \1B[1;35m$reccount\1B[0m \1B[2;35mRECORD\1B[0m $reconoff\1B[0m  \1B[1;7m$notename\1B[0m \1B[1;1m$5\1B[0m      "
    }

    # IF \$PIANO is called with a play=$myrecording, play that and exit
    :if ([:typeof $1]="array") do={
        # optional: store the saved recording, so it's returned again
        # :set played $play
        :set played $1
        :put ""
        :put " # SCRIPT TO PLAY RECORDING"
        :foreach rnote in=$played do={
            :if ([:typeof ($rnote->0)]="num" && [:typeof ($rnote->1)]~"(time|num)") do={
                :if (($rnote->0) > 19) do={
                    # play regular note
                    :if ($lsilent!="yes") do={
                        /beep freq=($rnote->0) length=($rnote->1)
                        /terminal/cuu
                    }
                    :put "     \1B[1;35m /beep\1B[0m  \1B[2;34mlength=\1B[0m\1B[1;34m$[:pick [:tostr ($rnote->1)] 7 16]\1B[0m \1B[2;31mfreq=\1B[0m\1B[1;31m$($rnote->0)\1B[0m \1B[2;31m; (\"\1B[0m\1B[1;7m$($rnote->2)\1B[0m\1B[2;31m\")\1B[0m \1B[2;35m; :delay $[:pick [:tostr ($rnote->1)] 7 16]\1B[0m     "
                } else={
                    # either "marker" - no delay, but comment
                    :if (($rnote->1) = 0) do={
                        :put "\t\t\t# MARK"
                    } else={
                        # or a "rest" - output the delay command
                        :put "\t\1B[1;35m     :delay $[:pick [:tostr ($rnote->1)] 7 16]\1B[0m     "
                    }
                }
                :if ($lsilent!="yes") do={
                    :delay ($rnote->1)
                }
            } else={
                :error "$[:tostr $rnote] contains invalid data"
            }
        }
        :return $played
    }

    # help screen
    :put "\1B[1;7m                    ROUTEROS PLAYER PIANO                    \1B[0m"
    :put "\1B[1;36mType a key to play a note...  1/8th note is $[:pick $nms 7 16]s."
    :put "\1B[2;36m\$PIANO takes ms= and bpm= to set the default note length"
    :put "\1B[1;36mTo play a longer note, use number key with #/8th of a note"
    :put "\1B[2;36m  1 == 1/8  2 == 1/4  4 = 1/2 ... 8 = whole note"
    :put "\1B[1;36mTo quit, hit 'q'"
    :put "\1B[1;36mUse 'x' for next higher octave, or 'z' to lower octave"
    :put "\1B[1;36mTo record, use ','|'.' to start|stop, <BS> to clear"
    :put "\1B[1;36mAny recording will be output as script after 'q'"
    :put "\1B[2;36m  to skip recording output use '\$PIANO as-value ms=120'"
    :put "\1B[2;36m  which will return an array of saved notes/rests/marks"
    :put "\1B[2;36m  e.g. ':global myrecording [\$PIANO as-value bpm=120]'"
    :put "\1B[1;36mTo later playback from var, use '\$PIANO \$myrecording'"
    :put "\1B[2;36m  with the array defined as {{freq;len};{freq;len},...}"
    :put "\1B[0m"
    :put "      \1B[2;34mLEN \1B[1;34m#\1B[2;34m/8\1B[0m \1B[1;34m 1\1B[0m \1B[1;34m 2\1B[0m \1B[1;34m 3\1B[0m \1B[1;34m 4\1B[0m \1B[1;34m 5\1B[0m \1B[1;34m 6\1B[0m \1B[1;34m 7\1B[0m \1B[1;34m 8\1B[0m   \1B[2;34mBPM \1B[1;34m$lbpm  \1B[1;35mCLEAR\1B[0m"
    :put "\t\1B[0m    `  1  2  3  4  5  6  7  8  9  0  -  = del"
    :put "\t      \1B[1;31mQUIT\1B[0m \1B[1;7mC#\1B[0m \1B[1;7mD#\1B[0m    \1B[1;7mF#\1B[0m \1B[1;7mG#\1B[0m \1B[1;7mA#\1B[0m    \1B[1;7mC#\1B[0m        \1B[1;35mMARK\1B[0m"
    :put "\t\1B[0m   tab  q  w  e  r  t  y  u  i  o  p  [  ]  \\"
    :put "\t         \1B[1;7mC\1B[0m  \1B[1;7mD\1B[0m  \1B[1;7mE\1B[0m  \1B[1;7mF\1B[0m  \1B[1;7mG\1B[0m  \1B[1;7mA\1B[0m  \1B[1;7mB\1B[0m  \1B[1;7mC\1B[0m  \1B[1;7mD\1B[0m        \1B[1mREST\1B[0m"
    :put "\t\1B[0m   caps  a  s  d  f  g  h  j  k  l  ;  '  ret"
    :put "\t\1B[1;31m          <  >               \1B[1;35mREC\1B[0m \1B[1;35mSTOP\1B[0m"
    :put "\t\1B[0m   shft   z  x  c  v  b  n  m  ,  .  /  shft"
    :put ""
    # first print of the status line
    $printstatus $octave $lnms $record $played 0 $neighth
    # start live player...
    # - loops per note time, plays notes per stored octave and keypress
    #   ends with q is pressed (ascii code 113)
    :local lastkey 65535
    :local lastfq 0
    :local notename ""
    :while ($lastkey != 113) do={
        # collect input
        :set lastkey [/terminal inkey]
        # 65535 means no keyboard input recieved before input timeout
        :if ($lastkey = 65535) do={:delay $nms} else={
            # if a number, use that as the multiplier for notes per second
            :if ($lastkey > 48 && $lastkey < 57) do={
                :set $neighth ($lastkey - 48)
                :set $lnms ($nms*$neighth)
                # update the display with new time per note
                $printstatus $octave $lnms $record $played $lastfq $neighth $notename
            }
            # convert the keypress ASCII code (num type) to a actual str type with a letter
            :local lastascii ($asciimap->$lastkey)
            :if ($lastkey = 60929) do={:set lastascii "left"}
            :if ($lastkey = 60930) do={:set lastascii "right"}
            :if ($lastkey = 60931) do={:set lastascii "up"}
            :if ($lastkey = 60932) do={:set lastascii "down"}
            # change octave via x or z
            :if ($lastascii ~ "x|z|left|right") do={
                :local newoctave
                :if ($lastascii~"z|left") do={ :set newoctave ($octave-1) } else={ :set newoctave ($octave +1) }
                :if ($newoctave > 0 && $newoctave < 10) do={
                    :set octave $newoctave
                }
            }
            # handle recording start/resume stop/start
            :if ($lastascii = ",") do={:set record 1}
            :if ($lastascii = ".") do={:set record 0}
            # handle clear recording
            :if ($lastascii = "back") do={:set played [:toarray ""]}
            # if enter key, that's a rest, which is stored as freq==0
            :if ($lastascii = "enter") do={
                # add the rest to stored recording
                :if ($record!=0) do={ :set $played ($played,{{0;$lnms}}) }
            }
            # handle mark recording
            :if ($lastascii = "\\") do={
                :if ($record!=0) do={ :set $played ($played,{{0;0}}) }
            }
            # fetch the actual Hz freq for the note, array is 0-based, so ->0 is 1st octave
            :local freq ($scalearr->$lastascii->($octave))
            # actually play the note
            :if ([:typeof $freq]="num") do={
                :if ($freq > 20) do={
                    :if ($silent!="yes") do={
                        :beep frequency=$freq length=$lnms
                    }
                    :set lastfq $freq
                    :set notename [$getnotename $octave ($scalearr->$lastascii->0)]
                    # if recording
                    :if ($record!=0) do={ :set $played ($played,{{$freq;$lnms;$notename}}) }
                }
                :delay $lnms
                /terminal cuu
            }
            $printstatus $octave $lnms $record $played $lastfq $neighth $notename
        }
    }
    :if ($asvalue=1) do={
        :return $played
    } else={
        $PIANO $played silent="yes"
        # in theory, should return nothing without "as-value"
        # but return anyway for easy-of-use
        :return $played
    }
}

:global myrecording [$PIANO bpm=150]
