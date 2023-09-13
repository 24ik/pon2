## This module implements the entry point of the GUI application.
##
## This module may require `-d:ssl` compile option.
## [Reference](https://izumiya-keisuke.github.io/puyo-simulator/puyo_simulatorpkg/gui/main.html)
##

import logging
import options
import tables
import uri

import docopt
import nazopuyo_core
import nigui
import puyo_core
import puyo_simulator

import ./answer
import ./controller
import ../manager

export solve

type
  Pon2Control* = ref object of LayoutContainer
    ## Root control of application window.
    manager*: ref Manager

  Pon2Window* = ref object of WindowImpl
    ## Application window.
    manager*: ref Manager

let logger = newConsoleLogger(lvlInfo, verboseFmtStr)

# ------------------------------------------------
# API
# ------------------------------------------------

proc operate*(manager: var Manager, event: KeyEvent): bool {.inline.} =
  ## Handler for keyboard input.
  ## Returns `true` if any action is executed.
  if not manager.focusAnswer and manager.simulator[].mode == IzumiyaSimulatorMode.EDIT:
    if event == ("Enter", false, false, false, false):
      manager.solve
      return true

  return manager.operateCommon event

proc keyboardEventHandler*(window: Pon2Window, event: KeyboardEvent, keys = downKeys()) {.inline.} =
  ## Keyboard event handler.
  let needRedraw = window.manager[].operate event.toKeyEvent keys
  if needRedraw:
    event.window.control.forceRedraw

proc keyboardEventHandler(event: KeyboardEvent) =
  ## Keyboard event handler.
  let rawWindow = event.window
  assert rawWindow of Pon2Window

  cast[Pon2Window](rawWindow).keyboardEventHandler event

proc makePon2Control*(manager: ref Manager): Pon2Control {.inline.} =
  ## Returns the root control of GUI window.
  result = new Pon2Control
  result.init
  result.layout = Layout_Horizontal

  result.manager = manager

  # col=0
  let simulatorControl = manager[].simulator.makePuyoSimulatorControl
  result.add simulatorControl

  # col=1
  let secondCol = newLayoutContainer Layout_Vertical
  result.add secondCol

  secondCol.padding = 10.scaleToDpi
  secondCol.spacing = 10.scaleToDpi

  secondCol.add manager.newControllerControl
  secondCol.add manager.newAnswerControl

proc makePon2Window*(manager: ref Manager, title = "Pon!通", setKeyHandler = true): Pon2Window {.inline.} =
  ## Returns the GUI window.
  result = new Pon2Window
  result.init

  result.manager = manager

  result.title = title
  result.resizable = false
  if setKeyHandler:
    result.onKeyDown = keyboardEventHandler

  let rootControl = manager.makePon2Control
  result.add rootControl

  when defined windows:
    # HACK: somehow this adjustment is needed on Windows
    # TODO: better implementation
    result.width = (rootControl.naturalWidth.float * 1.1).int
    result.height = (rootControl.naturalHeight.float * 1.1).int
  else:
    result.width = rootControl.naturalWidth
    result.height = rootControl.naturalHeight

# ------------------------------------------------
# Run GUI Application
# ------------------------------------------------

const IshikawaModeToIzumiyaMode: array[IshikawaSimulatorMode, IzumiyaSimulatorMode] = [
  IzumiyaSimulatorMode.EDIT, IzumiyaSimulatorMode.PLAY, IzumiyaSimulatorMode.REPLAY, IzumiyaSimulatorMode.PLAY]

proc runGui(
  nazoEnv: NazoPuyo or Environment, positions = none Positions, mode = IzumiyaSimulatorMode.EDIT
) {.inline.} =
  ## Runs the GUI application.
  app.init

  let manager = new Manager
  manager[] = nazoEnv.toManager(positions, mode, true)

  manager.makePon2Window.show
  app.run

proc runGui*(args: Table[string, Value]) {.inline.} =
  ## Runs the GUI application.
  case args["<uri>"].kind
  of vkNone:
    makeEmptyNazoPuyo().runGui
  of vkStr:
    let nazo = ($args["<uri>"]).parseUri.toNazoPuyo
    if nazo.isSome:
      nazo.get.nazoPuyo.runGui(
        nazo.get.positions, (
          if nazo.get.izumiyaMode.isSome: nazo.get.izumiyaMode.get
          else: IshikawaModeToIzumiyaMode[nazo.get.ishikawaMode.get]))
      return

    let env = ($args["<uri>"]).parseUri.toEnvironment
    if env.isSome:
      env.get.environment.runGui(
        env.get.positions, (
          if env.get.izumiyaMode.isSome: env.get.izumiyaMode.get
          else: IshikawaModeToIzumiyaMode[env.get.ishikawaMode.get]))
      return

    logger.log lvlError, "Invalid URI format"
    quit 1
  else:
    doAssert false
