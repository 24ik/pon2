## This module implements IDEs.
##

{.push raises: [].}
{.experimental: "strictDefs".}
{.experimental: "strictFuncs".}
{.experimental: "views".}

import std/[deques, sequtils, sugar]
import ./[key, nazopuyowrap, permute, simulator, solve]
import ../[core]
import ../private/[assign3, utils]

when defined(js):
  import std/[asyncjs]
else:
  import chronos

type
  IdeReplayData* = object ## Data for the replay simulator.
    stepsSeq: seq[Steps]
    stepsIdx: int

  Ide* = object ## IDE for Puyo Puyo and Nazo Puyo.
    simulator: Simulator
    replaySimulator: Simulator

    focusReplay: bool

    working: bool
    replayData: IdeReplayData

# ------------------------------------------------
# Constructor
# ------------------------------------------------

func init*(T: type Ide, simulator: Simulator): T {.inline.} =
  T(
    simulator: simulator,
    replaySimulator: Simulator.init Replay,
    focusReplay: false,
    working: false,
    replayData: IdeReplayData(stepsSeq: @[], stepsIdx: 0),
  )

func init*(T: type Ide): T {.inline.} =
  T.init Simulator.init EditorEdit

# ------------------------------------------------
# Property - Getter
# ------------------------------------------------

func simulator*(self: Ide): Simulator {.inline.} =
  ## Returns the simulator.
  self.simulator

func replaySimulator*(self: Ide): Simulator {.inline.} =
  ## Returns the replay simulator.
  self.replaySimulator

func focusReplay*(self: Ide): bool {.inline.} =
  ## Returns `true` if the replay simulator is focused.
  self.focusReplay

# ------------------------------------------------
# Edit - Other
# ------------------------------------------------

func toggleFocus*(self: var Ide) {.inline.} =
  ## Toggles focusing to replay simulator or not.
  if self.simulator.mode in EditorModes:
    self.focusReplay.toggle

# ------------------------------------------------
# Replay
# ------------------------------------------------

proc nextReplay*(self: var Ide) {.inline.} =
  ## Shows the next answer.
  if self.simulator.mode notin EditorModes or self.replayData.stepsSeq.len == 0:
    return

  if self.replayData.stepsIdx == self.replayData.stepsSeq.len.pred:
    self.replayData.stepsIdx.assign 0
  else:
    self.replayData.stepsIdx.inc

  self.replaySimulator.reset
  runIt self.replaySimulator.nazoPuyoWrap:
    var nazo = itNazo
    nazo.puyoPuyo.steps.assign self.replayData.stepsSeq[self.replayData.stepsIdx]

    self.replaySimulator.assign Simulator.init(nazo, Replay)

proc prevReplay*(self: var Ide) {.inline.} =
  ## Shows the previous answer.
  if self.simulator.mode notin EditorModes or self.replayData.stepsSeq.len == 0:
    return

  if self.replayData.stepsIdx == 0:
    self.replayData.stepsIdx.assign self.replayData.stepsSeq.len.pred
  else:
    self.replayData.stepsIdx.dec

  self.replaySimulator.reset
  runIt self.replaySimulator.nazoPuyoWrap:
    var nazo = itNazo
    nazo.puyoPuyo.steps.assign self.replayData.stepsSeq[self.replayData.stepsIdx]

    self.replaySimulator.assign Simulator.init(nazo, Replay)

# ------------------------------------------------
# Solve
# ------------------------------------------------

func workPostProcess[F: TsuField or WaterField](
    self: var Ide, nazo: NazoPuyo[F]
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

proc solve*(self: var Ide) {.inline.} =
  ## Solves the nazo puyo.
  if self.working or self.simulator.mode notin EditorModes or
      self.simulator.nazoPuyoWrap.optGoal.isErr or
      self.simulator.state notin {Stable, AfterEdit}:
    return
  runIt self.simulator.nazoPuyoWrap:
    if it.steps.len == 0:
      return

  self.working.assign true
  self.replayData.stepsSeq.setLen 0

  runIt self.simulator.nazoPuyoWrap:
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
    self: var Ide, fixIndices: openArray[int], allowDblNotLast, allowDblLast: bool
) {.inline.} =
  ## Permutes the nazo puyo.
  if self.working or self.simulator.mode notin EditorModes or
      self.simulator.nazoPuyoWrap.optGoal.isErr or
      self.simulator.state notin {Stable, AfterEdit}:
    return
  runIt self.simulator.nazoPuyoWrap:
    if it.steps.len == 0:
      return

  self.working.assign true
  self.replayData.stepsSeq.setLen 0

  runIt self.simulator.nazoPuyoWrap:
    for nazo in itNazo.permute(fixIndices, allowDblNotLast, allowDblLast):
      self.replayData.stepsSeq.add nazo.puyoPuyo.steps

    self.workPostProcess itNazo

  self.working.assign false

# ------------------------------------------------
# Keyboard
# ------------------------------------------------

proc operate*(self: var Ide, key: KeyEvent): bool {.inline, discardable.} =
  ## Performs an action specified by the key.
  ## Returns `true` if the key is catched.
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
