
exports.service_prefix = "rpcsrv"


exports.helpers =
  logger : 
    main : "#{OK_TOP}/bin/logger",
    listen : "/var/run/okws/logger.sock"
    rundir : "/var/log/okws"
  publisher:
    main : "#{OK_TOP}/bin/publisher"
    listen : "/var/run/okws/publisher.sock"
    rundir : "/var/www/docs"
  demux : 
    main : "#{OK_TOP}/bin/demux"
    listen : "/var/run/okws/demux.sock"
    rundir : "/var/run/okws/empty"

clusters.web_cluster = 
  hosts : [ "ws-0", "ws-1" ]

  web_config :
    http_listen  : [ 80, 81 ]
    https_listen : [ 443 ]
    cert : "/some/certfile"
    service_autodir : "websrv/"

  web_services : [{
    name   : "profile",
    uri    : [ "/profile", "/foo", /// /profile/:\d+.* /// ]
    listen : [ 81, 82 ]
    path   : "webserv/profile"
    web    : true
  },{
    name : "splash",
    uri  :  "/"
    web  : true
  }]

H=4  # number of match cluster hosts
W=10 # number of workers per host
B=3  # number of blobds per host

clusters.match_cluster =
  hosts : ({
    name : "ma-#{h}.prod.okcupid.com"
    id : h
    services : ({
      name   : "workerd"
      id     : h * H + i
      listen : 40000 + h * H + i
    } for i in [0..W-1] ).concat({
      name   : "blobd"
      id     : h * H + i
      listen : 50000 + h * H + i
    } for i in [0..B-1]).concat({
      named  : "coordinated"
      id     : h
      listen : 50100
    })
  } for h in [0..H-1] )

cluster.rpc_cluster =
  hosts : ( "rpc-#{i}.prod" for i in [0..2] )
  dead : [ "rpc-0" ]
  services : [{
      name   : "messaged"
      listen : 30011
    },{
      name   : "recommendd"
      listen : 3012
    }]

