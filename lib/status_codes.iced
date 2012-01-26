

CONSTANTS = 
  OK : [ 0 ]
  
  PC_CANTENCODEARGS   : [ 301,	"can't encode arguments" ]
  PC_CANTDECODERES    : [ 302, "can't decode results" ]
  RPC_CANTSEND         : [ 303, "failure in sending call" ]
  PC_CANTRECV         : [ 304, "failure in receiving result" ]
  PC_TIMEDOUT         : [ 305, "call timed out" ]
  
  PC_VERSMISMATCH     : [ 306, "rpc versions not compatible" ]
  PC_AUTHERROR        : [ 307,	"authentication error" ]
  PC_PROGUNAVAIL      : [ 308, "program not available" ]
  PC_PROGVERSMISMATCH : [ 309, "program version mismatched" ]
  PC_PROCUNAVAIL      : [ 310, "procedure unavailable" ]
  PC_CANTDECODEARGS   : [ 311,	"decode arguments error" ]
  PC_SYSTEMERROR      : [ 312, "generic 'other problem'" ]
  PC_NOBROADCAST      : [ 321,	"Broadcasting not supported" ]
  
  RPC_UNKNOWNHOST      : [ 313, "unknown host name" ]
  RPC_UNKNOWNPROTO     : [ 317, "unknown protocol" ]
  RPC_UNKNOWNADDR      : [ 319, "Remote address unknown" ]

  RPC_RPCBFAILURE      : [ 314,	"portmapper failed in its call" ]
  RPC_PROGNOTREGISTERED : [ 315,	"remote program is not registered" ]
  RPC_N2AXLATEFAILURE  : [ 322,	"Name to addr translation failed" ]

  RPC_MSG_PROG_UNAVAIL : [ 401, "accept_stat: program unavailable" ]
  RPC_MSG_PROG_MISMATCH: [ 402, "accept_stat: program mismatch" ]
  RPC_MSG_PROC_UNAVAIL : [ 403, "accept_stat: procedure unavailable" ]
  RPC_MSG_GARBAGE_ARGS : [ 404, "accept_stat: garbage args" ]
  RPC_MSG_SYSTEM_ERR   : [ 405, "accept_stat: system error" ]
  RPC_MSG_RPC_MISMATCH : [ 406, "reject_stat: RPC mismatch" ]
  RPC_MSG_AUTH_ERROR   : [ 407, "reject_stat: authentication error" ]
  RPC_MSG_MSG_ACCEPTED : [ 408, "reply_stat: msg accepted" ]
  RPC_MSG_MSG_DENIED   : [ 409, "reply_stat: msg denied" ]

##=======================================================================
 
exports.StatusCodes = class StatusCodes

  constructor : ->
    @index = {}
    @desc = {}
    for k,v of CONSTANTS
      @[k] = v[0]
      @desc[k] = v[1]
      @index[v[0]] = [k, v[1]]

  lookup : (n) ->
    if typeof n is 'string' then (@[n] || -1)
    else (@index[n] || null)


##=======================================================================

statusCodes = new StatusCodes() unless statusCodes?

exports.sc = statusCodes

