# Source: https://forum.mikrotik.com/t/mginx-container-reverse-proxy-for-cors-x-509-support-using-nginx/162709/1
# Topic: "Mginx" Container - Reverse Proxy for CORS & X.509 support using Nginx
# Source archive: mcp-discourse SQLite (source_name=amm0)
# Extracted from: code-block

###
# NGINX Proxy for Mikrotik RouterOS to add X.509 certs & CORS supports
###

# Technically, this is a "template"...
#    the $ { stuff } are Docker environment ENV variables that
#    can be provided at *runtime*, this happens via script
#    included by NGINX that parses this code before using it.

server {
   # Proxy all RouterOS traffic recieved on ENV:OURPROXYPORT (6443 default)
   listen ${OURPROXYPORT} ssl;

   ### X.509 Client Authentication Support ###
   
   # This is disabled by default, but tested and "plumb'ed".
   # If a *client* browser using this proxy has a X.509 cert install
   # that was *signed* by the CA referenced in ssl_client_certificate,
   # that can be used to authenticate to this proxy, thus *adding* security.
   # If you trust your certificate setup, the basic auth needed to use the
   # REST API can be provided using proxy_set_header - so no password needs 
   # be used with CORS, only the X.509 cert.  Instead, after auth, this proxy
   # can add the needed fixed username/password before  
  
   ssl_client_certificate /etc/ssl/certauth.ca.crt;
   ssl_verify_client ${X509AUTHMODE};
   
   #   HINT: Ideally replace the certauth.ca.crt file as part of Dockerfile. 
   #           The CA KEY file is NOT needed, just a PEM version when you use a "real" one.
   #           But since we have the server's self-signed certificate, that can be the CA to
   #           to sign client certs & auth them - this could be done via /container/shell on router
   #           as one workflow to get clients X509 certs.  Using /certificate on the Mikrotik
   #           likely be better, but even more complex to explain.  Thus just a "HINT" here on options.
   #   NOTE: The default is to use the self-generated SSL server key as the CA used to verify client X509.
   #           This is done by copying the key.pem to two locations, but for X509 using a different CA
   #           just add a file to build that points to certauth.ca.crt.  

   ### X.509 Passthrough Authentication
   # Is commented-out & disabled – since you need to customize if used...
   # "X.509 passthrough authentication" also this proxy to provide a username/password 
   # to RouterOS REST API on behalf of the user.  Since it a fixed, you'd want to 
   # really think about the security model before user (e.g. X.509 is required & working): 
    
   # proxy_set_header Authorization 'Basic ${BASE64AUTHBYPASS}';

   # WARNING: Using proxy_set_header Authorization is automatically providing any proxy'ed call to be
   #          authenticated WITHOUT a password.  If you have "ssl_verify_client on", this container
   #          verifies a valid cert BEFORE automatically providing the password - that how this is to be used.
   # HINT: You'll also need to use something to find/encode Authentication value in header above, like Postman.
   
   # Use SSL key and cert installed by Dockerfile at *build* time
   # ./build.sh that creates the .tar image, generates self-signed ones by default
   # To use your own, likely better to reference them in Dockerfile to these names: 
   ssl_certificate /etc/ssl/default.crt;
   ssl_certificate_key /etc/ssl/default.key;

   # Similarly, this should match the CN of the SSL certificate.  
   # For self-signed, it does & router.lan is used in the RouterOS default config
   server_name ${OURPROXYHOST};

   # This is just notes.  Logging goes stdout/stderr by default, which on RouterOS
   # is preferred at this point to going to container disk.  In theory, the log directories
   # should be mounted in the Dockerfile/container, but RouterOS does not support.
   # Leave commented out for now:
   #access_log   /var/log/nginx/nginx.vhost.access.log;
   #error_log    /var/log/nginx/nginx.vhost.error.log;
   
   # For a static web site that is not proxied, add files via Dockerfile. 
   # Disabled, mainly to test & requires changing the "location /" to "location /rest" or etc etc:
   #root /home/www/public;
   #autoindex on;
   #index index.html;
   # ... TODO: the above can be used to include an example JS code that uses the proxy in future

   # For all request, we just add CORS headers and potentially more.  While targeted
   # at /rest, we just always add CORS to everything going through the proxy.
   # NOTE: the proxy only proxies to the local router running the container,
   #       and NOT just any server (although that be possible with different config)
   
   # for the actual root, just redirect to real root
   #   e.g. logos/graphics would never need CORS
   location = / {
      proxy_pass https://${ROUTERHOST}:${ROUTERHTTPSPORT}; 
   }
   location / {
      # This is what a web browser JavaScript needs to see to use RouterOS REST API,
      # which is why there is this container in the middle...
      add_header 'Access-Control-Allow-Origin' '*' always;
      add_header 'Access-Control-Allow-Methods' 'GET, POST, PATCH, PUT, DELETE, OPTIONS' always;
      add_header 'Access-Control-Allow-Headers' 'Authorization,DNT,User-Agent,X-Requested-With,If-Modified-Since,Cache-Control,Content-Type,Range' always;
      add_header 'Access-Control-Expose-Headers' 'Content-Length,Content-Range' always;
      # since CORS needs OPTIONS
      # we provide a generic answer, that yes we support it.
      if ($request_method = 'OPTIONS') {
         add_header 'Access-Control-Allow-Origin' '*' always;
         add_header 'Access-Control-Allow-Headers' 'Authorization,DNT,User-Agent,X-Requested-With,If-Modified-Since,Cache-Control,Content-Type,Range';
         add_header 'Access-Control-Max-Age' 1728000;
         add_header 'Content-Type' 'text/plain; charset=utf-8';
         add_header 'Content-Length' 0;
         return 204;
      }
      # And as a proxy, we need to actually do that.  We can add headers OUTBOUND
      # so theoritically the RouterOS knows the request was proxies.  But ROS doesn't care AFAIK.
      proxy_set_header X-Real-IP $remote_addr;
      proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;

    
      # This is what does all the work.  It take any request recieved here, and just passes along
      # all the headers/data to the "real" RouterOS web server.  This is configuration at 
      # runtime via ENV vars, but using 172.28.1.1:443 is default 
      proxy_pass https://${ROUTERHOST}:${ROUTERHTTPSPORT};

      # ... again the $ { stuff } can be provided in environment at *runtime* on Mikrotik container,
      #     (or buildtime in Dockerfile) 
   }
}
