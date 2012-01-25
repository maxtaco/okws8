
{Getopt}  = require '../lib/getopt'
log       = require '../lib/log'
config    = require '../lib/config'
constants = require '../lib/constants'
fs        = require 'fs'

#-----------------------------------------------------------------------

SYNOPSIS = "Usage: okld [-dh] [-f<file>]"

SCHEMA = [
    [ 'd', 'daemon',      '',  'run in daemon mode' ],
    [ 'f', 'config-file', ':', 'the config file to use' ]
  ]

DESCRIPTION = '''
  - Start up OKWS, the master script...
'''

#=======================================================================
 
class Okld
  
  ##----------------------------------------
 
  constructor : ->
    @_daemon_mode = false
    @_config_file = constants.config_file

  ##----------------------------------------

  parse_args : (argv, cb) ->
    go = new Getopt SCHEMA, SYNOPSIS, DESCRIPTION
    res = go.parse argv
    if res.ok
      @_daemon_mode = true if res.opts.daemon
      @_config_file = res.opts.config_file if res.opts.config_file?
    else
      for line in res.msg
        log.error line 
    cb res.rc

  ##----------------------------------------
  
  configure : (cb) ->
    @_cfg = new Config @_config_file
    await @_cfg.open defer rc
    (rc = @_cfg.check) if rc is 0
    cb rc

  ##----------------------------------------
  
  run       : (cb) ->
    @_okd = new OkdHandle this
    await @launchHelperServices defer rc if rc is 0
    console.log "startup file: #{@_config_file}"
    cb 0

#=======================================================================
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
