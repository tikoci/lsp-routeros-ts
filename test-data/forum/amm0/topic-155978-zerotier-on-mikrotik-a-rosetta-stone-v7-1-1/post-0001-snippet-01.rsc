# Source: https://forum.mikrotik.com/t/zerotier-on-mikrotik-a-rosetta-stone-v7-1-1/155978/1
# Topic: ZeroTier on Mikrotik – a rosetta stone [v7.1.1+]
# Source archive: mcp-discourse SQLite (source_name=amm0)
# Extracted from: code-block

#
# THIS IS JUST AN EXAMPLE
#
# Below shows how a RouterOS script can "call" the "ZeroTier Central" (my.zerotier.com)
# using ZeroTier's REST API via /tool/fetch (& script functions)  
#
# This is useful if you want to script stuff like authorizing a "member"
# Or, creating new ZeroTier network from a Mikrotik script. 
#
# See ZeroTier Central API docs: https://docs.zerotier.com/central/v1
#
# You'll need to get an "API Access Token" from https://my.zerotier.com/account
# via "New Token" then "Generate", you name it whatever like "Mikrotik"
# It will generate a mixed case string like PlEaSeAdDJSONsUpPoRtInROSScript7
# You can use this as authentication to REST at https://my.zerotier.com/api/v1
# for management access to ZeroTier's "central" cloud configuration. 
#
# This is a simple function "$ztcget" we can use to call it easily from Mikrotik CLI
# Obviously, there could be a $ztcpost etc, or better "wrapper" over ZeroTier Central API.
# So this alone not that useful,  consider as an example of possibilities.
#
# TO TEST THIS SCRIPT...you NEED to set the ZeroTier API key, someplace.  
#
:global ztcget
:set $ztcget do={
    :if ([:typeof $apikey]="nothing") do={:error "apikey= must be provided"} 
    :if ([:typeof $path]="nothing") do={:error "path= must be provided"} 
    :local headers "Authorization: bearer $(apikey)"
    :local resp [/tool/fetch url="https://my.zerotier.com/api/v1$path" http-method=get http-header-field="$headers" output="user" as-value]
    :log info "\$ztcget: $($resp->"status") path=$($path) apikey-len=$([:len $apikey])"
    :return ($resp->"data")
}

# Mikrotik Script has NO JSON support, so need load another script for that:
:global JSONLoads
:if ([:typeof $JSONLoads]="nothing") do={
    /tool/fetch url=https://raw.githubusercontent.com/Winand/mikrotik-json-parser/master/JParseFunctions
    :import JParseFunctions
    :delay 5s
}
# (NOTE: the lack of JSON support in RouterOS script makes this MUCH less clean...)

# If we use another function, $ztclogin...
# We can call $ztcget above with /status to check if apikey is valid
# This is the first step to use the "REST" of the ZeroTier API for something useful.
:global ztclogin
:set $ztclogin do={
    # Declare the global functions we're using in the function
    :global ztcget
    :global JSONLoads

    # We'll just HTTP GET /status to see if we're authenticated.
    :local ztcjson [$ztcget apikey=$apikey path="/status"]

    # Parse the JSON into a Mikrotik :typeof "array"
    :local ztcstatus [$JSONLoads $ztcjson]

    # You can print the whole thing...for debug...
    # :put "$ztcstatus"

    # As a Mikrotik array, you can access the various JSON elements.
    # For ZeroTier Centeral's /status REST GET method...
    # if the apikey is valid, there would be a "user:"" in the JSON {..., user: {...}, ...}
    # if the apikey was wrong, user would be null. Or, with JSONLoads, :typeof "nil"
    :if ([:typeof ($ztcstatus->"user")]="nil") do={
        :put "Something is wrong.  Here the JSON what we got:"
        :put ($ztcjson)
        :error "** You may need to set the ZeroTier API Key, or its a bug. **"
    } else={
        :put "Hello $($ztcstatus->"user"->"displayName") - if that's right, you can use the ZTC API!"
    }
}

# And, THIS IS HOW you'd use the function(s) to "check if login is valid"

$ztclogin apikey=PlEaSeAdDJSONsUpPoRtInROSScript7

# If you got here, now you can change the apikey= above to test the script.
