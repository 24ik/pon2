## This module implements the IDE.
##
when defined(js):
  ## See also the [backend-specific documentation](./ide/web.html).
  ##
  discard
else:
  ## See also the [backend-specific documentation](./ide/native.html).
  ##
  discard

{.experimental: "inferGenericTypes".}
{.experimental: "notnil".}
{.experimental: "strictCaseObjects".}
{.experimental: "strictDefs".}
{.experimental: "strictFuncs".}
{.experimental: "views".}

import std/[deques, sequtils, sugar, uri]
import ./[key, nazopuyo, simulator]
import ../core/[field, fqdn, nazopuyo, pairposition, puyopuyo, requirement]
import ../private/[misc]

when defined(js):
  import std/[options]
  import karax/[karax, kdom, vdom]
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

  self.answerSimulator.reset
  self.answerSimulator.pairsPositions =
    self.answerData.pairsPositionsSeq[self.answerData.index]

proc prevAnswer*(self: Ide) {.inline.} =
  ## Shows the previous answer.
  if not self.answerData.hasData or self.answerData.pairsPositionsSeq.len == 0:
    return

  if self.answerData.index == 0:
    self.answerData.index = self.answerData.pairsPositionsSeq.len.pred
  else:
    self.answerData.index.dec

  self.answerSimulator.reset
  self.answerSimulator.pairsPositions =
    self.answerData.pairsPositionsSeq[self.answerData.index]

# ------------------------------------------------
# IDE <-> URI
# ------------------------------------------------

func toUri*(self: Ide, withPositions = true, fqdn = Pon2): Uri {.inline.} =
  ## Returns the URI converted from the IDE.
  self.simulator.toUri(withPositions, fqdn)

proc parseIde*(uri: Uri): Ide {.inline.} =
  ## Returns the IDE converted from the URI.
  ## If the URI is invalid, `ValueError` is raised.
  uri.parseSimulator.newIde

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
