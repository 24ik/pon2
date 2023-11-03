## This module implements the entry point for making a web page.
## 

{.experimental: "strictDefs".}

import std/[dom, options, random, sequtils, strutils, sugar, tables, uri]
import karax/[karax, karaxdsl, vdom]
import ./[controller, field, immediatePairs, messages, misc, nextPair, pairs,
          palette, requirement, select, share]
import ../[simulator]
import ../../core/[environment, field, misc as coreMisc, pair, position]
import ../../nazoPuyo/[nazoPuyo]

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

# ------------------------------------------------
# Web Page Generator
# ------------------------------------------------

var
  pageInitialized = false
  globalSimulator: Simulator

const
  RandomQueryKey = "random"
  RuleQueryKey = "rule"
  MoveCountQueryKey = "move"
  QueryToRule = {"t": Tsu, "w": Water}.toTable

proc isMobile: bool {.importjs:
  "navigator.userAgent.match(/iPhone|Android.+Mobile/)".}
  ## Returns `true` if the host is mobile.

proc initPuyoSimulatorDom(routerData: RouterData): VNode =
  ## Returns the simulator DOM with izumiya-format URI.
  if pageInitialized:
    return globalSimulator.initPuyoSimulatorDom

  pageInitialized = true
  let query =
    if routerData.queryString == cstring"": ""
    else: ($routerData.queryString)[1..^1] # remove '?'

  # random pairs
  var keys = newSeq[string](0)
  for key, _ in query.decodeQuery:
    keys.add key
  if RandomQueryKey in keys:
    {.push warning[ProveInit]:off.}
    var
      rule = none Rule
      moveCount = -1
    {.pop.}

    for key, val in query.decodeQuery:
      case key
      of RandomQueryKey:
        discard
      of RuleQueryKey:
        if val in QueryToRule:
          rule = some QueryToRule[val]
        else:
          return buildHtml(tdiv):
            text "URL形式エラー"
      of MoveCountQueryKey:
        try:
          moveCount = val.parseInt
        except ValueError:
          return buildHtml(tdiv):
            text "URL形式エラー"
      else:
        return buildHtml(tdiv):
          text "URL形式エラー"

    if rule.isNone or moveCount < 3:
      return buildHtml(tdiv):
        text "URL形式エラー"

    randomize()

    case rule.get
    of Tsu:
      var env = initTsuEnvironment()
      for _ in 0..<moveCount - 3:
        env.addPair

      globalSimulator = env.initSimulator(showCursor = not isMobile())
    of Water:
      var env = initWaterEnvironment()
      for _ in 0..<moveCount - 3:
        env.addPair

      globalSimulator = env.initSimulator(showCursor = not isMobile())
    return globalSimulator.initPuyoSimulatorDom

  var uri = initUri()
  uri.scheme = "https"
  uri.hostname = $Izumiya
  uri.path = "/puyo-simulator/playground/index.html"
  uri.query = query

  try:
    let parseRes = uri.parseNazoPuyos
    parseRes.nazoPuyos.flattenAnd:
      globalSimulator =
        if parseRes.positions.isSome:
          nazoPuyo.initSimulator(parseRes.positions.get,
                                 parseRes.izumiyaMode.get, not isMobile())
        else:
          nazoPuyo.initSimulator(parseRes.izumiyaMode.get, not isMobile())

    result = globalSimulator.initPuyoSimulatorDom
  except ValueError:
    try:
      let parseRes = uri.parseEnvironments
      parseRes.environments.flattenAnd:
        globalSimulator =
          if parseRes.positions.isSome:
            environment.initSimulator(parseRes.positions.get,
                                      parseRes.izumiyaMode.get, not isMobile())
          else:
            environment.initSimulator(parseRes.izumiyaMode.get, not isMobile())

      result = globalSimulator.initPuyoSimulatorDom
    except ValueError:
      result = buildHtml(tdiv):
        text "URL形式エラー"

proc initWebPage* {.inline.} =
  ## Makes the web page.
  initPuyoSimulatorDom.setRenderer
