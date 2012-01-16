
web_servers :

  hosts : [ "ws-0", "ws-1" ]

  web_server :
    http_ports   : [ 80, 81 ]
    https_ports  : [ 443 ]
    cert : "/some/certfile"

  web_services: [
    { prefix : "/profile",
      ports : [ 81, 82 ]
      main  : "webserv/profile"
    },
    { prefix : "/mailbox",
      main  : "webserv/mailbox"
    },
  ]

  services : [
    {
      name : "logger"
      main : "backend/logger",
      listen : "/var/run/okws/logger.sock"
      args :
        topdir : "/var/log/okws"
    },
    {
      name : "publisher"
      main : "backend/publisher"
      listen : "/var/run/okws/publisher.sock"
      args :
        topdir : "/var/www/docs"
    }
  ]


message_server : {

  hosts : [ "rpc-0", "rpc-1" ] 

  services : [


  ]


edges : [
   [ "web_servers.web_services.*" : [ "logger", "publisher", "message_server.*" ]
]
