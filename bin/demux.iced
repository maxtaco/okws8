
{ServiceBase} = require '../lib/service_base'


##=======================================================================
 
class Demux extends ServiceBase
  
  constructor : (argv) ->
    super argv

##=======================================================================
  
d = new Demux process.argv
d.run()
