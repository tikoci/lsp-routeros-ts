# Source: https://forum.mikrotik.com/t/how-to-read-line-by-line-from-a-file-using-a-script/179893/4
# Topic: How to Read line by line from a file using a script?
# Source archive: mcp-discourse SQLite (source_name=amm0)
# Extracted from: code-block

{
    :local filebody [/file/get iplist.txt contents]
    :local addressListName "MyAddressList"
    :local expire 1h
    
    :foreach ip in=[ :deserialize [:tolf $filebody] delimiter="\n" from=dsv options=dsv.plain ] do={
        /log debug "adding $ip to $addressListName"
        :if ([:tostr $ip] != "0.0.0.0") do={
             :onerror e in={
                  /ip firewall address-list add list=$addressListName address=$ip timeout=$expire
              } do={/log debug "skipping $ip ($e)"}
        }
    }
}
