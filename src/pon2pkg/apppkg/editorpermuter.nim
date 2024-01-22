## This module implements editor-permuters.
##

{.experimental: "strictDefs".}
{.experimental: "strictFuncs".}
{.experimental: "views".}

import std/[options, sequtils]
import ./[misc, simulator]
import ../corepkg/[environment, field, misc, pair, position]
import ../nazopuyopkg/[nazopuyo]
import ../private/[misc]

when defined(js):
  import std/[sugar, uri]
  import karax/[karax, karaxdsl, vdom]
  import ../private/[webworker]
else:
  {.push warning[Deprecated]: off.}
  import std/[sugar, threadpool]
  import nigui
  import ../nazopuyopkg/[permute, solve]
  {.pop.}

type
  EditorPermuter* = object
    ## Editor and Permuter.
    simulator*: ref Simulator
    replaySimulator*: ref Simulator

    replayData*: Option[seq[tuple[pairs: Pairs, positions: Positions]]]
    replayIdx*: Natural

    editor: bool
    focusReplay*: bool
    workerRunning*: bool

  TaskKind* = enum
    ## Worker task kind.
    Solve = "solve"
    Permute = "permute"

using
  self: EditorPermuter
  mSelf: var EditorPermuter

# ------------------------------------------------
# Constructor
# ------------------------------------------------

proc initEditorPermuter*[F: TsuField or WaterField](
    env: Environment[F], positions: Positions, mode = Play,
    editor = false): EditorPermuter {.inline.} =
  ## Returns a new `EditorManager`.
  ## If `mode` is `Edit`, `editor` will be ignored (*i.e.*, regarded as `true`).
  result.simulator = new Simulator
  result.simulator[] = env.initSimulator(positions, mode, editor)
  result.replaySimulator = new Simulator
  result.replaySimulator[] = 0.initEnvironment[:F].initSimulator(Replay, editor)

  {.push warning[ProveInit]: off.}
  result.replayData = default type result.replayData
  result.replayIdx = 0
  {.pop.}

  result.editor = editor
  result.focusReplay = false
  result.workerRunning = false

proc initEditorPermuter*[F: TsuField or WaterField](
    env: Environment[F], mode = Play, editor = false): EditorPermuter
    {.inline.} =
  ## Returns a new `EditorManager`.
  ## If `mode` is `Edit`, `editor` will be ignored (*i.e.*, regarded as `true`).
  env.initEditorPermuter(Position.none.repeat env.pairs.len, mode, editor)

proc initEditorPermuter*[F: TsuField or WaterField](
    nazo: NazoPuyo[F], positions: Positions, mode = Play,
    editor = false): EditorPermuter {.inline.} =
  ## Returns a new `EditorManager`.
  ## If `mode` is `Edit`, `editor` will be ignored (*i.e.*, regarded as `true`).
  result.simulator = new Simulator
  result.simulator[] = nazo.initSimulator(positions, mode, editor)
  result.replaySimulator = new Simulator
  result.replaySimulator[] = initNazoPuyo[F]().initSimulator(Replay, editor)

  {.push warning[ProveInit]: off.}
  result.replayData = default type result.replayData
  result.replayIdx = 0
  {.pop.}

  result.editor = editor
  result.focusReplay = false
  result.workerRunning = false

proc initEditorPermuter*[F: TsuField or WaterField](
    nazo: NazoPuyo[F], mode = Play, editor = false): EditorPermuter {.inline.} =
  ## Returns a new `EditorManager`.
  ## If `mode` is `Edit`, `editor` will be ignored (*i.e.*, regarded as `true`).
  nazo.initEditorPermuter(Position.none.repeat nazo.moveCount, mode, editor)

# ------------------------------------------------
# Edit - Other
# ------------------------------------------------

func toggleFocus*(mSelf) {.inline.} = mSelf.focusReplay.toggle
  ## Toggles focusing replay or not.

# ------------------------------------------------
# Solve
# ------------------------------------------------

proc updateReplaySimulator[F: TsuField or WaterField](mSelf; nazo: NazoPuyo[F])
                 {.inline.} =
  ## Updates the replay simulator.
  ## This function is assumed to be called after `mSelf.replayData` is set.
  assert mSelf.replayData.isSome

  if mSelf.replayData.get.len > 0:
    mSelf.focusReplay = true
    mSelf.replayIdx = 0

    var nazo2 = nazo
    nazo2.environment.pairs = mSelf.replayData.get[0].pairs
    mSelf.replaySimulator[] = nazo2.initSimulator(
      mSelf.replayData.get[mSelf.replayIdx].positions,
      mSelf.replaySimulator[].mode,
      mSelf.replaySimulator[].editor)
  else:
    mSelf.focusReplay = false

proc solve*(mSelf) {.inline.} =
  ## Solves the nazo puyo.
  if (mSelf.workerRunning or mSelf.simulator[].kind != Nazo):
    return

  mSelf.workerRunning = true

  mSelf.simulator[].withNazoPuyo:
    when defined(js):
      proc showReplay(returnCode: WorkerReturnCode, messages: seq[string]) =
        case returnCode
        of Success:
          mSelf.replayData = some messages.mapIt (
            nazoPuyo.environment.pairs, it.parsePositions Izumiya)
          mSelf.updateReplaySimulator nazoPuyo
          mSelf.workerRunning = false

          if not kxi.surpressRedraws:
            kxi.redraw
        of Failure:
          discard

      showReplay.initWorker.run $Solve, $nazoPuyo.toUri
    else:
      # FIXME: make asynchronous
      # FIXME: redraw
      mSelf.replayData = some nazoPuyo.solve.mapIt (
        nazoPuyo.environment.pairs, it)
      mSelf.updateReplaySimulator nazoPuyo
      mSelf.workerRunning = false

# ------------------------------------------------
# Permute
# ------------------------------------------------

proc permute*(mSelf; fixMoves: seq[Positive], allowDouble: bool,
              allowLastDouble: bool) {.inline.} =
  ## Permutes the nazo puyo.
  if (mSelf.workerRunning or mSelf.simulator[].kind != Nazo):
    return

  mSelf.workerRunning = true

  mSelf.simulator[].withNazoPuyo:
    when defined(js):
      proc showReplay(returnCode: WorkerReturnCode, messages: seq[string]) =
        case returnCode
        of Success:
          let replayData = collect:
            for i in 0 ..< messages.len div 2:
              (messages[2 * i].parsePairs Izumiya,
               messages[2 * i + 1].parsePositions Izumiya)
          mSelf.replayData = some replayData
          mSelf.updateReplaySimulator nazoPuyo
          mSelf.workerRunning = false

          if not kxi.surpressRedraws:
            kxi.redraw
        of Failure:
          discard

      showReplay.initWorker.run $nazoPuyo.toUri
    else:
      # FIXME: make asynchronous
      # FIXME: redraw
      let permuteRes = collect:
        for (pairs, answer) in nazoPuyo.permute(
            fixMoves, allowDouble, allowLastDouble):
          (pairs, answer)
      mSelf.replayData = some permuteRes
      mSelf.updateReplaySimulator nazoPuyo
      mSelf.workerRunning = false

# ------------------------------------------------
# Replay
# ------------------------------------------------

proc nextReplay*(mSelf) {.inline.} =
  ## Shows the next replay.
  if mSelf.replayData.isNone or mSelf.replayData.get.len == 0:
    return

  if mSelf.replayIdx == mSelf.replayData.get.len.pred:
    mSelf.replayIdx = 0
  else:
    mSelf.replayIdx.inc

  (mSelf.replaySimulator[].pairs, mSelf.replaySimulator[].positions) =
    mSelf.replayData.get[mSelf.replayIdx]
  mSelf.replaySimulator[].reset false

  mSelf.replaySimulator[].originalEnvironments =
    mSelf.replaySimulator[].environments

proc prevReplay*(mSelf) {.inline.} =
  ## Shows the previous replay.
  if mSelf.replayData.isNone or mSelf.replayData.get.len == 0:
    return

  if mSelf.replayIdx == 0:
    mSelf.replayIdx = mSelf.replayData.get.len.pred
  else:
    mSelf.replayIdx.dec

  (mSelf.replaySimulator[].pairs, mSelf.replaySimulator[].positions) =
    mSelf.replayData.get[mSelf.replayIdx]
  mSelf.replaySimulator[].reset false

  mSelf.replaySimulator[].originalEnvironments =
    mSelf.replaySimulator[].environments

# ------------------------------------------------
# Keyboard Operation
# ------------------------------------------------

proc operate*(mSelf; event: KeyEvent): bool {.inline.} =
  ## Handler for keyboard input.
  ## Returns `true` if any action is executed.
  if event == initKeyEvent("KeyQ", shift = true):
    mSelf.toggleFocus
    return true

  if mSelf.focusReplay:
    # move replay
    if event == initKeyEvent("KeyA"):
      mSelf.prevReplay
      return true
    if event == initKeyEvent("KeyD"):
      mSelf.nextReplay
      return true

    return mSelf.replaySimulator[].operate event

  if mSelf.simulator[].mode == Edit:
    # solve
    if event == initKeyEvent("Enter"):
      mSelf.solve
      return true

  return mSelf.simulator[].operate event

# ------------------------------------------------
# Backend-specific Implementation
# ------------------------------------------------

when defined(js):
  import std/[dom, sugar]
  import ../private/app/web/replay/[controller, pagination, simulator]

  # ------------------------------------------------
  # JS - Keyboard Handler
  # ------------------------------------------------

  proc runKeyboardEventHandler*(mSelf; event: KeyEvent) {.inline.} =
    ## Keyboard event handler.
    let needRedraw = mSelf.operate event
    if needRedraw and not kxi.surpressRedraws:
      kxi.redraw

  proc runKeyboardEventHandler*(mSelf; event: dom.Event) {.inline.} =
    ## Keybaord event handler.
    # HACK: somehow this assertion fails
    # assert event of KeyboardEvent
    mSelf.runKeyboardEventHandler cast[KeyboardEvent](event).toKeyEvent

  proc initKeyboardEventHandler*(mSelf): (event: dom.Event) -> void {.inline.} =
    ## Returns the keyboard event handler.
    (event: dom.Event) => mSelf.runKeyboardEventHandler event

  # ------------------------------------------------
  # JS - Node
  # ------------------------------------------------

  proc initEditorPermuterNode(mSelf; id: string): VNode {.inline.} =
    ## Returns the editor&permuter node without the external section.
    ## `id` is shared with other node-creating procedures and need to be unique.
    let simulatorNode = mSelf.simulator[].initSimulatorNode(
      setKeyHandler = false, id = id)

    result = buildHtml(tdiv(class = "columns is-mobile is-variable is-1")):
      tdiv(class = "column is-narrow"):
        simulatorNode
      if mSelf.editor:
        tdiv(class = "column is-narrow"):
          section(class = "section"):
            tdiv(class = "block"):
              mSelf.initReplayControllerNode
            if mSelf.replayData.isSome:
              tdiv(class = "block"):
                mSelf.initReplayPaginationNode
              if mSelf.replayData.isSome:
                tdiv(class = "block"):
                  mSelf.initReplaySimulatorNode

  proc initEditorPermuterNode*(mSelf; setKeyHandler = true, wrapSection = true,
                               id = ""): VNode {.inline.} =
    ## Returns the editor&permuter node.
    ## `id` is shared with other node-creating procedures and need to be unique.
    if setKeyHandler:
      document.onkeydown = mSelf.initKeyboardEventHandler

    if wrapSection:
      result = buildHtml(section(class = "section")):
        mSelf.initEditorPermuterNode id
    else:
      result = mSelf.initEditorPermuterNode id

  proc initEditorPermuterNode*[F: TsuField or WaterField](
      nazoEnv: NazoPuyo[F] or Environment[F], positions: Positions, mode = Play,
      editor = false, setKeyHandker = true, wrapSection = true, id = ""): VNode
      {.inline.} =
    ## Returns the editor&permuter node.
    ## `id` is shared with other node-creating procedures and need to be unique.
    var editorPermuter = nazoEnv.initEditorPermuter(positions, mode, editor)
    result = editorPermuter.initEditorPermuterNode(setKeyHandker, wrapSection,
                                                   id)

  proc initEditorPermuterNode*[F: TsuField or WaterField](
      nazoEnv: NazoPuyo[F] or Environment[F], mode = Play, editor = false,
      setKeyHandker = true, wrapSection = true, id = ""): VNode {.inline.} =
    ## Returns the editor&permuter node.
    ## `id` is shared with other node-creating procedures and need to be unique.
    var editorPermuter = nazoEnv.initEditorPermuter(mode, editor)
    result = editorPermuter.initEditorPermuterNode(setKeyHandker, wrapSection,
                                                   id)
else:
  import ../private/app/native/replay/[controller, pagination, simulator]

  type
    EditorPermuterControl* = ref object of LayoutContainer
      ## Root control of the editor&permuter.
      editorPermuter*: ref EditorPermuter

    EditorPermuterWindow* = ref object of WindowImpl
      ## Application window for the editor&permuter.
      editorPermuter*: ref EditorPermuter

  # ------------------------------------------------
  # Native - Keyboard Handler
  # ------------------------------------------------

  proc runKeyboardEventHandler*(
      window: EditorPermuterWindow, event: KeyboardEvent,
      keys = downKeys()) {.inline.} =
    ## Keyboard event handler.
    let needRedraw = window.editorPermuter[].operate event.toKeyEvent keys
    if needRedraw:
      event.window.control.forceRedraw

  proc keyboardEventHandler(event: KeyboardEvent) =
    ## Keyboard event handler.
    let rawWindow = event.window
    assert rawWindow of EditorPermuterWindow

    cast[EditorPermuterWindow](rawWindow).runKeyboardEventHandler event

  func initKeyboardEventHandler*: (event: KeyboardEvent) -> void {.inline.} =
    ## Returns the keyboard event handler.
    keyboardEventHandler

  # ------------------------------------------------
  # Native - Control
  # ------------------------------------------------

  proc initEditorPermuterControl*(editorPermuter: ref EditorPermuter):
      EditorPermuterControl {.inline.} =
    ## Returns the editor&permuter control.
    result = new EditorPermuterControl
    result.init
    result.layout = Layout_Horizontal

    result.editorPermuter = editorPermuter

    # col=0
    let simulatorControl = editorPermuter[].simulator.initSimulatorControl
    result.add simulatorControl

    # col=1
    let secondCol = newLayoutContainer Layout_Vertical
    result.add secondCol

    secondCol.padding = 10.scaleToDpi
    secondCol.spacing = 10.scaleToDpi

    secondCol.add editorPermuter.initReplayControllerControl
    secondCol.add editorPermuter.initReplayPaginationControl
    secondCol.add editorPermuter.initReplaySimulatorControl

  proc initEditorPermuterWindow*(
      editorPermuter: ref EditorPermuter, title = "Pon!通",
      setKeyHandler = true): EditorPermuterWindow {.inline.} =
    ## Returns the editor&permuter window.
    result = new EditorPermuterWindow
    result.init

    result.editorPermuter = editorPermuter

    result.title = title
    result.resizable = false
    if setKeyHandler:
      result.onKeyDown = keyboardEventHandler

    let rootControl = editorPermuter.initEditorPermuterControl
    result.add rootControl

    when defined(windows):
      # HACK: somehow this adjustment is needed on Windows
      # TODO: better implementation
      result.width = (rootControl.naturalWidth.float * 1.1).int
      result.height = (rootControl.naturalHeight.float * 1.1).int
    else:
      result.width = rootControl.naturalWidth
      result.height = rootControl.naturalHeight
