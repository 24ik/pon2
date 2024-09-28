## This module implements the controller node.
##

{.experimental: "strictDefs".}
{.experimental: "strictFuncs".}
{.experimental: "views".}

import std/[sugar]
import karax/[karax, karaxdsl, kbase, vdom]
import ../../../../app/[simulator]

proc initControllerNode*(simulator: ref Simulator): VNode {.inline.} =
  ## Returns the controller node.
  let insertingButtonClass =
    if simulator[].editing.insert:
      kstring"button is-selected is-primary"
    else:
      kstring"button"

  result = buildHtml(tdiv):
    case simulator[].mode
    of Play, PlayEditor:
      tdiv(class = "buttons is-centered mb-0"):
        button(
          class = "button is-light",
          onclick = () => simulator[].backward(toStable = false),
        ):
          span(class = "icon"):
            italic(class = "fa-solid fa-backward")
        button(
          class = "button is-light", onclick = () => simulator[].forward(skip = true)
        ):
          span(class = "icon"):
            italic(class = "fa-solid fa-forward")
      tdiv(class = "buttons is-centered mb-0"):
        button(class = "button is-light", onclick = () => simulator[].reset):
          span(class = "icon"):
            italic(class = "fa-solid fa-backward-fast")
        button(
          class = "button is-light", onclick = () => simulator[].forward(replay = true)
        ):
          span(class = "icon"):
            italic(class = "fa-solid fa-forward-step")
      tdiv(class = "buttons is-centered mb-0"):
        button(
          class = "button is-info",
          onclick = () => simulator[].rotateOperatingPositionLeft,
        ):
          span(class = "icon"):
            italic(class = "fa-solid fa-arrow-rotate-left")
        button(class = "button is-light", onclick = () => simulator[].backward):
          span(class = "icon"):
            italic(class = "fa-solid fa-backward-step")
        button(
          class = "button is-info",
          onclick = () => simulator[].rotateOperatingPositionRight,
        ):
          span(class = "icon"):
            italic(class = "fa-solid fa-arrow-rotate-right")
      tdiv(class = "buttons is-centered mb-0"):
        button(
          class = "button is-info",
          onclick = () => simulator[].moveOperatingPositionLeft,
        ):
          span(class = "icon"):
            italic(class = "fa-solid fa-arrow-left")
        button(class = "button is-info", onclick = () => simulator[].forward):
          span(class = "icon"):
            italic(class = "fa-solid fa-arrow-down")
        button(
          class = "button is-info",
          onclick = () => simulator[].moveOperatingPositionRight,
        ):
          span(class = "icon"):
            italic(class = "fa-solid fa-arrow-right")
    of Edit:
      tdiv(class = "buttons is-centered mb-0"):
        button(
          class = insertingButtonClass, onclick = () => simulator[].toggleInserting
        ):
          span(class = "icon"):
            italic(class = "fa-solid fa-indent")
        button(class = "button is-light", onclick = () => simulator[].flipFieldH):
          span(class = "icon"):
            italic(class = "fa-solid fa-arrow-right-arrow-left")
        button(class = "button is-light", onclick = () => simulator[].undo):
          span(class = "icon"):
            italic(class = "fa-solid fa-circle-arrow-left")
        button(class = "button is-light", onclick = () => simulator[].redo):
          span(class = "icon"):
            italic(class = "fa-solid fa-circle-arrow-right")
      tdiv(class = "buttons is-centered"):
        button(class = "button is-light", onclick = () => simulator[].shiftFieldLeft):
          span(class = "icon"):
            italic(class = "fa-solid fa-angles-left")
        button(class = "button is-light", onclick = () => simulator[].shiftFieldDown):
          span(class = "icon"):
            italic(class = "fa-solid fa-angles-down")
        button(class = "button is-light", onclick = () => simulator[].shiftFieldUp):
          span(class = "icon"):
            italic(class = "fa-solid fa-angles-up")
        button(class = "button is-light", onclick = () => simulator[].shiftFieldRight):
          span(class = "icon"):
            italic(class = "fa-solid fa-angles-right")
    of View:
      tdiv(class = "buttons is-centered mb-0"):
        button(class = "button is-light", onclick = () => simulator[].reset):
          span(class = "icon"):
            italic(class = "fa-solid fa-backward-fast")
        button(
          class = "button is-light",
          onclick = () => simulator[].backward(toStable = false),
        ):
          span(class = "icon"):
            italic(class = "fa-solid fa-backward")
      tdiv(class = "buttons is-centered mb-0"):
        button(class = "button is-light", onclick = () => simulator[].backward):
          span(class = "icon"):
            italic(class = "fa-solid fa-backward-step")
        button(
          class = "button is-light", onclick = () => simulator[].forward(replay = true)
        ):
          span(class = "icon"):
            italic(class = "fa-solid fa-forward-step")
