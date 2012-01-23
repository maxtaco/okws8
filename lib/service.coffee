
cp        = require 'child_process'
log       = require './log'
{List}    = require './list'
RpcStream = require('./ipc_rpc').Stream
{sc}      = require './status_codes'


#=======================================================================

exports.ServiceHandle = class ServiceHandle
  
  ##-----------------------------------------

  constructor : (parent, d) ->
    @_parent = parent
    @_name = d.name
    @_config = d
    @_receive_cbs = List
    @_pid = -1

  ##-----------------------------------------

  makeCmdLine : ->
    out = []
    out[0] = process.argv[0]
    out[1] = @_config.main
    
    for k,v of @_config.args
      
      dash = if k.length is 1 then "-" else "--"
      opt = dash + k
      
      skip = false
      value = null
      
      if typeof v is 'boolean'
        if not v then
          continue
      else
        value = v

      out.push opt
      out.push value if value
      
    out

  ##-----------------------------------------

  prefix : -> "#{_name}[#{_pid}]"
   
  ##-----------------------------------------

  problem : (m) -> log.error "#{@prefix()} #{m}" 
  
  ##-----------------------------------------

  exit_cb : (code) ->
    @_channel = null
    # all remaining receivers need to know they are out of luck!
    @_receive_cbs.walk (o) -> o(null, null)
    @problem "died with code=#{code}"
    @relaunch()
   
  ##-----------------------------------------

  relaunch : () ->
    unless @_parent.shutdown()
      await setTimeout defer(), @_parent.config().restartDelay()
    unless @_parent.shutdown()
      launch()
   
  ##-----------------------------------------

  ping : (cb) ->
    @_rpc_channel.call "ping", null, null, defer code, res
    rc = if code isnt sc.OK
      @problem "ping returned with code=#{code}"
      -3
    else if res isnt @_pid
      @problem "ping returned with wronge pid (#{res} v #{@_pid})"
      -4
    else 0
    
    cb rc

  ##-----------------------------------------
  
  launch : (rc) ->
    cl = @makeCmdLine()
    log.info "#{@_name}: launching: #{cl.join ' '}"
    opts =
      cwd : @_config.rundir
      env : process.env
      setsid : false
    @_channel = cp.fork cl.shift(), cl, opts
    @_pid = @_channel.pid
    @_rpc_channel = new RpcStream @_channel
    await @ping defer rc
    cb rc
   
  ##-----------------------------------------
