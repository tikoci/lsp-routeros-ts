# Source: https://forum.mikrotik.com/t/rextended-fragments-of-snippets/151033/57
# Post author: @rextended
# Extracted from: code-block

[] > :put [$pdutogsm7 ("\C8\34\88\FE\06\05\D9\EC\50\28\04")]
486920746F20416C6C212121

:put [$HexGSM7toCP1252  [$pdutogsm7 ("\C8\34\88\FE\06\05\D9\EC\50\28\04")]]
Hi to All!!!

:put [$HexGSM7toCP1252  "486920746F20416C6C212121"]
Hi to All!!!

[] > :put [$pdutogsm7 ("\C8\34\88\FE\06\05\D9\EC\50\28")]
Invalid PDU data, expected value not provided.

[] > :put [$pdutogsm7 ("\C8\34\88\FE\06\05\D9\EC\50\28") "ignoreinvalid"]
486920746F20416C6C212121

:put [$HexGSM7toCP1252  "486920746F20416C6C2121"]
Hi to All!!
