
{Getopt} = require '../lib/getopt'
log = require '../lib/log'
config = require '../lib/config'

#-----------------------------------------------------------------------

SYNOPSIS = "Usage: okld [-dh] [-f<file>]"

SCHEMA = [
    [ 'd', 'daemon',      '',  'run in daemon mode' ],
    [ 'f', 'config-file', ':', 'the config file to use' ]
  ]

DESCRIPTION = '''
  - Start up OKWS, the master script...
''' 

#-----------------------------------------------------------------------
 
class Okld
  constructor : ->
    @_daemon_mode = false
    @_config_file = config.config_file

  parse_args : (argv, cb) ->
    go = new Getopt SCHEMA, SYNOPSIS, DESCRIPTION
    res = go.parse argv
    if res.ok
      @_daemon_mode = true if res.opts.daemon
      @_config_file = res.opts.config_file if res.opts.config_file?
      console.log "XXX #{JSON.stringify res.opts}"
    else
      for line in res.msg
        log.error line 
    cb res.rc

  configure : (cb) -> cb 0
  run       : (cb) ->
    console.log "startup file: #{@_config_file}"
    cb 0

#-----------------------------------------------------------------------
# the main function
 
okld = new Okld()
rc = 0
log.set_proc process.argv[1]

await okld.parse_args process.argv[2..], defer rc  if rc is 0
await okld.configure defer rc                      if rc is 0
await okld.run defer rc                            if rc is 0

process.exit rc

#
#-----------------------------------------------------------------------
