# Source: https://forum.mikrotik.com/t/inquire-prompt-user-for-input-using-arrays-choices-qkeys/167956/1
# Topic: $INQUIRE - prompt user for input using arrays +$CHOICES +$QKEYS
# Source archive: mcp-discourse SQLite (source_name=amm0)
# Extracted from: code-block

# variable to store answers to return
:local answers [:toarray ""]

# use array to map "ASCII code" (e.g. num type) to a "char" (e.g. str type of len=1)
:local "asciimap" {
    "\00";"\01";"\02";"\03";"\04";"\05";"\06";"\07";"\08";"\09";"\0A";"\0B";"\0C";"\0D";"\0E";"\0F";
    "\10";"\11";"\12";"\13";"\14";"\15";"\16";"\17";"\18";"\19";"\1A";"\1B";"\1C";"\1D";"\1E";"\1F";
    "\20";"\21";"\22";"\23";"\24";"\25";"\26";"\27";"\28";"\29";"\2A";"\2B";"\2C";"\2D";"\2E";"\2F";
    "\30";"\31";"\32";"\33";"\34";"\35";"\36";"\37";"\38";"\39";"\3A";"\3B";"\3C";"\3D";"\3E";"\3F";
    "\40";"\41";"\42";"\43";"\44";"\45";"\46";"\47";"\48";"\49";"\4A";"\4B";"\4C";"\4D";"\4E";"\4F";
    "\50";"\51";"\52";"\53";"\54";"\55";"\56";"\57";"\58";"\59";"\5A";"\5B";"\5C";"\5D";"\5E";"\5F";
    "\60";"\61";"\62";"\63";"\64";"\65";"\66";"\67";"\68";"\69";"\6A";"\6B";"\6C";"\6D";"\6E";"\6F";
    "\70";"\71";"\72";"\73";"\74";"\75";"\76";"\77";"\78";"\79";"\7A";"\7B";"\7C";"\7D";"\7E";"\7F";
    "\80";"\81";"\82";"\83";"\84";"\85";"\86";"\87";"\88";"\89";"\8A";"\8B";"\8C";"\8D";"\8E";"\8F";
    "\90";"\91";"\92";"\93";"\94";"\95";"\96";"\97";"\98";"\99";"\9A";"\9B";"\9C";"\9D";"\9E";"\9F";
    "\A0";"\A1";"\A2";"\A3";"\A4";"\A5";"\A6";"\A7";"\A8";"\A9";"\AA";"\AB";"\AC";"\AD";"\AE";"\AF";
    "\B0";"\B1";"\B2";"\B3";"\B4";"\B5";"\B6";"\B7";"\B8";"\B9";"\BA";"\BB";"\BC";"\BD";"\BE";"\BF";
    "\C0";"\C1";"\C2";"\C3";"\C4";"\C5";"\C6";"\C7";"\C8";"\C9";"\CA";"\CB";"\CC";"\CD";"\CE";"\CF";
    "\D0";"\D1";"\D2";"\D3";"\D4";"\D5";"\D6";"\D7";"\D8";"\D9";"\DA";"\DB";"\DC";"\DD";"\DE";"\DF";
    "\E0";"\E1";"\E2";"\E3";"\E4";"\E5";"\E6";"\E7";"\E8";"\E9";"\EA";"\EB";"\EC";"\ED";"\EE";"\EF";
    "\F0";"\F1";"\F2";"\F3";"\F4";"\F5";"\F6";"\F7";"\F8";"\F9";"\FA";"\FB";"\FC";"\FD";"\FE";"\FF"
}

# some ANSI tricks are used in output to format input and errors
:local "ansi-bright-blue" "\1B[94m"
:local "ansi-reset" "\1B[0m"
:local "ansi-dim-start" "\1B[2m"
:local "ansi-dim-end" "\1B[22m"
:local "ansi-clear-to-end" "\1B[0K"

# main loop - ask each question provided in the $1/$qr array
:for iq from=0 to=([:len $qr]-1) do={
    # define the current answer and use "defval" to populate
    :local ans ($qr->$iq->"defval")
    # if "defval" is inline function, call it to get default value
    :if ([:typeof $ans] ~ "op|array") do={
        :set ans [$ans ($qr->$iq)]
    }
    # ask the question, using an default in $ans
    :put "  $($qr->$iq->"text") $($"ansi-bright-blue") $ans $($"ansi-reset") "
    # last char code received
    :local kin 0
    # keep looking for input from terminal while $inputmode = true
    :local inputmode true
    :while ($inputmode) do={
        # re-use same terminal line
        /terminal cuu
        # get keyboard input, one char
        :set kin [/terminal/inkey]
        # if NOT enter/return key, add char to the current answer in $ans
        :if ($kin != 0x0D) do={
            # use ascii map to convert num to str/"char"
            :set ans "$ans$($asciimap->$kin)"
        } else={
            # got enter/return, stop input
            :set inputmode false
        }
        # if backspace/delete, remove the control code & last char
        :if ($kin = 0x08 || $kin =0x7F) do={
            :set ans [:pick $ans 0 ([:len $ans]-2)]
        }
        # assume input is valud
        :local isvalid true
        :local errortext ""
        # unless validate= is defined...
        # if validate=(>[]) is inline function
        :if ([:typeof ($qr->$iq->"validate")] ~ "op|array") do={
            # call question's validator function
            :set isvalid [($qr->$iq->"validate") $ans]
        }
        # if validate="num", make sure it a num type
        :if (($qr->$iq->"validate") = "num") do={
            # see if casting to num is num
            :if ([:typeof [:tonum $ans]] = "num") do={
                # store as num type
                :set ans [:tonum $ans] 
                # valid so far
                :set isvalid true
                # if a min= is defined, check it
                :if ([:typeof ($qr->$iq->"min")] = "num") do={
                    :if ($ans>($qr->$iq->"min")) do={
                        :set isvalid true
                    } else={
                        :set isvalid "too small, must be > $($qr->$iq->"min") "
                    }
                }
                # if a max= is defined, check it
                :if ([:typeof ($qr->$iq->"max")] = "num") do={
                    # if already invalid, use that text first e.g. too small
                    :if ($isvalid = true) do={
                        :if ($ans<($qr->$iq->"max") && isvalid = true) do={
                            :set isvalid true
                        } else={
                            :set isvalid "too big, must be < $($qr->$iq->"max") "
                        }
                    }
                }
            } else={
                :set isvalid "must be a number"
            }
        }
        # if there is min= or max= but no validate=, assume validate str lengths
        :if ([:typeof ($qr->$iq->"validate")] ~ "nil|nothing") do={
           :if (([:typeof ($qr->$iq->"min")] = "num") || ([:typeof ($qr->$iq->"max")] = "num")) do={
              :set ($qr->$iq->"validate") "str"
           }
        }
        # if validate="str", make sure it's a str type
        :if (($qr->$iq->"validate") = "str") do={
            :if ([:typeof [:tostr $ans]] = "str") do={
                # save answer as str 
                :set ans [:tostr $ans] 
                :set isvalid true
                # if min=, check length in range
                :if ([:typeof ($qr->$iq->"min")] = "num") do={
                    :if ([:len $ans]>($qr->$iq->"min")) do={
                        :set isvalid true
                    } else={
                        :set isvalid "too short, must be > $($qr->$iq->"min") "
                    }
                }
                # if max=, check length in range
                :if ([:typeof ($qr->$iq->"max")] = "num") do={
                    :if ($isvalid = true) do={
                        :if ([:len $ans]<($qr->$iq->"max")) do={
                            :set isvalid true
                        } else={
                            :set isvalid "too long, must be < $($qr->$iq->"max") "
                        }
                    }
                }
            } else={
                :set isvalid "must be a string"
            }
        }
        # if validate="ip", make sure it valid IP address
        # note: IPv6 is not supported
        :if (($qr->$iq->"validate") = "ip") do={
            # make sure it's num.num.num.num BEFORE using :toip to avoid .0 being appended
            :if ($ans ~ "^[0-9]+[\\.][0-9]+[\\.][0-9]+[\\.][0-9]+\$") do={
                # then check it parsable using :toip
                :if ([:typeof [:toip $ans]] = "ip") do={
                    :set ans [:toip $ans] 
                    :set isvalid true
                } else={
                    :set isvalid "IP address not valid"
                }
            } else={
                    :set isvalid "bad IP address format, must be x.y.z.a"
            }
        }
        # if answer is valid, store it in the $answers array
        :if ($isvalid = true) do={
            # if a key="mykeyname" is used, that becomes the key in array map
            :if ([:typeof ($qr->$iq->"key")] = "str") do={
                :set ($answers->"$($qr->$iq->"key")") $ans
            } else={
                # otherwise the key in returned array map is "promptN" where N is index
                :set ($answers->"prompt$iq") $ans 
            }
            :set errortext ""
        } else={
            # if no valid... report the error, and continue input mode
            :set errortext $isvalid
            :set inputmode true
        }
        # finally output the question, using ANSI formatting
        :put "  $($qr->$iq->"text") $($"ansi-bright-blue") $ans $($"ansi-reset") $($"ansi-dim-start") $errortext $($"ansi-dim-end") $($"ansi-clear-to-end")"
        # if action= is defined & validated - call the action
        :if ($kin = 0x0D && isvalid = true) do={
            :if ([:typeof ($qr->$iq->"action")] ~ "op|array") do={
                [($qr->$iq->"action") $ans]
            }
        }
    }
}
# end of questions

# if 2nd arg is a function or "op" (e.g. inline function), call that with the $answers
:if ([:typeof $2] ~ "op|array") do={
    [$2 $answers]        
}
# if 2nd or 3rd arg is "as-value", do not print the results to terminal
:if (($2 = "as-value") || ($3 = "as-value")) do={
    :return $answers
} else={
    :put $answers
    :return $answers
}
