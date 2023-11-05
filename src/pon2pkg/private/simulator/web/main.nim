## This module implements the library entry point.
## 

{.experimental: "strictDefs".}

import std/[dom, sugar]
import karax/[karax, karaxdsl, vdom]
import ./[controller, field, immediatepairs, messages, misc, nextpair, pairs,
          palette, requirement, select, share]
import ../../../corepkg/[environment, misc as coreMisc, position]
import ../../../nazopuyopkg/[nazopuyo]
import ../../../simulatorpkg/[simulator]

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
  # assert event of KeyboardEvent # HACK: somehow this assertion fails
  simulator.runKeyboardEventHandler cast[KeyboardEvent](event).toKeyEvent

func initKeyboardEventHandler*(simulator: var Simulator):
    (event: dom.Event) -> void {.inline.} =
  ## Returns the keyboard event handler.
  (event: dom.Event) => simulator.runKeyboardEventHandler event

# ------------------------------------------------
# DOM
# ------------------------------------------------

proc initPuyoSimulatorDomCore(simulator: var Simulator, idx: int): VNode
                             {.inline.} =
  ## Returns the DOM without the external section.
  ## If this procedure is called multiple times,
  ## different `idx` need to be given.
  buildHtml(tdiv):
    tdiv(class = "block"):
      simulator.requirementFrame(idx = idx)
    tdiv(class = "block"):
      tdiv(class = "columns is-mobile is-variable is-1"):
        tdiv(class = "column is-narrow"):
          if simulator.mode in {IzumiyaSimulatorMode.Play, Replay}:
            tdiv(class = "block"):
              simulator.nextPairFrame
          tdiv(class = "block"):
            simulator.fieldFrame
          if simulator.mode in {IzumiyaSimulatorMode.Play, Replay}:
            tdiv(class = "block"):
              simulator.messagesFrame
          tdiv(class = "block"):
            simulator.selectFrame
          tdiv(class = "block"):
            simulator.shareFrame(idx = idx)
        if simulator.mode in {IzumiyaSimulatorMode.Play, Replay}:
          tdiv(class = "column is-narrow"):
            tdiv(class = "block"):
              simulator.immediatePairsFrame
        tdiv(class = "column is-narrow"):
          tdiv(class = "block"):
            simulator.controllerFrame
          if simulator.mode == IzumiyaSimulatorMode.Edit:
            tdiv(class = "block"):
              simulator.paletteFrame
          tdiv(class = "block"):
            simulator.pairsFrame

proc initPuyoSimulatorDom*(simulator: var Simulator, setKeyHandler = true,
                           wrapSection = true, idx = 0): VNode {.inline.} =
  ## Returns the simulator DOM.
  ## If this procedure is called multiple times,
  ## different `idx` need to be given.
  if setKeyHandler:
    document.onkeydown = simulator.initKeyboardEventHandler

  if wrapSection:
    result = buildHtml(section(class = "section")):
      simulator.initPuyoSimulatorDomCore idx
  else:
    result = simulator.initPuyoSimulatorDomCore idx

proc initPuyoSimulatorDom*(
    nazoEnv: NazoPuyo or Environment, mode = IzumiyaSimulatorMode.Play,
    showCursor = false, setKeyHandler = true,
    wrapSection = true, idx = 0): VNode {.inline.} =
  ## Returns the simulator DOM.
  ## If this procedure is called multiple times,
  ## different `idx` need to be given.
  var simulator = nazoEnv.initSimulator(mode, showCursor)
  result = simulator.initPuyoSimulatorDom(setKeyHandler, wrapSection, idx)

proc initPuyoSimulatorDom*(
    nazoEnv: NazoPuyo or Environment, positions: Positions,
    mode = IzumiyaSimulatorMode.Play, showCursor = false,
    setKeyHandler = true, wrapSection = true, idx = 0): VNode {.inline.} =
  ## Returns the simulator DOM.
  ## If this procedure is called multiple times,
  ## different `idx` need to be given.
  var simulator = nazoEnv.initSimulator(positions, mode, showCursor)
  result = simulator.initPuyoSimulatorDom(setKeyHandler, wrapSection, idx)

# ------------------------------------------------
# Answer DOM
# ------------------------------------------------

proc initPuyoSimulatorAnswerDomCore(simulator: var Simulator, idx: int): VNode
                                   {.inline.} =
  ## Returns the simulator DOM for showing answers.
  ## If this procedure is called multiple times,
  ## different `idx` need to be given.
  simulator.kind = IzumiyaSimulatorKind.Nazo
  simulator.mode = Replay

  result = buildHtml(tdiv):
    tdiv(class = "block"):
      simulator.requirementFrame(idx = idx)
    tdiv(class = "block"):
      tdiv(class = "columns is-mobile is-variable is-1"):
        tdiv(class = "column is-narrow"):
          if simulator.mode in {IzumiyaSimulatorMode.Play, Replay}:
            tdiv(class = "block"):
              simulator.nextPairFrame
          tdiv(class = "block"):
            simulator.fieldFrame
          if simulator.mode in {IzumiyaSimulatorMode.Play, Replay}:
            tdiv(class = "block"):
              simulator.messagesFrame
        if simulator.mode in {IzumiyaSimulatorMode.Play, Replay}:
          tdiv(class = "column is-narrow"):
            tdiv(class = "block"):
              simulator.immediatePairsFrame
        tdiv(class = "column is-narrow"):
          tdiv(class = "block"):
            simulator.controllerFrame
          if simulator.mode == IzumiyaSimulatorMode.Edit:
            tdiv(class = "block"):
              simulator.paletteFrame
          tdiv(class = "block"):
            simulator.pairsFrame

proc initPuyoSimulatorAnswerDom*(
    simulator: var Simulator, setKeyHandler = true,
    wrapSection = true, idx = 0): VNode {.inline, deprecated.} =
  ## Returns the simulator DOM for showing answers.
  ## If this procedure is called multiple times,
  ## different `idx` need to be given.
  if setKeyHandler:
    document.onkeydown = simulator.initKeyboardEventHandler

  result =
    if wrapSection:
      buildHtml(section(class = "section")):
        simulator.initPuyoSimulatorAnswerDomCore idx
  else:
    simulator.initPuyoSimulatorAnswerDomCore idx
