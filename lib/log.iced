path = require 'path'

##=======================================================================
 
LEVELS =
  NONE     : [ 0, ""  ]
  INFO     : [ 1, "i " ]
  WARN     : [ 2, "w " ]
  ERROR    : [ 3, "XX " ]
  CRITICAL : [ 4, "PANIC " ]
  DEBUG    : [ 5, "d " ]
  PLAIN    : [-1, '' ]
  
##=======================================================================
 
class Logger
  
  constructor: ->
    @_proc = process.title
    @_pid = process.pid
    @_level_string = {}
    for k,v of LEVELS
      @[k] = v[0]
      @_level_string[v[0]] = v[1]
    @_show_pid = true
    @LEVELS = LEVELS
    
  set_proc : (p) -> @_proc = p
  show_pid : (b) -> @_show_pid = b

  prefix : (level) ->
   "#{@_proc}#{if @_show_pid then '[' + @_pid + ']' else ''} #{@_level_string[level]}"

  line : (level, s) ->
    console.log "#{if level is @PLAIN then '' else @prefix level}#{s}"
    
  log: (level, s) ->
    lines = s.toString().split '\n'
    for l in lines
      @line level, l

##=======================================================================

exports.Logger = Logger

if not logger?
  exports.logger = logger = new Logger()

exports.set_proc = (n) ->
  logger.set_proc path.basename n, '.coffee'

###
Set up functions for log.info "blah" and log.critical "poop" etc
###
for k,v of logger.LEVELS
  exports[k.toLowerCase()] = ((level) -> (s) -> logger.log level, s)(v[0])

  
