
path      = require 'path'
constants = require './constants'

##=======================================================================

exports.Config = class Config

  #-----------------------------------------
  
  constructor : (f, @_argv_opts) ->
    @_file_name = f
    accessors = (k for k,v of constants)
    @_json = {}
    for a in accessors
      @[a] = () => @lookup a
    for k in [ "helpers" ]
      @[k] = ( -> @_json[k] )

  #-----------------------------------------

  in_place : () -> !!@_argv_opts.in_place 

  #-----------------------------------------

  json :     ()  -> @_json
  set_json : (j) -> @_json = j
   
  #-----------------------------------------

  export_to_rpc : () ->
    file : @_file_name
    obj : @_json
    argv_opts : @_argv_opts 
   
  #-----------------------------------------
  
  import_from_rpc : (o) ->
    @_file_name = o.file
    @_json = o.obj
    @_argv_opts = o.argv_opts 
   
  #-----------------------------------------
  
  open : ->
    f = @_file_name
    raw = require @_file_name
    for k, v in raw when typeof v isnt 'function'
      @_json[k] = v
    if generated = raw.generator? @
      for k, v in generated
        @_json[k] = v
    true
  
  #-----------------------------------------
  
  check : -> true

  #-----------------------------------------
  
  lookup : (k) -> if @_json[k]? then @_json[k] else constants[k]
  
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

##=======================================================================
