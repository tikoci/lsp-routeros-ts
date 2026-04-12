# Source: https://forum.mikrotik.com/t/convert-any-text-to-unicode/164329/27
# Topic: Convert any text to UNICODE
# Source archive: mcp-discourse SQLite (source_name=amm0)
# Extracted from: code-block

# if we add the "BOM" (byte order mark), it works to a file and displays in TextEdit (Mac version of notepad.exe)
# without the \FE\FF, an exported file is unreadable (starts with \00 so unsure what to do)
:global z ("\FE\FF".[$UTF8toUCS2 ("belli"."\E2\82\AC"."mo")])
# one important benefit of UTF16/UCS2 is getting the number of *characters* not *bytes* is possible...
# so if dealing with UTF8 from JSON etc, converting to UCS2 using $UTF8toUCS2 may be helpful
:put ([:len $z]/2)
9
# should be 8 but that BOM at start need to be accounted for here...
:put (([:len $z]/2)-1)
8
# what's curious is that UCS2 prints at least the ASCII parts just fine on Mac+SSH 
:put $z
# ��belli �mo
/file print file= ucsfile
/file set ucsfile contents=$z
/system script env print where name=z
# Columns: NAME, VALUE
#  NAME  VALUE                       
# 7  z     FEFF00b00e00l00l00i AC00m00o
