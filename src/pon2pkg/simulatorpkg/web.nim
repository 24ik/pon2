## This module implements APIs for web GUI application.
##

{.experimental: "strictDefs".}

import std/[dom, sugar]
import karax/[karax, karaxdsl, vdom]
import ./[simulator]
import ../private/simulator/web/[controller, field, immediatepairs, messages,
                                 misc, nextpair, pairs, palette, requirement,
                                 select, share]
import ../corepkg/[environment, field, misc as coreMisc, position]
import ../nazopuyopkg/[nazopuyo]

export misc.toKeyEvent

# ------------------------------------------------
# Keyboard Handler
# ------------------------------------------------

proc runKeyboardEventHandler*(simulator: var Simulator, event: KeyEvent)
                             {.inline.} =
  ## Keybaord event handler.
  let needRedraw = simulator.operate event
  if needRedraw and not kxi.surpressRedraws:
    kxi.redraw

proc runKeyboardEventHandler*(simulator: var Simulator, event: dom.Event)
                             {.inline.} =
  ## Keybaord event handler.
  # HACK: somehow this assertion fails
  # assert event of KeyboardEvent
  simulator.runKeyboardEventHandler cast[KeyboardEvent](event).toKeyEvent

func initKeyboardEventHandler*(simulator: var Simulator):
    (event: dom.Event) -> void {.inline.} =
  ## Returns the keyboard event handler.
  (event: dom.Event) => simulator.runKeyboardEventHandler event

# ------------------------------------------------
# DOM
# ------------------------------------------------

proc initSimulatorDom(simulator: var Simulator, idx: int): VNode {.inline.} =
  ## Returns the DOM without the external section.
  ## If this procedure is called multiple times,
  ## different `idx` need to be given.
  buildHtml(tdiv):
    tdiv(class = "block"):
      simulator.requirementNode(idx = idx)
    tdiv(class = "block"):
      tdiv(class = "columns is-mobile is-variable is-1"):
        tdiv(class = "column is-narrow"):
          if simulator.mode != Edit:
            tdiv(class = "block"):
              simulator.nextPairNode
          tdiv(class = "block"):
            simulator.fieldNode
          if simulator.mode != Edit:
            tdiv(class = "block"):
              simulator.messagesNode
          if simulator.editor:
            tdiv(class = "block"):
              simulator.selectNode
          tdiv(class = "block"):
            simulator.shareNode idx
        if simulator.mode != Edit:
          tdiv(class = "column is-narrow"):
            tdiv(class = "block"):
              simulator.immediatePairsNode
        tdiv(class = "column is-narrow"):
          tdiv(class = "block"):
            simulator.controllerNode
          if simulator.mode == Edit:
            tdiv(class = "block"):
              simulator.paletteNode
          tdiv(class = "block"):
            simulator.pairsNode

proc initSimulatorDom*(simulator: var Simulator, setKeyHandler = true,
                       wrapSection = true, idx = 0): VNode {.inline.} =
  ## Returns the simulator DOM.
  ## If this procedure is called multiple times,
  ## different `idx` need to be given.
  if setKeyHandler:
    document.onkeydown = simulator.initKeyboardEventHandler

  if wrapSection:
    result = buildHtml(section(class = "section")):
      simulator.initSimulatorDom idx
  else:
    result = simulator.initSimulatorDom idx

proc initSimulatorDom*[F: TsuField or WaterField](
    nazoEnv: NazoPuyo[F] or Environment[F], mode = Play, editor = false,
    setKeyHandler = true, wrapSection = true, idx = 0): VNode {.inline.} =
  ## Returns the simulator DOM.
  ## If this procedure is called multiple times,
  ## different `idx` need to be given.
  var simulator = nazoEnv.initSimulator(mode, editor)
  result = simulator.initSimulatorDom(setKeyHandler, wrapSection, idx)

proc initSimulatorDom*[F: TsuField or WaterField](
    nazoEnv: NazoPuyo[F] or Environment[F], positions: Positions, mode = Play,
    editor = false, setKeyHandler = true, wrapSection = true, idx = 0): VNode
    {.inline.} =
  ## Returns the simulator DOM.
  ## If this procedure is called multiple times,
  ## different `idx` need to be given.
  var simulator = nazoEnv.initSimulator(positions, mode, editor)
  result = simulator.initSimulatorDom(setKeyHandler, wrapSection, idx)
