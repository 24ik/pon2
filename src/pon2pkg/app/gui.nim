## This module implements the GUI application.
##

{.experimental: "strictDefs".}
{.experimental: "strictFuncs".}
{.experimental: "views".}

import std/[options, sequtils]
import ./[color, key, nazopuyo, simulator]
import
  ../core/[field, misc, nazopuyo, pair, pairposition, position, puyopuyo, requirement]
import ../private/[misc]

when defined(js):
  import std/[sugar, uri]
  import karax/[karax, karaxdsl, kdom, vdom]
  import ../private/[webworker]
  import ../private/app/[permute]
  import ../private/app/gui/web/[webworker]
else:
  {.push warning[Deprecated]: off.}
  import std/[cpuinfo, sugar, threadpool]
  import nigui
  import ./[permute, solve]
  {.pop.}

type GuiApplication* = object ## GUI application.
  simulator*: ref Simulator
  replaySimulator*: ref Simulator

  replayPairsPositions*: Option[PairsPositions]
  replayIdx*: Natural

  editor: bool
  focusEditor*: bool
  solving*: bool
  permuting*: bool

  when defined(js):
    progressBarData*: tuple[now: Natural, total: Natural]

using
  self: EditorPermuter
  mSelf: var EditorPermuter

# ------------------------------------------------
# Constructor
# ------------------------------------------------

const DefaultReq = Requirement(kind: Clear, color: RequirementColor.All, number: 0)

func initGuiApplication*(
    nazoPuyoWrap: NazoPuyoWrap, mode = Play, editor = false
): GuiApplication {.inline.} =
  ## Returns a new GUI application.
  ## If `mode` is `Edit`, `editor` will be ignored (*i.e.*, regarded as `true`).
  result.simulator = new Simulator
  result.simulator[] = nazoPuyoWrap.initSimulator(mode, editor)
  result.replaySimulator = new Simulator
  result.replaySimulator[] = nazoPuyoWrap.initSimulator(Replay, true)

  {.push warning[ProveInit]: off.}
  result.replayPairsPositions = none PairsPositions
  {.pop.}
  result.replayIdx = 0

  result.editor = editor or mode == Edit
  result.focusEditor = false
  result.solving = false
  result.permuting = false

  when defined(js):
    result.progressBarData.now = 0
    result.progressBarData.total = 0

func initGuiApplication*[F: TsuField or WaterField](
    nazo: NazoPuyo[F], mode = Play, editor = false
): GuiApplication {.inline.} =
  ## Returns a new GUI application.
  ## If `mode` is `Edit`, `editor` will be ignored (*i.e.*, regarded as `true`).
  initNazoPuyoWrap(nazo).initGuiApplication(mode, editor)

func initGuiApplication*[F: TsuField or WaterField](
    puyoPuyo: PuyoPuyo[F], mode = Play, editor = false
): GuiApplication {.inline.} =
  ## Returns a new GUI application.
  ## If `mode` is `Edit`, `editor` will be ignored (*i.e.*, regarded as `true`).
  NazoPuyo[F](puyoPuyo: puyoPuyo, requirement: DefaultReq).initGuiApplication(
    mode, editor
  )

# ------------------------------------------------
# Edit - Other
# ------------------------------------------------

func toggleFocus*(mSelf) {.inline.} = ## Toggles focusing to editor tab or not.
  mSelf.focusEditor.toggle

# ------------------------------------------------
# Solve
# ------------------------------------------------

when defined(js):
  const ResultMonitorIntervalMs = 100

func updateReplaySimulator[F: TsuField or WaterField](
    mSelf; nazo: NazoPuyo[F]
) {.inline.} =
  ## Updates the replay simulator.
  ## This function is assumed to be called after `mSelf.replayPairsPositions` is set.
  assert mSelf.replayPairsPositions.isSome

  if mSelf.replayPairsPositions.get.len > 0:
    mSelf.focusEditor = true
    mSelf.replayIdx = 0

    var nazo2 = nazo
    nazo2.puyoPuyo.pairsPositions = mSelf.replayPairsPositions.get[0]
    mSelf.replaySimulator[] =
      nazo2.initSimulator(mSelf.replaySimulator[].mode, mSelf.replaySimulator[].editor)
  else:
    mSelf.focusEditor = false

proc solve*(
    mSelf;
    parallelCount: Positive =
      when defined(js):
        6
      else:
        max(1, countProcessors())
    ,
) {.inline.} =
  ## Solves the nazo puyo.
  if mSelf.solving or mSelf.permuting or mSelf.simulator[].kind != Nazo:
    return

  mSelf.solving = true

  mSelf.simulator[].nazoPuyoWrap.flattenAnd:
    when defined(js):
      {.push warning[ProveInit]: off.}
      var results = @[none seq[PairsPositions]]
      {.pop.}
      nazoPuyo.asyncSolve(results, parallelCount = parallelCount)

      mSelf.progressBarData.total =
        if mSelf.simulator[].nazoPuyoWrap.pairsPositions[0].pair.isDouble:
          field.validDoublePositions.len
        else:
          field.validPositions.len
      mSelf.progressBarData.now = 0

      var interval: Interval
      proc showReplay() =
        mSelf.progressBarData.now = results.len.pred
        if results.allIt it.isSome:
          mSelf.progressBarData.total = 0
          mSelf.replayData = some results.mapIt(it.get).concat
          mSelf.updateReplaySimulator nazoPuyo
          mSelf.solving = false
          interval.clearInterval

        if not kxi.surpressRedraws:
          kxi.redraw

      interval = showReplay.setInterval ResultMonitorIntervalMs
    else:
      # FIXME: make asynchronous
      # FIXME: redraw
      mSelf.replayData = some nazoPuyo.solve(parallelCount = parallelCount)
      mSelf.updateReplaySimulator nazoPuyo
      mSelf.solving = false

# ------------------------------------------------
# Permute
# ------------------------------------------------

proc permute*(
    mSelf;
    fixMoves: seq[Positive],
    allowDouble: bool,
    allowLastDouble: bool,
    parallelCount =
      when defined(js):
        6
      else:
        max(1, countProcessors())
    ,
) {.inline.} =
  ## Permutes the nazo puyo.
  if mSelf.solving or mSelf.permuting or mSelf.simulator[].kind != Nazo:
    return

  mSelf.permuting = true

  mSelf.simulator[].nazoPuyoWrap.flattenAnd:
    when defined(js):
      {.push warning[ProveInit]: off.}
      var results = @[none PairsPositions]
      {.pop.}
      nazoPuyo.asyncPermute(
        results, fixMoves, allowDouble, allowLastDouble, parallelCount
      )

      mSelf.progressBarData.total =
        nazoPuyo.allPairsPositionsSeq(fixMoves, allowDouble, allowLastDouble).len
      mSelf.progressBarData.now = 0

      var interval: Interval
      proc showReplay() =
        mSelf.progressBarData.now = results.len.pred
        if results.allIt it.isSome:
          mSelf.progressBarData.total = 0
          mSelf.replayPairsPositions = some results.mapIt(it.get)
          mSelf.updateReplaySimulator nazoPuyo
          mSelf.permuting = false
          interval.clearInterval

        if not kxi.surpressRedraws:
          kxi.redraw

      interval = showReplay.setInterval ResultMonitorIntervalMs
    else:
      # FIXME: make asynchronous
      # FIXME: redraw
      mSelf.replayData = some nazoPuyo.permute(fixMoves, allowDouble, allowLastDouble)
      mSelf.updateReplaySimulator nazoPuyo
      mSelf.permuting = false

# ------------------------------------------------
# Replay
# ------------------------------------------------

proc nextReplay*(mSelf) {.inline.} =
  ## Shows the next replay.
  if mSelf.replayPairsPositions.isNone or mSelf.replayPairsPositions.get.len == 0:
    return

  if mSelf.replayIdx == mSelf.replayPairsPositions.get.len.pred:
    mSelf.replayIdx = 0
  else:
    mSelf.replayIdx.inc

  mSelf.replaySimulator[].nazoPuyoWrap.pairsPositions =
    mSelf.replayPairsPositions.get[mSelf.replayIdx]
  mSelf.replaySimulator[].originalNazoPuyoWrap.pairsPositions =
    mSelf.replayPairsPositions.get[mSelf.replayIdx]
  mSelf.replaySimulator[].reset false

proc prevReplay*(mSelf) {.inline.} =
  ## Shows the previous replay.
  if mSelf.replayPairsPositions.isNone or mSelf.replayPairsPositions.get.len == 0:
    return

  if mSelf.replayIdx == 0:
    mSelf.replayIdx = mSelf.replayPairsPositions.get.len.pred
  else:
    mSelf.replayIdx.dec

  mSelf.replaySimulator[].nazoPuyoWrap.pairsPositions =
    mSelf.replayPairsPositions.get[mSelf.replayIdx]
  mSelf.replaySimulator[].originalNazoPuyoWrap.pairsPositions =
    mSelf.replayPairsPositions.get[mSelf.replayIdx]
  mSelf.replaySimulator[].reset false

# ------------------------------------------------
# Keyboard Operation
# ------------------------------------------------

proc operate*(mSelf; event: KeyEvent): bool {.inline.} =
  ## Does operation specified by the keyboard input.
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
  import
    ../private/app/editorpermuter/web/editor/
      [controller, pagination, settings, progress, simulator]

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
    let simulatorNode =
      mSelf.simulator[].initSimulatorNode(setKeyHandler = false, id = id)

    result = buildHtml(tdiv(class = "columns is-mobile is-variable is-1")):
      tdiv(class = "column is-narrow"):
        simulatorNode
      if mSelf.editor and mSelf.simulator[].kind == Nazo:
        tdiv(class = "column is-narrow"):
          section(class = "section"):
            tdiv(class = "block"):
              mSelf.initEditorControllerNode id
            tdiv(class = "block"):
              mSelf.initEditorSettingsNode id
            if mSelf.progressBarData.total > 0:
              mSelf.initEditorProgressBarNode
            if mSelf.replayData.isSome:
              tdiv(class = "block"):
                mSelf.initEditorPaginationNode
              if mSelf.replayData.get.len > 0:
                tdiv(class = "block"):
                  mSelf.initEditorSimulatorNode

  proc initEditorPermuterNode*(
      mSelf; setKeyHandler = true, wrapSection = true, id = ""
  ): VNode {.inline.} =
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
      nazoEnv: NazoPuyo[F] or Environment[F],
      positions: Positions,
      mode = Play,
      editor = false,
      setKeyHandker = true,
      wrapSection = true,
      id = "",
  ): VNode {.inline.} =
    ## Returns the editor&permuter node.
    ## `id` is shared with other node-creating procedures and need to be unique.
    var editorPermuter = nazoEnv.initEditorPermuter(positions, mode, editor)
    result = editorPermuter.initEditorPermuterNode(setKeyHandker, wrapSection, id)

  proc initEditorPermuterNode*[F: TsuField or WaterField](
      nazoEnv: NazoPuyo[F] or Environment[F],
      mode = Play,
      editor = false,
      setKeyHandker = true,
      wrapSection = true,
      id = "",
  ): VNode {.inline.} =
    ## Returns the editor&permuter node.
    ## `id` is shared with other node-creating procedures and need to be unique.
    var editorPermuter = nazoEnv.initEditorPermuter(mode, editor)
    result = editorPermuter.initEditorPermuterNode(setKeyHandker, wrapSection, id)

else:
  import ../private/app/editorpermuter/native/editor/[controller, pagination, simulator]

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
      window: EditorPermuterWindow, event: KeyboardEvent, keys = downKeys()
  ) {.inline.} =
    ## Keyboard event handler.
    let needRedraw = window.editorPermuter[].operate event.toKeyEvent keys
    if needRedraw:
      event.window.control.forceRedraw

  proc keyboardEventHandler(event: KeyboardEvent) =
    ## Keyboard event handler.
    let rawWindow = event.window
    assert rawWindow of EditorPermuterWindow

    cast[EditorPermuterWindow](rawWindow).runKeyboardEventHandler event

  func initKeyboardEventHandler*(): (event: KeyboardEvent) -> void {.inline.} =
    ## Returns the keyboard event handler.
    keyboardEventHandler

  # ------------------------------------------------
  # Native - Control
  # ------------------------------------------------

  proc initEditorPermuterControl*(
      editorPermuter: ref EditorPermuter
  ): EditorPermuterControl {.inline.} =
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
      editorPermuter: ref EditorPermuter, title = "Pon!通", setKeyHandler = true
  ): EditorPermuterWindow {.inline.} =
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
