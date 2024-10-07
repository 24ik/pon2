## This module implements the web worker.
##
## Compile Options:
## | Option                         | Description                  | Default         |
## | ------------------------------ | ---------------------------- | --------------- |
## | `-d:pon2.workerfilename=<str>` | File name of the web worker. | `worker.min.js` |
##
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

{.experimental: "inferGenericTypes".}
{.experimental: "notnil".}
{.experimental: "strictCaseObjects".}
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
    seq[string] -> tuple[returnCode: WorkerReturnCode, messages: seq[string]]
    ## Task executed in a new thread.

  WorkerCompleteHandler* = (returnCode: WorkerReturnCode, messages: seq[string]) -> void
    ## Handler executed after the `WorkerTask` completed.

  Worker* = ref object ## Web worker.
    running*: bool
    webWorker: JsObject

const
  WorkerFileName {.define: "pon2.workerfilename".} = "worker.min.js"

  DefaultWorkerTask*: WorkerTask = (args: seq[string]) => (Success, newSeq[string](0))
  DefaultWorkerCompleteHandler*: WorkerCompleteHandler =
    (returnCode: WorkerReturnCode, messages: seq[string]) => (discard)

  HeaderSep = "|-<pon2-webworker-header-sep>-|"
  MessageSep = "|-<pon2-webworker-sep>-|"

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
    let (returnCode, messages) = task(($event.data.to cstring).split2 MessageSep)
    getSelf().postMessage cstring &"{returnCode}{HeaderSep}{messages.join MessageSep}"

  getSelf().onmessage = runTask

proc run*(self: Worker, args: varargs[string]) {.inline.} =
  ## Runs the task and sends the message to the caller of the worker.
  self.running = true
  self.webWorker.postMessage cstring args.join MessageSep

# ------------------------------------------------
# Constructor
# ------------------------------------------------

proc newWebWorker(): JsObject {.importjs: &"new Worker('{WorkerFileName}')".}
  ## Returns the web worker launched by the caller.

proc `completeHandler=`*(self: Worker, handler: WorkerCompleteHandler) {.inline.} =
  proc runHandler(event: JsObject) =
    self.running = false

    let messages = ($event.data.to cstring).split HeaderSep
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

  self.webWorker.onmessage = runHandler

proc newWorker*(): Worker {.inline.} =
  ## Returns the worker.
  result = Worker(running: false, webWorker: newWebWorker())
  result.completeHandler = DefaultWorkerCompleteHandler
