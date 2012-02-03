
path = require 'path'

constants =
  top_dir : "/usr/local/nws"
  restart_delay : 2000 # by default wait 2s before restarting something
  run_states :
    NONE : 0
    STARTUP : 1
    RUN : 2
    SHUTDOWN : 3

for k,v of constants
  exports[k] = v

exports.conf_dir    = config_dir =  path.join constants.top_dir,    "conf"
exports.config_file = config_file = path.join constants.config_dir, "nws.conf.iced"
