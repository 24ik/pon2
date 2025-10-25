## This module implements studios.
##

{.push raises: [].}
{.experimental: "strictDefs".}
{.experimental: "strictFuncs".}
{.experimental: "views".}

import std/[deques, sequtils, sugar]
import ./[key, nazopuyowrap, permute, simulator, solve]
import ../[core]
import ../private/[assign3, utils]

type
  StudioReplayData* = object ## Data for the replay simulator.
    stepsSeq: seq[Steps]
    stepsIdx: int

  Studio* = object ## Studio for Puyo Puyo and Nazo Puyo.
    simulator: Simulator
    replaySimulator: Simulator

    focusReplay: bool

    working: bool
    replayData: StudioReplayData

# ------------------------------------------------
# Constructor
# ------------------------------------------------

func init*(T: type Studio, simulator: Simulator): T {.inline.} =
  T(
    simulator: simulator,
    replaySimulator: Simulator.init Replay,
    focusReplay: false,
    working: false,
    replayData: StudioReplayData(stepsSeq: @[], stepsIdx: 0),
  )

func init*(T: type Studio): T {.inline.} =
  T.init Simulator.init EditorEdit

# ------------------------------------------------
# Property - Getter
# ------------------------------------------------

func simulator*(self: Studio): Simulator {.inline.} =
  ## Returns the simulator.
  self.simulator

func simulator*(self: var Studio): var Simulator {.inline.} =
  ## Returns the simulator.
  self.simulator

func replaySimulator*(self: Studio): Simulator {.inline.} =
  ## Returns the replay simulator.
  self.replaySimulator

func replaySimulator*(self: var Studio): var Simulator {.inline.} =
  ## Returns the replay simulator.
  self.replaySimulator

func focusReplay*(self: Studio): bool {.inline.} =
  ## Returns `true` if the replay simulator is focused.
  self.focusReplay

func working*(self: Studio): bool {.inline.} =
  ## Returns `true` if the studio is working.
  self.working

func replayStepsCnt*(self: Studio): int {.inline.} =
  ## Returns the number of steps for the replay simulator.
  self.replayData.stepsSeq.len

func replayStepsIdx*(self: Studio): int {.inline.} =
  ## Returns the index of steps for the replay simulator.
  self.replayData.stepsIdx

# ------------------------------------------------
# Edit - Other
# ------------------------------------------------

func toggleFocus*(self: var Studio) {.inline.} =
  ## Toggles focusing to replay simulator or not.
  if self.simulator.mode in EditorModes:
    self.focusReplay.toggle

# ------------------------------------------------
# Replay
# ------------------------------------------------

func nextReplay*(self: var Studio) {.inline.} =
  ## Shows the next answer.
  if self.simulator.mode notin EditorModes or self.replayData.stepsSeq.len == 0:
    return

  if self.replayData.stepsIdx == self.replayData.stepsSeq.len.pred:
    self.replayData.stepsIdx.assign 0
  else:
    self.replayData.stepsIdx.inc

  self.replaySimulator.reset
  unwrapNazoPuyo self.replaySimulator.nazoPuyoWrap:
    var nazo = itNazo
    nazo.puyoPuyo.steps.assign self.replayData.stepsSeq[self.replayData.stepsIdx]

    self.replaySimulator.assign Simulator.init(nazo, Replay)

func prevReplay*(self: var Studio) {.inline.} =
  ## Shows the previous answer.
  if self.simulator.mode notin EditorModes or self.replayData.stepsSeq.len == 0:
    return

  if self.replayData.stepsIdx == 0:
    self.replayData.stepsIdx.assign self.replayData.stepsSeq.len.pred
  else:
    self.replayData.stepsIdx.dec

  self.replaySimulator.reset
  unwrapNazoPuyo self.replaySimulator.nazoPuyoWrap:
    var nazo = itNazo
    nazo.puyoPuyo.steps.assign self.replayData.stepsSeq[self.replayData.stepsIdx]

    self.replaySimulator.assign Simulator.init(nazo, Replay)

# ------------------------------------------------
# Solve
# ------------------------------------------------

func workPostProcess[F: TsuField or WaterField](
    self: var Studio, nazo: NazoPuyo[F]
) {.inline.} =
  ## Updates the replay simulator.
  if self.replayData.stepsSeq.len > 0:
    self.focusReplay.assign true
    self.replayData.stepsIdx.assign 0

    var nazo2 = nazo
    nazo2.puyoPuyo.steps.assign self.replayData.stepsSeq[self.replayData.stepsIdx]
    self.replaySimulator.assign Simulator.init(nazo2, Replay)
  else:
    self.focusReplay.assign false

proc solve*(self: var Studio) {.inline.} =
  ## Solves the nazo puyo.
  if self.working or self.simulator.mode notin EditorModes or
      self.simulator.nazoPuyoWrap.optGoal.isErr or
      self.simulator.state notin {Stable, AfterEdit}:
    return
  unwrapNazoPuyo self.simulator.nazoPuyoWrap:
    if it.steps.len == 0:
      return

  self.working.assign true
  self.replayData.stepsSeq.setLen 0

  unwrapNazoPuyo self.simulator.nazoPuyoWrap:
    let
      answers = itNazo.solve
      stepsSeq = collect:
        for ans in answers:
          var steps = it.steps
          for stepIdx, optPlcmt in ans:
            if steps[stepIdx].kind == PairPlacement:
              steps[stepIdx].optPlacement.assign optPlcmt

          steps

    self.replayData.stepsSeq.assign stepsSeq
    self.workPostProcess itNazo

  self.working.assign false

# ------------------------------------------------
# Permute
# ------------------------------------------------

proc permute*(
    self: var Studio, fixIndices: openArray[int], allowDblNotLast, allowDblLast: bool
) {.inline.} =
  ## Permutes the nazo puyo.
  if self.working or self.simulator.mode notin EditorModes or
      self.simulator.nazoPuyoWrap.optGoal.isErr or
      self.simulator.state notin {Stable, AfterEdit}:
    return
  unwrapNazoPuyo self.simulator.nazoPuyoWrap:
    if it.steps.len == 0:
      return

  self.working.assign true
  self.replayData.stepsSeq.setLen 0

  unwrapNazoPuyo self.simulator.nazoPuyoWrap:
    for nazo in itNazo.permute(fixIndices, allowDblNotLast, allowDblLast):
      self.replayData.stepsSeq.add nazo.puyoPuyo.steps

    self.workPostProcess itNazo

  self.working.assign false

# ------------------------------------------------
# Keyboard
# ------------------------------------------------

proc operate*(self: var Studio, key: KeyEvent): bool {.inline, discardable.} =
  ## Performs an action specified by the key.
  ## Returns `true` if the key is handled.
  if self.simulator.mode in EditorModes:
    # focus
    if key == static(KeyEvent.init("Tab", shift = true)):
      self.toggleFocus
      return true

    # solve
    if key == static(KeyEvent.init "Enter"):
      self.solve
      return true

    if self.focusReplay:
      # next/prev replay
      if key == static(KeyEvent.init 'a'):
        self.prevReplay
        return true
      if key == static(KeyEvent.init 'd'):
        self.nextReplay
        return true

      return self.replaySimulator.operate key

  return self.simulator.operate key
