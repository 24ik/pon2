## This module implements studios.
##

{.push raises: [].}
{.experimental: "strictDefs".}
{.experimental: "strictFuncs".}
{.experimental: "views".}

import std/[deques, sequtils, sugar]
import ./[key, nazopuyowrap, permute, simulator, solve]
import ../[core]
import ../private/[assign, utils]

export simulator

when defined(js) or defined(nimsuggest):
  when not defined(pon2.build.worker):
    import std/[jsconsole]

type
  StudioReplayData* = object ## Data for the replay simulator.
    stepsSeq: seq[Steps]
    stepsIndex: int

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
    replayData: StudioReplayData(stepsSeq: @[], stepsIndex: 0),
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

func replayStepsCount*(self: Studio): int =
  ## Returns the number of steps for the replay simulator.
  self.replayData.stepsSeq.len

func replayStepsIndex*(self: Studio): int =
  ## Returns the index of steps for the replay simulator.
  self.replayData.stepsIndex

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

  if self.replayData.stepsIndex == self.replayData.stepsSeq.len.pred:
    self.replayData.stepsIndex.assign 0
  else:
    self.replayData.stepsIndex.inc

  self.replaySimulator.reset
  unwrap self.replaySimulator.nazoPuyoWrap:
    var nazo = it
    nazo.puyoPuyo.steps.assign self.replayData.stepsSeq[self.replayData.stepsIndex]

    self.replaySimulator.assign Simulator.init(nazo, Replay)

func prevReplay*(self: var Studio) =
  ## Shows the previous answer.
  if self.simulator.mode notin EditorModes or self.replayData.stepsSeq.len == 0:
    return

  if self.replayData.stepsIndex == 0:
    self.replayData.stepsIndex.assign self.replayData.stepsSeq.len.pred
  else:
    self.replayData.stepsIndex.dec

  self.replaySimulator.reset
  unwrap self.replaySimulator.nazoPuyoWrap:
    var nazo = it
    nazo.puyoPuyo.steps.assign self.replayData.stepsSeq[self.replayData.stepsIndex]

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

  if self.simulator.state notin {Stable, AfterEdit}:
    return false

  true

func workPostProcess[F: TsuField or WaterField](
    self: var Studio, nazoPuyo: NazoPuyo[F]
) =
  ## Updates the replay simulator.
  if self.replayData.stepsSeq.len > 0:
    self.focusReplay.assign true
    self.replayData.stepsIndex.assign 0

    var nazoPuyo2 = nazoPuyo
    nazoPuyo2.puyoPuyo.steps.assign self.replayData.stepsSeq[self.replayData.stepsIndex]
    self.replaySimulator.assign Simulator.init(nazoPuyo2, Replay)
  else:
    self.focusReplay.assign false

proc setAnswers[F: TsuField or WaterField](
    self: var Studio, originalNazoPuyo: NazoPuyo[F], answers: seq[SolveAnswer]
) =
  ## Sets the answers.
  let stepsSeq = collect:
    for answer in answers:
      var steps = originalNazoPuyo.puyoPuyo.steps
      for stepIndex, optPlacement in answer:
        if originalNazoPuyo.puyoPuyo.steps[stepIndex].kind == PairPlacement:
          steps[stepIndex].optPlacement.assign optPlacement

      steps

  self.replayData.stepsSeq.assign stepsSeq

proc solve*(self: var Studio) =
  ## Solves the nazo puyo.
  ## This function requires that the field is settled.
  if not self.canWork:
    return

  self.solving.assign true
  self.replayData.stepsSeq.setLen 0

  unwrap self.simulator.nazoPuyoWrap:
    self.setAnswers it, it.solve
    self.workPostProcess it

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

      unwrap self.simulator.nazoPuyoWrap:
        let originalNazoPuyo = it # NOTE: allow editing when working

        {.push warning[Uninit]: off.}
        discard originalNazoPuyo
          .asyncSolve(self[].progressRef)
          .then(
            (answers: seq[SolveAnswer]) => (
              block:
                self[].setAnswers originalNazoPuyo, answers
                self[].workPostProcess originalNazoPuyo
                self[].solving.assign false
            )
          )
          .catch((error: Error) => console.error error)
        {.pop.}

# ------------------------------------------------
# Permute
# ------------------------------------------------

proc permute*(
    self: var Studio,
    fixIndices: openArray[int],
    allowDoubleNotLast, allowDoubleLast: bool,
) =
  ## Permutes the nazo puyo.
  ## This function requires that the field is settled.
  if not self.canWork:
    return

  self.permuting.assign true
  self.replayData.stepsSeq.setLen 0

  unwrap self.simulator.nazoPuyoWrap:
    for nazoPuyo in it.permute(fixIndices, allowDoubleNotLast, allowDoubleLast):
      self.replayData.stepsSeq.add nazoPuyo.puyoPuyo.steps

    self.workPostProcess it

  self.permuting.assign false

when defined(js) or defined(nimsuggest):
  when not defined(pon2.build.worker):
    proc asyncPermute*(
        self: ref Studio,
        fixIndices: openArray[int],
        allowDoubleNotLast, allowDoubleLast: bool,
    ) =
      ## Permutes the nazo puyo asynchronously with web workers.
      ## This function requires that the field is settled.
      if not self[].canWork:
        return

      self.permuting.assign true
      self.replayData.stepsSeq.setLen 0

      unwrap self.simulator.nazoPuyoWrap:
        let originalNazoPuyo = it # NOTE: allow editing when working

        {.push warning[Uninit]: off.}
        discard originalNazoPuyo
          .asyncPermute(
            fixIndices, allowDoubleNotLast, allowDoubleLast, self[].progressRef
          )
          .then(
            (nazoPuyos: seq[originalNazo.type]) => (
              block:
                for nazoPuyo in nazoPuyos:
                  self[].replayData.stepsSeq.add nazoPuyo.puyoPuyo.steps
                self[].workPostProcess originalNazoPuyo
                self[].permuting.assign false
            )
          )
          .catch((error: Error) => console.error error)
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
