
###
#
# ipc_rpc.coffee
#
#    This is a simple RPC system used in communication between parents
#    and children over local IPC communication.  Supports FD passing
#    since it's a wrapper around the node.js classes
#
###

log            = require './log'
{EventEmitter} = require 'events'
{sc}           = require './status_codes'

##=======================================================================

class Reply
  constructor : (@_stream, @_xid) ->

  reply : (msg, fh) ->
    @_stream._make_reply @_xid, sc.OK, msg, fh

  reject : (code) ->
    @_stream._make_reply @_xid, code, null, null

##=======================================================================

#
# stolen from node/lib/child_process.js, and slightly modified...
# 
exports.setupChannel = (target, channel) ->
  jsonBuffer = ''
  target._channel = channel
  
  channel.onread = (pool, offset, length, recvHandle) ->
    if pool
      jsonBuffer += pool.toString('ascii', offset, offset + length)
      i = start = 0
      while ((i = jsonBuffer.indexOf('\n', start)) >= 0) 
        json = jsonBuffer.slice start, i
        message = JSON.parse json
        target.emit 'message', message, recvHandle
        start = i + 1
      jsonBuffer = jsonBuffer.slice start
    else
      channel.close()
      target._channel = null

  target.send = (message, sendHandle) ->
    
    if typeof message is 'undefined'
      throw new TypeError 'message cannot be undefined'
    if !target._channel
      throw new Error "channel closed"
    # For overflow protection don't write if channel queue is too deep.
    if channel.writeQueueSize > 1024 * 1024
      return false

    buffer = Buffer(JSON.stringify(message) + '\n');
    writeReq = channel.write(buffer, 0, buffer.length, sendHandle);
    if !writeReq
      throw errnoException(errno, 'write', 'cannot write to IPC channel.');
    writeReq.oncomplete = () ->
    return true

  channel.readStart()
    

##=======================================================================

exports.Stream = class Stream extends EventEmitter

  ##------------------------------
  
  constructor : (h, @_name) ->
    super()
    @_handle = h
    @_eof_flag = false
    @_tab = {}
    @_xid = 1
    @_start()

  ##------------------------------
  
  _start: ->
    @_handle.on 'exit',    (code)   => @_handle_exit code
    @_handle.on 'message', (msg, h) => @_handle_message msg, h
  
  ##------------------------------
  
  _format_msg : (msg) ->
    "ipc_rpc.Stream error on stream @{_name}: #{msg}"

  ##------------------------------
  
  _handle_exit : (code) ->
    @_hit_eof()
    @emit 'exit', code
    
  ##------------------------------
  
  _error : (msg) ->
    log.error _format_msg msg

  ##------------------------------
  
  _new_xid : () ->
    r = @_xid
    @_xid++
    @_xid = 1 if @_xid > 0xfffffff0
    r

  ##------------------------------
  
  _handle_call : (m, h) ->
    @emit 'call', m.name, m.arg, h, new Reply @, m.xid

  ##------------------------------
  
  _make_reply : (x, rc, m, h) ->
    obj =
      xid : x
      res : m
      rc : rc
      dir : 1
    @_handle.send obj, h

  ##------------------------------

  _error : (m) ->
    log.error "Error in IPC RPC: #{m}"
  
  ##------------------------------
  
  _handle_reply : (m, h) ->
    x = m.xid
    if not (w = @_tab[x])
      @_error "Unknown XID=#{x} on reply"
    else
      delete @_tab[x]
      w sc.OK, m.res, h

  ##------------------------------
  
  _kill_receivers : ->
    tab = @_tab
    @_tab = {}
    for k,cb of tab
      cb sc.RPC_PROGUNAVAIL, null, null

  ##------------------------------
  
  _hit_eof : () ->
    @_handle = null
    @_eof_flag = true
    @_kill_receivers()
  
  ##------------------------------
  
  _handle_message : (m, h) ->
    if m == null
      @_hit_eof()
    else if not m.xid?
      @_error "No XID found in RPC message"
    else if m.name and m.dir is 0
      @_handle_call m, h
    else if m.dir is 1
      @_handle_reply m, h
    else
      @_error "Incoming message was neither a call nor reply"

  ##-----------------------------------------------------------------------
  # the public interface:
  
  call : (name, arg, h, cb) ->
    x = @_new_xid()
    obj =
      xid : x
      name : name
      arg : arg
      dir : 0
    cb = ( (m,h) -> ) unless cb
    @_tab[x] = cb
    x = @_handle.send obj, h

  ##-----------------------------------------------------------------------
