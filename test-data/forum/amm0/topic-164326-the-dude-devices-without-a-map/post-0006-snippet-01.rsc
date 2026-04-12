# Source: https://forum.mikrotik.com/t/the-dude-devices-without-a-map/164326/6
# Topic: The dude devices without a map
# Source archive: mcp-discourse SQLite (source_name=amm0)
# Extracted from: code-block

import sqlite3, re, binascii
conn = sqlite3.connect('/home/ulypka/dude/dude.db')
maps=dict()
devices=dict()
net=dict()
def inttohex(a):
    h=hex(int(a))[2:].zfill(8)
    rh="".join(reversed([h[i:i+2] for i in range(0, len(h), 2)]))
    return(rh)
def addrhettarr(s):
    ips=list()
    for index in range(len(s)/8):
        #print index
        hip=s[:8]
        s=s[8:]
        bytes = ["".join(x) for x in zip(*[iter(hip)]*2)]
        bytes = [int(x, 16) for x in bytes]
        ips.append(".".join(str(x) for x in bytes))
    return(ips)
def hextoint(a):
    rh="".join(reversed([a[i:i+2] for i in range(0, len(a), 2)]))
    return(int(rh, 16))
for row in conn.execute("select id, HEX(obj) from objs"):
    rowmap=re.search('4e6574776f726b204d617020456c656d656e741000FE21..(.+)$',row[1],re.IGNORECASE)
    if rowmap:
        mname=rowmap.group(1)
        #print row[0], binascii.unhexlify(mname)
        #mname=rowmap.group(1)
        maps[row[0]]={'name':binascii.unhexlify(mname),'hex':inttohex(row[0])}
    if re.search("4D320100FF8801000F000000.+4C1F1008.+",row[1]):#Hosts
        #print 'original',row[0],row[1]
        hexname=re.search ('^4D320100FF8801000F000000.+1000FE21..(.+)$', row[1])
        name=binascii.unhexlify(hexname.group(1))
        #4D320100FF8801000F000000.+401F1088(ip count 2 bites)
        countip=re.search ('^4D320100FF8801000F000000.+401F1088(....).+$',row[1])
        #print countip.group(1)
        hexip=re.search ('^4D320100FF8801000F000000.+401F1088....(.{'+str(8*int(hextoint(countip.group(1))))+'}).+$',row[1])# .... is 2 vite for IP's
        #print hexip.group(1)
        ips=addrhettarr(hexip.group(1))
        #print row[1]
        #4D320100FF8801000F000000571F1088(01-EXIST/0-NOT)00AF726304
        pid=re.search ('^4D320100FF8801000F000000571F10880100(.{8}).+$',row[1])
        if pid:
            pid=pid.group(1)
            #print pid
            #print hextoint(pid)
        else:
            pid='0'
        devices[row[0]]={'name':name,'ips':ips,'pid':hextoint(pid)}
    NE="4D320100FF8801004A000000"
    if re.search(NE+".+",row[1]):#NetworkMapElement
        Hdata=row[1][len(NE):]
        Hdata2=re.search('(.+)D85D1031',Hdata)
        Tdata=Hdata2.group(1)
        #print 'original',Hdata2.group(1)
        net[row[0]]={}
        for m in re.finditer('....((100(0|1|8|9))|FE08)', Hdata2.group(1)):
            curind=m.group(0)
            if curind[-1]=='0' or curind[-1]=='1':#0 bite
                val='0'
            elif curind[-1]=='8':#4 bite
                val=Tdata[8:][:8]
                Tdata=Tdata[8:]
            elif curind[-1]=='9':#1 bite
                val=Tdata[8:][:2]
                Tdata=Tdata[2:]
            else:
                print 'allarm'
                quit()
            Tdata=Tdata[8:]
            #print 'id',row[0],'hexid',curind,'valueHEX',val, 'NormalVal',hextoint(val)
            net[row[0]][curind[:7]]={'val':val,'bit':curind[-1]}
#LINKS
#da5d1009#64#probebli type#db5d1008#b5726304#linkFrom#dc5d1008#e5929904#linkTo#dd5d1008#e8929904#linkID#df5d1009#04#linkWidth#0100fe08#ea929904#ItemID#
#c05d1008#abaf3a04#MapID#c25d100901c35d100900c45d1008ffffffff#c55d1009#4b#X#c65d1009#28#Y#c75d1009
#print row[1]
#LEN 1000 - 0 bite 1008 - 4 bites  1009 1 bites (len) 1031 maybe payload? FE08-itemid  4 bites
#HOST
#c05d1008#abaf3a04#mapID#c25d1009#00#c35d1009#00#c45d1008#5c375a06#itemID#c55d1008#f2080000#X#c65d1009#e9#Y#c75d1009#00#d85d1031#3c0b00000000000000
LIDlinkFrom='DB5D100'
LIDlinkTo='DC5D100'
LIDlinkID='DB5D100'
LIDItemID='0100FE0'
LIDMapID='C05D100'
LIDX='C55D100'
LIDY='C75D100'
HIDmapID='C05D100'
HIDitemID='C45D100'
HIDX='C55D100'
HIDY='C65D100'
#print devices
for index in net:
    if net[index][HIDitemID]['val']=='FFFFFFFF':#Link type
        linkID[index]={'linkFrom':hextoint(net[index][LIDlinkFrom]['val']),
                        'linkTo':hextoint(net[index][LIDlinkTo]['val']),
                        'MapID':hextoint(net[index][LIDMapID]['val']),
                        }
    else:#host
        h=hextoint(net[index][HIDitemID]['val'])
        if h in devices:
            devices[h]['itemX']=hextoint(net[index][HIDX]['val'])
            devices[h]['itemY']=hextoint(net[index][HIDY]['val'])
            devices[h]['itemID']=hextoint(net[index][HIDitemID]['val'])
            devices[h]['MapID']=hextoint(net[index][HIDmapID]['val'])
            devices[h]['LinkID']=index
