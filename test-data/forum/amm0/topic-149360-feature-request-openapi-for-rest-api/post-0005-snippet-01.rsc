# Source: https://forum.mikrotik.com/t/feature-request-openapi-for-rest-api/149360/5
# Topic: Feature Request : OpenAPI for REST API
# Source archive: mcp-discourse SQLite (source_name=amm0)
# Extracted from: code-block

function webfiglist(ip) {
  if (typeof window === "object" && !ip) {
    ip = (new URL(window.location.href)).host
  }
  return new Promise((done) => {
    fetch(`http://${ip}/webfig/list`)
      .then((req) => req.text())
      .then((txt) => {
        var results = {};
        /* this is critical... 
               the /webfig/list is not valid JSON document, it's a JS "fragment" 
               ...so we need eval() to "convert it" to a variable to then return */
        eval(`results = [${txt}]`);
        done(results);
      });
  });
}

function webfigschemas(ip) {
    if (typeof window === "object" && !ip) {
        ip = (new URL(window.location.href)).host
   }  
   return webfiglist(ip).then((list) =>
    Promise.all(
      list
        .filter((i) => i.unique)
        .map((i) => {
          return new Promise((done) => {
            let file = i.name
            fetch(`http://${ip}/webfig/${file}`)
              .then((req) => req.text())
              .then((txt) => {
                /* same eval() trick as the webfiglist, except return a "tuple" with [filename, data] */
                var results
                eval(`results = ${txt}`)
                done([ file, results ])
              })
          })
        })
    )
  )
}


webfiglist().then(console.log)
webfigschemas().then(console.log)

// NODE.JS save to file
// let ip = "192.168.88.1"
// const fs = require('fs');
// webfigschemas(ip).then(d => fs.writeFileSync("./webfig-list-schema.json", JSON.stringify(d)))
