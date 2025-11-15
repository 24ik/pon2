## This module implements web workers.
##
## Compile Options:
## | Option                    | Description            | Default           |
## | ------------------------- | ---------------------- | ----------------- |
## | `-d:pon2.webworker=<str>` | Web workers directory. | `./worker.min.js` |
##

{.push raises: [].}
{.experimental: "strictDefs".}
{.experimental: "strictFuncs".}
{.experimental: "views".}

import std/[asyncjs, jsffi, sequtils, strformat, sugar]
import ./[assign, results2, strutils2, utils]

when not defined(pon2.build.worker):
  import ./[math2]

type
  WebWorkerTask* = ((args: seq[string]) {.raises: [], gcsafe.} -> Res[seq[string]])
    ## Task executed by web workers.

  WebWorker = object ## Web worker.
    workerObj: JsObject
    running: bool

  WebWorkerPool* = object ## Web worker pool.
    workerRefs: seq[ref WebWorker]

const
  WebWorkerPath {.define: "pon2.webworker".} = "./worker.min.js"
  MsgSep = "<pon2-webworker-sep>"

# ------------------------------------------------
# Constructor
# ------------------------------------------------

const
  OkStr = "ok"
  ErrStr = "err"

proc newWorkerObj(): JsObject {.
  inline, noinit, importjs: "new Worker('{WebWorkerPath}')".fmt
.}

proc init(T: type WebWorker): T {.inline, noinit.} =
  T(workerObj: newWorkerObj(), running: false)

proc init(T: type WebWorkerPool, workerCnt = 1): T {.inline, noinit.} =
  let workerRefs = collect:
    for _ in 1 .. workerCnt:
      let workerRef = new WebWorker
      workerRef[] = WebWorker.init
      workerRef

  T(workerRefs: workerRefs)

# ------------------------------------------------
# Caller
# ------------------------------------------------

const PoolPollingMs = 100

func parseRes(str: string): Res[seq[string]] {.inline, noinit.} =
  ## Returns the result of the web worker's task.
  let errMsg = "Invalid result: {str}".fmt

  let strs = str.split2(MsgSep, 1)
  if strs.len != 2:
    return err errMsg

  case strs[0]
  of OkStr:
    ok strs[1].split2 MsgSep
  of ErrStr:
    err strs[1].split2(MsgSep).join "\n"
  else:
    err errMsg

proc run(
    self: ref WebWorker, args: varargs[string]
): Future[Res[seq[string]]] {.inline, noinit.} =
  ## Runs the task.
  ## If the worker is running, returns an error.
  if self[].running:
    return newPromise (resolve: (response: Res[seq[string]]) -> void) =>
      Res[seq[string]].err("Worker is running").resolve

  self[].running.assign true

  let argsSeq = args.toSeq
  proc handler(resolve: (response: Res[seq[string]]) -> void) =
    self[].workerObj.onmessage =
      (ev: JsObject) => (
        block:
          ($ev.data.to cstring).parseRes.resolve
          self[].running.assign false
      )

    self[].workerObj.postMessage argsSeq.join(MsgSep).cstring

  handler.newPromise

proc run*(
    self: WebWorkerPool, args: varargs[string]
): Future[Res[seq[string]]] {.async.} =
  ## Runs the task.
  var freeWorkerIdx = -1
  block waiting:
    while freeWorkerIdx < 0:
      for workerIdx, workerRef in self.workerRefs:
        if not workerRef[].running:
          freeWorkerIdx.assign workerIdx
          break waiting

      await sleep PoolPollingMs

  return await self.workerRefs[freeWorkerIdx].run args

# ------------------------------------------------
# Callee
# ------------------------------------------------

proc getSelf(): JsObject {.inline, noinit, importjs: "(self)".}
  ## Returns the web worker object.

func toStr(res: Res[seq[string]]): string {.inline, noinit.} =
  ## Returns the string representation of the task result.
  if res.isOk:
    "{OkStr}{MsgSep}{res.unsafeValue.join MsgSep}".fmt
  else:
    "{ErrStr}{MsgSep}{res.error}".fmt

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
