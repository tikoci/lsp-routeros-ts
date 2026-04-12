# Source: https://forum.mikrotik.com/t/importing-ip-list-from-file/143071/23
# Post author: @rextended
# Extracted from: code-block

# open the bracket { to test inside a terminal, remove on script
{

# put the context in right... context (bad, must be defined inside function, but now no matter)
/ip firewall address-list

# define update function
:local update do={

    # bad start rely immediately on "on-error"...
    :do {
        :local result [/tool fetch url=$url as-value output=user]
# TRUE: @@@ this line fetches the bottom defined URL and if value of the "downloaded" is not 63 it maps each line
# received from the $result variable into another local variable "data" @@@

        :if ($result->"downloaded" != "63") do={
            :local data ($result->"data")
# another on-Orror, the remove function in this case can't do any error...
            :do { remove [find list=$blacklist comment!="Optional"] } on-error={}
# TRUE: @@@ find an existant ACL and remove entries which do not have a comment-value set "Optional" @@@

            :while ([:len $data]!=0) do={
# TRUE: @@@ So as long as the $data is not empty (as it contained the freshly loaded info from the URL perform statements below @@@
                :if ([:pick $data ([:find $data "address=" -1] + 8) [:find $data " list=" -1]]~"((25[0-5]|(2[0-4]|[01]\?[0-9]\?)[0-9])\\.){3}(25[0-5]|(2[0-4]|[01]\?[0-9]\?)[0-9])\\/(3[0-2]|[0-2]\?[0-9])") do={
# TRUE: but is better to split on two passages, is more readable @@@ So scan each line looking for what is
# between the head & tail of each message. @@@

# another on-Orror
                   :do { add list=$blacklist address=([:pick $data 0 [:find $data $delimiter]])} on-error={}
# TRUE: @@@ populate the $blacklist (called here "GRTLD") @@@
               # end of if ([:pick $data ...
               }


# @@@ and this what I don't understand => The $data in the above only contain the data between address=X.X.X.X.X/3 list=GR
# You do not understand it, because everytime a record is saved, the remaining data replace "data",
# this is why before are present a ^ on front of the regex
# I use another method, instead to lost time modifing everytime the data,
# i move the current "pointer" of the start and the end of the point where regex try to find...
# @@@ Why this construction address=([:pick $data 0 [:find $data $delimiter]]) to populate the actual IP/MASK in the ACL \?
# Probably the $delimeter is of no use here anymore
# I do not write this functions, but all is a mess...

               :set data [:pick $data ([:find $data "\n"]+1) [:len $data]]
# @@@ Why the above rule - Why do you have to "set" data - You just want to parse (as long as $data!=0  right)
# parsing do not decrease data, I explain cut and paste of data lines before
           # end of while
           }
           :log warning "Imported address list < $blacklist> from file: $url"
       # end of :if ($result->"downloaded" != "63")
       } else={:log warning "Address list: <$blacklist>, downloaded file to big: $url" }


    # end of general function update
    } on-error={ :log warning "Address list <$blacklist> update failed" }
# TRUE: @@@ above some generic messages depending on exit/error-codes I guess, not really mandatory anyway @@@

# end of update function
}

# launch the function update with parameters
# better use " " everytime is not clearly a number, tue or false, yes or not, IP or IP-prefix, and something other now I miss for sure...
$update url=https://www.iwik.org/ipcountry/mikrotik/GR blacklist="GRTLD" delimiter=("\n")

# close the script for the terminal
}
