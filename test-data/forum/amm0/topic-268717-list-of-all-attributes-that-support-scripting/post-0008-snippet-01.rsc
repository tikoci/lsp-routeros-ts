# Source: https://forum.mikrotik.com/t/list-of-all-attributes-that-support-scripting/268717/8
# Topic: List of all attributes that support scripting?
# Source archive: mcp-discourse SQLite (source_name=amm0)
# Extracted from: code-block

rscfile://192.168.74.1:7080/
│
├── system/                                   (schema discovery root)
│   ├── script/                               (singleton: isList)
│   │   ├── Untitled-1                        [FILE] SystemScriptItem.source
│   │   ├── something                          [FILE] SystemScriptItem.source
│   │   └── [<new>]               
│   │
│   ├── scheduler/                            (isList: multiFilePerItem=false)
│   │   ├── aasdfasdfasdf                     [FILE] .on-event
│   │   └── [<new>]               [CREATE OK after cache sync]
│   │
│   ├── logging/
│   │   └── action/                           (isList: target=script filter)
│   │       └── actionscript                  [FILE] symlink to /system/script/Untitled-1
│   │           ^                             [SYMLINK: script= field → /system/script/name]
│   └── routerboard/                          (singleton: multiFilePerItem=true)
│       ├── mode-button/                      [DIR] button config sub-attributes
│       │   └── on-event                      [FILE] nested .mode-button.on-event
│       ├── reset-button/
│       │   └── on-event                      [FILE] nested .reset-button.on-event
│       └── wps-button/
│           └── on-event                      [FILE] nested .wps-button.on-event
│
├── interface/
│   └── vrrp/                                 (isList: multiFilePerItem=true)
│       ├── vrrp1/                            [DIR] VRRP instance
│       │   ├── on-master                     [FILE] .on-master script
│       │   └── on-backup                     [FILE] .on-backup script
│       └── [vrrp2, vrrp3, ...]/
│
│
├── ip/
│   ├── dhcp-client/                          (nameAttr=interface, template=${interface})
│   │   ├── ether1                            [FILE] DHCP script for ether1
│   │   └── ether2
│   │
│   ├── dhcp-server/                          (isList)
│   │   ├── dhcp_vlan10                       [FILE] lease-script
│   │   └── dhcp_vlan20
│   │
│   └── dhcp-server/
│       └── alert/                            (nested under /ip/dhcp-server)
│           ├── ether1-alert                  [FILE] on-alert for ether1
│           └── ether2-alert
│
├── ipv6/
│   ├── dhcp-client/                          (same as ip/dhcp-client, IPv6 variant)
│   ├── dhcp-server/                          (binding-script)
│   └── hotspot/
│       └── user-profile/                     (multiFilePerItem)
│           └── profile1/
│               ├── on-login                  [FILE]
│               └── on-logout                 [FILE]
│
├── tool/
│   ├── netwatch/                             (nameAttr=host, template=${host})
│   │   ├── 192.168.1.1/                      [DIR]
│   │   │   ├── on-up                         [FILE] up-script
│   │   │   ├── on-down                       [FILE] down-script
│   │   │   └── on-test                       [FILE] test-script
│   │   └── 10.0.0.1/
│   │
│   └── traffic-monitor/                      (multiFilePerItem)
│       ├── monitor1/
│       │   └── on-event                      [FILE]
│       └── monitor2/
│
├── ppp/
│   └── profile/                              (multiFilePerItem)
│       └── ppp_profile1/
│           ├── on-up                         [FILE]
│           └── on-down                       [FILE]
│
└── iot/
    ├── mqtt/
    │   └── subscriptions/                    (nameAttr=topic, template=${topic})
    │       ├── sensor/temp                   [FILE] on-message
    │       └── sensor/humidity               [FILE] on-message
    │
    └── gpio/
        └── digital                           [FILE] singleton script
