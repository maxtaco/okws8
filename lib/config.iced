
path      = require 'path'
constants = require './constants'
log       = require './log'
fs        = require 'fs'

##=======================================================================

exports.Config = class Config

  #-----------------------------------------
  
  constructor : (f, @_argv_opts) ->
    @_file_name = f
    accessors = (k for k,v of constants)
    @_json = {}
    for a in accessors
      @[a] = ((self, v) -> () => self.lookup v)(@, a)
    for k in [ "helpers" ]
      @[k] = ( -> @_json[k] )

  #-----------------------------------------

  in_place : () -> !!@_argv_opts.in_place 

  #-----------------------------------------

  json :     ()  -> @_json
  set_json : (j) -> @_json = j
   
  #-----------------------------------------

  export_to_rpc : (helper) ->
    file : @_file_name
    obj : @_json
    argv_opts : @_argv_opts
    helper_name : helper
   
  #-----------------------------------------

  me_as_helper : () ->
    @helpers()[@_helper_name]
   
  #-----------------------------------------
  
  import_from_rpc : (o) ->
    @_file_name = o.file
    @_json = o.obj
    @_argv_opts = o.argv_opts
    @_helper_name = o.helper_name
   
  #-----------------------------------------

  resolve_config_file : (cb) ->
    name_in = @_file_name
    await fs.realpath name_in, defer err, name_out
    if err
      log.error "Cannot resolve file #{name_in}: #{err}"
    else
      log.info "Resolving #{name_in} -> #{name_out}"
      @_file_name = name_out
    cb name_out
   
  #-----------------------------------------
  
  open : (cb) ->
    await @resolve_config_file defer f
    ok = false
    if f
      try
        raw = require f
        for k, v of raw when typeof v isnt 'function'
          @_json[k] = v
        if generated = raw.generator? @
          for k, v of generated
            @_json[k] = v
        ok = true
      catch e
        log.error "In requiring config file #{f}:"
        console.log e.stack
        ok = false
    else
      log.error "Cannot find config file #{f}"
      ok = false
    cb ok
  
  #-----------------------------------------
  
  check : -> true

  #-----------------------------------------
  
  lookup : (k) ->
    if @_json[k]? then @_json[k] else constants[k]
  
  #========================================

  config_path : (d, f) ->
    if f then path.join d,f
    else d
   
  #-----------------------------------------

  top_data_dir : (f) ->
    d = if @in_place() then "."
    else if t = @_argv_opts.top_data_dir? then t
    else if t = @_argv_opts.top_dir?      then t
    else if t = @_json.top_data_dir?      then t
    else if t = @_json.top_dir?           then t
    else constants.top_dir
    @config_path d, f
    
  #-----------------------------------------
  
  top_src_dir : (f) ->
    d = if @in_place() then "."
    else if t = @_argv_opts.top_src_dir? then t
    else if t = @_argv_opts.top_dir?     then t
    else if t = @_json.top_src_dir?      then t
    else if t = @_json.top_dir?          then t
    else constants.top_dir
    @config_path d, f

  #-----------------------------------------
  
  bin_dir    : (f) -> @config_path (@top_data_dir "bin"), f
  
  #-----------------------------------------
  
  secondary_dir : (d, f) -> @config_path (@top_src_dir d), f
  socket_dir : (f) -> @secondary_dir "run", f
  empty_jail : ()  -> @socket_dir    "empty"
  docs_dir   : (f) -> @secondary_dir "www", f
  log_dir    : (f) -> @secondary_dir "log", f

##=======================================================================
