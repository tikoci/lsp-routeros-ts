# Source: https://forum.mikrotik.com/t/new-feature-back-to-home-vpn/168434/351
# Topic: NEW FEATURE: Back to Home VPN
# Source archive: mcp-discourse SQLite (source_name=amm0)
# Extracted from: code-block

<html>
  <head>
  </head>
  <body>
    <script type="text/javascript">
      var userAgent = navigator.userAgent || navigator.vendor || window.opera;
      if (/android/i.test(userAgent)) {
          window.location.replace("market://details?id=com.mikrotik.android.freevpn");
      }
      else if (/iPad|iPhone|iPod/.test(userAgent) && !window.MSStream) {
          window.location.replace("https://apps.apple.com/us/app/mikrotik/id6450679198");
      }
      else {
          window.location.replace("https://mt.lv/bth");
      }
    </script>
  </body>
</html>
