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
    let step = Step.init(RedGreen, NonePlacement)
    check step.kind == PairPlacement
    check step.pair == RedGreen
    check step.optPlacement == NonePlacement

  block:
    let step = Step.init BlueYellow
    check step.kind == PairPlacement
    check step.pair == BlueYellow
    check step.optPlacement == NonePlacement

  block:
    let step = Step.init(PurplePurple, Down3)
    check step.kind == PairPlacement
    check step.pair == PurplePurple
    check step.optPlacement == OptPlacement.ok Down3

  block:
    let
      counts = [Col0: 1, 0, 1, 1, 0, 0]
      step = Step.init(counts, true)
    check step.kind == Garbages
    check step.counts == counts
    check step.dropHard

  block:
    let
      cross = false
      step = Step.init(cross)
    check step.kind == Rotate
    check step.cross == cross

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

block: # cellCount, puyoCount, colorPuyoCount, garbagesCount
  block:
    let step = Step.init YellowPurple
    check step.cellCount(Red) == 0
    check step.cellCount(Yellow) == 1
    check step.cellCount(Garbage) == 0
    check step.puyoCount == 2
    check step.colorPuyoCount == 2
    check step.garbagesCount == 0

  block:
    let step = Step.init([Col0: 2, 1, 0, 1, 0, 1], true)
    check step.cellCount(Red) == 0
    check step.cellCount(Yellow) == 0
    check step.cellCount(Hard) == 5
    check step.cellCount(Garbage) == 0
    check step.puyoCount == 5
    check step.colorPuyoCount == 0
    check step.garbagesCount == 5

  block:
    let steps = [Step.init RedGreen, Step.init([Col0: 5, 4, 5, 5, 5, 4], false)].toDeque
    check steps.cellCount(Red) == 1
    check steps.cellCount(Yellow) == 0
    check steps.cellCount(Garbage) == 28
    check steps.cellCount(Hard) == 0
    check steps.puyoCount == 30
    check steps.colorPuyoCount == 2
    check steps.garbagesCount == 28

  block:
    let steps = Step.init(cross = false)
    check steps.cellCount(Red) == 0
    check steps.cellCount(Yellow) == 0
    check steps.cellCount(Garbage) == 0
    check steps.cellCount(Hard) == 0
    check steps.puyoCount == 0
    check steps.colorPuyoCount == 0
    check steps.garbagesCount == 0

# ------------------------------------------------
# Step <-> string / URI
# ------------------------------------------------

block: # `$`, parseStep, toUriQuery
  let step = Step.init(BluePurple, Left3)

  check $step == "bp|43"
  check "bp|43".parseStep == StrErrorResult[Step].ok step

  check step.toUriQuery(Pon2) == StrErrorResult[string].ok "bp43"
  check step.toUriQuery(Ishikawa) == StrErrorResult[string].ok "QG"
  check step.toUriQuery(Ips) == StrErrorResult[string].ok "QG"

  check "bp43".parseStep(Pon2) == StrErrorResult[Step].ok step
  check "QG".parseStep(Ishikawa) == StrErrorResult[Step].ok step
  check "QG".parseStep(Ips) == StrErrorResult[Step].ok step

block: # garbages
  block: # Garbage
    let step = Step.init([Col0: 2, 3, 3, 2, 2, 3], false)
    check $step == "(2,3,3,2,2,3)"
    check "(2,3,3,2,2,3)".parseStep == StrErrorResult[Step].ok step

    check step.toUriQuery(Pon2) == StrErrorResult[string].ok "o2_3_3_2_2_3o"
    check step.toUriQuery(Ishikawa) == StrErrorResult[string].ok "yp"
    check step.toUriQuery(Ips) == StrErrorResult[string].ok "yp"

    check "o2_3_3_2_2_3o".parseStep(Pon2) == StrErrorResult[Step].ok step
    check "yp".parseStep(Ishikawa) == StrErrorResult[Step].ok step
    check "yp".parseStep(Ips) == StrErrorResult[Step].ok step

  block: # Hard
    let step = Step.init([Col0: 0, 0, 0, -1, 0, 0], true)
    check $step == "[0,0,0,-1,0,0]"
    check "[0,0,0,-1,0,0]".parseStep == StrErrorResult[Step].ok step

    check step.toUriQuery(Pon2) == StrErrorResult[string].ok "h0_0_0_-1_0_0h"
    check step.toUriQuery(Ishikawa).isErr
    check step.toUriQuery(Ips).isErr

  block: # rotate
    let step = Step.init(cross = false)
    check $step == "O"
    check "O".parseStep == StrErrorResult[Step].ok step

    check step.toUriQuery(Pon2) == StrErrorResult[string].ok "O"
    check step.toUriQuery(Ishikawa).isErr
    check step.toUriQuery(Ips).isErr

  block: # cross rotate
    let step = Step.init(cross = true)
    check $step == "X"
    check "X".parseStep == StrErrorResult[Step].ok step

    check step.toUriQuery(Pon2) == StrErrorResult[string].ok "X"
    check step.toUriQuery(Ishikawa).isErr
    check step.toUriQuery(Ips).isErr

# ------------------------------------------------
# Steps <-> string / URI
# ------------------------------------------------

block: # `$`, parseSteps, toUriQuery
  block: # Garbage
    let steps = [
      Step.init RedGreen,
      Step.init([Col0: 1, 0, 0, 0, 0, 1], false),
      Step.init(YellowYellow, Up2),
    ].toDeque

    let str = "rg|\n(1,0,0,0,0,1)\nyy|3N"
    check $steps == str
    check str.parseSteps == StrErrorResult[Steps].ok steps

    let query = "rgo1_0_0_0_0_1oyy3N"
    check steps.toUriQuery(Pon2) == StrErrorResult[string].ok query
    check steps.toUriQuery(Ishikawa) == StrErrorResult[string].ok "c1axG4"
    check steps.toUriQuery(Ips) == StrErrorResult[string].ok "c1axG4"

    check query.parseSteps(Pon2) == StrErrorResult[Steps].ok steps
    check "c1axG4".parseSteps(Ishikawa) == StrErrorResult[Steps].ok steps
    check "c1axG4".parseSteps(Ips) == StrErrorResult[Steps].ok steps

  block: # Hard
    let steps =
      [Step.init([Col0: 0, 0, 2, 0, 1, 3], true), Step.init PurpleBlue].toDeque

    let str = "[0,0,2,0,1,3]\npb|"
    check $steps == str
    check str.parseSteps == StrErrorResult[Steps].ok steps

    let query = "h0_0_2_0_1_3hpb"
    check steps.toUriQuery(Pon2) == StrErrorResult[string].ok query
    check steps.toUriQuery(Ishikawa).isErr
    check steps.toUriQuery(Ips).isErr

    check query.parseSteps(Pon2) == StrErrorResult[Steps].ok steps

  block: # rotate
    let steps = [Step.init(cross = true), Step.init(cross = false)].toDeque

    let str = "X\nO"
    check $steps == str
    check str.parseSteps == StrErrorResult[Steps].ok steps

    let query = "XO"
    check steps.toUriQuery(Pon2) == StrErrorResult[string].ok query
    check steps.toUriQuery(Ishikawa).isErr
    check steps.toUriQuery(Ips).isErr

    check query.parseSteps(Pon2) == StrErrorResult[Steps].ok steps

  block: # empty steps
    let steps = Steps.init

    check $steps == ""
    check "".parseSteps == StrErrorResult[Steps].ok steps

    for fqdn in SimulatorFqdn:
      check steps.toUriQuery(fqdn) == StrErrorResult[string].ok ""
      check "".parseSteps(fqdn) == StrErrorResult[Steps].ok steps
