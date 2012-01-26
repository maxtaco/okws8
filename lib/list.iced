
exports.List = class List

  constructor: ->
    @_head = null
    @_tail = null

  push : (o) ->
    w =
      _obj : o
      _prev : @_tail
      _next : null
    @_tail._next = w if @_tail
    @_tail = w
    @_head = w unless @_head
    w

  walk : (fn, wrappers = false) ->
    p = @_head
    while p
      next = p._next
      fn(if wrappers then p else p._obj )
      p = next

  remove : (w) ->
    next = w._next
    prev = w._prev
    
    if prev then prev._next = next
    else         @_head = next
    
    if next then next._prev = prev
    else         @_tail = prev

    w._next = null
    w._prev = null
    
      
      
