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

# ------------------------------------------------
# Property - Getter
# ------------------------------------------------

block: # simulator, replaySimulator, focusReplay
  let ide = Ide.init

  check ide.simulator == Simulator.init EditorEdit
  check ide.replaySimulator == Simulator.init Replay
  check not ide.focusReplay

# ------------------------------------------------
# Edit - Other
# ------------------------------------------------

block: # toggleFocus
  var ide = Ide.init

  ide.toggleFocus
  check ide.focusReplay

# ------------------------------------------------
# Replay, Solve, Permute
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
  block:
    Ide.privateAccess
    IdeReplayData.privateAccess
    ideAns.replaySimulator.assign simAns
    ideAns.replayData.stepsSeq.assign @[nazoAns.puyoPuyo.steps]

  ide.solve
  check ide == ideAns

  ide.nextReplay
  check ide == ideAns

  ide.prevReplay
  check ide == ideAns

  var nazoPermute1 = nazo
  nazoPermute1.puyoPuyo.steps[0].pair.assign GreenGreen
  nazoPermute1.puyoPuyo.steps[1].pair.assign BlueBlue
  nazoPermute1.puyoPuyo.steps[0].optPlacement.assign OptPlacement.ok Up0
  nazoPermute1.puyoPuyo.steps[1].optPlacement.assign OptPlacement.ok Up1
  let simPermute1 = Simulator.init(nazoPermute1, Replay)
  var idePermute1 = Ide.init sim
  idePermute1.toggleFocus
  block:
    Ide.privateAccess
    idePermute1.replaySimulator.assign simPermute1

  var nazoPermute2 = nazo
  nazoPermute2.puyoPuyo.steps[0].pair.assign GreenBlue
  nazoPermute2.puyoPuyo.steps[1].pair.assign GreenBlue
  nazoPermute2.puyoPuyo.steps[0].optPlacement.assign OptPlacement.ok Right0
  nazoPermute2.puyoPuyo.steps[1].optPlacement.assign OptPlacement.ok Right0
  let simPermute2 = Simulator.init(nazoPermute2, Replay)
  var idePermute2 = Ide.init sim
  idePermute2.toggleFocus
  block:
    Ide.privateAccess
    IdeReplayData.privateAccess
    idePermute2.replaySimulator.assign simPermute2
    idePermute2.replayData.stepsIdx.assign 1

  block:
    Ide.privateAccess
    IdeReplayData.privateAccess
    let stepsSeq = @[nazoPermute1.puyoPuyo.steps, nazoPermute2.puyoPuyo.steps]
    idePermute1.replayData.stepsSeq.assign stepsSeq
    idePermute2.replayData.stepsSeq.assign stepsSeq

  ide.permute(@[], allowDblNotLast = true, allowDblLast = true)
  check ide == idePermute1

  ide.nextReplay
  check ide == idePermute2

  ide.nextReplay
  check ide == idePermute1

  ide.prevReplay
  check ide == idePermute2

  ide.prevReplay
  check ide == idePermute1

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
    ide2 = ide1

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
  block:
    Ide.privateAccess
    ide2.replaySimulator.operate KeyEvent.init 's'
  check ide1 == ide2

  ide1.toggleFocus
  ide2.toggleFocus

  ide1.operate KeyEvent.init 's'
  block:
    Ide.privateAccess
    ide2.simulator.operate KeyEvent.init 's'
  check ide1 == ide2
