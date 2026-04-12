# Source: https://forum.mikrotik.com/t/feature-request-openapi-for-rest-api/149360/11
# Topic: Feature Request : OpenAPI for REST API
# Source archive: mcp-discourse SQLite (source_name=amm0)
# Extracted from: code-block

#%RAML 1.0
title: ROS.RAML sample
version: 7.6
protocols: [HTTPS]
mediaType: [application/json]
securitySchemes:
  basic:
    description: |
      Mikrotik REST API only supports Basic Authentication, secured by HTTPS
    type: Basic Authentication
securedBy: [basic]
baseUri: https://{host}:{port}/rest
baseUriParameters:
  host:
    description: RouterOS device IP or host name
    default: "192.168.88.1"
  port:
    description: RouterOS https port to use
    default: "443"
documentation:
  - title: RouterOS RAML Schema
    content: |
      Schema is generated using `/console/inspect` on a RouterOS devices and
      interpreted into a schema based on the rules in
      [Mikrotik REST documentation](https://help.mikrotik.com)
  - title: Demo Only
    content: We just try a few commands 

/console:
  /inspect:
    post:
      description: Inspects the RouterOS AST
      body:
        application/json:
          type: object
          properties:
            .proplist?:
              type: string
              description: List of properties to return (see RouterOS docs)
            .query?:
              type: string
              description: List of properties to return (see RouterOS docs)
            path?:
              type: string
              description: Comma-seperated string of RouterOS path
              example: 
            input?:
              type: string
            request:
              type: string
              enum: [self|child|completion|highlight|syntax|error]
          example:
              path: "ip,address,add,interface"
              request: syntax
      responses:
        200:
          body:
            application/json:
              type: array
