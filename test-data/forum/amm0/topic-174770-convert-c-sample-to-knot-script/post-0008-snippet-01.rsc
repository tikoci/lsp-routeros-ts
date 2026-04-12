# Source: https://forum.mikrotik.com/t/convert-c-sample-to-knot-script/174770/8
# Topic: Convert C sample to KNOT script
# Source archive: mcp-discourse SQLite (source_name=amm0)
# Extracted from: code-block

# returns num in mm, arg is num-array from BT advert data 
:global gettankheight do={
    :local bytes $1
    # Get raw level from data. Only the LS 14-bits represent the level
    :local u16raw (($bytes->8) * 256 + ($bytes->7))
    :put "u16raw= $u16raw"
    :local rawlevel ($u16raw & 0x3FFF)
    :put "rawlevel= $rawlevel"
    # Check for presence of extension bit on certain hardware/firmware
    :if (($bytes->4) & 0x80) do={
        :set rawlevel (16384 + $rawlevel * 4)
        :put "rawlevel= $rawlevel"
    }

    # Retrieve unscaled temperature from advert packet
    :local rawtemp (($bytes->6) & 0x7F)
    :put "rawtemp= $rawtemp"

    # Apply 2nd order polynomial to compensating the raw TOF into mm of LPG
    :local scale 100000
    :put "scale= $scale"
    :local coef { 57304500000, -2822000, -535 }
    :put "coefs= $[:tostr $coef]"
    :local lpgtof1 [:tonum (($coef->0) + ($coef->1) * ($rawtemp*$scale) + ($coef->2))]
    :put "lpgtof1= $lpgtof1"
    :local lpgtof2 ($lpgtof1 * [:tonum ($rawtemp*$scale)]) 
    :put "lpgtof2= $lpgtof2"
    :local lpgtof3 ($lpgtof2 * [:tonum ($rawtemp*$scale)])
    :put "lpgtof3= $lpgtof3"
    :local rv ($rawlevel * ($lpgtof3/$scale))
    :put "lpgtofX= $lpgtof1 $lpgtof2 $lpgtof3"
    :put "rv= $rv"
    :return $rv
}
