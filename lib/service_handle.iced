cp        = require 'child_process'
log       = require './log'
RpcStream = require('./ipc_rpc').Stream
{sc}      = require './status_codes'
fs        = require 'fs'
constants = require './constants'

#=======================================================================

exports.ServiceHandle = class ServiceHandle
  
  ##-----------------------------------------

  constructor : (parent, d, @_name) ->
    @_parent = parent
    @_config = d
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
        if not v 
          continue
      else
        value = v

      out.push opt
      out.push value if value
      
    out

  ##-----------------------------------------

  prefix : -> "#{@_name}[#{@_pid}]"
   
  ##-----------------------------------------

  problem : (m) -> log.error "#{@prefix()} #{m}" 
  
  ##-----------------------------------------

  exit_cb : (code) ->
    @_channel = null
    # all remaining receivers need to know they are out of luck!
    @problem "died with code=#{code}"
    @relaunch()
   
  ##-----------------------------------------

  relaunch : () ->
    if @_parent.run_state() is constants.run_states.RUN
      d = @_parent.config().restart_delay()
      await setTimeout defer(), d
    if @_parent.run_state() is constants.run_states.RUN
      @launch()
   
  ##-----------------------------------------

  ping : (cb) ->
    await @_rpc_channel.call "ping", null, null, defer code, res
    ok = if code isnt sc.OK
      @problem "ping returned with code=#{code}"
      false
    else if res isnt @_pid
      @problem "ping returned with wronge pid (#{res} v #{@_pid})"
      false
    else true
    cb ok

  ##-----------------------------------------
  
  launch : (cb) ->
    cl = @makeCmdLine()
    rd = @_config.rundir
    log.info "#{@_name}: launching: #{cl.join ' '} (rundir: #{rd})"
    await fs.stat rd, defer err, stats
    if err
      log.error "In sanity check of run dir '#{rd}': #{err}"
    else if not stats
      log.error "Cannot find directory #{rd}"
    else if not stats.isDirectory()
      log.error "Run dir #{rd} is not a directory"
    else
      opts =
        cwd : @_config.rundir
        env : process.env
        setsid : false
      @_channel = cp.fork cl.shift(), cl, opts
      @_channel.on 'call', (args...) => @handle_child_call args
      @_channel.on 'exit', (code) => @exit_cb code
      @_pid = @_channel.pid
      @_rpc_channel = new RpcStream @_channel, @prefix()
      await @ping defer ok
    cb ok
   
  ##-----------------------------------------

  handle_fetch_config : (arg, h, reply) ->
    reply.reply @_parent.config.export_to_rpc(), null
   
  ##-----------------------------------------

  handle_child_call : (name, args...) ->
    switch name
      when "fetch_config"
        @handle_fetch_config args
      else
        reply.reject sc.RPC_MSG_PROC_UNAVAIL
         
  ##-----------------------------------------
   
#=======================================================================

exports.DemuxHandle = class DemuxHandle extends ServiceHandle

  ##-----------------------------------------
   
  constructor : (parent, d) ->
    super parent, d, "demux"
  
  ##-----------------------------------------
   
#=======================================================================
