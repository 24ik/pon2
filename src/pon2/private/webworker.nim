## This module implements web workers.
##
## Compile Options:
## | Option                    | Description                  | Default           |
## | ------------------------- | ---------------------------- | ----------------- |
## | `-d:pon2.webworker=<str>` | Path of the web worker file. | `./worker.min.js` |
##

{.push raises: [].}
{.experimental: "strictDefs".}
{.experimental: "strictFuncs".}
{.experimental: "views".}

import std/[asyncjs, jsffi, strformat, sugar]
import ./[assign3, results2, strutils2]

type
  WebWorkerTask* = ((args: seq[string]) {.raises: [], gcsafe.} -> Res[seq[string]])
    ## Task executed by web workers.

  WebWorker* = object ## Web worker.
    workerObj: JsObject
    running: bool

const
  WebWorkerPath {.define: "pon2.webworker".} = "./worker.min.js"
  MsgSep = "<pon2-webworker-sep>"

# ------------------------------------------------
# Constructor
# ------------------------------------------------

const
  OkStr = "ok"
  ErrStr = "err"

proc newWorkerObj(): JsObject {.inline, importjs: "new Worker('{WebWorkerPath}')".fmt.}

proc init*(T: type WebWorker): T {.inline.} =
  T(running: false, workerObj: newWorkerObj())

# ------------------------------------------------
# Property
# ------------------------------------------------

func isRunning*(self: WebWorker): bool {.inline.} =
  ## Returns `true` if the worker is running.
  self.running

# ------------------------------------------------
# Caller
# ------------------------------------------------

func parseRes(str: string): Res[seq[string]] {.inline.} =
  ## Returns the result of the web worker's task.
  let strs = str.split(MsgSep, 1)
  if strs.len != 2:
    return err "Invalid result: {str}".fmt

  case strs[0]
  of OkStr:
    ok strs[1].split MsgSep
  of ErrStr:
    err strs[1].split(MsgSep).join "\n"
  else:
    err "Invalid result: {str}".fmt

proc run*(
    self: var WebWorker, args: varargs[string]
): Future[Res[seq[string]]] {.inline, async.} =
  ## Runs the task.
  ## If the worker is running, returns an error.
  if self.running:
    return Res[seq[string]].err "Worker is running"

  self.running.assign true

  proc handler(resolve: (response: Res[seq[string]]) -> void) =
    self.workerObj.onmessage =
      (ev: JsObject) => (
        block:
          ($ev.data.to cstring).parseRes.resolve
          self.running.assign false
      )

    self.workerObj.postMessage args.join(MsgSep).cstring

  handler.newPromise

# ------------------------------------------------
# Callee
# ------------------------------------------------

proc getSelf(): JsObject {.inline, importjs: "(self)".} ## Returns the web worker object.

func split2(str, sep: string): seq[string] {.inline.} =
  ## Returns the split strings.
  ## If the string is empty, returns an empty sequence.
  if str.len == 0:
    @[]
  else:
    str.split sep

func toStr(res: Res[seq[string]]): string {.inline.} =
  ## Returns the string representation of the task result.
  if res.isOk:
    "{OkStr}{MsgSep}{res.unsafeValue.join MsgSep}".fmt
  else:
    "{ErrStr}{MsgSep}{res.error}".fmt

proc register*(task: WebWorkerTask) {.inline.} =
  ## Registers the task to the web worker.
  getSelf().onmessage =
    (event: JsObject) =>
    getSelf().postMessage ($event.data.to cstring).split2(MsgSep).task.toStr.cstring
