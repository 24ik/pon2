## This module implements the controller node.
##

{.experimental: "strictDefs".}

import std/[sugar]
import karax/[karax, karaxdsl, vdom]
import ../../../corepkg/[misc]
import ../../../simulatorpkg/[simulator]

proc controllerNode*(simulator: var Simulator): VNode {.inline.} =
  ## Returns the controller node.
  buildHtml(tdiv):
    case simulator.mode
    of Edit:
      tdiv(class = "buttons is-centered mb-0"):
        button(
            class = (
              if simulator.editing.insert: "button is-selected is-primary"
              else: "button"),
            onclick = () => simulator.toggleInserting):
          span(class = "icon"):
            italic(class = "fa-solid fa-indent")
        button(class = "button is-light", onclick = () => simulator.flipFieldH):
          span(class = "icon"):
            italic(class = "fa-solid fa-arrow-right-arrow-left")
        button(class = "button is-light", onclick = () => simulator.undo):
          span(class = "icon"):
            italic(class = "fa-solid fa-circle-arrow-left")
        button(class = "button is-light", onclick = () => simulator.redo):
          span(class = "icon"):
            italic(class = "fa-solid fa-circle-arrow-right")
      tdiv(class = "buttons is-centered"):
        button(class = "button is-light",
               onclick = () => simulator.shiftFieldLeft):
          span(class = "icon"):
            italic(class = "fa-solid fa-angles-left")
        button(class = "button is-light",
               onclick = () => simulator.shiftFieldDown):
          span(class = "icon"):
            italic(class = "fa-solid fa-angles-down")
        button(class = "button is-light",
               onclick = () => simulator.shiftFieldUp):
          span(class = "icon"):
            italic(class = "fa-solid fa-angles-up")
        button(class = "button is-light",
               onclick = () => simulator.shiftFieldRight):
          span(class = "icon"):
            italic(class = "fa-solid fa-angles-right")
    of Play:
      tdiv(class = "buttons is-centered mb-0"):
        button(class = "button is-light",
               onclick = () => simulator.reset(resetPosition = false)):
          span(class = "icon"):
            italic(class = "fa-solid fa-backward-fast")
        button(class = "button is-light",
               onclick = () => simulator.forward(useNextPosition = false)):
          span(class = "icon"):
            italic(class = "fa-solid fa-forward-step")
        button(class = "button is-light",
               onclick = () => simulator.forward(skip = true)):
          span(class = "icon"):
            italic(class = "fa-solid fa-angles-right")
      tdiv(class = "buttons is-centered mb-0"):
        button(class = "button is-info",
               onclick = () => simulator.rotateNextPositionLeft):
          span(class = "icon"):
            italic(class = "fa-solid fa-arrow-rotate-left")
        button(class = "button is-light",
               onclick = () => simulator.backward):
          span(class = "icon"):
            italic(class = "fa-solid fa-backward-step")
        button(class = "button is-info",
               onclick = () => simulator.rotateNextPositionRight):
          span(class = "icon"):
            italic(class = "fa-solid fa-arrow-rotate-right")
      tdiv(class = "buttons is-centered mb-0"):
        button(class = "button is-info",
               onclick = () => simulator.moveNextPositionLeft):
          span(class = "icon"):
            italic(class = "fa-solid fa-arrow-left")
        button(class = "button is-info", onclick = () => simulator.forward):
          span(class = "icon"):
            italic(class = "fa-solid fa-arrow-down")
        button(class = "button is-info",
               onclick = () => simulator.moveNextPositionRight):
          span(class = "icon"):
            italic(class = "fa-solid fa-arrow-right")
    of Replay:
      tdiv(class = "buttons is-centered"):
        button(class = "button is-light",
               onclick = () => simulator.reset(resetPosition = false)):
          span(class = "icon"):
            italic(class = "fa-solid fa-backward-fast")
        button(class = "button is-light", onclick = () => simulator.backward):
          span(class = "icon"):
            italic(class = "fa-solid fa-backward-step")
        button(class = "button is-light",
               onclick = () => simulator.forward(useNextPosition = false)):
          span(class = "icon"):
            italic(class = "fa-solid fa-forward-step")
