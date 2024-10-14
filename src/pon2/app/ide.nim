## This module implements the IDE.
##
## Compile Options:
## | Option               | Description              | Default  |
## | -------------------- | ------------------------ | -------- |
## | `-d:pon2.path=<str>` | URI path of the web IDE. | `/pon2/` |
##

{.experimental: "inferGenericTypes".}
{.experimental: "notnil".}
{.experimental: "strictCaseObjects".}
{.experimental: "strictDefs".}
{.experimental: "strictFuncs".}
{.experimental: "views".}

import std/[deques, sequtils, strformat, strutils, sugar, uri]
import ./[key, nazopuyo, simulator]
import ../core/[field, fqdn, nazopuyo, pairposition, puyopuyo, requirement]
import ../private/[misc]

when defined(js):
  import std/[options]
  import karax/[karax, karaxdsl, kdom, vdom]
  import ../core/[pair]
  import ../private/[webworker]
  import ../private/app/[solve, permute]
  import ../private/app/ide/web/[webworker]
else:
  {.push warning[Deprecated]: off.}
  import std/[cpuinfo, threadpool]
  {.pop.}
  import nigui
  import ./[permute, solve]

type
  AnswerData* = object ## Data used in the answer simulator.
    hasData*: bool
    pairsPositionsSeq*: seq[PairsPositions]
    index*: Natural

  Ide* = ref object ## Puyo Puyo & Nazo Puyo IDE.
    simulator: Simulator
    answerSimulator: Simulator

    answerData: AnswerData

    focusAnswer: bool
    solving: bool
    permuting: bool

    progressBarData: tuple[now: Natural, total: Natural]

const IdeUriPath* {.define: "pon2.path".} = "/pon2/"

static:
  doAssert IdeUriPath.startsWith '/'

# ------------------------------------------------
# Constructor
# ------------------------------------------------

func newIde*(simulator: Simulator): Ide {.inline.} =
  ## Returns a new IDE.
  Ide(
    simulator: simulator,
    answerSimulator: initNazoPuyo[TsuField]().newSimulator View,
    answerData: AnswerData(hasData: false, pairsPositionsSeq: @[], index: 0),
    focusAnswer: false,
    solving: false,
    permuting: false,
    progressBarData: (now: 0, total: 0),
  )

func newIde*(): Ide {.inline.} =
  ## Returns a new IDE.
  initNazoPuyo[TsuField]().newSimulator(PlayEditor).newIde

# ------------------------------------------------
# Property
# ------------------------------------------------

func simulator*(self: Ide): Simulator {.inline.} =
  ## Returns the simulator.
  self.simulator

func answerSimulator*(self: Ide): Simulator {.inline.} =
  ## Returns the answer simulator.
  self.answerSimulator

func answerData*(self: Ide): AnswerData {.inline.} =
  ## Returns the data for the answer simulator.
  self.answerData

func focusAnswer*(self: Ide): bool {.inline.} =
  ## Returns `true` if the answer simulator is focused.
  self.focusAnswer

func solving*(self: Ide): bool {.inline.} =
  ## Returns `true` if a nazo puyo is being solved.
  self.solving

func permuting*(self: Ide): bool {.inline.} =
  ## Returns `true` if a nazo puyo is being permuted.
  self.permuting

func progressBarData*(self: Ide): tuple[now: int, total: int] {.inline.} =
  ## Returns the progress bar information.
  self.progressBarData

# ------------------------------------------------
# Edit - Other
# ------------------------------------------------

proc toggleFocus*(self: Ide) {.inline.} =
  ## Toggles focusing to answer simulator or not.
  self.focusAnswer.toggle

# ------------------------------------------------
# Solve
# ------------------------------------------------

when defined(js):
  const ResultMonitorIntervalMs = 100

proc updateAnswerSimulator[F: TsuField or WaterField](
    self: Ide, nazo: NazoPuyo[F]
) {.inline.} =
  ## Updates the answer simulator.
  ## This function is assumed to be called after `self.answerData.pairsPositionsSeq` is set.
  assert self.answerData.hasData

  if self.answerData.pairsPositionsSeq.len > 0:
    self.focusAnswer = true
    self.answerData.index = 0

    var nazo2 = nazo
    nazo2.puyoPuyo.pairsPositions = self.answerData.pairsPositionsSeq[0]
    self.answerSimulator = nazo2.newSimulator self.answerSimulator.mode
  else:
    self.focusAnswer = false

proc solve*(
    self: Ide,
    parallelCount: Positive =
      when defined(js):
        6
      else:
        max(1, countProcessors())
    ,
) {.inline.} =
  ## Solves the nazo puyo.
  if self.solving or self.permuting or self.simulator.kind != Nazo or
      self.simulator.state != Stable:
    return
  self.simulator.nazoPuyoWrap.get:
    if wrappedNazoPuyo.moveCount == 0:
      return

  self.solving = true

  self.simulator.nazoPuyoWrap.get:
    when defined(js):
      let results = new seq[seq[SolveAnswer]]
      wrappedNazoPuyo.asyncSolve(results, parallelCount = parallelCount)

      self.progressBarData.total =
        if wrappedNazoPuyo.puyoPuyo.pairsPositions.peekFirst.pair.isDouble:
          wrappedNazoPuyo.puyoPuyo.field.validDoublePositions.card
        else:
          wrappedNazoPuyo.puyoPuyo.field.validPositions.card
      self.progressBarData.now = 0

      var interval: Interval
      proc showAnswer() =
        let oldBarCount = self.progressBarData.now
        self.progressBarData.now = results[].len

        if results[].len == self.progressBarData.total:
          self.progressBarData.total = 0
          self.answerData.hasData = true
          self.answerData.pairsPositionsSeq = collect:
            for answer in results[].concat:
              var pairsPositions = wrappedNazoPuyo.puyoPuyo.pairsPositions
              pairsPositions.positions = answer
              pairsPositions
          self.updateAnswerSimulator wrappedNazoPuyo
          self.solving = false
          interval.clearInterval

        if self.progressBarData.now != oldBarCount and not kxi.surpressRedraws:
          kxi.redraw

      interval = showAnswer.setInterval ResultMonitorIntervalMs
    else:
      # FIXME: make asynchronous, redraw
      self.answerData.hasData = true
      self.answerData.pairsPositionsSeq = collect:
        for answer in wrappedNazoPuyo.solve(parallelCount = parallelCount):
          var pairsPositions = wrappedNazoPuyo.puyoPuyo.pairsPositions
          pairsPositions.positions = answer
          pairsPositions
      self.updateAnswerSimulator wrappedNazoPuyo
      self.solving = false

# ------------------------------------------------
# Permute
# ------------------------------------------------

proc permute*(
    self: Ide,
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
  if self.solving or self.permuting or self.simulator.kind != Nazo or
      self.simulator.state != Stable:
    return
  self.simulator.nazoPuyoWrap.get:
    if wrappedNazoPuyo.moveCount == 0:
      return

  self.permuting = true

  self.simulator.nazoPuyoWrap.get:
    when defined(js):
      let
        results = new seq[Option[PairsPositions]]
        pairsPositionsSeq =
          wrappedNazoPuyo.allPairsPositionsSeq(fixMoves, allowDouble, allowLastDouble)
      wrappedNazoPuyo.asyncPermute(
        results, pairsPositionsSeq, fixMoves, allowDouble, allowLastDouble,
        parallelCount,
      )

      self.progressBarData.total = pairsPositionsSeq.len
      self.progressBarData.now = 0

      var interval: Interval
      proc showAnswer() =
        let oldBarCount = self.progressBarData.now
        self.progressBarData.now = results[].len

        if results[].len == pairsPositionsSeq.len:
          self.progressBarData.total = 0
          self.answerData.hasData = true
          self.answerData.pairsPositionsSeq = results[].filterIt(it.isSome).mapIt it.get
          self.updateAnswerSimulator wrappedNazoPuyo
          self.permuting = false
          interval.clearInterval

        if self.progressBarData.now != oldBarCount and not kxi.surpressRedraws:
          kxi.redraw

      interval = showAnswer.setInterval ResultMonitorIntervalMs
    else:
      # FIXME: make asynchronous, redraw
      self.answerData.pairsPositionsSeq =
        wrappedNazoPuyo.permute(fixMoves, allowDouble, allowLastDouble).toSeq
      self.updateAnswerSimulator wrappedNazoPuyo
      self.permuting = false

# ------------------------------------------------
# Answer
# ------------------------------------------------

proc nextAnswer*(self: Ide) {.inline.} =
  ## Shows the next answer.
  if not self.answerData.hasData or self.answerData.pairsPositionsSeq.len == 0:
    return

  if self.answerData.index == self.answerData.pairsPositionsSeq.len.pred:
    self.answerData.index = 0
  else:
    self.answerData.index.inc

  self.answerSimulator.nazoPuyoWrap.get:
    wrappedNazoPuyo.puyoPuyo.pairsPositions =
      self.answerData.pairsPositionsSeq[self.answerData.index]
  self.answerSimulator.reset

proc prevAnswer*(self: Ide) {.inline.} =
  ## Shows the previous answer.
  if not self.answerData.hasData or self.answerData.pairsPositionsSeq.len == 0:
    return

  if self.answerData.index == 0:
    self.answerData.index = self.answerData.pairsPositionsSeq.len.pred
  else:
    self.answerData.index.dec

  self.answerSimulator.nazoPuyoWrap.get:
    wrappedNazoPuyo.puyoPuyo.pairsPositions =
      self.answerData.pairsPositionsSeq[self.answerData.index]
  self.answerSimulator.reset

# ------------------------------------------------
# IDE <-> URI
# ------------------------------------------------

func toUri*(self: Ide, withPositions = true, fqdn = Pon2): Uri {.inline.} =
  ## Returns the URI converted from the IDE.
  result = initUri()
  result.scheme =
    case fqdn
    of Pon2, Ishikawa: "https"
    of Ips: "http"
  result.hostname = $fqdn
  result.query = self.simulator.toUriQuery(withPositions, fqdn)

  # path
  case fqdn
  of Pon2:
    result.path = IdeUriPath
  of Ishikawa, Ips:
    let modeChar =
      case self.simulator.kind
      of Regular:
        case self.simulator.mode
        of Play, PlayEditor: 's'
        of Edit: 'e'
        of View: 'v'
      of Nazo:
        'n'
    result.path = &"/simu/p{modeChar}.html"

func allowedUriPaths(path: string): seq[string] {.inline.} =
  ## Returns the allowed paths.
  result = @[path]

  if path.endsWith "/index.html":
    result.add path.dup(removeSuffix("index.html"))
  elif path.endsWith '/':
    result.add &"{path}index.html"

const AllowedSimulatorUriPaths = IdeUriPath.allowedUriPaths

proc parseIde*(uri: Uri): Ide {.inline.} =
  ## Returns the IDE converted from the URI.
  ## If the URI is invalid, `ValueError` is raised.
  var
    kind = SimulatorKind.low
    mode = SimulatorMode.low
  let fqdn: IdeFqdn
  case uri.hostname
  of $Pon2:
    if uri.path notin AllowedSimulatorUriPaths:
      raise newException(ValueError, "Invalid IDE: " & $uri)

    fqdn = Pon2
  of $Ishikawa, $Ips:
    fqdn = if uri.hostname == $Ishikawa: Ishikawa else: Ips

    # kind, mode
    case uri.path
    of "/simu/pe.html":
      kind = Regular
      mode = Edit
    of "/simu/ps.html":
      kind = Regular
      mode = Play
    of "/simu/pv.html":
      kind = Regular
      mode = View
    of "/simu/pn.html":
      kind = Nazo
      mode = Play
    else:
      result = newIde() # HACK: dummy to suppress warning
      raise newException(ValueError, "Invalid IDE: " & $uri)
  else:
    fqdn = Pon2 # HACK: dummy to compile
    result = newIde() # HACK: dummy to suppress warning
    raise newException(ValueError, "Invalid IDE: " & $uri)

  let simulator = uri.query.parseSimulator fqdn
  if fqdn in {Ishikawa, Ips}:
    simulator.kind = kind
    simulator.mode = mode

  result = simulator.newIde

# ------------------------------------------------
# Keyboard Operation
# ------------------------------------------------

proc operate*(self: Ide, event: KeyEvent): bool {.inline.} =
  ## Does operation specified by the keyboard input.
  ## Returns `true` if any action is executed.
  if self.simulator.mode in {PlayEditor, Edit}:
    if event == initKeyEvent("Tab", shift = true):
      self.toggleFocus
      return true

    if self.focusAnswer:
      # move answer
      if event == initKeyEvent("KeyA"):
        self.prevAnswer
        return true
      if event == initKeyEvent("KeyD"):
        self.nextAnswer
        return true

      return self.answerSimulator.operate event

    # solve
    if event == initKeyEvent("Enter"):
      self.solve
      return true

  return self.simulator.operate event

# ------------------------------------------------
# Backend-specific Implementation
# ------------------------------------------------

when defined(js):
  import
    ../private/app/ide/web/[answer, controller, pagination, settings, share, progress]

  # ------------------------------------------------
  # JS - Keyboard Handler
  # ------------------------------------------------

  proc runKeyboardEventHandler*(
      self: Ide, event: KeyEvent
  ): bool {.inline, discardable.} =
    ## Runs the keyboard event handler.
    ## Returns `true` if any action is executed.
    result = self.operate event
    if result and not kxi.surpressRedraws:
      kxi.redraw

  proc runKeyboardEventHandler*(self: Ide, event: Event): bool {.inline, discardable.} =
    ## Keybaord event handler.
    # assert event of KeyboardEvent # HACK: somehow this fails

    result = self.runKeyboardEventHandler cast[KeyboardEvent](event).toKeyEvent
    if result:
      event.preventDefault

  func newKeyboardEventHandler*(self: Ide): (event: Event) -> void {.inline.} =
    ## Returns the keyboard event handler.
    (event: Event) => (discard self.runKeyboardEventHandler event)

  # ------------------------------------------------
  # JS - Node
  # ------------------------------------------------

  const
    MainSimulatorIdPrefix = "pon2-ide-mainsimulator-"
    AnswerSimulatorIdPrefix = "pon2-ide-answersimulator-"
    SettingsIdPrefix = "pon2-ide-settings-"
    ShareIdPrefix = "pon2-ide-share-"

  proc newIdeNode(self: Ide, id: string): VNode {.inline.} =
    ## Returns the IDE node without the external section.
    let
      simulatorNode = self.simulator.newSimulatorNode(
        wrapSection = false, id = &"{MainSimulatorIdPrefix}{id}"
      )
      settingsId = &"{SettingsIdPrefix}{id}"

    result = buildHtml(tdiv(class = "columns is-mobile is-variable is-1")):
      tdiv(class = "column is-narrow"):
        tdiv(class = "block"):
          simulatorNode
        tdiv(class = "block"):
          self.newShareNode &"{ShareIdPrefix}{id}"
      if self.simulator.mode in {PlayEditor, Edit} and self.simulator.kind == Nazo:
        tdiv(class = "column is-narrow"):
          section(class = "section"):
            tdiv(class = "block"):
              self.newEditorControllerNode settingsId
            tdiv(class = "block"):
              self.newEditorSettingsNode settingsId
            if self.progressBarData.total > 0:
              self.newEditorProgressBarNode
            if self.answerData.hasData:
              tdiv(class = "block"):
                self.newEditorPaginationNode
              if self.answerData.pairsPositionsSeq.len > 0:
                tdiv(class = "block"):
                  self.newAnswerSimulatorNode &"{AnswerSimulatorIdPrefix}{id}"

  proc newIdeNode*(
      self: Ide, setKeyHandler = true, wrapSection = true, id = ""
  ): VNode {.inline.} =
    ## Returns the IDE node.
    if setKeyHandler:
      document.onkeydown = self.newKeyboardEventHandler

    let node = self.newIdeNode id

    if wrapSection:
      result = buildHtml(section(class = "section")):
        node
    else:
      result = node

else:
  import ../private/app/ide/native/[answer, controller, pagination]

  type
    IdeControl* = ref object of LayoutContainer ## Root control of the IDE.

    IdeWindow* = ref object of WindowImpl ## GUI application window.
      ide: Ide

  # ------------------------------------------------
  # Native - Keyboard Handler
  # ------------------------------------------------

  proc runKeyboardEventHandler*(
      window: IdeWindow, event: KeyboardEvent, keys = downKeys()
  ): bool {.inline, discardable.} =
    ## Runs the keyboard event handler.
    ## Returns `true` if any action is executed.
    result = window.ide.operate event.toKeyEvent keys
    if result:
      event.window.control.forceRedraw

  proc runKeyboardEventHandler(event: KeyboardEvent): bool {.inline, discardable.} =
    ## Runs the keyboard event handler.
    ## Returns `true` if any action is executed.
    let rawWindow = event.window
    assert rawWindow of IdeWindow

    result = cast[IdeWindow](rawWindow).runKeyboardEventHandler event

  func newKeyboardEventHandler*(): (event: KeyboardEvent) -> void {.inline.} =
    ## Returns the keyboard event handler.
    (event: KeyboardEvent) => (discard event.runKeyboardEventHandler)

  # ------------------------------------------------
  # Native - Control / Window
  # ------------------------------------------------

  proc newIdeControl*(self: Ide): IdeControl {.inline.} =
    ## Returns the IDE control.
    {.push warning[ProveInit]: off.}
    result.new
    {.pop.}
    result.init
    result.layout = Layout_Horizontal

    # col=0
    let simulatorControl = self.simulator.newSimulatorControl
    result.add simulatorControl

    # col=1
    let secondCol = newLayoutContainer Layout_Vertical
    result.add secondCol

    secondCol.padding = 10.scaleToDpi
    secondCol.spacing = 10.scaleToDpi

    secondCol.add self.newEditorControllerControl
    secondCol.add self.newEditorPaginationControl
    secondCol.add self.newAnswerSimulatorControl

  proc newIdeWindow*(
      self: Ide, title = "Pon!通", setKeyHandler = true
  ): IdeWindow {.inline.} =
    ## Returns the IDE window.
    {.push warning[ProveInit]: off.}
    result.new
    {.pop.}
    result.init

    result.ide = self

    result.title = title
    result.resizable = false
    if setKeyHandler:
      result.onKeyDown = newKeyboardEventHandler()

    let rootControl = self.newIdeControl
    result.add rootControl

    when defined(windows):
      # FIXME: ad hoc adjustment needed on Windows and should be improved
      result.width = (rootControl.naturalWidth.float * 1.1).int
      result.height = (rootControl.naturalHeight.float * 1.1).int
    else:
      result.width = rootControl.naturalWidth
      result.height = rootControl.naturalHeight
