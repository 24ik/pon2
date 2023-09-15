## This module implements the entry point for making a editor web page.
##

import dom
import sugar
import options
import uri

import karax / [karax, karaxdsl, kdom, vdom]

import nazopuyo_core
import puyo_core
import puyo_simulator

import ./answer
import ./controller
import ../../core/manager/editor

export solve

# ------------------------------------------------
# API
# ------------------------------------------------

proc operate*(manager: var EditorManager, event: KeyEvent): bool {.inline.} =
  ## Handler for keyboard input.
  ## Returns `true` if any action is executed.
  if not manager.focusAnswer and manager.simulator[].mode == IzumiyaSimulatorMode.EDIT:
    if event == ("Enter", false, false, false, false):
      manager.solve
      return true

  return manager.operateCommon event

proc keyboardEventHandler*(manager: var EditorManager, event: KeyEvent) {.inline.} =
  ## Keyboard event handler.
  let needRedraw = manager.operate event
  if needRedraw and not kxi.surpressRedraws:
    kxi.redraw

proc keyboardEventHandler*(manager: var EditorManager, event: dom.Event) {.inline.} =
  ## Keybaord event handler.
  # assert event of KeyboardEvent # HACK: somehow this assertion fails
  manager.keyboardEventHandler cast[KeyboardEvent](event).toKeyEvent

proc makeKeyboardEventHandler*(manager: var EditorManager): (event: dom.Event) -> void {.inline.} =
  ## Returns the keyboard event handler.
  (event: dom.Event) => manager.keyboardEventHandler event

proc makePon2EditorDom*(manager: var EditorManager, setKeyHandler = true): VNode {.inline.} =
  ## Returns the DOM for the editor.
  if setKeyHandler:
    document.onkeydown = manager.makeKeyboardEventHandler

  let simulatorDom = manager.simulator[].makePuyoSimulatorDom(setKeyHandler = false)
  return buildHtml(tdiv(class = "columns is-mobile is-variable is-1")):
    tdiv(class = "column is-narrow"):
      simulatorDom
    tdiv(class = "column is-narrow"):
      section(class = "section"):
        tdiv(class = "block"):
          manager.controllerFrame
        if manager.answers.isSome:
          tdiv(class = "block"):
            manager.answerFrame

proc makePon2EditorDom*(
  nazoEnv: NazoPuyo or Environment,
  positions = none Positions,
  mode = IzumiyaSimulatorMode.PLAY,
  showCursor = false,
  setKeyHandler = true,
): VNode {.inline.} =
  ## Returns the DOM for the editor.
  var manager = nazoEnv.toEditorManager(positions, mode, showCursor)
  return manager.makePon2EditorDom setKeyHandler

# ------------------------------------------------
# Web Page Generator
# ------------------------------------------------

var
  pageInitialized = false
  globalManager: EditorManager

proc isMobile: bool {.importjs: "navigator.userAgent.match(/iPhone|Android.+Mobile/)".}

proc makePon2EditorDom(routerData: RouterData): VNode =
  ## Returns the DOM for the editor.
  if pageInitialized:
    return globalManager.makePon2EditorDom

  pageInitialized = true
  let query = if routerData.queryString == cstring"": "" else: ($routerData.queryString)[1 .. ^1]

  var uri = initUri()
  uri.scheme = "https"
  uri.hostname = $IZUMIYA
  uri.path = "/puyo-simulator/playground/index.html"
  uri.query = query

  let nazo = uri.toNazoPuyo
  if nazo.isSome:
    globalManager = nazo.get.nazoPuyo.toEditorManager(nazo.get.positions, nazo.get.izumiyaMode.get, not isMobile())
    return globalManager.makePon2EditorDom

  let env = uri.toEnvironment
  if env.isSome:
    globalManager = env.get.environment.toEditorManager(env.get.positions, env.get.izumiyaMode.get, not isMobile())
    return globalManager.makePon2EditorDom

  return buildHtml:
    text "URL形式エラー"

proc makePon2EditorWebPage* {.inline.} =
  ## Makes the web page of the GUI application.
  makePon2EditorDom.setRenderer
