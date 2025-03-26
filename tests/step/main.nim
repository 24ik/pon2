{.experimental: "strictDefs".}
{.experimental: "strictFuncs".}
{.experimental: "views".}

import std/[unittest]
import ../../src/pon2/core/[cell, common, fqdn, pair, placement, step]
import ../../src/pon2/private/[results2]

proc main*() =
  # ------------------------------------------------
  # Constructor
  # ------------------------------------------------

  # init
  block:
    block:
      let step = Step.init(RedGreen, NonePlacement)
      check step.pair == RedGreen
      check step.optPlacement == NonePlacement

    block:
      let step = Step.init BlueYellow
      check step.pair == BlueYellow
      check step.optPlacement == NonePlacement

    block:
      let step = Step.init(PurplePurple, Down3)
      check step.pair == PurplePurple
      check step.optPlacement == OptPlacement.ok Down3

    block:
      let
        garbageCnts = [Col0: 1, 0, 1, 1, 0, 0]
        step = Step.init garbageCnts
      check step.garbageCnts == garbageCnts

  # ------------------------------------------------
  # Property
  # ------------------------------------------------

  # isValid
  block:
    block:
      let step = Step.init BlueRed
      check step.isValid(originalCompatible = true)
      check step.isValid(originalCompatible = false)

    block:
      let step = Step.init [Col0: 3, 2, 2, 2, 2, 1]
      check not step.isValid(originalCompatible = true)
      check step.isValid(originalCompatible = false)

    block:
      let step = Step.init [Col0: -1, 0, 0, 0, 0, 0]
      check not step.isValid(originalCompatible = true)
      check not step.isValid(originalCompatible = false)

  # ------------------------------------------------
  # Count
  # ------------------------------------------------

  # cellCnt, colorCnt, garbageCnt
  block:
    block:
      let step = Step.init YellowPurple
      check step.cellCnt(Red) == 0
      check step.cellCnt(Yellow) == 1
      check step.cellCnt(Garbage) == 0
      check step.cellCnt == 2
      check step.colorCnt == 2
      check step.garbageCnt == 0

    block:
      let step = Step.init [Col0: 2, 1, 0, 1, 0, 1]
      check step.cellCnt(Red) == 0
      check step.cellCnt(Yellow) == 0
      check step.cellCnt(Garbage) == 5
      check step.cellCnt == 5
      check step.colorCnt == 0
      check step.garbageCnt == 5

    block:
      let steps = @[Step.init RedGreen, Step.init [Col0: 5, 4, 5, 5, 5, 4]]
      check steps.cellCnt(Red) == 1
      check steps.cellCnt(Yellow) == 0
      check steps.cellCnt(Garbage) == 28
      check steps.cellCnt == 30
      check steps.colorCnt == 2
      check steps.garbageCnt == 28

  # ------------------------------------------------
  # Step <-> string / URI
  # ------------------------------------------------

  # `$`, parseStep, toUriQuery
  block:
    let step = Step.init(BluePurple, Left3)

    check $step == "bp|43"
    check "bp|43".parseStep == Res[Step].ok step

    check step.toUriQuery(Pon2) == Res[string].ok "bp43"
    check step.toUriQuery(Ishikawa) == Res[string].ok "QG"
    check step.toUriQuery(Ips) == Res[string].ok "QG"

    check "bp43".parseStep(Pon2) == Res[Step].ok step
    check "QG".parseStep(Ishikawa) == Res[Step].ok step
    check "QG".parseStep(Ips) == Res[Step].ok step

  # garbage
  block:
    block:
      let step = Step.init [Col0: 2, 3, 3, 2, 2, 3]
      check $step == "(2,3,3,2,2,3)"
      check "(2,3,3,2,2,3)".parseStep == Res[Step].ok step

      check step.toUriQuery(Pon2) == Res[string].ok "o2_3_3_2_2_3o"
      check step.toUriQuery(Ishikawa) == Res[string].ok "yp"
      check step.toUriQuery(Ips) == Res[string].ok "yp"

      check "o2_3_3_2_2_3o".parseStep(Pon2) == Res[Step].ok step
      check "yp".parseStep(Ishikawa) == Res[Step].ok step
      check "yp".parseStep(Ips) == Res[Step].ok step

    block:
      let step = Step.init [Col0: 0, 0, 0, -1, 0, 0]
      check step.toUriQuery(Pon2) == Res[string].ok "o0_0_0_-1_0_0o"
      check step.toUriQuery(Ishikawa).isErr
      check step.toUriQuery(Ips).isErr

  # ------------------------------------------------
  # Steps <-> string / URI
  # ------------------------------------------------

  # `$`, parseSteps, toUriQuery
  block:
    let steps =
      @[
        Step.init RedGreen,
        Step.init [Col0: 1, 0, 0, 0, 0, 1],
        Step.init(YellowYellow, Up2),
      ]

    check $steps == "rg|\n(1,0,0,0,0,1)\nyy|3N"
    check "rg|\n(1,0,0,0,0,1)\nyy|3N".parseSteps == Res[Steps].ok steps

    check steps.toUriQuery(Pon2) == Res[string].ok "rgo1_0_0_0_0_1oyy3N"
    check steps.toUriQuery(Ishikawa) == Res[string].ok "c1axG4"
    check steps.toUriQuery(Ips) == Res[string].ok "c1axG4"

    check "rgo1_0_0_0_0_1oyy3N".parseSteps(Pon2) == Res[Steps].ok steps
    check "c1axG4".parseSteps(Ishikawa) == Res[Steps].ok steps
    check "c1axG4".parseSteps(Ips) == Res[Steps].ok steps
