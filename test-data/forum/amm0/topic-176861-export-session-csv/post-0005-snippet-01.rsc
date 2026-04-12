# Source: https://forum.mikrotik.com/t/export-session-csv/176861/5
# Topic: Export session .csv
# Source archive: mcp-discourse SQLite (source_name=amm0)
# Extracted from: code-block

{
:local infile "sessions.csv"
:local csvstr ""
:onerror e in={ :set csvstr [/file get $infile contents] } do={
    /file add name=$infile 
    /file set $infile contents="ID,User,Acct Session ID,NAS IP Address,Calling Station ID,Download (MB),Started,Uptime (s),Status,Last Accounting Packet\r\n"
} 

:local rows ""
:foreach session in=[/user-manager/session/print show-ids as-value] do={
    :local id ($session->".id")
    :local user ($session->"user")
    :local acctSessionId ($session->"acct-session-id")
    :local nasIpAddress ($session->"nas-ip-address")
    :local callingStationId ($session->"calling-station-id")
    :local download ($session->"download")
    :local started ($session->"started")
    :local uptime ($session->"uptime")
    :local status ($session->"status")
    :local lastAccountingPacket ($session->"last-accounting-packet")

    # Formatta i dati in formato CSV
    :local csvLine "$[:tostr $id],$[:tostr $user],$[:tostr $acctSessionId],$[:tostr $nasIpAddress],$[:tostr $callingStationId],$[:tostr $download],$[:tostr $started],$[:tostr $uptime],$[:tostr $status],$[:tostr $lastAccountingPacket]\r\n"
    :set rows "$rows$csvLine"
}

/file set $infile contents="$csvstr$rows"
:put [/file get $infile contents]
}
