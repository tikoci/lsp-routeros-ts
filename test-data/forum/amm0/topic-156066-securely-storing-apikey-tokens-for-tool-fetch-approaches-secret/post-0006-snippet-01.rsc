# Source: https://forum.mikrotik.com/t/securely-storing-apikey-tokens-for-tool-fetch-approaches-secret/156066/6
# Topic: Securely storing apikey/tokens for /tool/fetch... Approaches?  == $SECRET
# Source archive: mcp-discourse SQLite (source_name=amm0)
# Extracted from: code-block

### $SECRET
#   get <name>
#   set <name> password=<password>
# . remove <name
#   print
:global SECRET
:set $SECRET do={
    :global SECRET

    # helpers
    :local fixprofile do={
        :if ([/ppp profile find name="null"]) do={:put "nothing"} else={
            /ppp profile add bridge-learning=no change-tcp-mss=no local-address=0.0.0.0 name="null" only-one=yes remote-address=0.0.0.0 session-timeout=1s use-compression=no use-encryption=no use-mpls=no use-upnp=no
        }
    }
    :local lppp [:len [/ppp secret find where name=$2]]
    :local checkexist do={
        :if (lppp=0) do={
            :error "\$SECRET: cannot find $2 in secret store"
        }
    }

    # $SECRET
    :if ([:typeof $1]!="str") do={
        :put "\$SECRET"
        :put "   uses /ppp/secrets to store stuff like REST apikeys, or other sensative data"
        :put "\t\$SECRET print - prints stored secret passwords"
        :put "\t\$SECRET get <name> - gets a stored secret"
        :put "\t\$SECRET set <name> password=\"YOUR_SECRET\" - sets a secret password" 
        :put "\t\$SECRET remove <name> - removes a secret" 
    }

    # $SECRET print
    :if ($1~"^pr") do={
        /ppp secret print where comment~"\\\$SECRET"
        :return [:nothing] 
    }

    # $SECRET get
    :if ($1~"get") do={
        $checkexist
       :return [/ppp secret get $2 password] 
    }

    # $SECRET set
    :if ($1~"set|add") do={
        :if ([:typeof $password]="str") do={} else={:error "\$SECRET: password= required"}
        :if (lppp=0) do={
            /ppp secret add name=$2 password=$password 
        } else={
            /ppp secret set $2 password=$password
        }
        $fixprofile
        /ppp secret set $2 comment="used by \$SECRET"
        /ppp secret set $2 profile="null"
        /ppp secret set $2 service="async"
        :return [$SECRET get $2]
    } 

    # $SECRET remove
    :if ($1~"rm|rem|del") do={
        $checkexist
        :return [/ppp secret remove $2]
    }
    :error "\$SECRET: bad command"
}
