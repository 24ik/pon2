{.experimental: "strictDefs".}
{.experimental: "strictFuncs".}
{.experimental: "views".}

import std/[unittest]
import ../../src/pon2/core/[cell, common, fqdn, pair, placement, step]
import ../../src/pon2/private/[results2]

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
      cnts = [Col0: 1, 0, 1, 1, 0, 0]
      step = Step.init(cnts, true)
    check step.kind == Garbages
    check step.cnts == cnts
    check step.dropHard

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

# ------------------------------------------------
# Count
# ------------------------------------------------

block: # cellCnt, puyoCnt, colorPuyoCnt, garbagesCnt
  block:
    let step = Step.init YellowPurple
    check step.cellCnt(Red) == 0
    check step.cellCnt(Yellow) == 1
    check step.cellCnt(Garbage) == 0
    check step.puyoCnt == 2
    check step.colorPuyoCnt == 2
    check step.garbagesCnt == 0

  block:
    let step = Step.init([Col0: 2, 1, 0, 1, 0, 1], true)
    check step.cellCnt(Red) == 0
    check step.cellCnt(Yellow) == 0
    check step.cellCnt(Hard) == 5
    check step.cellCnt(Garbage) == 0
    check step.puyoCnt == 5
    check step.colorPuyoCnt == 0
    check step.garbagesCnt == 5

  block:
    let steps = @[Step.init RedGreen, Step.init([Col0: 5, 4, 5, 5, 5, 4], false)]
    check steps.cellCnt(Red) == 1
    check steps.cellCnt(Yellow) == 0
    check steps.cellCnt(Garbage) == 28
    check steps.cellCnt(Hard) == 0
    check steps.puyoCnt == 30
    check steps.colorPuyoCnt == 2
    check steps.garbagesCnt == 28

# ------------------------------------------------
# Step <-> string / URI
# ------------------------------------------------

block: # `$`, parseStep, toUriQuery
  let step = Step.init(BluePurple, Left3)

  check $step == "bp|43"
  check "bp|43".parseStep == Res[Step].ok step

  check step.toUriQuery(Pon2) == Res[string].ok "bp43"
  check step.toUriQuery(Ishikawa) == Res[string].ok "QG"
  check step.toUriQuery(Ips) == Res[string].ok "QG"

  check "bp43".parseStep(Pon2) == Res[Step].ok step
  check "QG".parseStep(Ishikawa) == Res[Step].ok step
  check "QG".parseStep(Ips) == Res[Step].ok step

block: # garbages
  block: # Garbage
    let step = Step.init([Col0: 2, 3, 3, 2, 2, 3], false)
    check $step == "(2,3,3,2,2,3)"
    check "(2,3,3,2,2,3)".parseStep == Res[Step].ok step

    check step.toUriQuery(Pon2) == Res[string].ok "o2_3_3_2_2_3o"
    check step.toUriQuery(Ishikawa) == Res[string].ok "yp"
    check step.toUriQuery(Ips) == Res[string].ok "yp"

    check "o2_3_3_2_2_3o".parseStep(Pon2) == Res[Step].ok step
    check "yp".parseStep(Ishikawa) == Res[Step].ok step
    check "yp".parseStep(Ips) == Res[Step].ok step

  block: # Hard
    let step = Step.init([Col0: 0, 0, 0, -1, 0, 0], true)
    check $step == "[0,0,0,-1,0,0]"
    check "[0,0,0,-1,0,0]".parseStep == Res[Step].ok step

    check step.toUriQuery(Pon2) == Res[string].ok "h0_0_0_-1_0_0h"
    check step.toUriQuery(Ishikawa).isErr
    check step.toUriQuery(Ips).isErr

# ------------------------------------------------
# Steps <-> string / URI
# ------------------------------------------------

block: # `$`, parseSteps, toUriQuery
  block: # Garbage
    let steps =
      @[
        Step.init RedGreen,
        Step.init([Col0: 1, 0, 0, 0, 0, 1], false),
        Step.init(YellowYellow, Up2),
      ]

    let str = "rg|\n(1,0,0,0,0,1)\nyy|3N"
    check $steps == str
    check str.parseSteps == Res[Steps].ok steps

    let query = "rgo1_0_0_0_0_1oyy3N"
    check steps.toUriQuery(Pon2) == Res[string].ok query
    check steps.toUriQuery(Ishikawa) == Res[string].ok "c1axG4"
    check steps.toUriQuery(Ips) == Res[string].ok "c1axG4"

    check query.parseSteps(Pon2) == Res[Steps].ok steps
    check "c1axG4".parseSteps(Ishikawa) == Res[Steps].ok steps
    check "c1axG4".parseSteps(Ips) == Res[Steps].ok steps

  block: # Hard
    let steps = @[Step.init([Col0: 0, 0, 2, 0, 1, 3], true), Step.init PurpleBlue]

    let str = "[0,0,2,0,1,3]\npb|"
    check $steps == str
    check str.parseSteps == Res[Steps].ok steps

    let query = "h0_0_2_0_1_3hpb"
    check steps.toUriQuery(Pon2) == Res[string].ok query
    check steps.toUriQuery(Ishikawa).isErr
    check steps.toUriQuery(Ips).isErr

    check query.parseSteps(Pon2) == Res[Steps].ok steps
