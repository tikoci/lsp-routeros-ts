# Source: https://forum.mikrotik.com/t/some-music/95593/36
# Topic: Some Music
# Source archive: mcp-discourse SQLite (source_name=amm0)
# Extracted from: code-block

# list of strings using Guido notation, with conversation to freq and duration based on time signature
:global musicGuidoList ("B3/4","B3/8") 

# TODO: some code that converts B3 and 4 into a frequency= and duration= stuff into an array like below to actually play:

# list of tuples (list containing another list with two values: frequency,  of two
:global musicBeepTupleList {(123, 231);(123,115)} 

# play array
:foreach i in=$musicBeepTupleList do={ :beep frequency=($i->0) length="$($i->1)ms"; :delay "$($i->1)ms"}
