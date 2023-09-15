## This module implements the controller frame.
##

import jsffi
import options
import sequtils
import strformat
import strutils
import sugar
import uri

import karax / [karax, karaxdsl, kbase, kdom, vdom]
import nazopuyo_core
import puyo_core
import puyo_simulator

import ../common
import ../../manager

const
  UriCopyButtonId = "pon2-button-uri"
  UriCopyMessageShowMs = 500

proc copyToClipboard(text: kstring) {.importjs: "navigator.clipboard.writeText(#);".}

proc showFlashMessage(element: Element, messageHtml: string, timeoutMs = Natural 500) {.inline.} =
  let oldHtml = element.innerHTML
  element.innerHTML = messageHtml
  discard setTimeout(() => (element.innerHTML = oldHtml), timeoutMs)

let worker = runWorker()

proc solveMessageHandler(event: JsObject, manager: var Manager, nazo: NazoPuyo) {.inline.} =
  ## Writes the answers to the window.
  let messages = ($event.data.to(cstring)).split WorkerMessageHeaderSeparator
  assert messages.len == 3
  assert messages[0] == $SOLVE
  assert messages[1] == $SUCCESS

  manager.answers =
    if messages[2] == "": some newSeq[Positions] 0
    else: some messages[2].split(WorkerMessageSeparator).mapIt it.toPositions(IZUMIYA).get
  manager.updateAnswerSimulator nazo

  manager.solving = false

  if not kxi.surpressRedraws:
    kxi.redraw

proc solve*(manager: var Manager) {.inline.} =
  ## Solves the nazo puyo.
  if manager.solving or manager.simulator[].requirement.isNone:
    return

  manager.solving = true

  let
    nazo = manager.simulator[].nazoPuyo.get
    nazoUri = cstring $nazo.toUri
  worker.onmessage = (event: JsObject) => event.solveMessageHandler(manager, nazo)
  worker.postMessage &"{SOLVE}{WorkerMessageHeaderSeparator}{nazoUri}"

proc controllerFrame*(manager: var Manager): VNode {.inline.} =
  ## Returns the controller frame.
  return buildHtml(tdiv(class = "buttons")):
    button(
      class = (if manager.focusAnswer: "button is-selected is-primary" else: "button"),
      onclick = () => manager.toggleFocus,
    ):
      text "解答を操作"
    button(
      class = (if manager.solving: "button is-loading" else: "button"),
      disabled = manager.solving,
      onclick = () => manager.solve,
    ):
      text "解探索"
    button(
      id = UriCopyButtonId,
      class = "button",
      onclick = () => (
        let btn = document.getElementById(UriCopyButtonId);
        btn.disabled = true;
        copyToClipboard kstring $manager.toUri;
        btn.showFlashMessage(
          "<span class='icon'><i class='fa-solid fa-check'></i></span><span>コピー</span>", UriCopyMessageShowMs);
        discard setTimeout(() => (btn.disabled = false), UriCopyMessageShowMs))
    ):
      text "Pon!通URLをコピー"
