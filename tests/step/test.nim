{.push raises: [].}
{.experimental: "strictDefs".}
{.experimental: "strictFuncs".}
{.experimental: "views".}

import std/[unittest]
import ../../src/pon2/core/[cell, common, fqdn, pair, placement, step]

# ------------------------------------------------
# Constructor
# ------------------------------------------------

block: # init
  block:
    let step = Step.init(PurplePurple, Down3)
    check step.kind == PairPlace
    check step.pair == PurplePurple
    check step.placement == Down3

  block:
    let
      counts = [Col0: 1, 0, 1, 1, 0, 0]
      hard = true
      step = Step.init(counts, hard)
    check step.kind == NuisanceDrop
    check step.counts == counts
    check step.hard == hard

  block:
    let
      cross = false
      step = Step.init(cross)
    check step.kind == FieldRotate
    check step.cross == cross

  block:
    check Step.init == Step.init Pair.init

# ------------------------------------------------
# Property
# ------------------------------------------------

block: # isValid
  block:
    let step = Step.init BlueRed
    check step.isValid(originalCompatible = true)
    check step.isValid(originalCompatible = false)

  block:
    let step = Step.init([Col0: 3, 2, 2, 2, 2, 1], true)
    check not step.isValid(originalCompatible = true)
    check step.isValid(originalCompatible = false)

  block:
    let step = Step.init([Col0: -1, 0, 0, 0, 0, 0], false)
    check not step.isValid(originalCompatible = true)
    check not step.isValid(originalCompatible = false)

  check Step.init(cross = true).isValid
  check Step.init(cross = false).isValid

# ------------------------------------------------
# Count
# ------------------------------------------------

block: # cellCount, puyoCount, colorPuyoCount, nuisancePuyoCount
  block:
    let step = Step.init YellowPurple
    check step.cellCount(Red) == 0
    check step.cellCount(Yellow) == 1
    check step.cellCount(Garbage) == 0
    check step.puyoCount == 2
    check step.colorPuyoCount == 2
    check step.nuisancePuyoCount == 0

  block:
    let step = Step.init([Col0: 2, 1, 0, 1, 0, 1], hard = true)
    check step.cellCount(Red) == 0
    check step.cellCount(Yellow) == 0
    check step.cellCount(Hard) == 5
    check step.cellCount(Garbage) == 0
    check step.puyoCount == 5
    check step.colorPuyoCount == 0
    check step.nuisancePuyoCount == 5

  block:
    let steps = [Step.init RedGreen, Step.init([Col0: 5, 4, 5, 5, 5, 4], false)].toDeque
    check steps.cellCount(Red) == 1
    check steps.cellCount(Yellow) == 0
    check steps.cellCount(Garbage) == 28
    check steps.cellCount(Hard) == 0
    check steps.puyoCount == 30
    check steps.colorPuyoCount == 2
    check steps.nuisancePuyoCount == 28

  block:
    let steps = Step.init(cross = false)
    check steps.cellCount(Red) == 0
    check steps.cellCount(Yellow) == 0
    check steps.cellCount(Garbage) == 0
    check steps.cellCount(Hard) == 0
    check steps.puyoCount == 0
    check steps.colorPuyoCount == 0
    check steps.nuisancePuyoCount == 0

# ------------------------------------------------
# Step <-> string / URI
# ------------------------------------------------

block: # `$`, parseStep, toUriQuery
  block: # pair
    let step = Step.init(BluePurple, Left3)

    check $step == "bp|43"
    check "bp|43".parseStep == Pon2Result[Step].ok step

    check step.toUriQuery(Pon2) == Pon2Result[string].ok "bp43"
    check step.toUriQuery(IshikawaPuyo) == Pon2Result[string].ok "QG"
    check step.toUriQuery(Ips) == Pon2Result[string].ok "QG"

    check "bp43".parseStep(Pon2) == Pon2Result[Step].ok step
    check "QG".parseStep(IshikawaPuyo) == Pon2Result[Step].ok step
    check "QG".parseStep(Ips) == Pon2Result[Step].ok step

  block: # nuisance (garbage)
    let step = Step.init [Col0: 2, 3, 3, 2, 2, 3]
    check $step == "(2,3,3,2,2,3)"
    check "(2,3,3,2,2,3)".parseStep == Pon2Result[Step].ok step

    check step.toUriQuery(Pon2) == Pon2Result[string].ok "o2_3_3_2_2_3o"
    check step.toUriQuery(IshikawaPuyo) == Pon2Result[string].ok "yp"
    check step.toUriQuery(Ips) == Pon2Result[string].ok "yp"

    check "o2_3_3_2_2_3o".parseStep(Pon2) == Pon2Result[Step].ok step
    check "yp".parseStep(IshikawaPuyo) == Pon2Result[Step].ok step
    check "yp".parseStep(Ips) == Pon2Result[Step].ok step

  block: # nuisance (hard)
    let step = Step.init([Col0: 0, 0, 0, -1, 0, 0], hard = true)
    check $step == "[0,0,0,-1,0,0]"
    check "[0,0,0,-1,0,0]".parseStep == Pon2Result[Step].ok step

    check step.toUriQuery(Pon2) == Pon2Result[string].ok "h0_0_0_-1_0_0h"
    check step.toUriQuery(IshikawaPuyo).isErr
    check step.toUriQuery(Ips).isErr

  block: # rotate
    let step = Step.init(cross = false)
    check $step == "R"
    check "R".parseStep == Pon2Result[Step].ok step

    check step.toUriQuery(Pon2) == Pon2Result[string].ok "R"
    check step.toUriQuery(IshikawaPuyo).isErr
    check step.toUriQuery(Ips).isErr

  block: # cross rotate
    let step = Step.init(cross = true)
    check $step == "C"
    check "C".parseStep == Pon2Result[Step].ok step

    check step.toUriQuery(Pon2) == Pon2Result[string].ok "C"
    check step.toUriQuery(IshikawaPuyo).isErr
    check step.toUriQuery(Ips).isErr

# ------------------------------------------------
# Steps <-> string / URI
# ------------------------------------------------

block: # `$`, parseSteps, toUriQuery
  block: # pair, nuisance (garbage)
    let steps = [
      Step.init RedGreen,
      Step.init [Col0: 1, 0, 0, 0, 0, 1],
      Step.init(YellowYellow, Up2),
    ].toDeque

    let str = "rg|\n(1,0,0,0,0,1)\nyy|3N"
    check $steps == str
    check str.parseSteps == Pon2Result[Steps].ok steps

    let query = "rgo1_0_0_0_0_1oyy3N"
    check steps.toUriQuery(Pon2) == Pon2Result[string].ok query
    check steps.toUriQuery(IshikawaPuyo) == Pon2Result[string].ok "c1axG4"
    check steps.toUriQuery(Ips) == Pon2Result[string].ok "c1axG4"

    check query.parseSteps(Pon2) == Pon2Result[Steps].ok steps
    check "c1axG4".parseSteps(IshikawaPuyo) == Pon2Result[Steps].ok steps
    check "c1axG4".parseSteps(Ips) == Pon2Result[Steps].ok steps

  block: # nuisance (hard)
    let steps =
      [Step.init([Col0: 0, 0, 2, 0, 1, 3], hard = true), Step.init PurpleBlue].toDeque

    let str = "[0,0,2,0,1,3]\npb|"
    check $steps == str
    check str.parseSteps == Pon2Result[Steps].ok steps

    let query = "h0_0_2_0_1_3hpb"
    check steps.toUriQuery(Pon2) == Pon2Result[string].ok query
    check steps.toUriQuery(IshikawaPuyo).isErr
    check steps.toUriQuery(Ips).isErr

    check query.parseSteps(Pon2) == Pon2Result[Steps].ok steps

  block: # rotate
    let steps = [Step.init(cross = true), Step.init(cross = false)].toDeque

    let str = "C\nR"
    check $steps == str
    check str.parseSteps == Pon2Result[Steps].ok steps

    let query = "CR"
    check steps.toUriQuery(Pon2) == Pon2Result[string].ok query
    check steps.toUriQuery(IshikawaPuyo).isErr
    check steps.toUriQuery(Ips).isErr

    check query.parseSteps(Pon2) == Pon2Result[Steps].ok steps

  block: # empty steps
    let steps = Steps.init

    check $steps == ""
    check "".parseSteps == Pon2Result[Steps].ok steps

    for fqdn in SimulatorFqdn:
      check steps.toUriQuery(fqdn) == Pon2Result[string].ok ""
      check "".parseSteps(fqdn) == Pon2Result[Steps].ok steps
