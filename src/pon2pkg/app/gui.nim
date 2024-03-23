## This module implements the GUI application.
##

{.experimental: "strictDefs".}
{.experimental: "strictFuncs".}
{.experimental: "views".}

import std/[sequtils]
import ./[key, nazopuyo, simulator]
import ../core/[field, nazopuyo, pairposition, puyopuyo, requirement]
import ../private/[misc]

when defined(js):
  import std/[options, sugar]
  import karax/[karax, karaxdsl, kdom, vdom]
  import ../core/[pair]
  import ../private/[webworker]
  import ../private/app/[permute]
  import ../private/app/gui/web/[webworker]
else:
  {.push warning[Deprecated]: off.}
  import std/[cpuinfo, sugar, threadpool]
  import nigui
  import ./[permute, solve]
  {.pop.}

type
  GuiApplicationReplay* = object ## Pairs&Positions for the replay simulator.
    hasData*: bool
    pairsPositionsSeq*: seq[PairsPositions]
    index*: Natural

  GuiApplication* = object ## GUI application.
    simulator*: ref Simulator
    replaySimulator*: ref Simulator

    replay: GuiApplicationReplay

    editor: bool
    focusEditor: bool
    solving: bool
    permuting: bool

    progressBar: tuple[now: Natural, total: Natural]

using
  self: GuiApplication
  mSelf: var GuiApplication

# ------------------------------------------------
# Constructor
# ------------------------------------------------

proc initGuiApplication*(simulator: Simulator): GuiApplication {.inline.} =
  ## Returns a new GUI application.
  result.simulator = new Simulator
  result.simulator[] = simulator
  result.replaySimulator = new Simulator
  result.replaySimulator[] = simulator

  result.replay.hasData = false
  result.replay.pairsPositionsSeq = @[]
  result.replay.index = 0

  result.editor = simulator.editor
  result.focusEditor = false
  result.solving = false
  result.permuting = false

  result.progressBar.now = 0
  result.progressBar.total = 0

# ------------------------------------------------
# Property
# ------------------------------------------------

func replay*(self): GuiApplicationReplay {.inline.} =
  ## Returns the pairs&positions for the replay simulator.
  self.replay

func focusEditor*(self): bool {.inline.} =
  ## Returns `true` if the editor simulator is focused.
  self.focusEditor

func solving*(self): bool {.inline.} =
  ## Returns `true` if a nazo puyo is being solved.
  self.solving

func permuting*(self): bool {.inline.} =
  ## Returns `true` if a nazo puyo is being permuted.
  self.permuting

func progressBar*(self): tuple[now: int, total: int] {.inline.} =
  ## Returns the progress bar information.
  result.now = self.progressBar.now
  result.total = self.progressBar.total

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

proc updateReplaySimulator[F: TsuField or WaterField](
    mSelf; nazo: NazoPuyo[F]
) {.inline.} =
  ## Updates the replay simulator.
  ## This function is assumed to be called after `mSelf.replay.pairsPositionsSeq` is set.
  assert mSelf.replay.hasData

  if mSelf.replay.pairsPositionsSeq.len > 0:
    mSelf.focusEditor = true
    mSelf.replay.index = 0

    var nazo2 = nazo
    nazo2.puyoPuyo.pairsPositions = mSelf.replay.pairsPositionsSeq[0]
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

  mSelf.simulator[].nazoPuyoWrap.get:
    when defined(js):
      {.push warning[ProveInit]: off.}
      var results = @[none seq[PairsPositions]]
      {.pop.}
      wrappedNazoPuyo.asyncSolve(results, parallelCount = parallelCount)

      mSelf.progressBar.total =
        if wrappedNazoPuyo.puyoPuyo.pairsPositions[0].pair.isDouble:
          wrappedNazoPuyo.puyoPuyo.field.validDoublePositions.card
        else:
          wrappedNazoPuyo.puyoPuyo.field.validPositions.card
      mSelf.progressBar.now = 0

      var interval: Interval
      proc showReplay() =
        mSelf.progressBar.now = results.len.pred
        if results.allIt it.isSome:
          mSelf.progressBar.total = 0
          mSelf.replay.hasData = true
          mSelf.replay.pairsPositionsSeq = results.mapIt(it.get).concat
          mSelf.updateReplaySimulator wrappedNazoPuyo
          mSelf.solving = false
          interval.clearInterval

        if not kxi.surpressRedraws:
          kxi.redraw

      interval = showReplay.setInterval ResultMonitorIntervalMs
    else:
      # FIXME: make asynchronous, redraw
      mSelf.replay.hasData = true
      mSelf.replay.pairsPositionsSeq =
        wrappedNazoPuyo.solve(parallelCount = parallelCount)
      mSelf.updateReplaySimulator wrappedNazoPuyo
      mSelf.solving = false

# ------------------------------------------------
# Permute
# ------------------------------------------------

{.push warning[Uninit]: off.}
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

  mSelf.simulator[].nazoPuyoWrap.get:
    when defined(js):
      {.push warning[ProveInit]: off.}
      var results = @[none PairsPositions]
      {.pop.}
      wrappedNazoPuyo.asyncPermute(
        results, fixMoves, allowDouble, allowLastDouble, parallelCount
      )

      mSelf.progressBar.total =
        wrappedNazoPuyo.allPairsPositionsSeq(fixMoves, allowDouble, allowLastDouble).len
      mSelf.progressBar.now = 0

      var interval: Interval
      proc showReplay() =
        mSelf.progressBar.now = results.len.pred
        if results.allIt it.isSome:
          mSelf.progressBar.total = 0
          mSelf.replay.pairsPositionsSeq = results.mapIt(it.get)
          mSelf.updateReplaySimulator wrappedNazoPuyo
          mSelf.permuting = false
          interval.clearInterval

        if not kxi.surpressRedraws:
          kxi.redraw

      interval = showReplay.setInterval ResultMonitorIntervalMs
    else:
      # FIXME: make asynchronous, redraw
      mSelf.replay.pairsPositionsSeq =
        wrappedNazoPuyo.permute(fixMoves, allowDouble, allowLastDouble).toSeq
      mSelf.updateReplaySimulator wrappedNazoPuyo
      mSelf.permuting = false

{.pop.}

# ------------------------------------------------
# Replay
# ------------------------------------------------

proc nextReplay*(mSelf) {.inline.} =
  ## Shows the next replay.
  if not mSelf.replay.hasData or mSelf.replay.pairsPositionsSeq.len == 0:
    return

  if mSelf.replay.index == mSelf.replay.pairsPositionsSeq.len.pred:
    mSelf.replay.index = 0
  else:
    mSelf.replay.index.inc

  mSelf.replaySimulator[].pairsPositions =
    mSelf.replay.pairsPositionsSeq[mSelf.replay.index]
  mSelf.replaySimulator[].reset false

proc prevReplay*(mSelf) {.inline.} =
  ## Shows the previous replay.
  if not mSelf.replay.hasData or mSelf.replay.pairsPositionsSeq.len == 0:
    return

  if mSelf.replay.index == 0:
    mSelf.replay.index = mSelf.replay.pairsPositionsSeq.len.pred
  else:
    mSelf.replay.index.dec

  mSelf.replaySimulator[].pairsPositions =
    mSelf.replay.pairsPositionsSeq[mSelf.replay.index]
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
  import ../private/app/gui/web/[controller, pagination, settings, progress, simulator]

  # ------------------------------------------------
  # JS - Keyboard Handler
  # ------------------------------------------------

  proc runKeyboardEventHandler*(mSelf; event: KeyEvent) {.inline.} =
    ## Runs the keyboard event handler.
    let needRedraw = mSelf.operate event
    if needRedraw and not kxi.surpressRedraws:
      kxi.redraw

  proc runKeyboardEventHandler*(mSelf; event: Event) {.inline.} =
    ## Keybaord event handler.
    # assert event of KeyboardEvent # HACK: somehow this assertion fails
    mSelf.runKeyboardEventHandler cast[KeyboardEvent](event).toKeyEvent

  proc initKeyboardEventHandler*(mSelf): (event: Event) -> void {.inline.} =
    ## Returns the keyboard event handler.
    (event: dom.Event) => mSelf.runKeyboardEventHandler event

  # ------------------------------------------------
  # JS - Node
  # ------------------------------------------------

  proc initGuiApplicationNode(mSelf; id: string): VNode {.inline.} =
    ## Returns the GUI application without the external section.
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
            if mSelf.progressBar.total > 0:
              mSelf.initEditorProgressBarNode
            if mSelf.replay.hasData:
              tdiv(class = "block"):
                mSelf.initEditorPaginationNode
              if mSelf.replay.pairsPositionsSeq.len > 0:
                tdiv(class = "block"):
                  mSelf.initEditorSimulatorNode

  proc initGuiApplicationNode*(
      mSelf; setKeyHandler = true, wrapSection = true, id = ""
  ): VNode {.inline.} =
    ## Returns the GUI application node.
    ## `id` is shared with other node-creating procedures and need to be unique.
    if setKeyHandler:
      document.onkeydown = mSelf.initKeyboardEventHandler

    if wrapSection:
      result = buildHtml(section(class = "section")):
        mSelf.initGuiApplicationNode id
    else:
      result = mSelf.initGuiApplicationNode id

else:
  import ../private/app/gui/native/[controller, pagination, simulator]

  type
    GuiApplicationControl* = ref object of LayoutContainer
      ## Root control of the GUI application.
      guiApplication*: ref GuiApplication

    GuiApplicationWindow* = ref object of WindowImpl ## Application window.
      guiApplication*: ref GuiApplication

  # ------------------------------------------------
  # Native - Keyboard Handler
  # ------------------------------------------------

  proc runKeyboardEventHandler*(
      window: GuiApplicationWindow, event: KeyboardEvent, keys = downKeys()
  ) {.inline.} =
    ## Runs the keyboard event handler.
    let needRedraw = window.guiApplication[].operate event.toKeyEvent keys
    if needRedraw:
      event.window.control.forceRedraw

  proc runKeyboardEventHandler(event: KeyboardEvent) =
    ## Keyboard event handler.
    let rawWindow = event.window
    assert rawWindow of GuiApplicationWindow

    cast[GuiApplicationWindow](rawWindow).runKeyboardEventHandler event

  func initKeyboardEventHandler*(): (event: KeyboardEvent) -> void {.inline.} =
    ## Returns the keyboard event handler.
    runKeyboardEventHandler

  # ------------------------------------------------
  # Native - Control
  # ------------------------------------------------

  proc initGuiApplicationControl*(
      guiApplication: ref GuiApplication
  ): GuiApplicationControl {.inline.} =
    ## Returns the GUI application control.
    result = new GuiApplicationControl
    result.init
    result.layout = Layout_Horizontal

    result.guiApplication = guiApplication

    # col=0
    let simulatorControl = guiApplication[].simulator.initSimulatorControl
    result.add simulatorControl

    # col=1
    let secondCol = newLayoutContainer Layout_Vertical
    result.add secondCol

    secondCol.padding = 10.scaleToDpi
    secondCol.spacing = 10.scaleToDpi

    secondCol.add guiApplication.initEditorControllerControl
    secondCol.add guiApplication.initEditorPaginationControl
    secondCol.add guiApplication.initEditorSimulatorControl

  proc initGuiApplicationWindow*(
      guiApplication: ref GuiApplication, title = "Pon!通", setKeyHandler = true
  ): GuiApplicationWindow {.inline.} =
    ## Returns the GUI application window.
    result = new GuiApplicationWindow
    result.init

    result.guiApplication = guiApplication

    result.title = title
    result.resizable = false
    if setKeyHandler:
      result.onKeyDown = runKeyboardEventHandler

    let rootControl = guiApplication.initGuiApplicationControl
    result.add rootControl

    when defined(windows):
      # FIXME: ad hoc adjustment needed on Windows and need improvement
      result.width = (rootControl.naturalWidth.float * 1.1).int
      result.height = (rootControl.naturalHeight.float * 1.1).int
    else:
      result.width = rootControl.naturalWidth
      result.height = rootControl.naturalHeight
