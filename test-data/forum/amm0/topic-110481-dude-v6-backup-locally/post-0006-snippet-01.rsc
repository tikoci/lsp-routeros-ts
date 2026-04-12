# Source: https://forum.mikrotik.com/t/dude-v6-backup-locally/110481/6
# Topic: Dude v6 - Backup locally
# Source archive: mcp-discourse SQLite (source_name=amm0)
# Extracted from: code-block

{

### Backup Dude locally ###

# Set root path for backup

:local localbackuppath "disk1"

# Define variables to use for file generation

:local dudeconffilename "Dude_configuration_backup"
:local dudedbfilename "Dude_db_backup"
:local dudeconffileext "rsc"
:local dudedbfileext "db"

# Get date and time

:local getnow do={
        :local d [/system/clock/get date]; 
        :local t [/system/clock/get time]; 
        :return "$[:pick $d 0 4]$[:pick $d 5 7]$[:pick $d 8 10]-$[:pick $t 0 2]$[:pick $t 3 5]"
}
:local now [$getnow]

# Make Dude backup

:log warn message="Dude backup locally started";

/dude export file="$localbackuppath/$dudeconffilename_$now.$dudeconffileext"
/dude export-db backup-file="$localbackuppath/$dudedbfilename_$now.$dudedbfileext"

:log warn message="Dude backup locally finished"

}
