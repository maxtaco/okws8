
{ServiceBase} = require '../lib/service_base'

log = require '../lib/log'

##=======================================================================
 
class Demux extends ServiceBase
  
  constructor : (argv) ->
    super argv

  launch : (cb) ->
    await @base_launch defer ok
    cb ok

  run : () ->

##=======================================================================
  
d = new Demux process.argv
await d.launch defer ok
if ok then d.run()
else process.exit -2
