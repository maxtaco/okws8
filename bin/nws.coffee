
{Getopt}  = require '../lib/getopt'
log       = require '../lib/log'
config    = require '../lib/config'
constants = require '../lib/constants'
fs        = require 'fs'
sh        = require '../lib/service_handle'

#-----------------------------------------------------------------------

SYNOPSIS = "Usage: okld [-dhi] [-f<file>]"

SCHEMA = [
    [ 'd', 'daemon',       '',  'run in daemon mode' ],
    [ 'f', 'config-file',  ':', 'the config file to use' ]
    [ 'i', 'in-place',     '',  'run in-place in the current dir' ]
    [ 't', 'top-data-dir', ':', 'override the top data directory' ]
    [ 'T', 'top-dir',      ':', 'override the top directory' ]
    [ 's', 'top-src-dir',  ':', 'override the top src directory' ]
  ]

DESCRIPTION = '''
  - Start up OKWS, the master script...
'''

#=======================================================================
 
class Okld
  
  ##----------------------------------------
 
  constructor : ->
    @_config_file = constants.config_file
    @_services = []
    @_helpers = []
    @_argv_opts = {}

  ##----------------------------------------

  parse_args : (argv, cb) ->
    go = new Getopt SCHEMA, SYNOPSIS, DESCRIPTION
    res = go.parse argv
    if res.ok
      @_argv_opts = res.opts
      @_config_file = res.opts.config_file if res.opts.config_file?
    else
      for line in res.msg
        log.error line 
    cb res.rc

  ##----------------------------------------
  
  configure : (cb) ->
    log.info "startup with config file: #{@_config_file}"
    @_cfg = new Config @_config_file, @_argv_opts
    await @_cfg.open defer ok
    (ok = @_cfg.check) if ok
    cb if ok then 0 else -3

  ##----------------------------------------
  
  launchHelpers : (cb) ->
    ok = true
    for h in @_helpers when ok
      await h.launch defer ok
    cb ok
   
  ##----------------------------------------
  
  run : (cb) ->
    if o = @_cfg.helpers()?.demux
      @_okd = new sh.DemuxHandle @, o
      @_helpers.push @_okd
    await @launchHelpers defer rc
    cb rc

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
