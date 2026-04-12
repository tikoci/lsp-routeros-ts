# Source: https://forum.mikrotik.com/t/inquire-prompt-user-for-input-using-arrays-choices-qkeys/167956/29
# Topic: $INQUIRE - prompt user for input using arrays +$CHOICES +$QKEYS
# Source archive: mcp-discourse SQLite (source_name=amm0)
# Extracted from: code-block

:if ([:typeof $1]!="array") do={
    :put " \1B[1m$0 - interactive menu tree, from a user-defined array of 'macros'\1B[0m"
    :put "\tUsage:"
    :put "\t\t$0 <array> [quit=(\"yes\"|\"no\")] [inline=(\"yes\"|\"no\")]\1B[2m" 
    :put "\t\t  <array> - key-value array of 'hotkey' mapped to either"
    :put "\t\t\t- 'op' function with command to run, or "
    :put "\t\t\t- another key-value array with a 'sub-menu' of commands"
    :put "\t\t  inline=(\"yes\"|\"no\") - \"yes\" (default) to show choices inline, \"no\" adds newlines"
    :put "\t\t  quit=(\"yes\"|\"no\") - default is \"yes\" to stay in menu until 'q' quit"
    :put "\t\t           quit=no will exit menu if an function returns a value"
    :put "\t\1B[0mMetakeys:\1B[2m"
    :put "\t\t'q' is always mapped to quit/exit, so it not valid as menu choice in <array>"
    :put "\t\t'/' returns to \"top\" of menu, if in a submenu"
    :put "\t\t'<backspace>' returns to previous menu, if in a submenu"
    :put "\t\1B[0mReturns:\1B[2m"
    :put "\t\tany return value for last command before 'q' (quit), or if quit=no"
    :put "\t\1B[0mMenu Array Format:\1B[2m"
    :put "\t\tThe general array shape is: { a={\"\";(>[]);{}}; s={\"\";{a={\"\";(>[])};{}}}"
    :put "\t\tIn the key-value array provided, the key= is always the keypress in menu"
    :put "\t\tThe key's value is a list-type array of 1, 2, or 3, items"
    :put "\t\tFirst element in list array, for a key, is name to display."
    :put "\t\tThe 2nd argument can be an 'array', in which case it a sub-menu"
    :put "\t\tIf the 2nd argument is an 'op' function, that contains the function to run on keypress"
    :put "\t\t\t(for 'op' types, optional 3rd argument can provide args to 'op' using <%%"
    :put "\t\tFor example, the 3rd arg provides 'hello' value to print in 'op' function:" 
    :put "\t\t\1B[0m\1B[1;36m\$QKEYS ({ k={\"name\";(>[:return \$arg1]);{arg1=\"hello\"}} })\1B[0m"
    :put "\t\1B[0mExample: 'yes' or 'no'\1B[1;36m"
    :put "\t  :put [$0 ({y={\"yes\";(>[:return true])};n={\"no\";(>[:return false])}}) quit=no]"
    :put "\t\1B[0mTips:\1B[2m" 
    :put "\t\t- array defined as function arg requires using () around it, as shown above"
    :put "\t\t- names are optional, only an 'op' is required in the value of a key"
    :put "\1B[0m"
    :error "QKEYS script requires an array with the menu"
}

# use 1st argument as array with choices, the "top menu"
:set topmap $1

# store position within menu created by input array 
:local currmap $topmap
:local currpath ""
:local mapstack [:toarray ""]

:local loop true
:local rv

# if quit=no, then "return on return"
:local exitOnReturn false
:if ($quit~"^(n|N)") do={:set exitOnReturn true}

# if inline=no, print menu choice on seperate lines
:local useNewlines false
:if ($inline~"^(n|N)") do={:set useNewlines true}

# print current menu choices
:local printHeader do={
    :local sep ""
    :if ($useNewlines) do={ :set sep "\r\n" }
    :local cmds "\1B[1;36m$currpath >\1B[0m$sep"
    :local builtin [:toarray ""]
    :if ($exitOnReturn = false) do={ :set builtin ($builtin,{q={"quit"}}) }
    :if ($currmap!=$topmap) do={ :set builtin ($builtin,{"/"={"top"}}) }
    :foreach k,v in=($currmap,$builtin) do={
        :set cmds "$cmds  \1B[1;32m($[:tostr $k]) \1B[2;39m$[:tostr ($v->0)] \1B[0m$sep"
    }
    :put $cmds
}

# main loop to go navigate array of keys
:while (loop) do={
    # normalize name so all keymaps have some name
    :foreach k,v in=$currmap do={
        :if ([:typeof $v]="op") do={
            :set ($currmap->$k) {"($[:pick [:tostr $v] 10 30])";$v}
        } 
    }
    
    $printHeader currmap=$currmap currpath=$currpath topmap=$topmap exitOnReturn=$exitOnReturn useNewlines=$useNewlines

    # get key
    :local kcode [/terminal/inkey]
    :local key ([:convert to=raw from=byte-array {$kcode}])

    # find in map    
    :local currval ($currmap->$key)         
    :if ([:typeof $currval]!="nil") do={
        :local currname ($currval->0)
        :local currdata ($currval->1)
        :local currtype [:typeof $currdata]
        :local currargs [:toarray ""]
        :if ([:typeof ($currval->2)]="array") do={:set currargs ($currval->2)}

        # found array (another tree)
        :if ($currtype="array") do={
            # store previous menu in stack
            :set mapstack ($mapstack,{{$currpath;$currmap}})
            # set new menu tree, since array-in-array
            :set currpath "$currpath \1B[1;36m> $currname\1B[0m"
            :set currmap $currdata
        }
        # found op (function) to run
        :if ($currtype="op") do={
            :put "$currpath \1B[1;31m> $currname\1B[0m"
            # since element has a function, call it - potentially using args
            :set rv ($currdata <%% $currargs)
            # if quit=no, then exit on return
            :if ([:typeof $rv]!="nil" && $exitOnReturn) do={ :return $rv}
            :put "\t \1B[2;35m$[:pick [:tostr $rv] 0 64]\1B[0m"
        }
    } else={
        # not in map
    }
    # if no "q" in map, then assign to quit
    :if ($key~"(q|Q)") do={ :set loop false }
    # / go to top
    :if ($kcode=47) do={ :set currmap $topmap; :set currpath ""; :set mapstack [:toarray ""]}
    # handle BS (backspace), uses mapstack to pop of submenu
    :if ($kcode=8) do={
        :if ([:len $mapstack]>0) do={
            :set currmap ($mapstack->([:len $mapstack]-1)->1)
            :set currpath ($mapstack->([:len $mapstack]-1)->0)
            :set mapstack [:pick $mapstack 0 ([:len $mapstack]-1)]
        }
    }
}
:return $rv
