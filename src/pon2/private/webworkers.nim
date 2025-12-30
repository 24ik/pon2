## This module implements web workers.
##
## Compile Options:
## | Option                    | Description       | Default           |
## | ------------------------- | ----------------- | ----------------- |
## | `-d:pon2.webworker=<str>` | Web workers file. | `./worker.min.js` |
##

{.push raises: [].}
{.experimental: "strictDefs".}
{.experimental: "strictFuncs".}
{.experimental: "views".}

import std/[asyncjs, jsffi, sequtils, strformat, sugar]
import ./[assign, dom, strutils, utils as privateUtils]
import ../[utils]

when not defined(pon2.build.worker):
  import ./[math]

export utils

type
  WebWorkerTask* =
    ((args: seq[string]) {.raises: [], gcsafe.} -> Pon2Result[seq[string]])
    ## Task executed by web workers.

  WebWorker = object ## Web worker.
    workerObj: JsObject
    running: bool

  WebWorkerPool* = object ## Web worker pool.
    workerRefs: seq[ref WebWorker]
    isReadyRef: ref bool

const
  WebWorkerPath {.define: "pon2.webworker".} = "./worker.min.js"
  MsgSep = "<pon2-webworker-sep>"

# ------------------------------------------------
# Constructor
# ------------------------------------------------

const
  OkStr = "ok"
  ErrorStr = "error"

proc newWorkerObj(): JsObject {.
  inline, noinit, importjs: "new Worker('{WebWorkerPath}')".fmt
.}

proc init(T: type WebWorker): T {.inline, noinit.} =
  T(workerObj: newWorkerObj(), running: false)

proc init(T: type WebWorkerPool, workerCount = 1): T {.inline, noinit.} =
  let
    workerRefs = collect:
      for _ in 1 .. workerCount:
        let workerRef = new WebWorker
        workerRef[] = WebWorker.init
        workerRef
    isReadyRef = new bool
  isReadyRef[] = true

  T(workerRefs: workerRefs, isReadyRef: isReadyRef)

# ------------------------------------------------
# Caller
# ------------------------------------------------

const PoolPollingMs = 100

func parseResult(str: string): Pon2Result[seq[string]] {.inline, noinit.} =
  ## Returns the result of the web worker's task.
  let errorMsg = "Invalid result: {str}".fmt

  let strs = str.split2(MsgSep, 1)
  if strs.len != 2:
    return err errorMsg

  case strs[0]
  of OkStr:
    ok strs[1].split2 MsgSep
  of ErrorStr:
    err strs[1].split2(MsgSep).join "\n"
  else:
    err errorMsg

proc run(
    self: ref WebWorker, args: varargs[string]
): Future[Pon2Result[seq[string]]] {.inline, noinit.} =
  ## Runs the task.
  ## If the worker is running, returns an error.
  if self[].running:
    return newPromise (resolve: (response: Pon2Result[seq[string]]) -> void) =>
      Pon2Result[seq[string]].err("Worker is running").resolve

  self[].running.assign true

  let argsSeq = args.toSeq
  proc handler(resolve: (response: Pon2Result[seq[string]]) -> void) =
    self[].workerObj.onmessage =
      (ev: JsObject) => (
        block:
          ($ev.data.to cstring).parseResult.resolve
          self[].running.assign false
      )

    self[].workerObj.postMessage argsSeq.join(MsgSep).cstring

  handler.newPromise

proc run*(
    self: WebWorkerPool, args: varargs[string]
): Future[Pon2Result[seq[string]]] {.async.} =
  ## Runs the task.
  while not self.isReadyRef[]:
    await sleep PoolPollingMs

  var freeWorkerIndex = -1
  block waiting:
    while freeWorkerIndex < 0:
      if not self.isReadyRef[]:
        break waiting

      for workerIndex, workerRef in self.workerRefs:
        if not workerRef[].running:
          freeWorkerIndex.assign workerIndex
          break waiting

      await sleep PoolPollingMs

  if not self.isReadyRef[]:
    return Pon2Result[seq[string]].ok @[]

  return await self.workerRefs[freeWorkerIndex].run args

proc terminate*(self: WebWorkerPool) {.inline, noinit.} =
  ## Terminates the web worker pool.
  self.isReadyRef[] = false

  for workerRef in self.workerRefs:
    workerRef[].workerObj.terminate()

  # NOTE: ensure that all `run`s already called return empty sequences
  discard setTimeout(
    () => (
      block:
        for workerRef in self.workerRefs:
          workerRef[] = WebWorker.init

        self.isReadyRef[] = true
    ),
    PoolPollingMs * 3,
  )

# ------------------------------------------------
# Callee
# ------------------------------------------------

proc getSelf(): JsObject {.inline, noinit, importjs: "(self)".}
  ## Returns the web worker object.

func toStr(res: Pon2Result[seq[string]]): string {.inline, noinit.} =
  ## Returns the string representation of the task result.
  if res.isOk:
    "{OkStr}{MsgSep}{res.unsafeValue.join MsgSep}".fmt
  else:
    "{ErrorStr}{MsgSep}{res.error}".fmt

proc register*(task: WebWorkerTask) {.inline, noinit.} =
  ## Registers the task to the web worker.
  getSelf().onmessage =
    (event: JsObject) =>
    getSelf().postMessage ($event.data.to cstring).split2(MsgSep).task.toStr.cstring

when not defined(pon2.build.worker):
  let webWorkerPool* = WebWorkerPool.init getNavigator().hardwareConcurrency
  .to(int)
  .ceilDiv(2)
  .clamp(1, 16)
