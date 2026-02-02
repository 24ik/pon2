## This module implements studios.
##

{.push raises: [].}
{.experimental: "strictDefs".}
{.experimental: "strictFuncs".}
{.experimental: "views".}

import std/[deques, sugar]
import ./[key, permute, simulator, solve]
import ../[core]
import ../private/[assign, utils]

export simulator

when defined(js) or defined(nimsuggest):
  when not defined(pon2.build.worker):
    import std/[jsconsole]
    import ../private/[webworkers]

type
  StudioReplayData = object ## Data for the replay simulator.
    stepsSeq: seq[Steps]
    stepsIndex: int

  Studio* = object ## Studio for Puyo Puyo and Nazo Puyo.
    simulator*: Simulator
    replaySimulator*: Simulator

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
  T.init Simulator.init EditEditor

# ------------------------------------------------
# Property
# ------------------------------------------------

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

func progress*(self: Studio): tuple[now, total: int] =
  ## Returns the progress.
  self.progressRef[]

# ------------------------------------------------
# Toggle
# ------------------------------------------------

func toggleFocus*(self: var Studio) =
  ## Toggles focusing to replay simulator or not.
  self.focusReplay.toggle

# ------------------------------------------------
# Replay
# ------------------------------------------------

func updateReplaySimulator(self: var Studio) =
  ## Updates the replay simulator.
  self.replaySimulator.reset

  var nazoPuyo = self.replaySimulator.nazoPuyo
  nazoPuyo.puyoPuyo.steps.assign self.replayData.stepsSeq[self.replayData.stepsIndex]

  self.replaySimulator.assign Simulator.init(
    nazoPuyo, Replay, self.replaySimulator.keyBindPattern
  )

func nextReplay*(self: var Studio) =
  ## Shows the next solution.
  if self.replayData.stepsSeq.len == 0:
    return

  if self.replayData.stepsIndex == self.replayData.stepsSeq.len.pred:
    self.replayData.stepsIndex.assign 0
  else:
    self.replayData.stepsIndex += 1

  self.updateReplaySimulator

func prevReplay*(self: var Studio) =
  ## Shows the previous solution.
  if self.simulator.mode notin EditorModes or self.replayData.stepsSeq.len == 0:
    return

  if self.replayData.stepsIndex == 0:
    self.replayData.stepsIndex.assign self.replayData.stepsSeq.len.pred
  else:
    self.replayData.stepsIndex -= 1

  self.updateReplaySimulator

# ------------------------------------------------
# Terminate
# ------------------------------------------------

when defined(js) or defined(nimsuggest):
  when not defined(pon2.build.worker):
    proc stopWork*(self: ref Studio) =
      ## Stops the current work.
      if not self[].working:
        return

      webWorkerPool.terminate

      self[].solving.assign false
      self[].permuting.assign false
      self[].replayData.stepsSeq.setLen 0
      self[].progressRef[] = (0, 0)

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

func workPostProcess(self: var Studio, nazoPuyo: NazoPuyo) =
  ## Updates the replay simulator.
  if self.replayData.stepsSeq.len > 0:
    self.focusReplay.assign true
    self.replayData.stepsIndex.assign 0

    var nazoPuyo2 = nazoPuyo
    nazoPuyo2.puyoPuyo.steps.assign self.replayData.stepsSeq[self.replayData.stepsIndex]
    self.replaySimulator.assign Simulator.init(
      nazoPuyo2, Replay, self.replaySimulator.keyBindPattern
    )
  else:
    self.focusReplay.assign false

proc setSolutions(
    self: var Studio, originalNazoPuyo: NazoPuyo, solutions: seq[Solution]
) =
  ## Sets the solutions.
  let stepsSeq = collect:
    for solution in solutions:
      var steps = originalNazoPuyo.puyoPuyo.steps
      for stepIndex, placement in solution:
        if originalNazoPuyo.puyoPuyo.steps[stepIndex].kind == PairPlace:
          steps[stepIndex].placement.assign placement

      steps

  self.replayData.stepsSeq.assign stepsSeq

proc solve*(self: var Studio) =
  ## Solves the nazo puyo.
  ## This function requires that the field is settled.
  if not self.canWork:
    return

  self.solving.assign true
  self.replayData.stepsSeq.setLen 0

  self.setSolutions self.simulator.nazoPuyo, self.simulator.nazoPuyo.solve
  self.workPostProcess self.simulator.nazoPuyo

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

      let originalNazoPuyo = self[].simulator.nazoPuyo # NOTE: allow editing when working

      {.push warning[Uninit]: off.}
      discard originalNazoPuyo
        .asyncSolve(self[].progressRef)
        .then(
          (solutions: seq[Solution]) => (
            block:
              self[].setSolutions originalNazoPuyo, solutions
              self[].workPostProcess originalNazoPuyo
              self[].solving.assign false
          )
        )
        .catch((error: Error) => console.error error)
      {.pop.}

# ------------------------------------------------
# Permute
# ------------------------------------------------

proc permute*(self: var Studio, fixIndices, allowDoubleIndices: openArray[int]) =
  ## Permutes the nazo puyo.
  ## This function requires that the field is settled.
  if not self.canWork:
    return

  self.permuting.assign true
  self.replayData.stepsSeq.setLen 0

  for nazoPuyo in self.simulator.nazoPuyo.permute(fixIndices, allowDoubleIndices):
    self.replayData.stepsSeq.add nazoPuyo.puyoPuyo.steps
  self.workPostProcess self.simulator.nazoPuyo

  self.permuting.assign false

when defined(js) or defined(nimsuggest):
  when not defined(pon2.build.worker):
    proc asyncPermute*(
        self: ref Studio, fixIndices, allowDoubleIndices: openArray[int]
    ) =
      ## Permutes the nazo puyo asynchronously with web workers.
      ## This function requires that the field is settled.
      if not self[].canWork:
        return

      self.permuting.assign true
      self.replayData.stepsSeq.setLen 0

      let originalNazoPuyo = self[].simulator.nazoPuyo # NOTE: allow editing when working

      {.push warning[Uninit]: off.}
      discard originalNazoPuyo
        .asyncPermute(fixIndices, allowDoubleIndices, self[].progressRef)
        .then(
          (nazoPuyos: seq[NazoPuyo]) => (
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
# Key
# ------------------------------------------------

proc operate*(self: ref Studio, key: KeyEvent): bool {.discardable.} =
  ## Performs an action specified by the key.
  ## Returns `true` if the key is handled.
  if self[].simulator.mode in EditorModes:
    # focus
    if key == KeyEventShiftTab:
      self[].toggleFocus
      return true

    if self[].focusReplay:
      # next/prev replay
      if key == KeyEventA:
        self[].prevReplay
        return true
      if key == KeyEventD:
        self[].nextReplay
        return true

      return self[].replaySimulator.operate key

  return self[].simulator.operate key
