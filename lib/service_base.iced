
RpcStream      = require('./ipc_rpc').Stream
{sc}           = require './status_codes'
log            = require './log'
path           = require 'path'
{Config}       = require '../lib/config'

##=======================================================================

exports.ServiceBase = class ServiceBase

  constructor : (@_argv) ->
    log.set_proc @_argv[1]
    
    # See node/fixtures/child-process-spawn-node.js;
    #   we treat the process object as an event emitter,
    #   and can call process.on on it...
    @_parent_proc = new RpcStream process, @prefix()
    @_start()
    @_ping_waiter = null

  prefix : -> "#{process.title}[process.pid]"

  _start : ->
    @_parent_proc.on 'call', (args...) => @handle_parent_call args

  handle_parent_call : (name, arg, h, reply) ->
    switch name
      when "ping"
        @handle_ping arg, h, reply
      else
        reply.reject sc.RPC_MSG_PROC_UNAVAIL

  handle_ping : (arg, h, reply) ->
    reply.reply @_pid, null
    if @_ping_waiter
      e = @_ping_waiter
      @_ping_waiter = null
      e()

  fetch_config : (cb) ->
    await @_parent_proc.call "fetch_config", null, null, defer err, res
    ok = false
    if err
      log.error "fetching config from parent: #{err}"
    else if not res.file? or not res.obj?
      log.error "incomplete results passed back"
    else
      @_config = new Config 
      @_config.import_from_rpc res
      ok = true
    cb ok

  launch : (cb) ->
    await @_parent_proc.call "ping", process.pid, null, defer code, res
    ok = if code isnt sc.OK
      log.error "ping returned with code=#{code}"
      false
    else if not res
      log.error "ping failed upstream"
      false
    else true
    await @fetch_config defer ok if ok
    cb ok

  run : () ->
    log.info "starting up"
    await @launch defer()
    log.info "Output Config: #{JSON.stringify @_config.export_to_rpc()}"
