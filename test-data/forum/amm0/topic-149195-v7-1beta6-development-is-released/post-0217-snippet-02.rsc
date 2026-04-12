# Source: https://forum.mikrotik.com/t/v7-1beta6-development-is-released/149195/217
# Topic: v7.1beta6 [development] is released!
# Source archive: mcp-discourse SQLite (source_name=amm0)
# Extracted from: code-block

/routing/route/print detail 
As + ;;; ecmp2
    afi=ip4 
       contribution=active dst-address=0.0.0.0/0 routing-table=ecmp2 pref-src="" gateway=lte2 immediate-gw=lte2 distance=1 scope=30 target-scope=10 
       belongs-to="Static route" 
       debug.fwp-ptr=0x20202000 

 As + ;;; ecmp2
    afi=ip4 
       contribution=active dst-address=0.0.0.0/0 routing-table=ecmp2 pref-src="" gateway=lte1 immediate-gw=lte1 distance=1 scope=30 target-scope=10 
       belongs-to="Static route" 
       debug.fwp-ptr=0x20202060
