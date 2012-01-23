
path      = require 'path'
constants = require './constants'

##=======================================================================

exports.Config = class Config

  #-----------------------------------------
  
  constructor : (f) ->
    @_file_name = f
    accessors = (k for k,v of constants)
    @_json = {}
    for a in accessors
      @[a] = () => @lookup a

  #-----------------------------------------
  
  open : (cb) ->
    f = @_file_name
    await fs.readFile f, "utf-8", defer err, raw
    rc = 0
    if err
      rc = -2
      console.error "Reading file #{f}: #{err}"
    else
      try
        @_json = JSON.parse raw
      catch e
        console.error "In file #{f} JSON parse error: #{e}"
        rc = -3
    cb rc

  #-----------------------------------------
  
  check : -> 0

  #-----------------------------------------
  
  lookup : (k) -> if @_json[k]? then @_json[k] else config[k]

##=======================================================================
