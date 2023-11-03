## This module implements the entry point.
##
## This module may require `-d:ssl` compile option since `assets.loadAssets` may require it.
##

{.experimental: "strictDefs".}

import std/[options, setutils, sugar, uri]
import docopt
import nigui
import puyo_core
import ./[assets, field, immediatePairs, messages, misc, nextPair, pairs,
          requirement, select, share]
import ../[simulator]

export misc.toKeyEvent

type
  PuyoSimulatorControl* = ref object of LayoutContainer
    ## Root control of the application window.
    simulator*: ref Simulator

  PuyoSimulatorWindow* = ref object of WindowImpl
    ## Application window.
    simulator*: ref Simulator

# ------------------------------------------------
# Keyboard Handler
# ------------------------------------------------

proc runKeyboardEventHandler*(window: PuyoSimulatorWindow, event: KeyboardEvent,
                              keys = downKeys()) {.inline.} =
  ## Keyboard event handler.
  let needRedraw = window.simulator[].operate event.toKeyEvent keys
  if needRedraw:
    event.window.control.forceRedraw

proc keyboardEventHandler(event: KeyboardEvent) =
  ## Keyboard event handler.
  let rawWindow = event.window
  assert rawWindow of PuyoSimulatorWindow

  cast[PuyoSimulatorWindow](rawWindow).runKeyboardEventHandler event

func initKeyboardEventHandler*: (event: KeyboardEvent) -> void {.inline.} =
  ## Returns the keyboard event handler.
  keyboardEventHandler

# ------------------------------------------------
# Control
# ------------------------------------------------
 
proc initPuyoSimulatorControl*(simulator: ref Simulator): PuyoSimulatorControl
                              {.inline.} =
  ## Returns the root control of GUI window.
  result = new PuyoSimulatorControl
  result.init
  result.layout = Layout_Vertical

  result.simulator = simulator

  let assetsRef = new Assets
  assetsRef[] = initAssets()

  # row=0
  let reqControl = simulator.initRequirementControl
  result.add reqControl

  # row=1
  let secondRow = newLayoutContainer Layout_Horizontal
  result.add secondRow

  # row=1, left
  let left = newLayoutContainer Layout_Vertical
  secondRow.add left

  let
    field = simulator.initFieldControl assetsRef
    messages = simulator.initMessagesControl assetsRef
  left.add simulator.initNextPairControl assetsRef
  left.add field
  left.add messages
  left.add simulator.initSelectControl reqControl
  left.add simulator.initShareControl

  # row=1, center
  secondRow.add simulator.initImmediatePairsControl assetsRef

  # row=1, right
  secondRow.add simulator.initPairsControl assetsRef

  # set size
  reqControl.setWidth secondRow.naturalWidth
  messages.setWidth field.naturalWidth

proc initPuyoSimulatorWindow*(simulator: ref Simulator, title = "ぷよぷよシミュレータ",
                              setKeyHandler = true): PuyoSimulatorWindow {.inline.} =
  ## Returns the GUI window.
  result = new PuyoSimulatorWindow
  result.init

  result.simulator = simulator

  result.title = title
  result.resizable = false
  if setKeyHandler:
    result.onKeyDown = keyboardEventHandler

  let rootControl = simulator.initPuyoSimulatorControl
  result.add rootControl

  when defined(windows):
    # HACK: somehow this adjustment is needed on Windows
    # TODO: better implementation
    result.width = (rootControl.naturalWidth.float * 1.1).int
    result.height = (rootControl.naturalHeight.float * 1.1).int
  else:
    result.width = rootControl.naturalWidth
    result.height = rootControl.naturalHeight

# ------------------------------------------------
# Answer Control
# ------------------------------------------------

proc initPuyoSimulatorAnswerControl*(simulator: ref Simulator):
    PuyoSimulatorControl {.inline, deprecated.} =
  ## Returns the root control of GUI window for showing answers.
  simulator[].kind = IzumiyaSimulatorKind.Nazo
  simulator[].mode = Replay

  result = new PuyoSimulatorControl
  result.init
  result.layout = Layout_Vertical

  result.simulator = simulator

  let assetsRef = new Assets
  assetsRef[] = initAssets()

  # row=0
  let reqControl = simulator.initRequirementControl
  result.add reqControl

  # row=1
  let secondRow = newLayoutContainer Layout_Horizontal
  result.add secondRow

  # row=1, left
  let left = newLayoutContainer Layout_Vertical
  secondRow.add left

  let
    field = simulator.initFieldControl assetsRef
    messages = simulator.initMessagesControl assetsRef
  left.add simulator.initNextPairControl assetsRef
  left.add field
  left.add messages

  # row=1, center
  secondRow.add simulator.initImmediatePairsControl assetsRef

  # row=1, right
  secondRow.add simulator.initPairsControl assetsRef

  # set size
  reqControl.width = secondRow.naturalWidth
  messages.width = field.naturalWidth

# ------------------------------------------------
# Run GUI Application
# ------------------------------------------------

const IshikawaModeToIzumiyaMode: array[IshikawaSimulatorMode,
                                       IzumiyaSimulatorMode] = [
  IzumiyaSimulatorMode.Edit, Play, Replay, Play]

proc runGui[F: TsuField or WaterField](
    nazoEnv: NazoPuyo[F] or Environment[F], positions: Option[Positions],
    mode: IzumiyaSimulatorMode) {.inline.} =
  ## Runs the GUI application.
  app.init

  let simulator = new Simulator
  simulator[] =
    if positions.isSome: nazoEnv.initSimulator(positions.get, mode, true)
    else: nazoEnv.initSimulator(mode, true)

  simulator.initPuyoSimulatorWindow.show
  app.run

proc runGui[F: TsuField or WaterField](
    nazoEnv: NazoPuyo[F] or Environment[F], mode = Play) {.inline.} =
  ## Runs the GUI application.
  nazoEnv.runGui none Positions, mode

proc runGui[F: TsuField or WaterField](
    nazoEnv: NazoPuyo[F] or Environment[F], positions: Positions, mode = Play)
    {.inline.} =
  ## Runs the GUI application.
  nazoEnv.runGui some positions, mode

proc runGui*(args: Table[string, Value]) {.inline.} =
  ## Runs the GUI application.
  case args["<uri>"].kind
  of vkNone:
    initTsuEnvironment(0, colorCount = 5, setPairs = false).runGui
  of vkStr:
    try:
      let
        nazoPos = ($args["<uri>"]).parseUri.parseNazoPuyos
        positions = nazoPos.positions
        mode =
          if nazoPos.izumiyaMode.isSome: nazoPos.izumiyaMode.get
          else: IshikawaModeToIzumiyaMode[nazoPos.ishikawaMode.get]

      case nazoPos.rule
      of Tsu: nazoPos.nazoPuyos.tsu.runGui positions, mode
      of Water: nazoPos.nazoPuyos.water.runGui positions, mode
    except ValueError:
      let
        envPos = ($args["<uri>"]).parseUri.parseEnvironments
        positions = envPos.positions
        mode =
          if envPos.izumiyaMode.isSome: envPos.izumiyaMode.get
          else: IshikawaModeToIzumiyaMode[envPos.ishikawaMode.get]

      case envPos.rule
      of Tsu: envPos.environments.tsu.runGui positions, mode
      of Water: envPos.environments.water.runGui positions, mode
  else:
    assert false
