# Source: https://forum.mikrotik.com/t/chalk-function-for-colorizing-text-output-using-ansi-codes/168093/1
# Topic: $CHALK - function for colorizing text output using ANSI codes
# Source archive: mcp-discourse SQLite (source_name=amm0)
# Extracted from: code-block

# handle 8-bit color names
:local lookupcolor8 do={
    :local color8 {
        black={30;40};
        red={31;41};
        green={32;42};
        yellow={33;43};
        blue={34;44};
        magenta={35;45};
        cyan={36;46};
        white={37;47};
        "no-style"={39;49};
        reset={0;0};
        "bright-black"={90;0};
        "gray"={90;100};
        "grey"={90;100};
        "bright-red"={91;101};
        "bright-green"={92;103};
        "bright-yellow"={93;104};
        "bright-blue"={94;104};
        "bright-magenta"={95;105};
        "bright-cyan"={96;106};
        "bright-white"={97;107}
    }
    :if ($1 = "as-array") do={:return $color8}
    :if ([:typeof ($color8->$1)]="array") do={
        :return ($color8->$1) 
    } else={
        :return [:nothing]
    }
}

:if ($1 = "color") do={
    :if ([:typeof $2] = "str") do={
        :local ccode [$lookupcolor8 $2]
        :if ([:len $ccode] > 0) do={
            :put $ccode 
            :return [:nothing]
        } else={$CHALK colors}
    } else={$CHALK colors}
}
:if ($1 = "colors") do={
    :put "\t <color>\t\t $[$CHALK no-style inverse=yes]inverse=yes$[$CHALK reset]\t\t $[$CHALK no-style bold=yes]bold=yes$[$CHALK reset]\t\t $[$CHALK no-style dim=yes]dim=yes$[$CHALK reset]"
    :foreach k,v in=[$lookupcolor8 as-array] do={
        :local ntabs "\t"
        :if ([:len $k] <  8 ) do={
            :set ntabs "\t\t"
        } 
        :put "\t$[$CHALK $k]$k$[$CHALK reset]$ntabs$[$CHALK $k inverse=yes]\t$k$[$CHALK reset]\t$[$CHALK $k bold=yes]$ntabs$k$[$CHALK reset]\t$[$CHALK $k dim=yes]$ntabs$k$[$CHALK reset]"

   } 
   :return [:nothing]
}

:if ($1 = "help") do={
    :put $helptext
    :return [:nothing]
}

# handle clickable URLs
:if ($1 = "url") do={
    :local lurl "http://example.com"
    :if ([:typeof $2]="str") do={
        :set lurl $2
    } else={
        :if ([:typeof $url]="str") do={
            :set lurl $url
        } 
    }
    :local ltxt $lurl
    :if ([:typeof $text]="str") do={
        :set ltxt $text
    }
    :return "\1B]8;;$lurl\07$ltxt\1B]8;;\07" 
}

# set default colors
:local c8str {mod="";fg="$([$lookupcolor8 no-style]->0)";bg="$([$lookupcolor8 no-style]->1)"}

# if the color name is the 1st arg, make the the foreground color
:if ([:typeof [$lookupcolor8 $1]] = "array") do={
    :set ($c8str->"fg") ([$lookupcolor8 $1]->0) 
} 

# set default colors

# set the modifier...
# hidden= 
:if ($hidden="yes") do={
    :set ($c8str->"mod") "8;"
} else={
    # inverse= 
    :if ($inverse="yes") do={
        :set ($c8str->"mod") "7;"
    } 
    # bold=
    :if ($bold="yes") do={
        :set ($c8str->"mod") "$($c8str->"mod")1;"
        # set both bold=yes and light=yes? bold wins...
    } else={
        # dim=
        :if ($dim="yes") do={
            :set ($c8str->"mod") "$($c8str->"mod")2;"
        }
    }        
}

# if bg= set, apply color  
:if ([:typeof $bg]="str") do={
    :if ([:typeof [$lookupcolor8 $bg]] = "array") do={
        :set ($c8str->"bg") ([$lookupcolor8 $bg]->1)
    } else={:error "bg=$bg is not a valid color"}
}

# build the output
:local rv "\1B[$($c8str->"mod")$($c8str->"fg");$($c8str->"bg")m"

# if debug=yes, show the ANSI codes instead
:if ($debug = "yes") do={
    :return [:put "\\1B[$[:pick $rv 2 80]"]
}

# if the 2nd arg is text, or text= set, 
:local ltext $2
:if ([:typeof $text]="str") do={
    :set ltext $text
}

:if ([:typeof $ltext] = "str") do={
    :return [:put "$rv$2$[$CHALK reset]"]
}


:return $rv
