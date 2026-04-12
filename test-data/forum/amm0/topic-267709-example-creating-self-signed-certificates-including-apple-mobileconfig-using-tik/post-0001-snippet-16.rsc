# Source: https://forum.mikrotik.com/t/example-creating-self-signed-certificates-including-apple-mobileconfig-using-tikbook/267709/1
# Topic: ✍️ Example: Creating self-signed certificates, including Apple `.mobileconfig`, using TikBook
# Source archive: mcp-discourse SQLite (source_name=amm0)
# Extracted from: code-block

:global makeAppleProfileFile do={

:global getScepAuthorityName

:global caDownloadUrl

:global UUIDv4

:global scepserverhost

:global scepserverport

:global keyUsage

:global certkeysize

:global retries

:global retryDelay

:global clientname

:global scepbase

:global caCertFile

:global sysname

:local caPayloadId [$UUIDv4]

:local scepPayloadId [$UUIDv4]

:local profilePayloadId [$UUIDv4]

:local keyUsageNumber 0

:local keyUsageEnum {"none"=0;"key encipherment"=4;"signature"=1;"all"=5}

:if ($keyUsageEnum->$keyUsage) do={:set keyUsageNumber ($keyUsageEnum->$keyUsage)}

:local xml "<?xml version= \"1.0\" encoding= \"UTF-8\"?>

<!DOCTYPE plist PUBLIC \"-//Apple//DTD PLIST 1.0//EN\" \"http://www.apple.com/DTDs/PropertyList-1.0.dtd\">

<plist version=\"1.0\">

<dict>

<key>PayloadContent</key>

<array>

<dict>

<key>PayloadCertificateFileName</key>

<string>routeros-ca.crt</string>

<key>PayloadContent</key>

<data>

$[:convert to=base64 [/file/get [find name=[:pick $caCertFile 1 1024] contents]]]

</data>

<key>PayloadDescription</key>

<string>Adds a CA root certificate</string>

<key>PayloadDisplayName</key>

<string>$[:convert transform=uc $scepbase] Authority ($sysname)</string>

<key>PayloadIdentifier</key>

<string>com.apple.security.root.$caPayloadId</string>

<key>PayloadType</key>

<string>com.apple.security.root</string>

<key>PayloadUUID</key>

<string>$caPayloadId</string>

<key>PayloadVersion</key>

<integer>1</integer>

</dict>

</array>

<key>PayloadDescription</key>

<string>Adds certificate authority using RouterOS '$sysname' from '$scepbase' organization</string>

<key>PayloadDisplayName</key>

<string>Certificates from $scepbase-$sysname</string>

<key>PayloadIdentifier</key>

<string>routeros.scepclient.$sysname.$profilePayloadId</string>

<key>PayloadOrganization</key>

<string>$scepbase</string>

<key>PayloadRemovalDisallowed</key>

<false />

<key>PayloadType</key>

<string>Configuration</string>

<key>PayloadUUID</key>

<string>$profilePayloadId</string>

<key>PayloadVersion</key>

<integer>1</integer>

</dict>

</plist>"

:return $xml

}
