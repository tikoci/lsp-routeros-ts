# Source: https://forum.mikrotik.com/t/modify-files-inside-mikrotik/179159/14
# Topic: modify files inside mikrotik
# Source archive: mcp-discourse SQLite (source_name=amm0)
# Extracted from: code-block

### $STR - string helpers 
# from: https://raw.githubusercontent.com/merlinthemagic/MTM-RouterOS-Scripting/main/src/flash/MTM/Tools/Strings/Part1.rsc
:global STR
:set STR do={
    :if ($1="trim") do={
        :local param1
        :if ([:typeof $2] != nil) do={
            :set param1 $2;
        } else={
            :if ([:typeof $str] != nil) do={
                :set param1 $str
            }
            :error "String is mandatory";
        }
        :set param1 [:tostr $param1]; #ROS casts lots of things as arrays. e.g. rx/tx data from interfaces
        :local rLen [:len $param1];
        :local rData "";
        :local ch "";
        :local isDone 0;
        # remove leading spaces
        :for x from=0 to=($rLen - 1) do={
            :set ch [:pick $param1 $x];
            :if ($isDone = 0 && $ch != " " && $ch != "\n" && $ch != "\r") do={
                :set rData [:pick $param1 $x $rLen];
                :set isDone 1;
            }
        }
        :set rLen [:len $rData];
        :local cPos $rLen;
        :set isDone 0;
        # remove trailing spaces
        :for x from=1 to=($rLen - 1) do={
            :set cPos ($rLen - $x);
            :set ch [:pick $rData $cPos];
            :if ($isDone = 0 && $ch != " " && $ch != "\n" && $ch != "\r") do={
                :set rData [:pick $rData 0 ($cPos + 1)];
                :set isDone 1;
            }
        }
        :if ($rData = [:nothing]) do={
            #always return string, the nil value is a pain
            :set rData "";
        }
        :return $rData;
    }
    :if ($1="replace") do={
        
        :local param1; #str
        :local param2; ##find
        :local param3; ##replace
        :if ([:typeof $1] != nil) do={
            :set param1 $2;
            :set param2 $3;
            :set param3 $4;
        } else={
            :if ([:typeof $str] != nil) do={
                :set param1 $str;
                :set param2 $find;
                :set param3 $replace;
            } else={
                :error "String is mandatory";
            }
        }
        
        :set param1 [:tostr $param1]; #ROS casts lots of things as arrays. e.g. rx/tx data from interfaces
        :local rData "";
        :local pos;
        :local rLen [:len $param1];
        
        :local findLen [:len $param2];
        :local isDone 0;
        :while ($isDone = 0) do={
            :set pos [:find $param1 $param2];
            :if ([:typeof $pos] = "num") do={
                :set rData ($rData.[:pick $param1 0 $pos].$param3);
                :set param1 [:pick $param1 ($pos + $findLen) $rLen];
                :set rLen [:len $param1];
            } else={
                :set rData ($rData.$param1);
                :set isDone 1;
            }
        }
        :return $rData;
    }
    :if ($1="split") do={
        :local param1; #input
        :local param2; #deliminator
        :if ([:typeof $2] != nil) do={
            :set param1 $2;
            #delemitor= case ...
            :set param2 $3;
        } else={
            :if ([:typeof $str] != nil) do={
                :set param1 $str;
                :set param2 $delimitor;
            } else={
                :error "String is mandatory";
            }
        }

        :local rData [:toarray ""];
        :local rCount 0;
        :local splitLen [:len $param2];
        :if ($splitLen = 0) do={
            :set ($rData->$rCount) $param1;
            :return $rData;
        }
        :local lData "";
        :local rLen [:len $param1];
        :local pos;
        :local isDone 0;
        :while ($isDone = 0) do={
            :set pos [:find $param1 $param2];
            :if ([:typeof $pos] = "num") do={
                :set lData [:pick $param1 0 $pos];
                :set param1 [:pick $param1 ($pos + $splitLen) $rLen];
                :set rLen [:len $param1];
            } else={
                :set lData $param1;
                :set isDone 1;
            }
            :set ($rData->$rCount) $lData;
            :set rCount ($rCount + 1);
        }
        :return $rData;
    }
}
