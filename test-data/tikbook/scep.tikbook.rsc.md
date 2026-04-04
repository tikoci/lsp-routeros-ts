[//]: #!tikbook

## Using RouterOS's SCEP Server with ~~Apple "Profiles"~~ `scepclient` on Linux"
First, we need to set up self-signed chain on RouterOS.  To keep things organized, using a variables to store a "base name" and other details used when creating certificates:

```routeros
:global scepbase "tikoci"
:global certkeysize 2048
:global digestalgo "sha256"
:global certdays 365
:global certcadays 1825


# Just to sure that `:execute as-string` can read it back in TikBook
:put "$scepbase"
```

Output what we know about certificates from RouterOS **before** doing anything.
> For a `print` command, it will **also** retrieve JSON using "pure REST" call.  Using the "..." next to the output cell let you use different formats using "Change Presentation", including other "Notebook Renders" that show a pretty table from the JSON.  You can use `plain/text` to see the results of the `:execute`"

```routeros
/certificate/print
```

>
> Since we're _testing_, just remove any existing certificates using our scheme.  This allow the notebook to run **multiple** times.  Now for `/certificate`, that means client certs associated with any created here get deleted.  So likely you want to run this "once".
>

```routeros
/certificate { :foreach c in=[find name~"$scepbase"] do={ remove $c } }
:delay 2s
```

#### Add Certificate Authority
This will then need to be signed.  In RouterOS, this is a "certificate template".

```routeros
/certificate add  name="$scepbase-ca-router" organization="$scepbase" common-name="Router Authority" unit=[/system/identity/get name] digest-algorithm=$digestalgo days-valid=$certcadays  key-usage=key-cert-sign,crl-sign key-size=$certkeysize
```

#### Add Server and Client Certificate Templates
The SCEP server does not need thise, since SCEP client request one.  But to use X.509 later, you'll need the server certificate.  And the "client template" can use to create new from "locally" (without SCEP)
##### Server

```routeros
/certificate add name="$scepbase-router" organization="$scepbase" common-name="Router Services" unit=[/system/identity/get name] digest-algorithm=$digestalgo days-valid=$certdays  key-usage=digital-signature,content-commitment,key-encipherment,data-encipherment,key-agreement,tls-server,tls-client,code-sign,email-protect,timestamp,ocsp-sign key-size=$certkeysize
```

##### Client

```routeros
/certificate add name="$scepbase-client" organization="$scepbase" common-name="Client Authorization" unit=[/system/identity/get name] digest-algorithm=$digestalgo days-valid=$certdays  key-usage=digital-signature,content-commitment,key-encipherment,data-encipherment,key-agreement,tls-client,code-sign,email-protect key-size=$certkeysize
```

And let's print it agian, to be sure we got them...

```routeros
/certificate/print
```

##### Use "helper function" to find the CA root used in signing next

```routeros
:global getScepAuthorityName do={
    :global scepbase
    :return [/certificate/get [find name="$scepbase-ca-router"] name]
}

:put [$getScepAuthorityName]
```

> RouterOS script is tricky.  While $scepbase is a :global, it have to be "declared" in the helper as `:global scepbase` in above.  Let's check it gets the right name...




### Sign the CA to add key and make it "self-signed"

```routeros
/certificate/sign [$getScepAuthorityName]
```

#### Sign the Client and "Server"/Router Certs using CA

```routeros
/certificate/sign ca=[$getScepAuthorityName] [find name="$scepbase-router"]

/certificate/sign ca=[$getScepAuthorityName] [find name="$scepbase-client"]
```

### Now, add an SCEP Server

Before doing that, show and cleanup any old ones created

```routeros
/certificate/scep-server print
```

```routeros
/certificate/scep-server/remove [find path="/scep/$scepbase"]
```

### Actually add the SCEP Server

This will use the path based on `$scepbase`, like `/scep/tikoci`.  You'll need this to use an SCEP Client, like Apple Profile.

```routeros
/certificate/scep-server/add ca-cert=[$getScepAuthorityName] path="/scep/$scepbase"
```

### Export the CA certificate and "Share"

The "fingerprint" in it may be needed in MDM.  So export as PEM and share using BackToHomeFiles...

```routeros
/certificate/export-certificate [$getScepAuthorityName] file-name="/$[$getScepAuthorityName]"
```

Remove and re-add the exported certificate from "sharing" in /ip/cloud

```routeros
/ip/cloud/back-to-home-file/remove [find path="/$[$getScepAuthorityName].crt"]
```

```routeros
/ip/cloud/back-to-home-file/add path="/$[$getScepAuthorityName].crt" expires=1d disabled=no
```

It take could to a little bit of time for "BTHF" to actually share it.  It might show "getting certificate" from below:

```routeros
/ip/cloud/back-to-home-file/print
```

```routeros
:delay 10
```

```routeros
/ip/cloud/back-to-home-file/print
```

#### URL to download Root Cerificate Authority ("Router Authority")

```routeros
:put [/ip/cloud/back-to-home-file/get [find path="/$[$getScepAuthorityName].crt"] direct-url]
```

