# Source: https://forum.mikrotik.com/t/experiments-with-convert-for-bits-bytes-csv-from-iot/179268/3
# Topic: Experiments with [:convert] for bits&bytes +CSV from /iot/...
# Source archive: mcp-discourse SQLite (source_name=amm0)
# Extracted from: code-block

:global rxframes [:deserialize from=dsv delimiter=, options=dsv.array  [/file get rxframes.csv contents as-string]]
:global temps [:toarray ""]
:foreach k,v in=$rxframes do={ 
    :local tempC ([$decodeDriago ($v->"Data")]->"_intTempRawC") 
    :if ($tempC > 0) do={:set $temps ($temps,$tempC) }
}
:put [:serialize to=dsv delimiter=" " $temps ]
