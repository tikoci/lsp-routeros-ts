# Source: https://forum.mikrotik.com/t/importing-ip-list-from-file/143071/25
# Post author: @rextended
# Extracted from: code-block

# simulation of reading from a file
:global teststr (":do { add address=2.84.0.0/14 list=GR } on-error={}\r\n:do { add address=5.54.0.0/15 list=GR } on-error={}\r\
                \n:do { add address=5.144.192.0/18 list=GR } on-error={}\r\n:do { add address=5.172.192.0/32 list=GR } on-error={}\r\
                \n:do { add address=5.203.0.0/00 list=GR } on-error={}\r\n:do { add address=31.14.168.0/0 list=GR } on-error={}")

# manually defined, but in the future read as parameters of the function
:global addlist "test"
# add parameter if the entry must be dynamic (only on volatile memory, self-destructing after x seconds/hours/days/etc.)
# or static (keeped on reboot)
# must be added the option to accept from the downloaded address list only IP, only IP prefixes or both. For now it accepts only IP prefixes
# keep previous entries in the address-list or not
:global keep true
:global head "address="
:global tail " list="

# initializing variables (on global because we want test it on terminal, on script can/must be local
:global regexipwithsubnet "((25[0-5]|(2[0-4]|[01]\?[0-9]\?)[0-9])\\.){3}(25[0-5]|(2[0-4]|[01]\?[0-9]\?)[0-9])\\/(3[0-2]|[0-2]\?[0-9])"
:global lenght [:len $teststr]
:global offset [:len $head]
:global actualhead -1
:global actualtail -1
:global testip ""

# move all to the right context to shorten the commands
/ip firewall address-list

# if the previous content is not to be kept, it removes all entries
:if (!($keep)) do={ remove [find where list=$addlist] }

:while ([:typeof $actualtail] != "nil") do={
    :set actualhead ([:find $teststr $head $actualtail] + $offset)
    :set actualtail  [:find $teststr $tail $actualhead]
    :if ([:typeof $actualtail] != "nil") do={
        :set testip [:pick $teststr $actualhead $actualtail]
# if must be imported a list of IP without prefix, simply check
#        :if ([:typeof [:toip $testip]] = "ip") do={
# because for a bug added on newer versions,
# can not test directly if a string is a ip-prefix and ip-prefix do not have function like :toip
# I invented this walkthrough for not use regex, but is hard to understand and I don't know if it stop working on future versions
#        :if ([:typeof [[:parse ":return $testip"]] ] = "ip-prefix") do={
        :if ($testip ~ $regexipwithsubnet) do={
            :if ($testip ~ "\\/0(0|\$)") do={
                :log warning "Invalid IP-prefix >$testip<"
            } else={
                # address list save IP/32 without /32, must search for duplicate without the /32, adding with or without /32 not matter
                :if ($testip ~ "\\/32") do={ :set testip [:pick $testip 0 [:find $testip "/32" -1]] }
                :if ([:len [find where list=$addlist and address=$testip]] = 0) do={ add list=$addlist address=$testip }
            }
        }
    }
}
