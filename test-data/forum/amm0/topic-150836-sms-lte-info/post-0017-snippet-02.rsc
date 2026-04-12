# Source: https://forum.mikrotik.com/t/sms-lte-info/150836/17
# Topic: SMS LTE Info
# Source archive: mcp-discourse SQLite (source_name=amm0)
# Extracted from: code-block

:global toarrayFromTelitResponse
:set toarrayFromTelitResponse do={
    :local z [ [:tostr [:pick $1 ([:find $1 ":"]+2) [:len $1] ]]]
    :return [:toarray $z];
};

:global toarrayApplyTemplate
:set toarrayApplyTemplate do={ 
    :local s [toarray "$2"];
    :local z [:toarray ""];
    :foreach i,k in=$s do={:set ($z->$k) ($1->$i)};
    :log debug message="toarrayApplyTemplate $s -> $z";
    :return $z; 
};

:global ATrfsts 
:set ATrfsts do={
    :global toarrayApplyTemplate;
    :global toarrayFromTelitResponse;
    :global ATVAR;
    :local TErfsts1 "PLMN,EARFCN,RSRP,RSSI,RSRQ,TAC,RAC,TXPWR,DRX,MM,RRC,CID,IMSI,NETNAME,SD,ABND"
    :local TErfsts2 "PLMN,EARFCN,RSRP,RSSI,RSRQ,TAC,RAC,DRX,MM,RRC,CID,IMSI,NETNAME,SD,ABND"
    :local TErfsts3 "PLMN,EARFCN,RSRP,RSSI,RSRQ,TAC,RAC,DRX,MM,RRC,CID,IMSI,SD,ABND"
    :local TErfmmstate {0= "NULL";3="LOCATION_UPDATE_INITIATED";5="WAIT_FOR_OUTGOING_MM_CONNECTION";6="CONNECTION_ACTIVE";7="IMSI_DETACH_INITIATED";8="PROCESS_CM_SERVICE_PROMPT";9="WAIT_FOR_NETWORK_COMMAND";10="LOCATION_UPDATE_REJECTED";13="WAIT_FOR_RR_CONNECTION_LU";14="WAIT_FOR_RR_CONNECTION_MM";15="WAIT_FOR_RR_CONNECTION_IMSI_DETACH";17="REESTABLISHMENT_INITIATED";18="WAIT_FOR_RR_ACTIVE";19="IDLE";20="WAIT_FOR_ADDITIONAL_OUTGOING_MM_CONNECTION";21="WAIT_FOR_RR_CONNECTION_REESTABLISHMENT";22="WAIT_FOR_REESTABLISH_DECISION";23="LOCATION_UPDATING_PENDING";24="IMSI DETACH PENDING";25="CONNECTION_RELEASE_NOT_ALLOWED"};
    :local TErfrrcstate1 {0="IDLE";2="CELL DCH"};
    :local TErfrrcstate2 {0="IDLE";2="CELL FACH";3="CELL DCH";4="CELL PCH";5="URA PCH";};
    :local TErfsdstate {0="NONE";1="CS_ONLY";2="PS_ONLY";3="CS_PS"};
    :local a [$ATVAR "AT#RFSTS"]
    :local r [$toarrayFromTelitResponse $a];
    :local z [:toarray ""];
    :local l [:len $r];
    :if ($l=16) do={ :set z [$toarrayApplyTemplate $r $TErfsts1]; }; 
    :if ($l=15) do={ :set z [$toarrayApplyTemplate $r $TErfsts2]; };
    :if ($l=14) do={ :set z [$toarrayApplyTemplate $r $TErfsts3]; };
    #:if ($l>16 || $l<14) do={ :error "Frfsts got unexpected length ($l) from: $r"};
    :set ($z->"MM") ($TErfmmstate->($z->"MM"));
    :set ($z->"RRC") ($TErfrrcstate1->($z->"RRC"));
    :set ($z->"SD") ($TErfsdstate->($z->"SD"));
    #cleanup
    :set ($z->"ABND") [:pick ($z->"ABND") 0 [find ($z->"ABND") "\n"]]
    :return $z;
}
