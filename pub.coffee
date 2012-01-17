
exports.progs =

  # The publishing protocol, version v1
  "pub.1" :

    # generic checkers, which are augmented below
    arg :
      file : "s # the file to operate on"
    res:
      status : "i # integer status code"

    # The RPCs in this program
    procs :

      # Totally freeform
      null :
        res_override : {}
        arg_override : {}

      read :
        res :
          dat : "s? # file data if the call succeeded"
          
      stat :
        res :
          stat : "O? # the stat data returned from the syscall, if the call succeeded"

      write :
        arg :
          offset : "i # the file offset to write to"
          dat : "s # the data to write to the file"
