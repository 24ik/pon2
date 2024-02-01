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
  import std/[strformat, sugar, uri]
  import karax/[karax, karaxdsl, kdom, vdom]
  import nuuid
  import ../private/[lock, webworker]
  import ../private/app/editorpermuter/web/editor/[webworker]
else:
  {.push warning[Deprecated]: off.}
  import std/[sugar, threadpool]
  import nigui
  import ../nazopuyopkg/[permute, solve]
  {.pop.}

type EditorPermuter* = object
  ## Editor and Permuter.
  simulator*: ref Simulator
  replaySimulator*: ref Simulator

  replayData*: Option[seq[tuple[pairs: Pairs, positions: Positions]]]
  replayIdx*: Natural

  editor: bool
  focusEditor*: bool
  solving*: bool
  permuting*: bool

  when defined(js):
    solveThreadInterval: Interval

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
  result.focusEditor = false
  result.solving = false
  result.permuting = false

  when defined(js):
    result.solveThreadInterval = Interval()

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
  result.focusEditor = false
  result.solving = false
  result.permuting = false

  when defined(js):
    result.solveThreadInterval = Interval()

proc initEditorPermuter*[F: TsuField or WaterField](
    nazo: NazoPuyo[F], mode = Play, editor = false): EditorPermuter {.inline.} =
  ## Returns a new `EditorManager`.
  ## If `mode` is `Edit`, `editor` will be ignored (*i.e.*, regarded as `true`).
  nazo.initEditorPermuter(Position.none.repeat nazo.moveCount, mode, editor)

# ------------------------------------------------
# Edit - Other
# ------------------------------------------------

func toggleFocus*(mSelf) {.inline.} = mSelf.focusEditor.toggle
  ## Toggles focusing to editor tab or not.

# ------------------------------------------------
# Solve
# ------------------------------------------------

when defined(js):
  const
    LockNamePrefix = "pon2-editorpermuter-lock"
    ResultMonitorIntervalMs = 100
    AllPositionsSeq = collect:
      for pos in AllPositions:
        pos

proc updateReplaySimulator[F: TsuField or WaterField](mSelf; nazo: NazoPuyo[F])
                 {.inline.} =
  ## Updates the replay simulator.
  ## This function is assumed to be called after `mSelf.replayData` is set.
  assert mSelf.replayData.isSome

  if mSelf.replayData.get.len > 0:
    mSelf.focusEditor = true
    mSelf.replayIdx = 0

    var nazo2 = nazo
    nazo2.environment.pairs = mSelf.replayData.get[0].pairs
    mSelf.replaySimulator[] = nazo2.initSimulator(
      mSelf.replayData.get[0].positions, mSelf.replaySimulator[].mode,
      mSelf.replaySimulator[].editor)
  else:
    mSelf.focusEditor = false

proc solve*(mSelf; parallelCount: Positive = 12) {.inline.} =
  ## Solves the nazo puyo.
  ## `parallelCount` will be ignored on non-JS backend.
  if mSelf.solving or mSelf.permuting or mSelf.simulator[].kind != Nazo:
    return

  mSelf.solving = true

  mSelf.simulator[].withNazoPuyo:
    when defined(js):
      # NOTE: I think `results` should be alive after this this procedure
      # finished so should be global (e.g. EditorPermuter's field), but somehow
      # local `results` works.
      var results = @[none Positions].toAtomic2
      nazoPuyo.asyncSolve results

      proc showReplay =
        if results[].allIt it.isSome:
          mSelf.replayData = some results[].concat.mapIt (
            nazoPuyo.environment.pairs, it.get)
          mSelf.updateReplaySimulator nazoPuyo
          mSelf.solving = false
          mSelf.solveThreadInterval.clearInterval

          if not kxi.surpressRedraws:
            kxi.redraw
      mSelf.solveThreadInterval = showReplay.setInterval ResultMonitorIntervalMs
    else:
      # FIXME: make asynchronous
      # FIXME: redraw
      mSelf.replayData = some nazoPuyo.solve.mapIt (
        nazoPuyo.environment.pairs, it)
      mSelf.updateReplaySimulator nazoPuyo
      mSelf.solving = false

# ------------------------------------------------
# Permute
# ------------------------------------------------

proc permute*(mSelf; fixMoves: seq[Positive], allowDouble: bool,
              allowLastDouble: bool) {.inline.} =
  ## Permutes the nazo puyo.
  if mSelf.solving or mSelf.permuting or mSelf.simulator[].kind != Nazo:
    return

  mSelf.permuting = true

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
          mSelf.permuting = false

          if not kxi.surpressRedraws:
            kxi.redraw
        of Failure:
          discard

      var worker = initWorker()
      worker.completeHandler = showReplay
      worker.run @[$Permute, $nazoPuyo.toUri, $allowDouble, $allowLastDouble] &
          fixMoves.mapIt $it
    else:
      # FIXME: make asynchronous
      # FIXME: redraw
      let permuteRes = collect:
        for (pairs, answer) in nazoPuyo.permute(
            fixMoves, allowDouble, allowLastDouble):
          (pairs, answer)
      mSelf.replayData = some permuteRes
      mSelf.updateReplaySimulator nazoPuyo
      mSelf.permuting = false

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

  mSelf.replaySimulator[].pairs = mSelf.replayData.get[mSelf.replayIdx].pairs
  mSelf.replaySimulator[].originalPairs =
    mSelf.replayData.get[mSelf.replayIdx].pairs
  mSelf.replaySimulator[].positions =
    mSelf.replayData.get[mSelf.replayIdx].positions

  mSelf.replaySimulator[].reset false

proc prevReplay*(mSelf) {.inline.} =
  ## Shows the previous replay.
  if mSelf.replayData.isNone or mSelf.replayData.get.len == 0:
    return

  if mSelf.replayIdx == 0:
    mSelf.replayIdx = mSelf.replayData.get.len.pred
  else:
    mSelf.replayIdx.dec

  mSelf.replaySimulator[].pairs = mSelf.replayData.get[mSelf.replayIdx].pairs
  mSelf.replaySimulator[].originalPairs =
    mSelf.replayData.get[mSelf.replayIdx].pairs
  mSelf.replaySimulator[].positions =
    mSelf.replayData.get[mSelf.replayIdx].positions

  mSelf.replaySimulator[].reset false

# ------------------------------------------------
# Keyboard Operation
# ------------------------------------------------

proc operate*(mSelf; event: KeyEvent): bool {.inline.} =
  ## Handler for keyboard input.
  ## Returns `true` if any action is executed.
  if event == initKeyEvent("KeyQ", shift = true):
    mSelf.toggleFocus
    return true

  if mSelf.focusEditor:
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
  import std/[dom]
  import ../private/app/editorpermuter/web/editor/[
    controller, pagination, permute as webPermute, simulator]

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
      if mSelf.editor and mSelf.simulator[].kind == Nazo:
        tdiv(class = "column is-narrow"):
          section(class = "section"):
            tdiv(class = "block"):
              mSelf.initEditorControllerNode id
            tdiv(class = "block"):
              mSelf.initEditorPermuteNode id
            if mSelf.replayData.isSome:
              tdiv(class = "block"):
                mSelf.initEditorPaginationNode
              if mSelf.replayData.get.len > 0:
                tdiv(class = "block"):
                  mSelf.initEditorSimulatorNode

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
  import ../private/app/editorpermuter/native/editor/[
    controller, pagination, simulator]

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

    secondCol.add editorPermuter.initEditorControllerControl
    secondCol.add editorPermuter.initEditorPaginationControl
    secondCol.add editorPermuter.initEditorSimulatorControl

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
