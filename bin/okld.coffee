
{OptionParser} = require 'coffee-script/lib/coffee-script/optparse'
log = require '../lib/log'
config = require '../lib/config'

#-----------------------------------------------------------------------

BANNER = '''
  Usage: okld [options]
  
    Start up OKWS, master script
'''

SWITCHES = [
  [ '-d', '--daemon',             'run in daemon mode' ]
  [ '-f', '--config-file',        'specify config file' ]
  [ '-h', '--help',               'print this help screen' ]
]

#-----------------------------------------------------------------------
 
class Okld
  constructor : ->
    @_daemon_mode = false
    @_config_file = config.config_file

  parse_args : (cb) ->
    argv = require('optimist').
      usage('usage: $0 [-dh] [-f<file>]').
      boolean('d').
      alias('d', 'daemon').
      describe('d', 'run in daemon mode').
      
      
      
      
    
    optionParser = new OptionParser SWITCHES, BANNER
    usage = ->
      log.none optionParser.help()
    rc = 0
    try
      o = optionParser.parse argv[2..]
      @_daemon_mode = true if o.daemon
      @_config_file = o["config-file"] if o["config-file"]?
      console.log "XXX #{JSON.stringify o}"
      rc = 1 if o.help
    catch e
      log.error e.toString()
      rc = -2

    usage() unless rc is 0
    cb rc

  configure : (cb) -> cb 0
  run       : (cb) ->
    console.log "startup file: #{@_config_file}"
    cb 0

#-----------------------------------------------------------------------
# the main function
 
okld = new Okld()
rc = 0
log.set_proc process.argv[1]

await okld.parse_args process.argv, defer rc if rc is 0
await okld.configure defer rc                if rc is 0
await okld.run defer rc                      if rc is 0

process.exit rc

#
#-----------------------------------------------------------------------
