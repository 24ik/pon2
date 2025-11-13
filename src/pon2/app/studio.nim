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

when defined(js) or defined(nimsuggest):
  when not defined(pon2.build.worker):
    import std/[jsconsole]

type
  StudioReplayData* = object ## Data for the replay simulator.
    stepsSeq: seq[Steps]
    stepsIdx: int

  Studio* = object ## Studio for Puyo Puyo and Nazo Puyo.
    simulator: Simulator
    replaySimulator: Simulator

    focusReplay: bool

    solving: bool
    permuting: bool

    replayData: StudioReplayData
    progressRef: ref tuple[now, total: int]

# ------------------------------------------------
# Constructor
# ------------------------------------------------

proc init*(T: type Studio, simulator: Simulator): T =
  let progressRef = new tuple[now, total: int]
  progressRef[] = (0, 0)

  T(
    simulator: simulator,
    replaySimulator: Simulator.init Replay,
    focusReplay: false,
    solving: false,
    permuting: false,
    replayData: StudioReplayData(stepsSeq: @[], stepsIdx: 0),
    progressRef: progressRef,
  )

proc init*(T: type Studio): T =
  T.init Simulator.init EditorEdit

# ------------------------------------------------
# Property - Getter
# ------------------------------------------------

func simulator*(self: Studio): Simulator =
  ## Returns the simulator.
  self.simulator

func simulator*(self: var Studio): var Simulator =
  ## Returns the simulator.
  self.simulator

func replaySimulator*(self: Studio): Simulator =
  ## Returns the replay simulator.
  self.replaySimulator

func replaySimulator*(self: var Studio): var Simulator =
  ## Returns the replay simulator.
  self.replaySimulator

func focusReplay*(self: Studio): bool =
  ## Returns `true` if the replay simulator is focused.
  self.focusReplay

func solving*(self: Studio): bool =
  ## Returns `true` if the studio is solving.
  self.solving

func permuting*(self: Studio): bool =
  ## Returns `true` if the studio is permuting.
  self.permuting

func working*(self: Studio): bool =
  ## Returns `true` if the studio is working.
  self.solving or self.permuting

func replayStepsCnt*(self: Studio): int =
  ## Returns the number of steps for the replay simulator.
  self.replayData.stepsSeq.len

func replayStepsIdx*(self: Studio): int =
  ## Returns the index of steps for the replay simulator.
  self.replayData.stepsIdx

func progressRef*(self: Studio): ref tuple[now, total: int] =
  ## Returns the progress.
  self.progressRef

# ------------------------------------------------
# Edit - Other
# ------------------------------------------------

func toggleFocus*(self: var Studio) =
  ## Toggles focusing to replay simulator or not.
  if self.simulator.mode in EditorModes:
    self.focusReplay.toggle

# ------------------------------------------------
# Replay
# ------------------------------------------------

func nextReplay*(self: var Studio) =
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

func prevReplay*(self: var Studio) =
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

func canWork(self: Studio): bool =
  ## Returns `true` if the studio is ready to work.
  if self.working:
    return false

  if self.simulator.mode notin EditorModes:
    return false

  if self.simulator.nazoPuyoWrap.optGoal.isErr:
    return false

  if self.simulator.state notin {Stable, AfterEdit}:
    return false

  true

func workPostProcess[F: TsuField or WaterField](self: var Studio, nazo: NazoPuyo[F]) =
  ## Updates the replay simulator.
  if self.replayData.stepsSeq.len > 0:
    self.focusReplay.assign true
    self.replayData.stepsIdx.assign 0

    var nazo2 = nazo
    nazo2.puyoPuyo.steps.assign self.replayData.stepsSeq[self.replayData.stepsIdx]
    self.replaySimulator.assign Simulator.init(nazo2, Replay)
  else:
    self.focusReplay.assign false

proc setAnswers[F: TsuField or WaterField](
    self: var Studio, originalNazo: NazoPuyo[F], answers: seq[SolveAnswer]
) =
  ## Sets the answers.
  let stepsSeq = collect:
    for ans in answers:
      var steps = originalNazo.puyoPuyo.steps
      for stepIdx, optPlcmt in ans:
        if originalNazo.puyoPuyo.steps[stepIdx].kind == PairPlacement:
          steps[stepIdx].optPlacement.assign optPlcmt

      steps

  self.replayData.stepsSeq.assign stepsSeq

proc solve*(self: var Studio) =
  ## Solves the nazo puyo.
  ## This function requires that the field is settled.
  if not self.canWork:
    return

  self.solving.assign true
  self.replayData.stepsSeq.setLen 0

  unwrapNazoPuyo self.simulator.nazoPuyoWrap:
    self.setAnswers itNazo, itNazo.solve
    self.workPostProcess itNazo

  self.solving.assign false

when defined(js) or defined(nimsuggest):
  when not defined(pon2.build.worker):
    proc asyncSolve*(self: ref Studio) =
      ## Solves the nazo puyo asynchronously with web workers.
      ## This function requires that the field is settled.
      if not self[].canWork:
        return

      self.solving.assign true
      self.replayData.stepsSeq.setLen 0

      unwrapNazoPuyo self.simulator.nazoPuyoWrap:
        let originalNazo = itNazo # NOTE: allow editing when working

        {.push warning[Uninit]: off.}
        discard originalNazo
          .asyncSolve(self[].progressRef)
          .then(
            (answers: seq[SolveAnswer]) => (
              block:
                self[].setAnswers originalNazo, answers
                self[].workPostProcess originalNazo
                self[].solving.assign false
            )
          )
          .catch((e: Error) => console.error e)
        {.pop.}

# ------------------------------------------------
# Permute
# ------------------------------------------------

proc permute*(
    self: var Studio, fixIndices: openArray[int], allowDblNotLast, allowDblLast: bool
) =
  ## Permutes the nazo puyo.
  ## This function requires that the field is settled.
  if not self.canWork:
    return

  self.permuting.assign true
  self.replayData.stepsSeq.setLen 0

  unwrapNazoPuyo self.simulator.nazoPuyoWrap:
    for nazo in itNazo.permute(fixIndices, allowDblNotLast, allowDblLast):
      self.replayData.stepsSeq.add nazo.puyoPuyo.steps

    self.workPostProcess itNazo

  self.permuting.assign false

when defined(js) or defined(nimsuggest):
  when not defined(pon2.build.worker):
    proc asyncPermute*(
        self: ref Studio,
        fixIndices: openArray[int],
        allowDblNotLast, allowDblLast: bool,
    ) =
      ## Permutes the nazo puyo asynchronously with web workers.
      ## This function requires that the field is settled.
      if not self[].canWork:
        return

      self.permuting.assign true
      self.replayData.stepsSeq.setLen 0

      unwrapNazoPuyo self.simulator.nazoPuyoWrap:
        let originalNazo = itNazo # NOTE: allow editing when working

        {.push warning[Uninit]: off.}
        discard originalNazo
          .asyncPermute(fixIndices, allowDblNotLast, allowDblLast, self[].progressRef)
          .then(
            (nazos: seq[originalNazo.type]) => (
              block:
                for nazo in nazos:
                  self[].replayData.stepsSeq.add nazo.puyoPuyo.steps
                self[].workPostProcess originalNazo
                self[].permuting.assign false
            )
          )
          .catch((e: Error) => console.error e)
        {.pop.}

# ------------------------------------------------
# Keyboard
# ------------------------------------------------

proc operate*(self: ref Studio, key: KeyEvent): bool {.discardable.} =
  ## Performs an action specified by the key.
  ## Returns `true` if the key is handled.
  if self[].simulator.mode in EditorModes:
    # focus
    if key == static(KeyEvent.init("Tab", shift = true)):
      self[].toggleFocus
      return true

    if self[].focusReplay:
      # next/prev replay
      if key == static(KeyEvent.init 'a'):
        self[].prevReplay
        return true
      if key == static(KeyEvent.init 'd'):
        self[].nextReplay
        return true

      return self[].replaySimulator.operate key

  return self[].simulator.operate key
