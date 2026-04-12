# Source: https://forum.mikrotik.com/t/mginx-container-reverse-proxy-for-cors-x-509-support-using-nginx/162709/1
# Topic: "Mginx" Container - Reverse Proxy for CORS & X.509 support using Nginx
# Source archive: mcp-discourse SQLite (source_name=amm0)
# Extracted from: code-block

#!/bin/sh

# Container name
IMAGENAME=mginx
echo "Container name (e.g. .tar name, without the .tar) = $IMAGENAME"

# Container platform to build
BUILDPLATFORM=linux/arm/v7
echo "What platform to build? = $BUILDPLATFORM" 

# Build copies container TAR to Mikrotik and configures it
# and uses SSH/SCP to do it.  Fromat is <username>@<routeros_ip>.
# SSH must be enabled on RouterOS for this work.
# If a SSH key is defined for the user, no password is required
# Otherwise, the build will prompt for credentials for upload & config
SSHHOST=admin@router.lan
echo "SSH/SCP user@host = $SSHHOST"

# When copied, where on RouterOS file system (path only)?
TARDEST=sata1-part1
echo "Container build (.tar) will be copied to: $TARDEST/$IMAGENAME.tar"

# An subnet is used for the container. Typically 24 (for a /24)
SUBNETSIZE=24
echo "Container network using a /$SUBNETSIZE" 

# Container's IP address
CONTAINERIP=169.254.8.2
echo "Container IP is: $CONTAINERIP/$SUBNETSIZE" 
#    ... Must be same subnet (based on SUBNETSIZE) as ROUTERHOST below 

# IP address of router running the container
ROUTERHOST=169.254.8.1
echo "Container Gateway (Hosting RouterOS) IP is: $ROUTERHOST/$SUBNETSIZE" 
#    ... Must be same subnet (based on SUBNETSIZE) as CONTAINERIP above
#         & both that subnet must NOT overlap any existing subnet on router

# HTTPS port configurated on Mikrotik the proxy will use
ROUTERHTTPSPORT=443
echo "Hosting RouterOS HTTPS URL: https://$ROUTERHOST:$ROUTERHTTPSPORT" 

# Proxy server's HTTP hostname
OURPROXYHOST=router.lan
echo "Proxy Server Name: $OURPROXYHOST/$SUBNETSIZE" 

# Proxy server's listen port for proxy requests
OURPROXYPORT=6443
echo "Proxy Server Address (may need dest-nat rule on RouterOS): https://$OURPROXYHOST:$OURPROXYPORT" 

# When creating the container's network, what virtual interface name to use
NETIFACE=vethMginxProxy
echo "Container will create/use virtual network interface: $NETIFACE" 

# SSH & SCP are used to automate deployment and configuration
SSHCMD=ssh
SCPCMD=scp
# but to disable, un-comment below
#SSHCMD=echo
#SCPCMD=echo

# Use X509 Authentication
# e.g. sets nginx's ssl_verify_client, values: on | off | optional | optional_no_ca
X509AUTHMODE=off

# Self-signed Validity
# When generating self-signed certificate, the number of days they should be valid
SELFSSLDAYS=1024

# This isn't used unless the nginx.conf is explictly changed, but
# it's the Base-64 version of user:password for your router.  This is fake.
# It's here to avoid needing to change container code to use it if desired.
BASE64AUTHBYPASS="baae64eec0d3d48e57a00902d="

### START BUILD
# NOTE: All build config variables should be assigned above, and only _used_ below...

# Detect actual router's SSL port (TODO: override the configured one if got VALID one...)
# DETECTED_SSLPORT=`$SSHCMD $SSHHOST ":put [/ip/service/get www-ssl port]"` 
echo "Proxy is using $ROUTERHTTPSPORT this needs to match your www-ssl port on RouterOS!"


# Generate self-signed key and certificate for container web server
#    ... typically this is only done once, you can comment out if you want to rebuild and use same certificate
openssl req -x509 -newkey rsa:4096 -keyout self.key.pem -out self.cert.pem -sha256 -days $SELFSSLDAYS -nodes -subj "/C=AQ/O=Unsecured Worldwide/OU=Self Signed/CN=$OURPROXYHOST"

#    ... HINT: if a build is being deployed to same server in future, you may want to comment out the above
#              as it will use the already generated keys = the client-side trust doesn't need to change
#              otherwise, you will have to "re-trust" the newly generated self-signed cert on your PC before using CORS again


# These create potential client/browser-side X509 authentication cert that can be used to access REST
#   Note: A password is still required by default WITH cert.  See nginx.conf for details ONLY require X509.
#         X509AUTHMODE must be "on" for these to have any effect.
# X509AUTHMODE=on   
# create client certificate request
# openssl req -newkey rsa:4096 -keyout client.key.pem -out client.csr.pem -nodes -days $SELFSSLDAYS -subj "/C=AQ/O=Unsecured Worldwide/OU=Self Signed/CN=X509 Client Access to $OURPROXYHOST"
# sign request using server's self-signed SSL certificate as the "CA", which is what to this instance signed client cert = authorized
# openssl x509 -req -in client.csr.pem -CA self.cert.pem -CAkey self.key.pem -out client.cert.pem -set_serial 01 -days $SELFSSLDAYS
# the PEM file can be imported in the local system (or another system) to beable to access the proxy with X509
# EXAMPLE:  This converts the generated keys into a PKCS12 file that can be imported to a PC - but requires a passphrase
#           & asking for one during a build may be confusing.  But uncomment, and load in Certificate Keychain and browser can use it.
#openssl pkcs12 -export -clcerts -in client.cert.pem -inkey client.key.pem -out client.p12


echo "** Starting Docker Build **"

# Using --build-arg to convert the shell env vars into docker build ARG values used by Dockerfile...
#  n.b. which then convert back to env vars inside the container,
#       so default settings can be from here (buildtime) and built-in to image
#       or changed at runtime inside container's settings later

# Build the container for platform
docker buildx build --platform $BUILDPLATFORM \
--build-arg defaultContainerGateway=$ROUTERHOST \
--build-arg defaultRouterHttpsPort=$ROUTERHTTPSPORT \
--build-arg defaultProxyHostname=$OURPROXYHOST \
--build-arg defaultProxyPort=$OURPROXYPORT \
--build-arg defaultX509AuthMode=$X509AUTHMODE \
--build-arg defaultBase64AuthBypass=$BASE64AUTHBYPASS \
-t $IMAGENAME . 

echo "** Docker Build Completed **"

# Save and generate build as .tar file
docker save $IMAGENAME > $IMAGENAME.tar    
echo "Container image, $IMAGENAME.tar, saved locally" 
pwd 

# Copy the tar to the router
echo "Copy to RouterOS..."
SCP_COPY_CMD="$IMAGENAME.tar $SSHHOST:$TARDEST/$IMAGENAME.tar"
echo $SCP_COPY_CMD
$SCPCMD $SCP_COPY_CMD

# Create the network interface and firewall rules
echo RouterOS configuration...

# remove any veth assocated with container
SCMD_RMNET="{ /interface/veth remove [find comment~\"$IMAGENAME\"]; /ip/address remove [find comment~\"$IMAGENAME\"] }" 
echo $SCMD_RMNET
$SSHCMD $SSHHOST "$SCMD_RMNET" 

# add a veth to use for container
SCMD_MKNET="/interface/veth add address=$CONTAINERIP/$SUBNETSIZE gateway=$ROUTERHOST comment=\"$IMAGENAME\" name=\"$NETIFACE\" }; /"
echo $SCMD_MKNET
$SSHCMD $SSHHOST "$SCMD_MKNET" 

# add IP address to same veth for router
SCMD_MKIP="/ip/address add address=$ROUTERHOST/$SUBNETSIZE interface=\"$NETIFACE\" comment=\"$IMAGENAME\" }; /"
echo $SCMD_MKIP 
$SSHCMD $SSHHOST "$SCMD_MKIP"
 
# remove any containers of our type - we only want one
SCMD_RMDOCK="/container { :foreach i in=[find comment~\"$IMAGENAME\"] do={stop \$i; :delay 10s; remove \$i }}; /"
echo $SCMD_RMDOCK
$SSHCMD $SSHHOST "$SCMD_RMDOCK"

# add a new container using this build and start it
SCMD_MKDOCK="/container { add file=$TARDEST/$IMAGENAME.tar logging=yes start-on-boot=yes interface=\"$NETIFACE\" comment=\"$IMAGENAME\"; :delay 10s; start [find comment=\"$IMAGENAME\"]; }; /"
echo $SCMD_MKDOCK 
$SSHCMD $SSHHOST "$SCMD_MKDOCK"

# re-create a NAT dst-nat rule that provides access to proxy
SCMD_NATRULE="/ip/firewall/nat { remove [find comment~\"$IMAGENAME\"]; add action=dst-nat chain=dstnat dst-port=$OURPROXYPORT protocol=tcp to-addresses=$CONTAINERIP to-ports=$OURPROXYPORT comment=\"$IMAGENAME\" }"
echo $SCMD_NATRULE
$SSHCMD $SSHHOST "$SCMD_NATRULE"

echo "** END **"
