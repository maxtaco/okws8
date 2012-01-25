
exports.service_prefix = "rpcsrv"
require 'path'

exports.top_dir = "/opt/node-ws/"

exports.generator = (config) ->
  
  helpers :
    logger : 
      main   : config.bin_dir "logger"
      listen : config.socket_dir "logger.sock"
      rundir : config.log_dir()
    publisher :
      main   : config.bin_dir "publisher"
      listen : config.socket_dir "publisher.sock"
      rundir : config.docs_dir()
    demux : 
      main   : config.bin_dir "demux"
      listen : config.socket_dir "demux.sock"
      rundir : config.empty_jail() 
