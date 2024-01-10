## This module implements the controller node.
##

{.experimental: "strictDefs".}
{.experimental: "strictFuncs".}
{.experimental: "views".}

import std/[jsffi, options, sequtils, strformat, strutils, sugar, uri]
import karax/[karax, karaxdsl, kbase, kdom, vdom]
import ./[misc, webworker]
import ../../../apppkg/[editorpermuter]
import ../../../corepkg/[environment, field, misc, position]
import ../../../nazopuyopkg/[nazopuyo]
import ../../../simulatorpkg/[simulator, web]

const
  UriCopyButtonId = "pon2-button-uri"
  UriCopyMessageShowMs = 500

# FIXME: now multiple editors use the same worker
var worker: Worker

proc solve*(editorPermuter: var EditorPermuter) {.inline.} =
  ## Solves the nazo puyo.
  if (editorPermuter.solving or editorPermuter.editSimulator[].kind != Nazo):
    return

  editorPermuter.solving = true

  editorPermuter.editSimulator[].withNazoPuyo:
    proc showAnswers(returnCode: WorkerReturnCode, messages: seq[string]) =
      case returnCode
      of Success:
        editorPermuter.answers = some messages.mapIt it.parsePositions Izumiya
        editorPermuter.updateAnswer nazoPuyo
        editorPermuter.solving = false

        if not kxi.surpressRedraws:
          kxi.redraw
      of Failure:
        discard

    worker = initWorker showAnswers
    worker.run $nazoPuyo.toUri

proc controllerNode*(editorPermuter: var EditorPermuter): VNode {.inline.} =
  ## Returns the controller node.
  result = buildHtml(tdiv(class = "buttons")):
    let focusButtonClass =
      if editorPermuter.focusAnswer: kstring"button is-selected is-primary"
      else: kstring"button"
    button(class = focusButtonClass,
           onclick = () => editorPermuter.toggleFocus):
      text "解答を操作"

    let solveButtonClass =
      if editorPermuter.solving: kstring"button is-loading"
      else: kstring"button"
    button(class = solveButtonClass, disabled = editorPermuter.solving,
           onclick = () => editorPermuter.solve):
      text "解探索"

    let copyButtonClickHandler = () => (block:
      let btn = document.getElementById UriCopyButtonId
      btn.disabled = true;
      copyToClipboard kstring $editorPermuter.editSimulator[].toUri
      btn.showFlashMessage(
        "<span class='icon'><i class='fa-solid fa-check'></i></span>" &
        "<span>コピー</span>", UriCopyMessageShowMs);
      discard setTimeout(() => (btn.disabled = false),
                        UriCopyMessageShowMs))
    button(id = UriCopyButtonId, class = "button",
           onclick = copyButtonClickHandler):
      text "Pon!通URLをコピー"
