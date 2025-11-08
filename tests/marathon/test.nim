{.experimental: "strictDefs".}
{.experimental: "strictFuncs".}
{.experimental: "views".}

import std/[critbits, random, sequtils, sets, sugar, unittest]
import ../../src/pon2/[core]
import ../../src/pon2/app/[key, marathon, nazopuyowrap, simulator]

# ------------------------------------------------
# Operator
# ------------------------------------------------

func `==`(tree1, tree2: CritBitTree[void]): bool =
  tree1.items.toSeq == tree2.items.toSeq

# ------------------------------------------------
# Load / Property
# ------------------------------------------------

block: # load, isReady, `isReady=`, allQueryCnt
  var
    rng = 123.initRand
    marathon = Marathon.init rng
  check not marathon.isReady
  check marathon.allQueryCnt == 0

  marathon.load @["rr"]
  check not marathon.isReady
  check marathon.allQueryCnt == 0

  marathon.load @["rg"]
  check not marathon.isReady
  check marathon.allQueryCnt == 0

  marathon.isReady = true
  check marathon.isReady
  check marathon.allQueryCnt == 2

  marathon.isReady = false
  check marathon.isReady
  check marathon.allQueryCnt == 2

  marathon.load @["ry"]
  check marathon.isReady
  check marathon.allQueryCnt == 2

  check Marathon.init(rng, ["rr", "rg"], isReady = true) == marathon
  check Marathon.init(rng, @["rr", "rg"], isReady = true) == marathon

block: # simulator
  var
    rng = 123.initRand
    marathon = Marathon.init rng

  var sim = Simulator.init PuyoPuyo[TsuField].init
  check marathon.simulator == sim

  sim.writeCell Cell.Green
  marathon.simulator.writeCell Cell.Green
  check marathon.simulator == sim

# ------------------------------------------------
# Match
# ------------------------------------------------

block: # matchQueryCnt, match
  var
    rng = 123.initRand
    marathon = Marathon.init(rng, ["rrgg", "rgrg", "byby", "rgrb", "grrb", "bgyy"])

  marathon.match "r"
  check marathon.matchQueryCnt == 0

  marathon.isReady = true

  marathon.match ""
  check marathon.matchQueryCnt == 0

  marathon.match "r"
  check marathon.matchQueryCnt == 3

  marathon.match "y"
  check marathon.matchQueryCnt == 0

  marathon.match "rr"
  check marathon.matchQueryCnt == 1

  marathon.match "rg"
  check marathon.matchQueryCnt == 2

  marathon.match "gr"
  check marathon.matchQueryCnt == 1

  marathon.match ""
  check marathon.matchQueryCnt == 0

  marathon.match "a"
  check marathon.matchQueryCnt == 0

  marathon.match "ab"
  check marathon.matchQueryCnt == 5

  marathon.match "bc"
  check marathon.matchQueryCnt == 0

  marathon.match "abac"
  check marathon.matchQueryCnt == 2

  marathon.match "abc"
  check marathon.matchQueryCnt == 2

  marathon.match "abcc"
  check marathon.matchQueryCnt == 1

  marathon.match "cabb"
  check marathon.matchQueryCnt == 1

# ------------------------------------------------
# Simulator
# ------------------------------------------------

block: # selectQuery, selectRandomQuery
  let queries = ["rrgg", "rgrg", "rgbb"]
  var
    rng = 123.initRand
    marathon = Marathon.init(rng, queries)

  marathon.selectQuery 0
  check marathon.simulator == Simulator.init PuyoPuyo[TsuField].init

  marathon.match "ab"
  marathon.selectQuery 0
  check marathon.simulator == Simulator.init PuyoPuyo[TsuField].init

  marathon.isReady = true
  marathon.match "ab"

  for i in 0 ..< 2:
    marathon.selectQuery i
    unwrapNazoPuyo marathon.simulator.nazoPuyoWrap:
      check not it.steps[0].pair.isDbl

  for _ in 1 .. 5:
    marathon.selectRandomQuery
    unwrapNazoPuyo marathon.simulator.nazoPuyoWrap:
      check not it.steps[0].pair.isDbl

  let stepsSeq = queries.mapIt(it.parseSteps(Pon2).unsafeValue).mapIt it.toSeq.map(
    (step: Step) => Step.init step.pair.swapped
  ).toDeque2
  for _ in 1 .. 5:
    marathon.selectRandomQuery(fromMatched = false)
    unwrapNazoPuyo marathon.simulator.nazoPuyoWrap:
      check it.steps in stepsSeq

# ------------------------------------------------
# Keyboard
# ------------------------------------------------

block: # operate
  var
    rng = 123.initRand
    marathon1 = Marathon.init(rng, ["rrgg", "rgrg", "rgbb", "rgyy", "rgyg"])
  marathon1.isReady = true

  marathon1.match "rg"
  var marathon2 = marathon1

  marathon1.operate KeyEvent.init("Enter")
  marathon2.selectRandomQuery
  check marathon1 == marathon2

  marathon1.operate KeyEvent.init("Enter", shift = true)
  marathon2.selectRandomQuery(fromMatched = false)
  check marathon1 == marathon2
