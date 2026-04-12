# Source: https://forum.mikrotik.com/t/experiments-with-convert-for-bits-bytes-csv-from-iot/179268/1
# Topic: Experiments with [:convert] for bits&bytes +CSV from /iot/...
# Source archive: mcp-discourse SQLite (source_name=amm0)
# Extracted from: code-block

## BATTERY - stores BOTH mV and status
# size: 2 bytes - first 2 bits MSB are "status", next 14 bits are mV 
# docs suggest: 
#   BAT status = (0xCBA4cba4>>14) & 0xFF = 11b (00=bad ... 11=great)
#   Battery Voltage = 0xCBF6&0x3FFF = 0x0BA4 = 2980mV
# voltage: (ignoring first 2 bits)
:local battRaw [:convert from=byte-array to=num [:pick $bytes 0 2]]
:set ($data->"_battRaw") [:tonum $battRaw]
:set ($data->"battMillivolts") ([:tonum $battRaw] & [:tonum "0x3FFF"])
# status: (using new "to=bit-array-msb" to get 2 bits with status)
:local bits [:convert $bytes to=bit-array-msb from=byte-array]
:if (($bits->0) = 1 and ($bits->1) = 1) do={ :set ($data->"battStatus") "good" }
:if (($bits->0) = 1 and ($bits->1) = 0) do={ :set ($data->"battStatus") "fair" }
:if (($bits->0) = 0 and ($bits->1) = 1) do={ :set ($data->"battStatus") "low" }
:if (($bits->0) = 0 and ($bits->1) = 0) do={ :set ($data->"battStatus") "EOL" }

## TEMP - internal, "centi-celsius" (C in 1/100th)  
# size: 2 bytes, MSB int 
:local intTempRaw [:convert from=byte-array to=num [:pick $bytes 2 4]]
:set ($data->"_intTempRawC") $intTempRaw 
:set ($data->"intTempC") "$[:pick $intTempRaw 0 ([:len $intTempRaw]-2)].$[:pick $intTempRaw ([:len $intTempRaw]-2) [:len $intTempRaw]]"

## HUMIDITY - internal, "deci-percentage" (% in 1/10th)
# size: 2 bytes, MSB int
:local intHumRaw [:convert from=byte-array to=num [:pick $bytes 4 6]]
:set ($data->"_intHumidityRaw") $intHumRaw 
:set ($data->"intHumidity") "$[:pick $intHumRaw 0 ([:len $intHumRaw]-1)].$[:pick $intHumRaw ([:len $intHumRaw]-1) [:len $intHumRaw]]"

## EXT SENSOR TYPE - connected external sensor  
# size: 1 bytes (docs have table)
:local sensorTypeRaw ($bytes->6)
:set ($data->"_sensorTypeRaw") $sensorTypeRaw
:local sensorType [:toarray ""]
:set ($sensorType->1) "temperature"
:set ($sensorType->4) "interrupt"
:set ($sensorType->5) "illumination"
:set ($sensorType->6) "adc"
:set ($sensorType->7) "counting-16bit"
:set ($sensorType->8) "counting-32bit"
:set ($sensorType->9) "temperature+datalog"
:set ($data->"sensorType") ($sensorType->$sensorTypeRaw) 

## EXT SENSOR - RAW undecoded
# size: last 4 bytes MSB, sensor dependant  
:local extSensorData [:convert from=byte-array to=num [:pick $bytes 7 11]]
:set ($data->"_sensorDataRaw") $extSensorData 
:set ($data->"_sensorDataHex") [:convert from=num to=hex $extSensorData] 

## EXT SENSOR - parsed data based on type 
:if (($data->"sensorType") = "temperature") do={
    # size: 2 bytes MSB, starting at 7th (or 7, 0-based index)
    :local extTempRaw [:convert from=byte-array to=num [:pick $bytes 7 9]] 
    :set ($data->"_extTempRawC") $extTempRaw 
    :if ($extTempRaw != [:tonum "0x3FFF"]) do={
        :set ($data->"extTempC") "$[:pick $extTempRaw 0 ([:len $extTempRaw]-2)].$[:pick $extTempRaw ([:len $extTempRaw]-2) [:len $extTempRaw]]"
    } else={
        :set ($data->"sensorError") "disconnected" 
    }
} else={
    ## OTHER SENSOR TYPES - NOT SUPPORTED
    :set ($data->"sensorError") "unsupported" 
}

## STRIP "RAW" - if called with "debug=no"
:if ($terse="yes") do={
    :foreach k,v in=$data do={
        :if ($k~"^_") do={:set ($data->$k)}
    }
}

## OUTPUT
:return $data
