# Source: https://forum.mikrotik.com/t/need-some-scripting-help-bounty-available/162737/4
# Topic: need some scripting help, bounty available
# Source archive: mcp-discourse SQLite (source_name=amm0)
# Extracted from: code-block

[user@bigdude] > :put [$JSON myjson.txt]
description=address=30 Rockafeller Center;contact=email=;name=;phone=;deviceCount=6;deviceListStatus=active;deviceOutageCount=0;elevation=;endpoints=;height=;ipAddresses=100.70.5.
93;100.70.9.200;100.70.31.179;100.70.32.190;location=;note=;regulatoryDomain=US;sla=1;ucrmId=537;id=d66feee0-601e-4b45-8135-2fece1df4a41;identification=id=d66feee0-601e-4b45-8135-
2fece1df4a41;name=Customer Name;parent=;status=active;suspended=false;type=endpoint;updated=2022-12-06T05:56:03.035Z;lastSpeedReport=;notifications=type=none;users=;qos=aggregatio
n=;downloadBurstSize=;downloadSpeed=50000000;enabled=true;propagation=;uploadBurstSize=;uploadSpeed=20000000;ucrm=client=id=254;isLead=false;name=customer name;service=activeFrom=
2021-11-28T00:00:00.000Z;id=537;name=50M-R;status=1;tariffId=24;trafficShapingOverrideEnabled=false


[user@bigdude] > :global ja [$JSON myjson.txt]


[user@bigdude] > :foreach k,v in=($ja->0) do={:put "$[:tostr $k] = $[:tostr $v]"}
description = address=30 Rockafeller Center;contact=email=;name=;phone=;deviceCount=6;deviceListStatus=active;deviceOutageCount=0;elevation=;endpoints=;height=;ipAddresses=100.70.
5.93;100.70.9.200;100.70.31.179;100.70.32.190;location=;note=;regulatoryDomain=US;sla=1;ucrmId=537
id = d66feee0-601e-4b45-8135-2fece1df4a41
identification = id=d66feee0-601e-4b45-8135-2fece1df4a41;name=Customer Name;parent=;status=active;suspended=false;type=endpoint;updated=2022-12-06T05:56:03.035Z
lastSpeedReport = 
notifications = type=none;users=
qos = aggregation=;downloadBurstSize=;downloadSpeed=50000000;enabled=true;propagation=;uploadBurstSize=;uploadSpeed=20000000
ucrm = client=id=254;isLead=false;name=customer name;service=activeFrom=2021-11-28T00:00:00.000Z;id=537;name=50M-R;status=1;tariffId=24;trafficShapingOverrideEnabled=false

[user@bigdude] > $YAML ($ja->0)
  description:
    address: 30 Rockafeller Center
    contact:
      email: 
      name: 
      phone: 
    deviceCount: 6
    deviceListStatus: active
    deviceOutageCount: 0
    elevation: 
    endpoints:
    height: 
    ipAddresses:
      0: 100.70.5.93
      1: 100.70.9.200
      2: 100.70.31.179
      3: 100.70.32.190
    location: 
    note: 
    regulatoryDomain: US
    sla: 1
    ucrmId: 537
  id: d66feee0-601e-4b45-8135-2fece1df4a41
  identification:
    id: d66feee0-601e-4b45-8135-2fece1df4a41
    name: Customer Name
    parent: 
    status: active
    suspended: false
    type: endpoint
    updated: 2022-12-06T05:56:03.035Z
  lastSpeedReport: 
  notifications:
    type: none
    users:
  qos:
    aggregation: 
    downloadBurstSize: 
    downloadSpeed: 50000000
    enabled: true
    propagation: 
    uploadBurstSize: 
    uploadSpeed: 20000000
  ucrm:
    client:
      id: 254
      isLead: false
      name: customer name
    service:
      activeFrom: 2021-11-28T00:00:00.000Z
      id: 537
      name: 50M-R
      status: 1
      tariffId: 24
      trafficShapingOverrideEnabled: false


# As an array you can pull out the parts you need...  Again no need to use YAML, the print could work but that YAML code deals with unwinding the nesting (I normally just use it to OUTPUT a more friendly version of an array to the console)

[user@bigdude] > $YAML ($ja->0->"description")
  address: 30 Rockafeller Center
  contact:
    email: 
    name: 
    phone: 
  deviceCount: 6
  deviceListStatus: active
  deviceOutageCount: 0
  elevation: 
  endpoints:
  height: 
  ipAddresses:
    0: 100.70.5.93
    1: 100.70.9.200
    2: 100.70.31.179
    3: 100.70.32.190
  location: 
  note: 
  regulatoryDomain: US
  sla: 1
  ucrmId: 537
