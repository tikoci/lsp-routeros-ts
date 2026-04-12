# Source: https://forum.mikrotik.com/t/mkdir-function-for-easy-folder-creation/132775/17
# Post author: @rextended
# Extracted from: code-block

:global createpath do={
    :global createpath
    :if ([/system resource get architecture-name] = "smips") do={:return [:toarray ("ERROR,SMIPS")]}
    :if ([:typeof $1] = "nothing") do={:return [:toarray "ERROR,Directory not specified"]}
    :local invalidchars "[\01-\1F\7F-\FF]"
    :local invalidonwin "[\22\2A\3A\3C\3E\3F\5C\7C]"
    :local fullpath $1
    :if ($fullpath ~ $invalidchars) do={:return [:toarray "ERROR,Invalid character on Linux"  ]}
    :if ($fullpath ~ $invalidonwin) do={:return [:toarray "ERROR,Invalid character on Windows"]}
    :if ($fullpath ~ "//"         ) do={:return [:toarray "ERROR,Invalid // path specified"   ]}
    :if ($fullpath ~ "^/"         ) do={:set fullpath [:pick $fullpath 1  [:len $fullpath]     ]}
    :if ($fullpath ~ "^flash/"    ) do={:set fullpath [:pick $fullpath 6  [:len $fullpath]     ]}
    :if ($fullpath ~ "/\$"        ) do={:set fullpath [:pick $fullpath 0 ([:len $fullpath] - 1)]}
    /file
    :local rootdir ""
    # if the root is on ramdisk the folder must go on flash disk...
    :if ([:len [find where name=flash and type=disk]] = 1) do={:set rootdir "flash/"}
    :if ([:len [find where name="$rootdir$fullpath" and type=directory]] = 1) do={:return [:toarray "OK EXIST,$rootdir$fullpath"]}
    :if (($fullpath ~ "/") and ($2 != "NOREC")) do={
        :local workpath $fullpath
        :local whereare $rootdir
        :local thisdir  ""
        :while ($workpath ~ "/") do={
            :set thisdir  [:pick $workpath 0 [:find $workpath "/" 0]]
            :set whereare "$whereare$thisdir"
            :if ([:len [find where name="$rootdir$whereare" and type=directory]] = 0) do={$createpath $whereare "NOREC"}
            :set whereare "$whereare/"
            :set workpath [:pick $workpath ([:find $workpath "/" -1] + 1) [:len $workpath]]
        }
    }
    /ip smb shares
    :local defaultentry [find where default=yes]
    :if ([:len $defaultentry] = 1) do={
        :local previousdir [get $defaultentry directory]
        set $defaultentry directory="$rootdir$fullpath"
        set $defaultentry directory=$previousdir
    }
    :return [:toarray "OK CREATED,$rootdir$fullpath"]
}
