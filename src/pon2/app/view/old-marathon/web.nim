## This module implements marathon mode for web.
##

{.experimental: "inferGenericTypes".}
{.experimental: "notnil".}
{.experimental: "strictCaseObjects".}
{.experimental: "strictDefs".}
{.experimental: "strictFuncs".}
{.experimental: "views".}

import std/[strformat, sugar]
import karax/[karax, karaxdsl, kdom, vdom]
import ../[key, marathon]
import ../../private/app/[misc]
import
  ../../private/app/marathon/web/
    [controller, pagination, searchbar, searchresult, simulator as simulatorModule]

# ------------------------------------------------
# Keyboard Handler
# ------------------------------------------------

proc runKeyboardEventHandler*(
    self: Marathon, event: KeyEvent
): bool {.inline, discardable.} =
  ## Runs the keyboard event handler.
  ## Returns `true` if any action is executed.
  result = self.operate event
  if result and not kxi.surpressRedraws:
    kxi.redraw

proc runKeyboardEventHandler*(
    self: Marathon, event: Event
): bool {.inline, discardable.} =
  ## Runs the keyboard event handler.
  # assert event of KeyboardEvent # HACK: somehow this fails

  result = self.runKeyboardEventHandler cast[KeyboardEvent](event).toKeyEvent
  if result:
    event.preventDefault

func newKeyboardEventHandler*(self: Marathon): (event: Event) -> void {.inline.} =
  ## Returns the keyboard event handler.
  (event: Event) => (discard self.runKeyboardEventHandler event)

# ------------------------------------------------
# Node
# ------------------------------------------------

const
  SimulatorIdPrefix = "pon2-marathon-simulator-"
  SearchBarIdPrefix = "pon2-marathon-searchbar-"

proc newMarathonNode(self: Marathon, id: string): VNode {.inline.} =
  ## Returns the node of marathon manager.
  buildHtml(tdiv(class = "columns is-mobile")):
    tdiv(class = "column is-narrow"):
      tdiv(class = "block"):
        self.newMarathonPlayControllerNode
      tdiv(class = "block"):
        self.newMarathonSimulatorNode &"{SimulatorIdPrefix}{id}"
    tdiv(class = "column is-narrow"):
      tdiv(class = "block"):
        self.newMarathonSearchBarNode &"{SearchBarIdPrefix}{id}"
      if not isMobile():
        tdiv(class = "block"):
          self.newMarathonFocusControllerNode
      tdiv(class = "block"):
        self.newMarathonPaginationNode
      if self.matchResult.strings.len > 0:
        tdiv(class = "block"):
          self.newMarathonSearchResultNode

proc newMarathonNode*(
    self: Marathon, setKeyHandler = true, wrapSection = true, id = ""
): VNode {.inline.} =
  ## Returns the node of marathon manager.
  ## `id` is shared with other node-creating procedures and need to be unique.
  if setKeyHandler:
    document.onkeydown = self.newKeyboardEventHandler

  let node = self.newMarathonNode id

  if wrapSection:
    result = buildHtml(section(class = "section")):
      node
  else:
    result = node
