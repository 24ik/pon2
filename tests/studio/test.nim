{.push raises: [].}
{.experimental: "strictDefs".}
{.experimental: "strictFuncs".}
{.experimental: "views".}

import std/[importutils, unittest]
import ../../src/pon2/[core]
import ../../src/pon2/app/[key, nazopuyowrap, simulator, studio]
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
    sim = Simulator.init EditorEdit
    replaySim = Simulator.init Replay

  studio.simulator.writeCell Cell.Red
  sim.writeCell Cell.Red
  check studio.simulator == sim

  studio.replaySimulator.writeCell Cell.Green
  replaySim.writeCell Cell.Green
  check studio.replaySimulator == replaySim

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
    nazo = parseNazoPuyo[TsuField](
      """
3連鎖するべし
======
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
bg|"""
    ).unsafeValue
    sim = Simulator.init(nazo, EditorEdit)
  var studio = Studio.init sim

  var nazoAns = nazo
  nazoAns.puyoPuyo.steps[0].optPlacement.assign OptPlacement.ok Left1
  nazoAns.puyoPuyo.steps[1].optPlacement.assign OptPlacement.ok Left1
  let simAns = Simulator.init(nazoAns, Replay)
  var studioAns = Studio.init sim
  studioAns.toggleFocus
  block:
    Studio.privateAccess
    StudioReplayData.privateAccess
    studioAns.replaySimulator.assign simAns
    studioAns.replayData.stepsSeq.assign @[nazoAns.puyoPuyo.steps]

  studio.solve
  check studio == studioAns
  check studio.replayStepsCount == 1
  check studio.replayStepsIndex == 0

  studio.nextReplay
  check studio == studioAns
  check studio.replayStepsCount == 1
  check studio.replayStepsIndex == 0

  studio.prevReplay
  check studio == studioAns
  check studio.replayStepsCount == 1
  check studio.replayStepsIndex == 0

  var nazoPermute1 = nazo
  nazoPermute1.puyoPuyo.steps[0].pair.assign GreenGreen
  nazoPermute1.puyoPuyo.steps[1].pair.assign BlueBlue
  nazoPermute1.puyoPuyo.steps[0].optPlacement.assign OptPlacement.ok Up0
  nazoPermute1.puyoPuyo.steps[1].optPlacement.assign OptPlacement.ok Up1
  let simPermute1 = Simulator.init(nazoPermute1, Replay)
  var studioPermute1 = Studio.init sim
  studioPermute1.toggleFocus
  block:
    Studio.privateAccess
    studioPermute1.replaySimulator.assign simPermute1

  var nazoPermute2 = nazo
  nazoPermute2.puyoPuyo.steps[0].pair.assign GreenBlue
  nazoPermute2.puyoPuyo.steps[1].pair.assign GreenBlue
  nazoPermute2.puyoPuyo.steps[0].optPlacement.assign OptPlacement.ok Right0
  nazoPermute2.puyoPuyo.steps[1].optPlacement.assign OptPlacement.ok Right0
  let simPermute2 = Simulator.init(nazoPermute2, Replay)
  var studioPermute2 = Studio.init sim
  studioPermute2.toggleFocus
  block:
    Studio.privateAccess
    StudioReplayData.privateAccess
    studioPermute2.replaySimulator.assign simPermute2
    studioPermute2.replayData.stepsIndex.assign 1

  block:
    Studio.privateAccess
    StudioReplayData.privateAccess
    let stepsSeq = @[nazoPermute1.puyoPuyo.steps, nazoPermute2.puyoPuyo.steps]
    studioPermute1.replayData.stepsSeq.assign stepsSeq
    studioPermute2.replayData.stepsSeq.assign stepsSeq

  studio.permute(@[], allowDoubleNotLast = true, allowDoubleLast = true)
  check studio == studioPermute1
  check studio.replayStepsCount == 2
  check studio.replayStepsIndex == 0

  studio.nextReplay
  check studio == studioPermute2
  check studio.replayStepsCount == 2
  check studio.replayStepsIndex == 1

  studio.nextReplay
  check studio == studioPermute1
  check studio.replayStepsCount == 2
  check studio.replayStepsIndex == 0

  studio.prevReplay
  check studio == studioPermute2
  check studio.replayStepsCount == 2
  check studio.replayStepsIndex == 1

  studio.prevReplay
  check studio == studioPermute1
  check studio.replayStepsCount == 2
  check studio.replayStepsIndex == 0

# ------------------------------------------------
# Keyboard
# ------------------------------------------------

block: # operate
  let
    nazo = parseNazoPuyo[TsuField](
      """
1連鎖するべし
======
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
pp|23"""
    ).unsafeValue
    studio1 = new Studio
  studio1[] = Studio.init Simulator.init(nazo, EditorEdit)
  var studio2 = Studio.init Simulator.init(nazo, EditorEdit)

  studio1.operate KeyEvent.init("Tab", shift = true)
  studio2.toggleFocus
  check studio1[] == studio2

  studio1[].solve
  studio2.solve

  studio1.operate KeyEvent.init 'a'
  studio2.prevReplay
  check studio1[] == studio2

  studio1.operate KeyEvent.init 'd'
  studio2.nextReplay
  check studio1[] == studio2

  studio1.operate KeyEvent.init 's'
  block:
    Studio.privateAccess
    studio2.replaySimulator.operate KeyEvent.init 's'
  check studio1[] == studio2

  studio1[].toggleFocus
  studio2.toggleFocus

  studio1.operate KeyEvent.init 's'
  block:
    Studio.privateAccess
    studio2.simulator.operate KeyEvent.init 's'
  check studio1[] == studio2
