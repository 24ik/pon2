## This module implements common stuff.
##

import jsffi

# ------------------------------------------------
# Worker
# ------------------------------------------------

type
  WorkerTask* {.pure.} = enum
    ## Kind of the worker task.
    SOLVE = "solve"

  WorkerResult* {.pure.} = enum
    ## Worker task result.
    SUCCESS = "success"
    FAILURE = "failure"

const
  WorkerMessageHeaderSeparator* = "|--|"
  WorkerMessageSeparator* = "|-|"

proc runWorker*: JsObject {.importjs: "new Worker('worker.js')".} ## Returns the worker.
