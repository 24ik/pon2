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
  GuiApplicationAnswer* = object ## Pairs&Positions for the answer simulator.
    hasData*: bool
    pairsPositionsSeq*: seq[PairsPositions]
    index*: Natural

  GuiApplication* = object ## GUI application.
    simulator: ref Simulator
    answerSimulator: ref Simulator

    answer: GuiApplicationAnswer

    focusAnswer: bool
    solving: bool
    permuting: bool

    progressBar: tuple[now: Natural, total: Natural]

using
  self: GuiApplication
  mSelf: var GuiApplication
  rSelf: ref GuiApplication

# ------------------------------------------------
# Constructor
# ------------------------------------------------

proc initGuiApplication*(simulator: ref Simulator): GuiApplication {.inline.} =
  ## Returns a new GUI application.
  result.simulator = simulator
  result.answerSimulator.new
  result.answerSimulator[] = initNazoPuyo[TsuField]().initSimulator View

  result.answer.hasData = false
  result.answer.pairsPositionsSeq = @[]
  result.answer.index = 0

  result.focusAnswer = false
  result.solving = false
  result.permuting = false

  result.progressBar.now = 0
  result.progressBar.total = 0

proc initGuiApplication*(): GuiApplication {.inline.} =
  ## Returns a new GUI application.
  let simulator = new Simulator
  simulator[] = initNazoPuyo[TsuField]().initSimulator PlayEditor

  result = simulator.initGuiApplication

# ------------------------------------------------
# Property
# ------------------------------------------------

func simulator*(self): Simulator {.inline.} =
  ## Returns the simulator.
  self.simulator[].copy

func simulatorRef*(mSelf): ref Simulator {.inline.} =
  ## Returns the reference to the simulator.
  mSelf.simulator

func answerSimulator*(self): Simulator {.inline.} =
  ## Returns the answer simulator.
  self.answerSimulator[].copy

func answerSimulatorRef*(mSelf): ref Simulator {.inline.} =
  ## Returns the reference to the answer simulator.
  mSelf.answerSimulator

func answer*(self): GuiApplicationAnswer {.inline.} =
  ## Returns the pairs&positions for the answer simulator.
  self.answer

func focusAnswer*(self): bool {.inline.} =
  ## Returns `true` if the answer simulator is focused.
  self.focusAnswer

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

func toggleFocus*(mSelf) {.inline.} = ## Toggles focusing to answer simulator or not.
  mSelf.focusAnswer.toggle

# ------------------------------------------------
# Solve
# ------------------------------------------------

when defined(js):
  const ResultMonitorIntervalMs = 100

proc updateAnswerSimulator[F: TsuField or WaterField](
    mSelf; nazo: NazoPuyo[F]
) {.inline.} =
  ## Updates the answer simulator.
  ## This function is assumed to be called after `mSelf.answer.pairsPositionsSeq` is set.
  assert mSelf.answer.hasData

  if mSelf.answer.pairsPositionsSeq.len > 0:
    mSelf.focusAnswer = true
    mSelf.answer.index = 0

    var nazo2 = nazo
    nazo2.puyoPuyo.pairsPositions = mSelf.answer.pairsPositionsSeq[0]
    mSelf.answerSimulator[] = nazo2.initSimulator mSelf.answerSimulator[].mode
  else:
    mSelf.focusAnswer = false

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
  mSelf.simulator[].nazoPuyoWrap.get:
    if wrappedNazoPuyo.moveCount == 0:
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
      proc showAnswer() =
        let oldBarCount = mSelf.progressBar.now
        mSelf.progressBar.now = results.len.pred

        if results.allIt it.isSome:
          mSelf.progressBar.total = 0
          mSelf.answer.hasData = true
          mSelf.answer.pairsPositionsSeq = results.mapIt(it.get).concat
          mSelf.updateAnswerSimulator wrappedNazoPuyo
          mSelf.solving = false
          interval.clearInterval

        if mSelf.progressBar.now != oldBarCount and not kxi.surpressRedraws:
          kxi.redraw

      interval = showAnswer.setInterval ResultMonitorIntervalMs
    else:
      # FIXME: make asynchronous, redraw
      mSelf.answer.hasData = true
      mSelf.answer.pairsPositionsSeq =
        wrappedNazoPuyo.solve(parallelCount = parallelCount)
      mSelf.updateAnswerSimulator wrappedNazoPuyo
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
  mSelf.simulator[].nazoPuyoWrap.get:
    if wrappedNazoPuyo.moveCount == 0:
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
      proc showAnswer() =
        let oldBarCount = mSelf.progressBar.now
        mSelf.progressBar.now = results.len.pred

        if results.allIt it.isSome:
          mSelf.progressBar.total = 0
          mSelf.answer.hasData = true
          mSelf.answer.pairsPositionsSeq = results.mapIt(it.get)
          mSelf.updateAnswerSimulator wrappedNazoPuyo
          mSelf.permuting = false
          interval.clearInterval

        if mSelf.progressBar.now != oldBarCount and not kxi.surpressRedraws:
          kxi.redraw

      interval = showAnswer.setInterval ResultMonitorIntervalMs
    else:
      # FIXME: make asynchronous, redraw
      mSelf.answer.pairsPositionsSeq =
        wrappedNazoPuyo.permute(fixMoves, allowDouble, allowLastDouble).toSeq
      mSelf.updateAnswerSimulator wrappedNazoPuyo
      mSelf.permuting = false

{.pop.}

# ------------------------------------------------
# Answer
# ------------------------------------------------

proc nextAnswer*(mSelf) {.inline.} =
  ## Shows the next answer.
  if not mSelf.answer.hasData or mSelf.answer.pairsPositionsSeq.len == 0:
    return

  if mSelf.answer.index == mSelf.answer.pairsPositionsSeq.len.pred:
    mSelf.answer.index = 0
  else:
    mSelf.answer.index.inc

  mSelf.answerSimulator[].pairsPositions =
    mSelf.answer.pairsPositionsSeq[mSelf.answer.index]
  mSelf.answerSimulator[].reset

proc prevAnswer*(mSelf) {.inline.} =
  ## Shows the previous answer.
  if not mSelf.answer.hasData or mSelf.answer.pairsPositionsSeq.len == 0:
    return

  if mSelf.answer.index == 0:
    mSelf.answer.index = mSelf.answer.pairsPositionsSeq.len.pred
  else:
    mSelf.answer.index.dec

  mSelf.answerSimulator[].pairsPositions =
    mSelf.answer.pairsPositionsSeq[mSelf.answer.index]
  mSelf.answerSimulator[].reset

# ------------------------------------------------
# Keyboard Operation
# ------------------------------------------------

proc operate*(mSelf; event: KeyEvent): bool {.inline.} =
  ## Does operation specified by the keyboard input.
  ## Returns `true` if any action is executed.
  if mSelf.simulator[].mode in {PlayEditor, Edit}:
    if event == initKeyEvent("Tab", shift = true):
      mSelf.toggleFocus
      return true

    if mSelf.focusAnswer:
      # move answer
      if event == initKeyEvent("KeyA"):
        mSelf.prevAnswer
        return true
      if event == initKeyEvent("KeyD"):
        mSelf.nextAnswer
        return true

      return mSelf.answerSimulator[].operate event

    # solve
    if event == initKeyEvent("Enter"):
      mSelf.solve
      return true

  return mSelf.simulator[].operate event

# ------------------------------------------------
# Backend-specific Implementation
# ------------------------------------------------

when defined(js):
  import std/[strformat]
  import
    ../private/app/gui/web/
      [controller, pagination, settings, progress, simulator as simulatorModule]

  # ------------------------------------------------
  # JS - Keyboard Handler
  # ------------------------------------------------

  proc runKeyboardEventHandler*(rSelf; event: KeyEvent): bool {.inline, discardable.} =
    ## Runs the keyboard event handler.
    ## Returns `true` if any action is executed.
    result = rSelf[].operate event
    if result and not kxi.surpressRedraws:
      kxi.redraw

  proc runKeyboardEventHandler*(rSelf; event: Event): bool {.inline, discardable.} =
    ## Keybaord event handler.
    assert event of KeyboardEvent

    result = rSelf.runKeyboardEventHandler cast[KeyboardEvent](event).toKeyEvent
    if result:
      event.preventDefault

  proc initKeyboardEventHandler*(rSelf): (event: Event) -> void {.inline.} =
    ## Returns the keyboard event handler.
    (event: Event) => (discard rSelf.runKeyboardEventHandler event)

  # ------------------------------------------------
  # JS - Node
  # ------------------------------------------------

  const
    LeftSimulatorIdPrefix = "left-"
    RightSimulatorIdPrefix = "right-"

  proc initGuiApplicationNode(rSelf; id: string): VNode {.inline.} =
    ## Returns the GUI application without the external section.
    ## `id` is shared with other node-creating procedures and need to be unique.
    let simulatorNode =
      rSelf.simulator.initSimulatorNode(id = &"{LeftSimulatorIdPrefix}{id}")

    result = buildHtml(tdiv(class = "columns is-mobile is-variable is-1")):
      tdiv(class = "column is-narrow"):
        simulatorNode
      if rSelf.simulator[].mode in {PlayEditor, Edit} and rSelf.simulator[].kind == Nazo:
        tdiv(class = "column is-narrow"):
          section(class = "section"):
            tdiv(class = "block"):
              rSelf.initEditorControllerNode id
            tdiv(class = "block"):
              rSelf.initEditorSettingsNode id
            if rSelf.progressBar.total > 0:
              rSelf.initEditorProgressBarNode
            if rSelf.answer.hasData:
              tdiv(class = "block"):
                rSelf.initEditorPaginationNode
              if rSelf.answer.pairsPositionsSeq.len > 0:
                tdiv(class = "block"):
                  rSelf.initEditorSimulatorNode &"{RightSimulatorIdPrefix}{id}"

  proc initGuiApplicationNode*(
      rSelf; setKeyHandler = true, wrapSection = true, id = ""
  ): VNode {.inline.} =
    ## Returns the GUI application node.
    ## `id` is shared with other node-creating procedures and need to be unique.
    if setKeyHandler:
      document.onkeydown = rSelf.initKeyboardEventHandler

    let node = rSelf.initGuiApplicationNode id

    if wrapSection:
      result = buildHtml(section(class = "section")):
        node
    else:
      result = node

else:
  import
    ../private/app/gui/native/[controller, pagination, simulator as simulatorModule]

  type
    GuiApplicationControl* = ref object of LayoutContainer
      ## Root control of the GUI application.

    GuiApplicationWindow* = ref object of WindowImpl ## GUI application window.
      guiApplication: ref GuiApplication

  # ------------------------------------------------
  # Native - Keyboard Handler
  # ------------------------------------------------

  proc runKeyboardEventHandler*(
      window: GuiApplicationWindow, event: KeyboardEvent, keys = downKeys()
  ): bool {.inline, discardable.} =
    ## Runs the keyboard event handler.
    ## Returns `true` if any action is executed.
    result = window.guiApplication[].operate event.toKeyEvent keys
    if result:
      event.window.control.forceRedraw

  proc runKeyboardEventHandler(event: KeyboardEvent): bool {.inline, discardable.} =
    ## Runs the keyboard event handler.
    ## Returns `true` if any action is executed.
    let rawWindow = event.window
    assert rawWindow of GuiApplicationWindow

    result = cast[GuiApplicationWindow](rawWindow).runKeyboardEventHandler event

  func initKeyboardEventHandler*(): (event: KeyboardEvent) -> void {.inline.} =
    ## Returns the keyboard event handler.
    (event: KeyboardEvent) => (discard event.runKeyboardEventHandler)

  # ------------------------------------------------
  # Native - Control / Window
  # ------------------------------------------------

  proc initGuiApplicationControl*(rSelf): GuiApplicationControl {.inline.} =
    ## Returns the GUI application control.
    result = new GuiApplicationControl
    result.init
    result.layout = Layout_Horizontal

    # col=0
    let simulatorControl = rSelf[].simulator.initSimulatorControl
    result.add simulatorControl

    # col=1
    let secondCol = newLayoutContainer Layout_Vertical
    result.add secondCol

    secondCol.padding = 10.scaleToDpi
    secondCol.spacing = 10.scaleToDpi

    secondCol.add rSelf.initEditorControllerControl
    secondCol.add rSelf.initEditorPaginationControl
    secondCol.add rSelf.initEditorSimulatorControl

  proc initGuiApplicationWindow*(
      rSelf; title = "Pon!通", setKeyHandler = true
  ): GuiApplicationWindow {.inline.} =
    ## Returns the GUI application window.
    result = new GuiApplicationWindow
    result.init

    result.guiApplication = rSelf

    result.title = title
    result.resizable = false
    if setKeyHandler:
      result.onKeyDown = initKeyboardEventHandler()

    let rootControl = rSelf.initGuiApplicationControl
    result.add rootControl

    when defined(windows):
      # FIXME: ad hoc adjustment needed on Windows and should be improved
      result.width = (rootControl.naturalWidth.float * 1.1).int
      result.height = (rootControl.naturalHeight.float * 1.1).int
    else:
      result.width = rootControl.naturalWidth
      result.height = rootControl.naturalHeight
