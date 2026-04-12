# Source: https://forum.mikrotik.com/t/corebit-network-topology-monitoring-tool-inspired-by-the-dude/267329/140
# Topic: CoreBit – Network topology & monitoring tool inspired by “The Dude”
# Source archive: mcp-discourse SQLite (source_name=amm0)
# Extracted from: code-block

:global corebitinstall do={
    # container network defaults
    :local corebitserverippre "169.254.123"
    :local dockerbridge corebit

    # database defaults
    :local corebituser corebit
    :local corebitpassword [:rndstr length=16]
    :local corebitdbname corebit
    :local dbport 5432

    # app defaults    
    :local corebitsecret [:rndstr length=32]
    :local appport 3000

    # calculated later, NAT address and root disk placeholder
    :local approuterip
    :local appdisk
    
    # check for 7.21 /app support and new container CLI
    :local hasappsupport false
    :if ([:len [/console/inspect path=app request=child as-value]]>0) do={ :set hasappsupport true }
    :if ($hasappsupport=false) do={ :put "FAILURE: RouterOS no /container with /app support, cannot setup corebit" }
    :if [/system/device-mode/get container] do={} else={ :error "FAILURE: device-mode must allow /container, cannot setup containers" }

    # figure out router's management address using /app/settings
    :set approuterip [/app settings get router-ip]
    :if ([:typeof $approuterip]="nil") do={
        :set approuterip [/app settings get assumed-router-ip]
    }
    :if ([:typeof $approuterip]="nil") do={
        :put "WARNING: No management 'router-ip' set in /app/settings, using default"
        :set approuterip 192.168.88.1
    }
    :set approuterip [/terminal/ask preinput=$approuterip prompt="Please provide the router's management IP address:"]
    :if ([:typeof [:toip $approuterip]]="ip") do={} else={ :error "Install failed - invalid management IP ($approuterip)" }
    
    # determine root disk path
    :set appdisk [/app settings get disk]
    :if ([:typeof $appdisk]="nil" || $appdisk="none") do={
        :local firstdisk [/disk get [find mounted=yes fs~"(btrfs|ext4)" disabled=no] slot]
        :set appdisk [/terminal/ask preinput=$firstdisk prompt="No 'disk' set in /app/settings\r\nPlease provide the root disk's 'slot' (without starting /):"]
    }
    :if ([:len [/disk/find slot=$appdisk]]=0) do={ :error "Install failed - Run /app/setup to configure disk,\r\n or provide a valid disk 'slot' name, then re-run this script."}

    # remove any existing
    :put "Removing any existing corebit containers..."
    /container 
    :foreach cid in=[find name~"corebit-"] do={
        stop $cid
        :while ([get $cid stopped]!=true) do={:delay 1s }
    }
    /interface bridge port remove [find bridge=$dockerbridge interface~"veth-corebit"]
    /ip address remove [find interface~"veth-corebit-"]
    /ip address remove [find comment~"corebit" or address="$corebitserverippre.1/24"]
    /interface veth remove [find name~"veth-corebit"]
    /container remove [find name~"corebit-"]
    /container envs remove [find list~"corebit-"]
    /ip firewall nat remove [find comment~"corebit-"]
    /interface bridge remove [find name="$dockerbridge" or comment~"corebit"]

    # check for /app internal bridge otherwise create a new bridge
    :put "Starting configuration of networking..."
    /interface bridge
    add name=$dockerbridge comment="corebit container bridge"
    /ip/address
    add address="$corebitserverippre.1/24" interface=$dockerbridge
    /ip firewall nat 
    add comment=corebit-bridge chain=srcnat action=masquerade in-interface=$dockerbridge
    # not cannot use place-before=0 if none

    # configure network interfaces and NAT access
    /interface veth
    add address="$corebitserverippre.2/24" dhcp=no gateway="$corebitserverippre.1" name=veth-corebit-app
    add address="$corebitserverippre.3/24" dhcp=no gateway="$corebitserverippre.1" name=veth-corebit-db
    /ip firewall nat
    add comment=corebit-app chain=dstnat action=dst-nat to-addresses="$corebitserverippre.2" to-ports=$appport protocol=tcp dst-address=$approuterip dst-port=$appport 
    # optionally, dstnat db for external access
    add comment=corebit-db chain=dstnat action=dst-nat to-addresses="$corebitserverippre.3" to-ports=$dbport protocol=tcp dst-address=$approuterip dst-port=$dbport 
    /interface bridge port
    add interface=veth-corebit-app bridge=$dockerbridge
    add interface=veth-corebit-db bridge=$dockerbridge

    # add envs needed for corebit
    :put "Adding env variables..."
    /container envs
    add key=DATABASE_URL list=corebit-app value="postgresql://$corebituser:$corebitpassword@$corebitserverippre.3:$dbport/$corebitdbname"
    add key=HOST list=corebit-app value=0.0.0.0
    add key=NODE_ENV list=corebit-app value=production
    add key=PORT list=corebit-app value=$appport
    add key=SESSION_SECRET list=corebit-app value=$corebitsecret
    # App ENVs; You may need to change APP_PORT if you have anything else on port 3000
    add key=APP_PORT list=corebit-db value=$appport
    add key=PGPORT list=corebit-db value=$dbport
    add key=POSTGRES_DB list=corebit-db value=$corebitdbname
    add key=POSTGRES_PASSWORD list=corebit-db value=$corebitpassword
    add key=POSTGRES_USER list=corebit-db value=$corebituser
    add key=SESSION_SECRET list=corebit-db value=$corebitsecret
    
    # ensure a temp direcotry
    :put "Setting container directory to use $appdisk per /app scheme"
    /container config
    set tmpdir="/$appdisk/tmp" layer-dir="/$appdisk/apps/layers"

    # add mounts for config file
    :if $hasappsupport do={
        :put "Running on 7.21, using mounts on container"
        /container
        :put "Adding corebit-app container..."
        add envlists=corebit-db,corebit-app interface=veth-corebit-app mount="/$appdisk/apps/corebit/corebit-data:/app/data:rw,/$appdisk/apps/corebit/corebit-backups:/app/backups:rw"  name=corebit-app remote-image=ghcr.io/cis2131/corebit-docker root-dir="/$appdisk/apps/corebit" logging=yes start-on-boot=yes workdir=/app
        :put "Adding corebit-db container..."
        add envlists=corebit-db interface=veth-corebit-db mount="/$appdisk/apps/corebit-db/corebit-db:/var/lib/postgresql/data:rw" name=corebit-db remote-image=registry-1.docker.io/library/postgres:16-alpine root-dir="/$appdisk/apps/corebit-db" logging=yes start-on-boot=yes workdir=/
    } else={
        :error "$0 Script requires RouterOS 7.21 or greater"
    } 

    # start containers
    /container
    :delay 5s
    :foreach cid in=[find name~"corebit-"] do={
        :put "Queue start of $[get $cid name]..."
        start $cid
    }
    :put "Waiting for container setup..."
    :while (!([get corebit-app running] && [get corebit-db running])) do={    
        :put "corebit-app - $[get corebit-app about]"
        :put "corebit-db - $[get corebit-db about]"
        /terminal/cuu
        /terminal/cuu
        :delay 2s
    }
    :put "\r\n\r\n\rDONE\n\tUse http://$approuterip:$appport then provide 'admin' as both username and password"
    # /container/print where name~"corebit-"
}

$corebitinstall
