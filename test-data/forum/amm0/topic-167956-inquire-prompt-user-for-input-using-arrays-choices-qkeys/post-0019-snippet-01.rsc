# Source: https://forum.mikrotik.com/t/inquire-prompt-user-for-input-using-arrays-choices-qkeys/167956/19
# Topic: $INQUIRE - prompt user for input using arrays +$CHOICES +$QKEYS
# Source archive: mcp-discourse SQLite (source_name=amm0)
# Extracted from: code-block

{
    :local iftrans do={
        :global CHOICES
        :local gostspecs {"OST 8483";"GOST 16876-71 (1973";"T SEV 1362 (1978)";"GOST 7.79-2000 (2002)";"GOST 52535.1-2006 (2006)";"ALA-LC";"ISO/R 9";"ISO 9"}
        :if ($1 = "Latin-Transliterated Cyrillic") do={
            :put "There are many standards for transliteration...which one?"
            :return [$CHOICES $gostspecs]
        } else={:return [:nothing]} 
    }

    :local encodings {"Urlencoded";"Base64";"HexString";"UCS2";"GSM7";"UTF8";{text="CP1252 / Latin-1";val="CP1252";help="RouterOS default"};"CP1291";{val="ASCII";text="US ASCII"; help="us-ascii"};"Latin-Transliterated Cyrillic"}
    :local inouts {"global/local variable";"file";"escaped string text";"PDU field (big-endian,semi-octets)"}
    :put "How is the text already encoded?"
    :local inencoding [$CHOICES $encodings]
    :local ingosts [$iftrans $inencoding]
    :put "Where is it stored currently?"
    :local insrc [$CHOICES $inouts]
    :put "What encoding to you need output?"
    :local outencoding [$CHOICES $encodings]
    :local outgosts [$iftrans $outencoding] 
    :put "Which output do you need?"
    :local outdest [$CHOICES $inouts]

    :put "..."
    :put "SpamGPT says:"
    :put "..."
    :put "Help @rextended! I need $inencoding $ingosts stored in a $insrc, for output in $outencoding $outgosts to $outdest."
    :put "..."
    :put "@reextended says:"  
    :put "Do you not know how to search? \1B]8;;$http://forum.mikrotik.com/search.php?keywords=$($inencoding)to$($outencoding)\07http://forum.mikrotik.com/search.php?keywords=$($inencoding)to$($outencoding)\1B]8;;\07"  
    :put ""
}
