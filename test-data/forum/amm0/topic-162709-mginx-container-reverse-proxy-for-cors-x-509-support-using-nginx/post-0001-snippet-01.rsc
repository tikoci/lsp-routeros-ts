# Source: https://forum.mikrotik.com/t/mginx-container-reverse-proxy-for-cors-x-509-support-using-nginx/162709/1
# Topic: "Mginx" Container - Reverse Proxy for CORS & X.509 support using Nginx
# Source archive: mcp-discourse SQLite (source_name=amm0)
# Extracted from: code-block

FROM nginx:alpine

# NOTE: Dockerfile requires key/cert for proxy webserver.
#       ./build.sh run from the same directory will generate them
#       But can be generated using the following at docker build terminal:
# openssl req -x509 -newkey rsa:4096 -keyout self.key.pem -out self.cert.pem -sha256 -days 1024 -nodes -subj "/C=AQ/O=Unsecured Worldwide/OU=Self Signed/CN=router.lan"

# "build time" arguments to override container image default ENVs
ARG defaultProxyPort=6443
ARG defaultContainerGateway=169.254.8.1
ARG defaultRouterHttpsPort=443
ARG defaultProxyHostname=router.lan
ARG defaultX509AuthMode=off
ARG defaultBase64AuthBypass="b@se64encod3dUser:P@ssw0rd="

# "runtime" arguments, this can be provided in the container at launch
ENV ROUTERHOST=$defaultContainerGateway
ENV ROUTERHTTPSPORT=$defaultRouterHttpsPort
ENV OURPROXYPORT=$defaultProxyPort
ENV OURPROXYHOST=$defaultProxyHostname
ENV BASE64AUTHBYPASS=$defaultBase64AuthBypass

# Use X509 authentication?
# e.g. sets nginx's ssl_verify_client, values: on | off | optional | optional_no_ca
ENV X509AUTHMODE=$defaultX509AuthMode


# configuration file used by proxy 
#   ... note it goes to ".../templates", but a NGINX script parses it to
#       /etc/nginx/conf.d/default.conf 
#   ... but this is how we can use any ENV defined in this Dockerfile
#       inside the nginx configuraiton (which does NOT support environment vars) 
COPY nginx.conf /etc/nginx/templates/default.conf.template

# SSL server certificates - these are need to enabled SSL, which is required by CORS
#   ... since we proxy SSL, we either need to export RouterOS's key/cert to use
#       or use self-signed ones & trust them in the browser's computer,
#       or do more fancy stuff like certbot in a container, etc.  #self-signed works fine
COPY self.cert.pem /etc/ssl/default.crt
COPY self.key.pem /etc/ssl/default.key

# This is not needed unless you modify the config to use X.509 authentication
# e.g. via X509AUTHMODE=on - add your own file, and change "self.cert.pem" to use a different
# root CA as the trusted source for verifying an *client* X.509 auth recieved.
# NOTE: 
COPY self.cert.pem /etc/ssl/certauth.ca.crt

# Copy the "public" web pages, from the build's "public" directory, disabled by default
# COPY public/ /home/www/public/

# Not sure RouterOS uses this, but tells the container system the proxy port 
# we'll be listening on.
EXPOSE $defaultProxyPort 

# ENTRYPOINT comes from NGINX parent - normally there'd be one - but not an error here.
