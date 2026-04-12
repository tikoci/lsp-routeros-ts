# Source: https://forum.mikrotik.com/t/address-lists-downloader-dshield-spamhaus-drop-edrop-etc/133640/158
# Post author: @rextended
# Extracted from: code-block

:global checkurl do={
    /file remove [find where name~"checkurl.(txt|tmp)"]
    {
        :local jobid [:execute file=checkurl.txt \
            script="/tool fetch http-header-field=\"Range: bytes=0-0\" dst-path=\"checkurl.tmp\" url=\"$1\""]
        :local testsec 0
        :while (([:len [/sys script job find where .id=$jobid]] = 1) && ($testsec < 20)) do={
            :set testsec ($testsec + 1)
            :delay 1s
        }
        :local error { cod="000.0" ; txt="NO CODE"}
        :if ([:len [/file find where name="checkurl.txt"]] = 1) do={
            :local check [/file get [/file find where name="checkurl.txt"] contents]
            /file remove [find where name~"checkurl.(txt|tmp)"]
            # 200 URL OK
            :if ($check~"status: finished") do={
                :set ($error->"cod") "200"
                :set ($error->"txt") "OK"
                :return $error
            }
            # 301 Permanent Redirect
            :if ($check~" <301 Moved Permanently ") do={
                :set ($error->"cod") "301"
                :set ($error->"txt") [:pick $check ([:find $check " <301 Moved Permanently \"" -1] + 25) [:find $check "\"> " -1]]
                :return $error
            }
            # 302 Redirect
            :if ($check~" <302 Found ") do={
                :set ($error->"cod") "302"
                :set ($error->"txt") [:pick $check ([:find $check " <302 Found \"" -1] + 13) [:find $check "\"> " -1]]
                :return $error
            }
            # other Codes (error or not)
            :if ($check~" <.*> ") do={
                :set ($error->"txt") [:pick $check ([:find $check " <" -1] + 2) [:find $check "> " -1]]
                :set ($error->"cod") [:pick ($error->"txt") 0 [:find ($error->"txt") " " -1]]
                :set ($error->"txt") [:pick ($error->"txt") ([:find ($error->"txt") " " -1] + 1) [:len ($error->"txt")]]
                :return $error
            }
            # MikroTik fetch specific errors
            :if ($check~"failure: ") do={
                :set ($error->"cod") "666.1"
                :set ($error->"txt") [:pick $check ([:find $check "failure: " -1] + 9) [:len $check]]
                :return $error
            }
            # unexpected results
            :set ($error->"cod") "000"
            :set ($error->"txt") $check
            :return $error
        } else={
            # :execute unsuccessful or timeout
            :set error { cod="666.0" ; txt="TEMP FILE ERROR"}
            /file remove [find where name~"checkurl.(txt|tmp)"]
            :return $error
        }
    }
}
