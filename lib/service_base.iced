
RpcStream      = require('./ipc_rpc').Stream
{sc}           = require './status_codes'
log            = require './log'
path           = require 'path'
{Config}       = require '../lib/config'
net            = require 'net'
{iced}         = require 'iced-coffee-script'

##=======================================================================

exports.ServiceBase = class ServiceBase

  constructor : (@_argv) ->
    log.set_proc @_argv[1]
    
    # See node/fixtures/child-process-spawn-node.js;
    #   we treat the process object as an event emitter,
    #   and can call process.on on it...
    @_parent_proc = new RpcStream process, @prefix()
    @_start()

  prefix : -> "#{process.title}[process.pid]"

  ##-----------------------------------------

  _start : ->
    @_parent_proc.on 'call', (args...) => @handle_parent_call args

  ##-----------------------------------------

  handle_parent_call : (name, arg, h, reply) ->
    switch name
      when "ping"
        @handle_ping arg, h, reply
      when "get_socket"
        @handle_get_socket arg, h, reply
      else
        reply.reject sc.RPC_MSG_PROC_UNAVAIL

  ##-----------------------------------------

  handle_ping : (arg, h, reply) ->
    reply.reply @_pid, null

  ##-----------------------------------------

  fetch_config : (cb) ->
    await @_parent_proc.call "fetch_config", null, null, defer err, res
    ok = false
    if err
      log.error "fetching config from parent: #{err}"
    else if not res.file? or not res.obj?
      log.error "incomplete results passed back"
    else
      @_global_config = new Config 
      @_global_config.import_from_rpc res
      @_my_config = @_global_config.me_as_helper()
      ok = !! @_my_config
    cb ok

  ##-----------------------------------------

  do_ping : (cb) -> 
    await @_parent_proc.call "ping", process.pid, null, defer code, res
    ok = if code isnt sc.OK
      log.error "ping returned with code=#{code}"
      false
    else if not res
      log.error "ping failed upstream"
      false
    else true
    cb ok

  ##-----------------------------------------

  do_cwd : (cb) ->
    rd = @_my_config.rundir
    try
      prev = process.cwd()
      process.chdir rd
      after = process.cwd()
      log.info "chdir from '#{prev}' to '#{after}'"
      ok = true
    catch err
      log.error "failed to chdir to #{rd}: #{err}"
      ok = false
    cb ok

  ##-----------------------------------------

  handle_socket_err : (e) ->
    log.error "Error on my socket '#{@_my_sock}' : #{e}"
    process.exit -2
   
  ##-----------------------------------------

  handle_new_connection : (s) ->
    log.warn "New connection, but nothing to do!"
    s.end()
   
  ##-----------------------------------------

  open_listen_socket : (cb) ->
    sock = @_my_sock = @_my_config.listen
    ok = true
    if sock
      log.info "listening on socket: #{sock}"
      @_server = new net.Server()
      @_server.listen sock
      rv = new iced.Rendezvous()
      @_server.on "listening", rv.id(true).defer()
      @_server.on "err",       rv.id(false).defer(err)
      await rv.wait defer ok
      if not ok
        log.error "Error opening socket #{sock}: #{err}"
      else
        @_server.on "err", ((e) => @handle_socket_err e)
        @_server.on "connection", ((s) => @handle_new_connection s)
        log.info "listening successfully on socket"
    cb ok
    
   
  ##-----------------------------------------

  base_launch : (cb) ->
    log.info "starting up"
    await @do_ping defer ok
    await @fetch_config defer ok         if ok
    await @open_listen_socket defer ok   if ok
    await @do_cwd defer ok               if ok
    if ok then log.info "launch succeded"
    else       log.error "launch failed; bailing out"
    cb ok

  ##-----------------------------------------
