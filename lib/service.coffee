
cp     = require 'child_process'
log    = require './log'
{List} = require './list'

#=======================================================================

class Service
  
  ##-----------------------------------------

  constructor : (parent, d) ->
    @_parent = parent
    @_name = d.name
    @_config = d
    @_receive_cbs = List

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

  exit_cb : (code) ->
    @_channel = null
    # all remaining receivers need to know they are out of luck!
    @_receive_cbs.walk (o) -> o(null, null)
    log.error "#{@_name} died with code=#{code}"
    @relaunch()
   
  ##-----------------------------------------

  relaunch : () ->
    unless @_parent.shutdown()
      await setTimeout defer(), @_parent.config().restartDelay()
    unless @_parent.shutdown()
      launch()
   
  ##-----------------------------------------

  ##-----------------------------------------

  receive : (cb) ->
    await
      receive_cb = defer msg, fd
      rch = @_receivers.push receive_cb
      @_channel.once 'message', receive_cb
    @_receivers.remove rch
    cb msg, fd
   
  ##-----------------------------------------

  ping : (cb) ->
    @_channel.send { ping : true }
    await @receive defer msg, fd
    cb(msg?.pong)

  ##-----------------------------------------
  
  launch : (rc) ->
    cl = @makeCmdLine()
    log.info "#{@_name}: launching: #{cl.join ' '}"
    opts =
      cwd : @_config.rundir
      env : process.env
      setsid : false
    @_channel = cp.fork cl.shift(), cl, opts
    @_channel.on 'exit', (code) => @exit_cb code
    await @ping defer rc
    cb rc
   
  ##-----------------------------------------
