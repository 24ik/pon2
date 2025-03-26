{.experimental: "strictDefs".}
{.experimental: "strictFuncs".}
{.experimental: "views".}

import std/[unittest]
import ../../src/pon2/core/[fqdn, goal]
import ../../src/pon2/private/[results2]

proc main*() =
  # ------------------------------------------------
  # Constructor
  # ------------------------------------------------

  # init
  block:
    check Goal.init(Clear, OptGoalColor.ok Red, OptGoalVal.err) == Goal.init(Clear, Red)
    check Goal.init(ChainMore, OptGoalColor.err, OptGoalVal.ok 5) ==
      Goal.init(ChainMore, 5)
    check Goal.init(Conn, OptGoalColor.ok Color, OptGoalVal.ok 10) ==
      Goal.init(Conn, Color, 10)

  # ------------------------------------------------
  # Property
  # ------------------------------------------------

  # isNormalForm, isSupported
  block:
    let
      goal1 = Goal.init(Clear, OptGoalColor.err, OptGoalVal.err)
      goal2 = Goal.init(Clear, Green)
      goal3 = Goal.init(Clear, 3)
      goal4 = Goal.init(Clear, Green, 3)

      goal5 = Goal.init(Chain, OptGoalColor.err, OptGoalVal.err)
      goal6 = Goal.init(Chain, Green)
      goal7 = Goal.init(Chain, 4)
      goal8 = Goal.init(Chain, Green, 4)

      goal9 = Goal.init(PlaceMore, OptGoalColor.err, OptGoalVal.err)
      goal10 = Goal.init(PlaceMore, Green)
      goal11 = Goal.init(PlaceMore, 5)
      goal12 = Goal.init(PlaceMore, Green, 5)

      goal13 = Goal.init(PlaceMore, Garbage, 5)

    check not goal1.isNormalForm
    check goal2.isNormalForm
    check not goal3.isNormalForm
    check not goal4.isNormalForm
    check not goal5.isNormalForm
    check not goal6.isNormalForm
    check goal7.isNormalForm
    check not goal8.isNormalForm
    check not goal9.isNormalForm
    check not goal10.isNormalForm
    check not goal11.isNormalForm
    check goal12.isNormalForm
    check goal13.isNormalForm

    check not goal1.isSupported
    check goal2.isSupported
    check not goal3.isSupported
    check goal4.isSupported
    check not goal5.isSupported
    check not goal6.isSupported
    check goal7.isSupported
    check goal8.isSupported
    check not goal9.isSupported
    check not goal10.isSupported
    check not goal11.isSupported
    check goal12.isSupported
    check not goal13.isSupported

  # ------------------------------------------------
  # Normalize
  # ------------------------------------------------

  # normalize, normalized
  block:
    block:
      var goal = Goal.init(ClearChainMore, OptGoalColor.err, OptGoalVal.err)
      let goal2 = Goal.init(ClearChainMore, All, 0)
      check goal.normalized == goal2
      goal.normalize
      check goal == goal2

      check goal2.normalized == goal2

    block:
      let goal = Goal.init(Clear, Purple, 3)
      check goal.normalized == Goal.init(Clear, Purple)

    block:
      let goal = Goal.init(Chain, Garbage, 2)
      check goal.normalized == Goal.init(Chain, 2)

  # ------------------------------------------------
  # Goal <-> string / URI
  # ------------------------------------------------

  # `$`, toUriQuery, parseGoal
  block:
    # w/ color
    block:
      let
        goal = Goal.init(Clear, Garbage)
        str = "おじゃまぷよ全て消すべし"
        pon2Uri = "0_6_"
        ishikawaUri = "260"

      check $goal == str
      check goal.toUriQuery(Pon2) == Res[string].ok pon2Uri
      check goal.toUriQuery(Ishikawa) == Res[string].ok ishikawaUri
      check goal.toUriQuery(Ips) == Res[string].ok ishikawaUri
      check str.parseGoal == Res[Goal].ok goal
      check pon2Uri.parseGoal(Pon2) == Res[Goal].ok goal
      check ishikawaUri.parseGoal(Ishikawa) == Res[Goal].ok goal

    # w/ val
    block:
      let
        goal = Goal.init(Chain, 5)
        str = "5連鎖するべし"
        pon2Uri = "5__5"
        ishikawaUri = "u05"

      check $goal == str
      check goal.toUriQuery(Pon2) == Res[string].ok pon2Uri
      check goal.toUriQuery(Ishikawa) == Res[string].ok ishikawaUri
      check goal.toUriQuery(Ips) == Res[string].ok ishikawaUri
      check str.parseGoal == Res[Goal].ok goal
      check pon2Uri.parseGoal(Pon2) == Res[Goal].ok goal
      check ishikawaUri.parseGoal(Ishikawa) == Res[Goal].ok goal

    # w/ color and val
    block:
      let
        goal = Goal.init(ClearChainMore, Red, 3)
        str = "3連鎖以上&赤ぷよ全て消すべし"
        pon2Uri = "8_1_3"
        ishikawaUri = "x13"

      check $goal == str
      check goal.toUriQuery(Pon2) == Res[string].ok pon2Uri
      check goal.toUriQuery(Ishikawa) == Res[string].ok ishikawaUri
      check goal.toUriQuery(Ips) == Res[string].ok ishikawaUri
      check str.parseGoal == Res[Goal].ok goal
      check pon2Uri.parseGoal(Pon2) == Res[Goal].ok goal
      check ishikawaUri.parseGoal(Ishikawa) == Res[Goal].ok goal

    # invalid with Ishikawa/Ips
    block:
      let goal = Goal.init(Conn, Yellow, -1)
      check goal.toUriQuery(Pon2) == Res[string].ok "15_4_-1"
      check goal.toUriQuery(Ishikawa).isErr
      check goal.toUriQuery(Ips).isErr
