# Source: https://forum.mikrotik.com/t/changing-the-mmm-dd-yyyy-date-format/5183/22
# Post author: @rextended
# Extracted from: code-block

{
    :local x [$currdatetimestrArr]
    :local str "Current Unix time is: %Unix%, so now are %HH%:%mm%"
    :foreach name,item in=$x do={
        :put "Search in the string %$name% and replace with $item"
    }
}
