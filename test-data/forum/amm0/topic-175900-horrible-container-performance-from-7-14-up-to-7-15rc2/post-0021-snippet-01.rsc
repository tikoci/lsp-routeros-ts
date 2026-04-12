# Source: https://forum.mikrotik.com/t/horrible-container-performance-from-7-14-up-to-7-15rc2/175900/21
# Topic: Horrible container performance from 7.14 up to 7.15rc2
# Source archive: mcp-discourse SQLite (source_name=amm0)
# Extracted from: code-block

{
FILE=~/dnsperf.queries
DNSSERVER=192.168.88.1
CONNECTIONS=20 
QUERIESPERSEC=100
DURATION=10
TESTHOST=google.com

echo "** DNSPERF TEST **"
echo "Running dnsperf to $DNSSERVER for $DURATION sec, using $CONNECTIONS connections, at max rate of $QUERIESPERSEC queries per sec."
echo "... using the following query file at $FILE:"
echo "$TESTHOST A" > $FILE   
cat $FILE
echo "Starting dnsperf...\n"
dnsperf -s $DNSSERVER  -c $CONNECTIONS -l $DURATION -Q $QUERIESPERSEC -d $FILE   
}
