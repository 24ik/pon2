## This module implements the web worker.
## Outline of the processing flow:
##
## 1. The main file launches the web worker by `initWorker()`.
## 1. The main file assigns the handler that executed after the task is done.
## 1. The main file makes the worker do the task. The task is implemented in the
## worker file by `assignToWorker()`.
## 1. The handler is executed.
##
## The following example shows the number-increment task.
##

runnableExamples:
  # Main File
  proc show(returnCode: WorkerReturnCode, messages: seq[string]) =
    echo "returnCode: ", returnCode, " messages: ", messages

  let worker = initWorker
  worker.completeHandler = show
  worker.run 6

runnableExamples:
  # Worker File
  # The name of the output file should be `worker.min.js`.
  # To change this, specify the compile option
  # `-d:pon2.workerfilename=<fileName>`.
  import std/[strutils]
  import ./pon2/private/[webworker] # change path if needed

  proc succ2(
      args: seq[string]
  ): tuple[returnCode: WorkerReturnCode, messages: seq[string]] =
    if args.len != 1:
      return (Failure, @["Invalid number of arguments are given."])
    try:
      return (Success, @[$args[0].parseInt.succ])
    except ValueError:
      return (Failure, @["Could not parse as an integer: " & args[0]])

  when isMainModule:
    assignToWorker(myInc)

{.experimental: "strictDefs".}
{.experimental: "strictFuncs".}
{.experimental: "views".}

import std/[jsffi, strformat, strutils, sugar]

type
  WorkerReturnCode* {.pure.} = enum
    ## Return code of the worker task.
    Success = "success"
    Failure = "failure"

  WorkerTask* =
    (seq[string] -> tuple[returnCode: WorkerReturnCode, messages: seq[string]])
    ## Task executed in a new thread.

  WorkerCompleteHandler* =
    ((returnCode: WorkerReturnCode, messages: seq[string]) -> void)
    ## Handler executed after the `WorkerTask` completed.

  Worker* = object ## Web worker.
    running*: bool
    webWorker: JsObject

const
  WorkerFileName {.define: "pon2.workerfilename".} = "worker.min.js"

  DefaultWorkerTask*: WorkerTask = (args: seq[string]) => (Success, newSeq[string](0))
  DefaultWorkerCompleteHandler*: WorkerCompleteHandler =
    (returnCode: WorkerReturnCode, messages: seq[string]) => (discard)

  HeaderSep = "|-<pon2-webworker-header-sep>-|"
  MessageSep = "|-<pon2-webworker-sep>-|"

using
  self: Worker
  mSelf: var Worker

# ------------------------------------------------
# Task
# ------------------------------------------------

proc getSelf(): JsObject {.importjs: "(self)".} ## Returns the web worker object.

func split2(str: string, sep: string): seq[string] {.inline.} =
  ## Splits `str` by `sep`.
  ## If `str == ""`, returns `@[]`
  ## (unlike `strutils.split`; it returns `@[""]`).
  if str == "":
    @[]
  else:
    str.split sep

proc assignToWorker*(task: WorkerTask) {.inline.} =
  ## Assigns the task to the worker.
  proc runTask(event: JsObject) =
    let (returnCode, messages) = task(($event.data.to(cstring)).split2 MessageSep)
    getSelf().postMessage(cstring &"{returnCode}{HeaderSep}{messages.join MessageSep}")

  getSelf().onmessage = runTask

proc run*(mSelf; args: varargs[string]) {.inline.} =
  ## Runs the task and sends the message to the caller of the worker.
  mSelf.running = true
  mSelf.webWorker.postMessage cstring args.join MessageSep

# ------------------------------------------------
# Constructor
# ------------------------------------------------

proc initWebWorker(): JsObject {.importjs: &"new Worker('{WorkerFileName}')".}
  ## Returns the web worker launched by the caller.

proc `completeHandler=`*(mSelf; handler: WorkerCompleteHandler) {.inline.} =
  proc runHandler(event: JsObject) =
    mSelf.running = false

    let messages = ($event.data.to(cstring)).split HeaderSep
    if messages.len != 2:
      echo "Invalid arguments are passed to the complete handler: ", $messages
      return

    case messages[0]
    of $Success:
      handler(Success, messages[1].split2 MessageSep)
    of $Failure:
      echo "The task failed; error message: ", messages[1]
    else:
      echo "Invalid return code is passed to the complete handler: ", messages[0]

  mSelf.webWorker.onmessage = runHandler

proc initWorker*(): Worker {.inline.} =
  ## Returns the worker.
  result.running = false
  result.webWorker = initWebWorker()
  result.completeHandler = DefaultWorkerCompleteHandler
