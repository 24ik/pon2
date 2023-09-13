## This module implements the web worker.
##

{.experimental: "strictDefs".}

import jsffi
import options
import sequtils
import strformat
import strutils
import uri

import nazopuyo_core
import puyo_core

import ./common
import ../core/solve

# ------------------------------------------------
# Task
# ------------------------------------------------

proc solve(message: string): tuple[code: WorkerResult, message: string] {.inline.} =
  ## Solves the nazo puyo.
  let nazo = message.parseUri.toNazoPuyo
  if nazo.isNone:
    result.code = FAILURE
    result.message = "Worker caught an invalid URI."
    return

  result.code = SUCCESS
  result.message = nazo.get.nazoPuyo.solve.mapIt(it.toUriQueryValue IZUMIYA).join WorkerMessageSeparator

# ------------------------------------------------
# Entry Point
# ------------------------------------------------

proc getSelf: JsObject {.importjs: "(self)".} ## Returns the worker object.

proc postMessage(self: JsObject, code: WorkerResult, message: string) {.inline.} =
  ## Sends the message to the caller of the worker.
  self.postMessage cstring &"{code}{WorkerMessageHeaderSeparator}{message}"

proc postMessage(self: JsObject, task: WorkerTask, code: WorkerResult, message: string) {.inline.} =
  ## Sends the message to the caller of the worker.
  self.postMessage cstring &"{task}{WorkerMessageHeaderSeparator}{code}{WorkerMessageHeaderSeparator}{message}"

proc messageEventListener(event: JsObject) =
  ## Message event listener.
  let self = getSelf()

  let messages = ($event.data.to(cstring)).split WorkerMessageHeaderSeparator
  if messages.len != 2:
    self.postMessage FAILURE, "Worker caught an invalid message."
    return

  let
    task: WorkerTask
    code: WorkerResult
    message: string
  case messages[0]
  of $SOLVE:
    task = SOLVE
    (code, message) = messages[1].solve
  else:
    self.postMessage FAILURE, "Worker caught an invalid task."
    return

  self.postMessage task, code, message

getSelf().onmessage = messageEventListener
