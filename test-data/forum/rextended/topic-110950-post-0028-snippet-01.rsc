# Source: https://forum.mikrotik.com/t/send-mikrotik-notification-via-whatsapp/110950/28
# Post author: @rextended
# Extracted from: code-block

:global ASCIItoCP1252toUTF8 do={
    :local ascii "\00\01\02\03\04\05\06\07\08\09\0A\0B\0C\0D\0E\0F\
                  \10\11\12\13\14\15\16\17\18\19\1A\1B\1C\1D\1E\1F\
                  \20\21\22\23\24\25\26\27\28\29\2A\2B\2C\2D\2E\2F\
                  \30\31\32\33\34\35\36\37\38\39\3A\3B\3C\3D\3E\3F\
                  \40\41\42\43\44\45\46\47\48\49\4A\4B\4C\4D\4E\4F\
                  \50\51\52\53\54\55\56\57\58\59\5A\5B\5C\5D\5E\5F\
                  \60\61\62\63\64\65\66\67\68\69\6A\6B\6C\6D\6E\6F\
                  \70\71\72\73\74\75\76\77\78\79\7A\7B\7C\7D\7E\7F\
                  \80\81\82\83\84\85\86\87\88\89\8A\8B\8C\8D\8E\8F\
                  \90\91\92\93\94\95\96\97\98\99\9A\9B\9C\9D\9E\9F\
                  \A0\A1\A2\A3\A4\A5\A6\A7\A8\A9\AA\AB\AC\AD\AE\AF\
                  \B0\B1\B2\B3\B4\B5\B6\B7\B8\B9\BA\BB\BC\BD\BE\BF\
                  \C0\C1\C2\C3\C4\C5\C6\C7\C8\C9\CA\CB\CC\CD\CE\CF\
                  \D0\D1\D2\D3\D4\D5\D6\D7\D8\D9\DA\DB\DC\DD\DE\DF\
                  \E0\E1\E2\E3\E4\E5\E6\E7\E8\E9\EA\EB\EC\ED\EE\EF\
                  \F0\F1\F2\F3\F4\F5\F6\F7\F8\F9\FA\FB\FC\FD\FE\FF"
    :local CP1252toUTF8 {"EFBFBD";"EFBFBD";"EFBFBD";"EFBFBD";"EFBFBD";"EFBFBD";"EFBFBD";"EFBFBD";"EFBFBD";"09";"0A";"EFBFBD";"0A";"0A";"EFBFBD";"EFBFBD";
                         "EFBFBD";"EFBFBD";"EFBFBD";"EFBFBD";"EFBFBD";"EFBFBD";"EFBFBD";"EFBFBD";"EFBFBD";"EFBFBD";"EFBFBD";"EFBFBD";"EFBFBD";"EFBFBD";"EFBFBD";"EFBFBD";
                         "20";"21";"22";"23";"24";"25";"26";"27";"28";"29";"2A";"2B";"2C";"2D";"2E";"2F";
                         "30";"31";"32";"33";"34";"35";"36";"37";"38";"39";"3A";"3B";"3C";"3D";"3E";"3F";
                         "40";"41";"42";"43";"44";"45";"46";"47";"48";"49";"4A";"4B";"4C";"4D";"4E";"4F";
                         "50";"51";"52";"53";"54";"55";"56";"57";"58";"59";"5A";"5B";"5C";"5D";"5E";"5F";
                         "60";"61";"62";"63";"64";"65";"66";"67";"68";"69";"6A";"6B";"6C";"6D";"6E";"6F";
                         "70";"71";"72";"73";"74";"75";"76";"77";"78";"79";"7A";"7B";"7C";"7D";"7E";"7F";
                         "E282AC";"EFBFBD";"E2809A";"C692";"E2809E";"E280A6";"E280A0";"E280A1";"CB86";"E280B0";"C5A0";"E280B9";"C592";"EFBFBD";"C5BD";"EFBFBD";
                         "EFBFBD";"E28098";"E28099";"E2809C";"E2809D";"E280A2";"E28093";"E28094";"CB9C";"E284A2";"C5A1";"E280BA";"C593";"EFBFBD";"C5BE";"C5B8";
                         "C2A0";"C2A1";"C2A2";"C2A3";"C2A4";"C2A5";"C2A6";"C2A7";"C2A8";"C2A9";"C2AA";"C2AB";"C2AC";"C2AD";"C2AE";"C2AF";
                         "C2B0";"C2B1";"C2B2";"C2B3";"C2B4";"C2B5";"C2B6";"C2B7";"C2B8";"C2B9";"C2BA";"C2BB";"C2BC";"C2BD";"C2BE";"C2BF";
                         "C380";"C381";"C382";"C383";"C384";"C385";"C386";"C387";"C388";"C389";"C38A";"C38B";"C38C";"C38D";"C38E";"C38F";
                         "C390";"C391";"C392";"C393";"C394";"C395";"C396";"C397";"C398";"C399";"C39A";"C39B";"C39C";"C39D";"C39E";"C39F";
                         "C3A0";"C3A1";"C3A2";"C3A3";"C3A4";"C3A5";"C3A6";"C3A7";"C3A8";"C3A9";"C3AA";"C3AB";"C3AC";"C3AD";"C3AE";"C3AF";
                         "C3B0";"C3B1";"C3B2";"C3B3";"C3B4";"C3B5";"C3B6";"C3B7";"C3B8";"C3B9";"C3BA";"C3BB";"C3BC";"C3BD";"C3BE";"C3BF"
                        }
    :local string $1
    :if (([:typeof $string] != "str") or ($string = "")) do={ :return "" }
    :local lenstr [:len $string]
    :local constr ""
    :for pos from=0 to=($lenstr - 1) do={
        :local utf ($CP1252toUTF8->[:find $ascii [:pick $string $pos ($pos + 1)] -1])
        :local sym ""
        :if ([:len $utf] = 2) do={:set sym "%$[:pick $utf 0 2]" }
        :if ([:len $utf] = 4) do={:set sym "%$[:pick $utf 0 2]%$[:pick $utf 2 4]" }
        :if ([:len $utf] = 6) do={:set sym "%$[:pick $utf 0 2]%$[:pick $utf 2 4]%$[:pick $utf 4 6]" }
        :set constr "$constr$sym"
    }
    :return $constr
}

:put [$ASCIItoCP1252toUTF8 "test"]
