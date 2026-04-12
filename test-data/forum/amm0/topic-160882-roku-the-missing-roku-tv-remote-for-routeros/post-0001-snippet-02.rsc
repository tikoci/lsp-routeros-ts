# Source: https://forum.mikrotik.com/t/roku-the-missing-roku-tv-remote-for-routeros/160882/1
# Topic: $ROKU, the missing Roku TV remote for RouterOS
# Source archive: mcp-discourse SQLite (source_name=amm0)
# Extracted from: code-block

# $ROKU - the missing remote for RouterOS


:global ROKU
:global debug 0

# helpers types
:global "roku-rcpmap"
:global "roku-sendkey"

# UDP port for communication with roku (set later, default is 8060)
:global "roku-active-rcpport"

# RouterOS ASCII mappings 
:global "ascii-map"
:global "ascii-name"

# main command function
:set ROKU do={
    # no keyboard events, so poll for keypresses every...
    :local loopdelay 100ms
    
    # global used variables must be defined
    :global ROKU
    :global "roku-rcpmap"
    :global "roku-sendkey"
    :global "ascii-map"
    :global "ascii-name" 
    :global "roku-active-rcpport"

    # default is port 8060
    :if ([:typeof ($"roku-active-rcpport")]!="num") do={ 
        :set "roku-active-rcpport" 8060
    }
 
   
    # we require some command after $ROKU, like help or remote...
    :if ([typeof $1]="str") do={
        # if it's a known command, like "$ROKU back", easy...
        :local cmd ($"roku-rcpmap"->$1->"cmd")
        :if ([:typeof $cmd]="str") do={
            :local sendkeyout [$"roku-sendkey" $1]
            :put "\$ROKU '$1' sent to $sendkeyout"
            :return $sendkeyout
        }
        # interactive remote use "$ROKU remote"...
        :if ($1="remote") do={
            # first, output possible commands            
            :put "\t   ALL  \t            TV ONLY"

            # & process $"roku-rcpmap" for output and
            # as a "pivot" rcpmap on keypress (e.g. lookup table for keypress to roku cmds)
            :local cmdkeymap [:toarray ""]
            :local lastcol -1
            :foreach k,v in=($"roku-rcpmap") do={ 
                :local hit ($v->"keypress")
                :local tags ($v->"tags")
                :local cmd ($v->"cmd")
                :if ($tags~"tv") do={
                    :if ($lastcol=0) do={/terminal cuu}
                    :put "\t\t\t\t$hit - $cmd"
                    :set $lastcol 1
                } else={
                    :if ($lastcol=1) do={/terminal cuu}
                    :put "$hit - $cmd"
                    :set $lastcol 0
                }
                :set ($cmdkeymap->"$hit") $cmd
            }
            # always map array keys
            :set ($cmdkeymap->"up") "Up"
            :set ($cmdkeymap->"down") "Down"
            :set ($cmdkeymap->"left") "Left"
            :set ($cmdkeymap->"right") "right"
            :put ""

            :local keyed 65535
            :local started 1
            :local keyboard 0
            :while ($started) do={ 
                :local keyname [$"ascii-name" $keyed]
         
                :if ($keyname="`") do={
                    :if ($keyboard=1) do={
                        :set keyboard 0
                        /terminal cuu
                    } else={
                        :set keyboard 1
                        :put "KEYBOARD MODE ACTIVE               "
                    }
                }
                :if ($keyboard=0 && [:typeof ($cmdkeymap->"$keyname")]="str") do={
                        :local sendkeyout [$"roku-sendkey" ($cmdkeymap->"$keyname")]
                        :put "\$ROKU $sendkeyout SENT $(($cmdkeymap->"$keyname"))"
                        :set keyed 65535
                        /terminal cuu
                } else={
                    :if ($keyboard=1 && $keyname~"^([A-z0-9]|\\.|enter|space|back)\$") do={
                        :local litkey "Lit_$keyname"
                        :if ($keyname="enter") do={:set litkey "Enter"}
                        :if ($keyname="space") do={:set litkey "Lit_%20"}
                        :if ($keyname="back") do={:set litkey "Backspace"}
                        $"roku-sendkey" $litkey
                        /terminal cuu 
                        :put "\t\t\t\t     sent $litkey      "
                    }
                }                
                :if ($keyboard=0 && $keyname~"q|Q|x|X") do={
                    :return "Quiting Roku Remote..."
                }
                :set keyed [/terminal inkey timeout=$loopdelay]
            }
            :return ""
        }
        :if ($1="help") do={
            :put "\$ROKU - the missing remote for Mikrotik"
            :put "   \$ROKU remote  -  interactive remote using vi-like key maps"
            :put "   \$ROKU set ip=<roku_ip> - set Roku IP address as a static DNS name 'roku'"
            :put "   \$ROKU <cmd>  -  issues a single Roku remote control command, specifically:"
            :foreach k,v in=($"roku-rcpmap") do={
                :local requires ""
                :if (($v->"tags")~"tv") do={
                    :set requires "(requires TV with built-in Roku)"
                }
                :put "\t\$ROKU $k \t$requires"
            }
            :return ""
        }
        :if ($1="set") do={
            :if ([:typeof [:toip $ip]]="ip") do={
                :local rokudns [/ip dns static find name="roku"]
                :if ([:len $rokudns]=1) do={
                    /ip dns static set $rokudns address=$ip
                } else={
                    /ip dns static add name=roku address=$ip type=A
                }
            }
            :if ([:typeof $port]="str") do={
                :set ($"roku-active-rcpport") [:tonum $port]
            }
            :return ""
        }
        :if ($1="print") do={
            :put "\t ip: \t $[:resolve roku]"
            :put "\t port: \t $($"roku-active-rcpport")"
            :return ""
        }
    }

    [$ROKU help]
}

:global "roku-sendkey"
:set "roku-sendkey" do={
    :global "roku-rcpmap"
    :global "roku-active-rcpport"
    :global debug
    :local rokuip [:resolve roku]
    :local rokuport ($"roku-active-rcpport")
    :if ([:typeof $rokuip]!="ip") do={
        :put "Problem! \$ROKU does a DNS lookup for 'roku'. To fix, use a static DNS entry with the IP of your Roku devices"
        :error "\$ROKU 'roku' does not resolve to an IP address.  An IP address of a Roku device is required."
    }
    :if ($1="Lit") do={:return "$rokuip:$rokuport"}
    :local rokurl "http://$rokuip:$rokuport/keypress/$1"
    :if ($debug = 1) do={
        :put "DEBUG: sending $rokurl"
    } 
    :do command={
        :local out [/tool fetch http-method=post output=none url=$rokurl as-value]
    } on-error={:put "Unsupported command."; /terminal cuu}
    :return "$rokuip:$rokuport"
}

# KV array mapping roku commands to keyboard
# (tags= is used by help to organize the grouping)
:global "roku-rcpmap" 
:set "roku-rcpmap" {
    "home"={
        cmd="Home";
        keypress="tab";
        tags={""}
    };
    "reverse"={
        cmd="Rev";
        keypress="b";
        tags={""}
    };
    "forward"={
        cmd="Fwd";
        keypress="f";
        tags={""}
    };
    "play"={
        cmd="Play";
        keypress="space";
        tags={""}
    };
    "select"={
        cmd="Select";
        keypress="enter";
        tags={""}
    };
    "left"={
        cmd="Left";
        keypress="h";
        tags={""}
    };
    "right"={
        cmd="Right";
        keypress="l";
        tags={""}
    };
    "down"={
        cmd="Down";
        keypress="j";
        tags={""}
    };
    "up"={
        cmd="Up";
        keypress="k";
        tags={""}
    };
    "back"={
        cmd="Back";
        keypress="back";
        tags={""}
    };
    "replay"={
        cmd="InstantReplay";
        keypress="r";
        tags={""}
    };
    "info"={
        cmd="Info";
        keypress="i";
        tags={""}
    };
    "backspace"={
        cmd="Backspace";
        keypress="left";
        tags={""}
    };
    "search"={
        cmd="Search";
        keypress="/";
        tags={""}
    };
    "enter"={
        cmd="Enter";
        keypress="enter";
        tags={""}
    };
    "literal"={
        cmd="Lit";
        keypress="`";
        tags={""}
    };
    "find_remote"={
        cmd="FindRemote";
        keypress="F";
        tags={"find"}
    };
    "volume_down"={
        cmd="VolumeDown";
        keypress="-";
        tags={"tv"}
    };
    "volume_up"={
        cmd="VolumeUp";
        keypress="+";
        tags={"tv"}
    };
    "volume_mute"={
        cmd="VolumeMute";
        keypress="0";
        tags={"tv"}
    };
    "channel_up"={
        cmd="ChannelUp";
        keypress="up";
        tags={"tv";"channel"}
    };
    "channel_down"={
        cmd="ChannelDown";
        keypress="down";
        tags={"tv";"channel"}
    };
    "input_tuner"={
        cmd="InputTuner";
        keypress="t";
        tags={"tv";"input"}
    };
    "input_hdmi1"={
        cmd="InputHDMI1";
        keypress="1";
        tags={"tv";"input"}
    };
    "input_hdmi2"={
        cmd="InputHDMI2";
        keypress="2";
        tags={"tv";"input"}
    };
    "input_hdmi3"={
        cmd="InputHDMI3";
        keypress="3";
        tags={"tv";"input"}
    };
    "input_hdmi4"={
        cmd="InputHDMI4";
        keypress="4";
        tags={"tv";"input"}
    };
    "input_av1"={
        cmd="InputAV1";
        keypress="!";
        tags={"tv";"input"}
    };
    "power"={
        cmd="Power";
        keypress="\\";
        tags={"tv";"power"}
    };
    "poweroff"={
        cmd="PowerOff";
        keypress="P";
        tags={"tv";"power"}
    };
    "poweron"={
        cmd="PowerOn";
        keypress="p";
        tags={"tv";"power"}
    }
}

# function, takes $1 a num result from [/terminal inkey] 
#           and maps to name a string name like "tab" or "enter"
:global "ascii-name"
:set "ascii-name" do={
    :global "ascii-map"
    :local keyname ""
    :local keyed [:tonum $1]
    :if ($keyed<255) do={
        :set keyname ($"ascii-map"->$keyed)
        #:put $keyname
    } else={
        :if ($keyed=65535) do={ :set keyname "timeout" }
        :if ($keyed=60929) do={ :set keyname "left" }
        :if ($keyed=60930) do={ :set keyname "right" }
        :if ($keyed=60931) do={ :set keyname "up" }
        :if ($keyed=60932) do={ :set keyname "down" }
    }
    :return $keyname
}

# array of str, with array index match the ascii code with value being the str name 
:global "ascii-map"
:set "ascii-map" {"";"NUL";"SOH";"STX";"ETX";"EOT";"ENQ";"ACK";"back";"back";"tab";"VT";"FF";"enter";"return";"SI";"DLE";"DC1";"DC2";"DC3";"DC4";"NAK";"SYN";"ETB";"CAN";"EM";"SUB";"ESC";"FS";"GS";"RS";"US";"space";"!";"\"";"comment";"\$";"%";"&";"";"(";")";"*";"+";",";"-";".";"/";"0";"1";"2";"3";"4";"5";"6";"7";"8";"9";":";";";"<";"=";">";"\?";"@";"A";"B";"C";"D";"E";"F";"G";"H";"I";"J";"K";"L";"M";"N";"O";"P";"Q";"R";"S";"T";"U";"V";"W";"X";"Y";"Z";"[";"\\";"]";"^";"_";"`";"a";"b";"c";"d";"e";"f";"g";"h";"i";"j";"k";"l";"m";"n";"o";"p";"q";"r";"s";"t";"u";"v";"w";"x";"y";"z";"{";"|";"}";"~";"delete";"\80";"\81";"\82";"\83";"\84";"\85";"\86";"\87";"\88";"\89";"\8A";"\8B";"\8C";"\8D";"\8E";"\8F";"\90";"\91";"\92";"\93";"\94";"\95";"\96";"\97";"\98";"\99";"\9A";"\9B";"\9C";"\9D";"\9E";"\9F";"\A0";"\A1";"\A2";"\A3";"\A4";"\A5";"\A6";"\A7";"\A8";"\A9";"\AA";"\AB";"\AC";"\AD";"\AE";"\AF";"\B0";"\B1";"\B2";"\B3";"\B4";"\B5";"\B6";"\B7";"\B8";"\B9";"\BA";"\BB";"\BC";"\BD";"\BE";"\BF";"\C0";"\C1";"\C2";"\C3";"\C4";"\C5";"\C6";"\C7";"\C8";"\C9";"\CA";"\CB";"\CC";"\CD";"\CE";"\CF";"\D0";"\D1";"\D2";"\D3";"\D4";"\D5";"\D6";"\D7";"\D8";"\D9";"\DA";"\DB";"\DC";"\DD";"\DE";"\DF";"\E0";"\E1";"\E2";"\E3";"\E4";"\E5";"\E6";"\E7";"\E8";"\E9";"\EA";"\EB";"\EC";"\ED";"\EE";"\EF";"\F0";"\F1";"\F2";"\F3";"\F4";"\F5";"\F6";"\F7";"\F8";"\F9";"\FA";"\FB";"\FC";"\FD";"\FE";"\FF"}
