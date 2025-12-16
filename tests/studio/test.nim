{.push raises: [].}
{.experimental: "strictDefs".}
{.experimental: "strictFuncs".}
{.experimental: "views".}

import std/[importutils, unittest]
import ../../src/pon2/[core]
import ../../src/pon2/app/[key, simulator, studio]
import ../../src/pon2/private/[assign]

func `==`(progressRef1, progressRef2: ref tuple[now, total: int]): bool =
  progressRef1[] == progressRef2[]

# ------------------------------------------------
# Constructor
# ------------------------------------------------

block: # init
  check Studio.init == Studio.init Simulator.init EditorEdit

# ------------------------------------------------
# Property - Getter
# ------------------------------------------------

block:
  # simulator, replaySimulator, focusReplay, solving, permuting, working,
  # replayStepsCount, replayStepsIndex, progressRef
  let studio = Studio.init

  check studio.simulator == Simulator.init EditorEdit
  check studio.replaySimulator == Simulator.init Replay
  check not studio.focusReplay
  check not studio.solving
  check not studio.permuting
  check not studio.working
  check studio.replayStepsCount == 0
  check studio.replayStepsIndex == 0
  check studio.progressRef[] == (0, 0)

block: # simulator (var), replaySimulator (var)
  var
    studio = Studio.init
    simulator = Simulator.init EditorEdit
    replaySimulator = Simulator.init Replay

  studio.simulator.writeCell Cell.Red
  simulator.writeCell Cell.Red
  check studio.simulator == simulator

  studio.replaySimulator.writeCell Cell.Green
  replaySimulator.writeCell Cell.Green
  check studio.replaySimulator == replaySimulator

# ------------------------------------------------
# Edit - Other
# ------------------------------------------------

block: # toggleFocus
  var studio = Studio.init

  studio.toggleFocus
  check studio.focusReplay

# ------------------------------------------------
# Replay, Solve, Permute, Property
# ------------------------------------------------

block: # nextReplay, prevReplay, solve, permute
  let
    nazoPuyo =
      """
ちょうど3連鎖するべし
======
[通]
......
......
......
......
......
......
......
......
......
..oo..
..bb..
o.go.o
ggoggg
------
bg|
bg|""".parseNazoPuyo.unsafeValue
    simulator = Simulator.init(nazoPuyo, EditorEdit)
  var studio = Studio.init simulator

  var answerNazoPuyo = nazoPuyo
  answerNazoPuyo.puyoPuyo.steps[0].placement.assign Left1
  answerNazoPuyo.puyoPuyo.steps[1].placement.assign Left1
  let answerSimulator = Simulator.init(answerNazoPuyo, Replay)
  var answerStudio = Studio.init simulator
  answerStudio.toggleFocus
  block:
    Studio.privateAccess
    StudioReplayData.privateAccess
    answerStudio.replaySimulator.assign answerSimulator
    answerStudio.replayData.stepsSeq.assign @[answerNazoPuyo.puyoPuyo.steps]

  studio.solve
  check studio == answerStudio
  check studio.replayStepsCount == 1
  check studio.replayStepsIndex == 0

  studio.nextReplay
  check studio == answerStudio
  check studio.replayStepsCount == 1
  check studio.replayStepsIndex == 0

  studio.prevReplay
  check studio == answerStudio
  check studio.replayStepsCount == 1
  check studio.replayStepsIndex == 0

  var permuteNazoPuyo1 = nazoPuyo
  permuteNazoPuyo1.puyoPuyo.steps[0].pair.assign GreenGreen
  permuteNazoPuyo1.puyoPuyo.steps[1].pair.assign BlueBlue
  permuteNazoPuyo1.puyoPuyo.steps[0].placement.assign Up0
  permuteNazoPuyo1.puyoPuyo.steps[1].placement.assign Up1
  let permuteSimulator1 = Simulator.init(permuteNazoPuyo1, Replay)
  var permuteStudio1 = Studio.init simulator
  permuteStudio1.toggleFocus
  block:
    Studio.privateAccess
    permuteStudio1.replaySimulator.assign permuteSimulator1

  var permuteNazoPuyo2 = nazoPuyo
  permuteNazoPuyo2.puyoPuyo.steps[0].pair.assign GreenBlue
  permuteNazoPuyo2.puyoPuyo.steps[1].pair.assign GreenBlue
  permuteNazoPuyo2.puyoPuyo.steps[0].placement.assign Right0
  permuteNazoPuyo2.puyoPuyo.steps[1].placement.assign Right0
  let permuteSimulator2 = Simulator.init(permuteNazoPuyo2, Replay)
  var permuteStudio2 = Studio.init simulator
  permuteStudio2.toggleFocus
  block:
    Studio.privateAccess
    StudioReplayData.privateAccess
    permuteStudio2.replaySimulator.assign permuteSimulator2
    permuteStudio2.replayData.stepsIndex.assign 1

  block:
    Studio.privateAccess
    StudioReplayData.privateAccess
    let stepsSeq = @[permuteNazoPuyo1.puyoPuyo.steps, permuteNazoPuyo2.puyoPuyo.steps]
    permuteStudio1.replayData.stepsSeq.assign stepsSeq
    permuteStudio2.replayData.stepsSeq.assign stepsSeq

  studio.permute(@[], [0, 1])
  check studio == permuteStudio1
  check studio.replayStepsCount == 2
  check studio.replayStepsIndex == 0

  studio.nextReplay
  check studio == permuteStudio2
  check studio.replayStepsCount == 2
  check studio.replayStepsIndex == 1

  studio.nextReplay
  check studio == permuteStudio1
  check studio.replayStepsCount == 2
  check studio.replayStepsIndex == 0

  studio.prevReplay
  check studio == permuteStudio2
  check studio.replayStepsCount == 2
  check studio.replayStepsIndex == 1

  studio.prevReplay
  check studio == permuteStudio1
  check studio.replayStepsCount == 2
  check studio.replayStepsIndex == 0

# ------------------------------------------------
# Keyboard
# ------------------------------------------------

block: # operate
  let
    nazoPuyo =
      """
ちょうど1連鎖するべし
======
[通]
......
......
......
......
......
......
......
......
......
......
......
......
bbb...
------
by|
pp|23""".parseNazoPuyo.unsafeValue
    studio1 = new Studio
  studio1[] = Studio.init Simulator.init(nazoPuyo, EditorEdit)
  var studio2 = Studio.init Simulator.init(nazoPuyo, EditorEdit)

  studio1.operate KeyEventShiftTab
  studio2.toggleFocus
  check studio1[] == studio2

  studio1[].solve
  studio2.solve

  studio1.operate KeyEventA
  studio2.prevReplay
  check studio1[] == studio2

  studio1.operate KeyEventD
  studio2.nextReplay
  check studio1[] == studio2

  studio1.operate KeyEventS
  block:
    Studio.privateAccess
    studio2.replaySimulator.operate KeyEventS
  check studio1[] == studio2

  studio1[].toggleFocus
  studio2.toggleFocus

  studio1.operate KeyEventS
  block:
    Studio.privateAccess
    studio2.simulator.operate KeyEventS
  check studio1[] == studio2
