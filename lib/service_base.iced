
RpcStream      = require('./ipc_rpc').Stream
{sc}           = require './status_codes'

##=======================================================================

exports ServiceBase = class ServiceBase

  constructor : (@_argv) ->
    @_pid = process.pid
    @_parent_proc = new RpcStream new RpcStream process, @prefix()
    @_start()
    @_ping_waiter = null

  prefix : -> #{@_argv[1]}[#{@_pid}]"

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
    await @_ping_waiter = defer()
    await @fetch_config defer()

  run : () ->
    await launch defer()
    log.info "Output Config: #{JSON.stingify @_config.export_to_rpc()}"
