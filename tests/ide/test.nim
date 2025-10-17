{.push raises: [].}
{.experimental: "strictDefs".}
{.experimental: "strictFuncs".}
{.experimental: "views".}

import std/[importutils, unittest]
import ../../src/pon2/[core]
import ../../src/pon2/app/[key, ide, nazopuyowrap, simulator]
import ../../src/pon2/private/[assign3]

# ------------------------------------------------
# Constructor
# ------------------------------------------------

block: # init
  check Ide.init == Ide.init Simulator.init EditorEdit

  let simRef = new Simulator
  simRef[] = Simulator.init ViewerPlay
  check Ide.init(Simulator.init ViewerPlay) == Ide.init simRef

# ------------------------------------------------
# Operator, Copy
# ------------------------------------------------

block: # `==`, copy
  var ide1 = Ide.init
  let ide2 = ide1

  ide1.simulator[].moveCursorUp
  check ide1 == ide2

  var ide3 = Ide.init
  let ide4 = ide3.copy

  ide3.simulator[].moveCursorUp
  check ide3 != ide4

# ------------------------------------------------
# Property - Getter
# ------------------------------------------------

block: # simulator, replaySimulator, focusReplay, replayStepsCnt, replayStepsCnt
  let ide = Ide.init

  check ide.simulator[] == Simulator.init EditorEdit
  check ide.replaySimulator[] == Simulator.init Replay
  check not ide.focusReplay
  check not ide.working
  check ide.replayStepsCnt == 0
  check ide.replayStepsIdx == 0

# ------------------------------------------------
# Edit - Other
# ------------------------------------------------

block: # toggleFocus
  var ide = Ide.init

  ide.toggleFocus
  check ide.focusReplay

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
  var ide = Ide.init sim

  var nazoAns = nazo
  nazoAns.puyoPuyo.steps[0].optPlacement.assign OptPlacement.ok Left1
  nazoAns.puyoPuyo.steps[1].optPlacement.assign OptPlacement.ok Left1
  let simAns = Simulator.init(nazoAns, Replay)
  var ideAns = Ide.init sim
  ideAns.toggleFocus
  ideAns.replaySimulator[] = simAns
  block:
    Ide.privateAccess
    IdeReplayData.privateAccess
    ideAns.replayData.stepsSeq.assign @[nazoAns.puyoPuyo.steps]

  ide.solve
  check ide == ideAns
  check ide.replayStepsCnt == 1
  check ide.replayStepsIdx == 0

  ide.nextReplay
  check ide == ideAns
  check ide.replayStepsCnt == 1
  check ide.replayStepsIdx == 0

  ide.prevReplay
  check ide == ideAns
  check ide.replayStepsCnt == 1
  check ide.replayStepsIdx == 0

  var nazoPermute1 = nazo
  nazoPermute1.puyoPuyo.steps[0].pair.assign GreenGreen
  nazoPermute1.puyoPuyo.steps[1].pair.assign BlueBlue
  nazoPermute1.puyoPuyo.steps[0].optPlacement.assign OptPlacement.ok Up0
  nazoPermute1.puyoPuyo.steps[1].optPlacement.assign OptPlacement.ok Up1
  let simPermute1 = Simulator.init(nazoPermute1, Replay)
  var idePermute1 = Ide.init sim
  idePermute1.toggleFocus
  idePermute1.replaySimulator[] = simPermute1

  var nazoPermute2 = nazo
  nazoPermute2.puyoPuyo.steps[0].pair.assign GreenBlue
  nazoPermute2.puyoPuyo.steps[1].pair.assign GreenBlue
  nazoPermute2.puyoPuyo.steps[0].optPlacement.assign OptPlacement.ok Right0
  nazoPermute2.puyoPuyo.steps[1].optPlacement.assign OptPlacement.ok Right0
  let simPermute2 = Simulator.init(nazoPermute2, Replay)
  var idePermute2 = Ide.init sim
  idePermute2.toggleFocus
  idePermute2.replaySimulator[] = simPermute2
  block:
    Ide.privateAccess
    IdeReplayData.privateAccess
    idePermute2.replayData.stepsIdx.assign 1

  block:
    Ide.privateAccess
    IdeReplayData.privateAccess
    let stepsSeq = @[nazoPermute1.puyoPuyo.steps, nazoPermute2.puyoPuyo.steps]
    idePermute1.replayData.stepsSeq.assign stepsSeq
    idePermute2.replayData.stepsSeq.assign stepsSeq

  ide.permute(@[], allowDblNotLast = true, allowDblLast = true)
  check ide == idePermute1
  check ide.replayStepsCnt == 2
  check ide.replayStepsIdx == 0

  ide.nextReplay
  check ide == idePermute2
  check ide.replayStepsCnt == 2
  check ide.replayStepsIdx == 1

  ide.nextReplay
  check ide == idePermute1
  check ide.replayStepsCnt == 2
  check ide.replayStepsIdx == 0

  ide.prevReplay
  check ide == idePermute2
  check ide.replayStepsCnt == 2
  check ide.replayStepsIdx == 1

  ide.prevReplay
  check ide == idePermute1
  check ide.replayStepsCnt == 2
  check ide.replayStepsIdx == 0

# ------------------------------------------------
# Keyboard
# ------------------------------------------------

block: # operate
  let nazo = parseNazoPuyo[TsuField](
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
  var
    ide1 = Ide.init Simulator.init(nazo, EditorEdit)
    ide2 = ide1.copy

  ide1.operate KeyEvent.init("Tab", shift = true)
  ide2.toggleFocus
  check ide1 == ide2

  ide1.operate KeyEvent.init "Enter"
  ide2.solve
  check ide1 == ide2

  ide1.operate KeyEvent.init 'a'
  ide2.prevReplay
  check ide1 == ide2

  ide1.operate KeyEvent.init 'd'
  ide2.nextReplay
  check ide1 == ide2

  ide1.operate KeyEvent.init 's'
  ide2.replaySimulator[].operate KeyEvent.init 's'
  check ide1 == ide2

  ide1.toggleFocus
  ide2.toggleFocus

  ide1.operate KeyEvent.init 's'
  ide2.simulator[].operate KeyEvent.init 's'
  check ide1 == ide2
