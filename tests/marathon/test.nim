{.experimental: "strictDefs".}
{.experimental: "strictFuncs".}
{.experimental: "views".}

import std/[critbits, random, sequtils, sugar, unittest]
import ../../src/pon2/[core]
import ../../src/pon2/app/[key, marathon, simulator]

# ------------------------------------------------
# Operator
# ------------------------------------------------

func `==`(tree1, tree2: CritBitTree[void]): bool =
  tree1.items.toSeq == tree2.items.toSeq

# ------------------------------------------------
# Constructor
# ------------------------------------------------

block: # load, init
  var
    rng1 = 123.initRand
    marathon1 = Marathon.init rng1
  marathon1.load ["rr", "gb"]

  var
    rng2 = 123.initRand
    marathon2 = Marathon.init(rng2, ["rr", "gb"], SimulatorKeyBindPattern.Pon2)

  check marathon1 == marathon2

# ------------------------------------------------
# Property
# ------------------------------------------------

block: # matchQueryCount, allQueryCount
  var
    rng = 123.initRand
    marathon = Marathon.init rng
  check marathon.matchQueryCount == 0
  check marathon.allQueryCount == 0

  marathon.load @["rr"]
  check marathon.matchQueryCount == 0
  check marathon.allQueryCount == 0

  marathon.load @["gr"]
  check marathon.matchQueryCount == 0
  check marathon.allQueryCount == 0

  marathon.isReady = true
  check marathon.matchQueryCount == 0
  check marathon.allQueryCount == 2

  marathon.load @["ry"]
  check marathon.matchQueryCount == 0
  check marathon.allQueryCount == 2

  marathon.match "r"
  check marathon.matchQueryCount == 1
  check marathon.allQueryCount == 2

# ------------------------------------------------
# Match
# ------------------------------------------------

block: # match
  var
    rng = 123.initRand
    marathon = Marathon.init(rng, ["rrgg", "rgrg", "byby", "rgrb", "grrb", "bgyy"])

  marathon.match "r"
  check marathon.matchQueryCount == 0

  marathon.isReady = true

  marathon.match ""
  check marathon.matchQueryCount == 0

  marathon.match "r"
  check marathon.matchQueryCount == 3

  marathon.match "y"
  check marathon.matchQueryCount == 0

  marathon.match "rr"
  check marathon.matchQueryCount == 1

  marathon.match "rg"
  check marathon.matchQueryCount == 2

  marathon.match "gr"
  check marathon.matchQueryCount == 1

  marathon.match ""
  check marathon.matchQueryCount == 0

  marathon.match "a"
  check marathon.matchQueryCount == 0

  marathon.match "ab"
  check marathon.matchQueryCount == 5

  marathon.match "bc"
  check marathon.matchQueryCount == 0

  marathon.match "abac"
  check marathon.matchQueryCount == 2

  marathon.match "abc"
  check marathon.matchQueryCount == 2

  marathon.match "abcc"
  check marathon.matchQueryCount == 1

  marathon.match "cabb"
  check marathon.matchQueryCount == 1

# ------------------------------------------------
# Simulator
# ------------------------------------------------

block: # selectQuery, selectRandomQuery
  let queries = ["rrgg", "rgrg", "rgbb"]
  var
    rng = 123.initRand
    marathon = Marathon.init(rng, queries)

  marathon.selectQuery 0
  check marathon.simulator == Simulator.init PuyoPuyo.init

  marathon.match "ab"
  marathon.selectQuery 0
  check marathon.simulator == Simulator.init PuyoPuyo.init

  marathon.isReady = true
  marathon.match "ab"

  for i in 0 ..< 2:
    marathon.selectQuery i
    check not marathon.simulator.nazoPuyo.puyoPuyo.steps[0].pair.isDouble

  for _ in 1 .. 5:
    marathon.selectRandomQuery
    check not marathon.simulator.nazoPuyo.puyoPuyo.steps[0].pair.isDouble

  let stepsSeq = queries.mapIt(it.parseSteps(Pon2).unsafeValue).mapIt it.toSeq.map(
    (step: Step) => Step.init step.pair.swapped
  ).toDeque
  for _ in 1 .. 5:
    marathon.selectRandomQuery(fromMatched = false)
    check marathon.simulator.nazoPuyo.puyoPuyo.steps in stepsSeq

# ------------------------------------------------
# Key
# ------------------------------------------------

block: # operate
  var
    rng = 123.initRand
    marathon1 = Marathon.init(rng, ["rrgg", "rgrg", "rgbb", "rgyy", "rgyg"])
  marathon1.isReady = true

  marathon1.match "rg"
  var marathon2 = marathon1

  marathon1.operate KeyEventEnter
  marathon2.selectRandomQuery
  check marathon1 == marathon2

  marathon1.operate KeyEventShiftEnter
  marathon2.selectRandomQuery(fromMatched = false)
  check marathon1 == marathon2
