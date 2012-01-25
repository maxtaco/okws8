
###
# 
# Dump in code from options.js, cloned from here:
#
# //
# // Node.js should really standardize option parsing, so as not to 
# // introduce dependencies.
#
#  /** Command-line options parser (http://valeriu.palos.ro/1026/).
#    Copyright 2011 Valeriu Paloş (valeriu@palos.ro). All rights reserved.
#    Released as Public Domain.
#
#    Expects the "schema" array with options definitions and produces the
#    "options" object and the "args" array, which will contain all
#    non-option arguments encountered (including the script name and such).
#
#    Syntax:
#        [«short», «long», «attributes», «brief», «callback»]
#
#    Attributes:
#        ! - option is mandatory;
#        : - option expects a parameter;
#        + - option may be specified multiple times (repeatable).
#
#    Notes:
#        - Parser is case-sensitive.
#        - The '-h|--help' option is provided implicitly.
#        - Parsed options are placed as fields in the "options" object.
#        - Non-option arguments are placed in the "arguments" array.
#        - Options and their parameters must be separated by space.
#        - Either one of «short» or «long» must always be provided.
#        - The «callback» function is optional.
#        - Cumulated short options are supported (i.e. '-tv').
#        - If an error occurs, the process is halted and the help is shown.
#        - Repeatable options will be cumulated into arrays.
#        - The parser does *not* test for duplicate option definitions.
#
# =======================================================================
#
# Usage:
#
#  schema = [ .. ]
#  synopsis = "usage: <prog>..."
#  desc = "a long description..."
#
#  op = new OptParser schema, synoposis, desc
#  obj = op.parse process.argv
#  if obj.ok
#     # obj.args
#     # obj.opts
#  else
#    console.error obj.msg.join '\n'
#    process.exit obj.rc
# 
###

##=======================================================================

exports.Getopt = class Getopt

  constructor: (@_schema, @_synopsis, @_desc) ->
    @_out_args = []
    @_out_options = {}
    @_in_option_map = {}
    @_in_option_list = []
    @_rc = 0
    @_msg = ""
    @makeOptions()

  ##-----------------------------------------

  optClean : (s) ->
    if s then s.replace '-', '_'
    else null
   
  ##-----------------------------------------

  makeOptions : () ->
    toSet = (s) ->
      obj = {}
      for c in s.split ''
        obj[c] = true
      obj
    
    for row in @_schema
      obj = 
        short : row[0]
        long : row[1],
        opts : toSet row[2]
        desc : row[3]
        func : row[4]
        found : false
      @_in_option_map[obj.short] = obj if obj.short
      @_in_option_map[obj.long] = obj if obj.long
      @_in_option_list.push obj

  ##-----------------------------------------

  rc : () -> @_rc
  ok : () -> @_rc is 0
  msg : () -> @_msg
  args : () -> @_out_args
  opts : () -> @_out_options
   
  ##-----------------------------------------
   
  makeTokens : (argv) ->
    tokens = []
    for item in argv
      if not (item.charAt(0) is '-')
        tokens.push item
      else if not (item.charAt(1) is '-')
        tokens = tokens.concat item.split('').join('-').split('').slice(1)
      else
        tokens.push '--', item.slice(2)
    tokens

  ##-----------------------------------------
   
  handleOption : (prfx, tokens) ->
    opt = tokens.shift()
    if opt in [ "help", "?", "h" ]
      throw 'help'
    option = @_in_option_map[opt]
    throw "Unknown option #{prfx}#{opt} encountered!" unless option
    value = true
    if option.opts[":"] and not (value = tokens.shift())
      throw "Options #{prfx}#{opt} expected a parmeter"
    index = (@optClean option.long) || option.short
    if option.opts["+"]
      @_out_options[index] = [] unless @_out_options[index] instanceof Array
      @_out_options[index].push value
    else
      @_out_options[index] = value
    option.func(value) if typeof option.func is 'function'
    option.found = true
    
  ##-----------------------------------------
   
  traverseTokens : (tokens) ->
    while tokens.length
      first = tokens.shift()
      if first in ["-", "--"]
        @handleOption first, tokens
      else
        @_out_args.push first

  ##-----------------------------------------

  enforceMandatories : () ->
    for o in @_in_option_list
      if o.opts['!'] and not o.found
        nm = if o.long then "--" + o.long else "-" + o.short
        throw "Option '#{nm}' is mandatory but was not given"
  
  ##-----------------------------------------

  usage_v : (prfx) ->
    msg = []
    msg.push prfx if prfx
    msg.push @_synopsis
    msg.push "Options:"
    for o in @_in_option_list
      names = []
      names.push "-#{o.short}" if o.short
      names.push "--#{o.long}" if o.long
      names = names.join "|"
      syntax = [ names ]
      syntax.push '«value»' if o.opts[':']
      l = (syntax.join ' ').length
      syntax.push (new Array 20 - l).join ' ' if l < 20
      syntax = syntax.join ' '
      flags =  [ if o.opts['!'] then '*' else ' ' ]
      flags.push (if o.opts['+'] then '+' else ' ')
      flags = flags.join ''
      opt = "\t#{flags}#{syntax}\t#{o.desc}"
      msg.push opt
    msg.push @_desc
    msg
     
  ##-----------------------------------------

  makeReturn : ->
    args : @args()
    opts : @opts()
    ok : @ok()
    rc : @rc()
    msg : @msg()
 
  ##-----------------------------------------
  
  parse : (argv) ->
    try
      tokens = @makeTokens argv
      @traverseTokens tokens
      @enforceMandatories()
    catch e
      if e is 'help'
        @_rc = 1
        e = null
      else @_rc = -1
      @_msg = @usage_v e
    @makeReturn()

##=======================================================================
