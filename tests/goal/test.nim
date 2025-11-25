{.push raises: [].}
{.experimental: "strictDefs".}
{.experimental: "strictFuncs".}
{.experimental: "views".}

import std/[sugar, unittest]
import ../../src/pon2/core/[fqdn, goal]

# ------------------------------------------------
# Constructor
# ------------------------------------------------

block: # init
  check Goal.init(Connection, Colors, 8, Exact, GoalColor.Green) ==
    Goal(
      kind: Connection,
      color: Colors,
      val: 8,
      valOperator: Exact,
      clearColor: GoalColor.Green,
    )
  check Goal.init(Place, All, 1, AtLeast) ==
    Goal(
      kind: Place, color: All, val: 1, valOperator: AtLeast, clearColor: GoalColor.None
    )
  check Goal.init(Chain, 3, Exact, All) ==
    Goal(
      kind: Chain, color: GoalColor.None, val: 3, valOperator: Exact, clearColor: All
    )
  check Goal.init(AccumColor, 2, AtLeast) ==
    Goal(
      kind: AccumColor,
      color: GoalColor.None,
      val: 2,
      valOperator: AtLeast,
      clearColor: GoalColor.None,
    )
  check Goal.init(GoalColor.Red) ==
    Goal(
      kind: GoalKind.None,
      color: GoalColor.None,
      val: 0,
      valOperator: Exact,
      clearColor: GoalColor.Red,
    )
  check Goal.init == NoneGoal

# ------------------------------------------------
# Property
# ------------------------------------------------

block: # isSupported
  check Goal.init(Place, GoalColor.Red, 3, Exact).isSupported
  check not Goal.init(Place, Garbages, 3, Exact).isSupported
  check Goal.init(Place, Colors, 3, Exact).isSupported

  check Goal.init(AccumCount, GoalColor.Red, 3, Exact).isSupported
  check Goal.init(AccumCount, Garbages, 3, Exact).isSupported
  check Goal.init(AccumCount, Colors, 3, Exact).isSupported

  check not NoneGoal.isSupported

# ------------------------------------------------
# Normalize
# ------------------------------------------------

block: # isNormalized, normalize, normalized
  let
    goal1 = Goal.init(Connection, GoalColor.Green, 5, AtLeast, All)

    goal2 = Goal.init(Chain, GoalColor.Green, 5, AtLeast, GoalColor.Purple)
    goal3 = Goal.init(Chain, 5, AtLeast, GoalColor.Purple)

    goal4 = Goal(
      kind: GoalKind.None,
      color: GoalColor.Red,
      val: 0,
      valOperator: Exact,
      clearColor: Colors,
    )
    goal5 = Goal(
      kind: GoalKind.None,
      color: GoalColor.None,
      val: 0,
      valOperator: Exact,
      clearColor: Colors,
    )

  check goal1.isNormalized
  check not goal2.isNormalized
  check goal3.isNormalized
  check not goal4.isNormalized
  check goal5.isNormalized

  check goal2.normalized == goal3
  check goal4.normalized == goal5

  check goal2.dup(normalize) == goal3
  check goal4.dup(normalize) == goal5

  check NoneGoal.isNormalized

# ------------------------------------------------
# Goal <-> string / URI
# ------------------------------------------------

block: # `$`, toUriQuery, parseGoal
  block: # w/ color and val
    let
      goal = Goal.init(Count, GoalColor.Green, 5, AtLeast)
      str = "緑ぷよ5個以上同時に消すべし"
      pon2Uri = "3_3_5_1_0"
      ishikawaUri = "H25"

    check $goal == str
    check goal.toUriQuery(Pon2) == StrErrorResult[string].ok pon2Uri
    check goal.toUriQuery(Ishikawa) == StrErrorResult[string].ok ishikawaUri
    check goal.toUriQuery(Ips) == StrErrorResult[string].ok ishikawaUri
    check str.parseGoal == StrErrorResult[Goal].ok goal
    check pon2Uri.parseGoal(Pon2) == StrErrorResult[Goal].ok goal
    check ishikawaUri.parseGoal(Ishikawa) == StrErrorResult[Goal].ok goal

  block: # w/ val
    let
      goal = Goal.init(AccumColor, 2, Exact)
      str = "累計ちょうど2色消すべし"
      pon2Uri = "6_0_2_0_0"
      ishikawaUri = "a02"

    check $goal == str
    check goal.toUriQuery(Pon2) == StrErrorResult[string].ok pon2Uri
    check goal.toUriQuery(Ishikawa) == StrErrorResult[string].ok ishikawaUri
    check goal.toUriQuery(Ips) == StrErrorResult[string].ok ishikawaUri
    check str.parseGoal == StrErrorResult[Goal].ok goal
    check pon2Uri.parseGoal(Pon2) == StrErrorResult[Goal].ok goal
    check ishikawaUri.parseGoal(Ishikawa) == StrErrorResult[Goal].ok goal

  block: # only clear
    let
      goal = Goal.init Colors
      str = "色ぷよ全て消すべし"
      pon2Uri = "0_0_0_0_8"
      ishikawaUri = "270"

    check $goal == str
    check goal.toUriQuery(Pon2) == StrErrorResult[string].ok pon2Uri
    check goal.toUriQuery(Ishikawa) == StrErrorResult[string].ok ishikawaUri
    check goal.toUriQuery(Ips) == StrErrorResult[string].ok ishikawaUri
    check str.parseGoal == StrErrorResult[Goal].ok goal
    check pon2Uri.parseGoal(Pon2) == StrErrorResult[Goal].ok goal
    check ishikawaUri.parseGoal(Ishikawa) == StrErrorResult[Goal].ok goal

  block: # chain w/ clear
    let
      goal = Goal.init(Chain, 3, AtLeast, GoalColor.Red)
      str = "3連鎖以上する&赤ぷよ全て消すべし"
      pon2Uri = "1_0_3_1_2"
      ishikawaUri = "x13"

    check $goal == str
    check goal.toUriQuery(Pon2) == StrErrorResult[string].ok pon2Uri
    check goal.toUriQuery(Ishikawa) == StrErrorResult[string].ok ishikawaUri
    check goal.toUriQuery(Ips) == StrErrorResult[string].ok ishikawaUri
    check str.parseGoal == StrErrorResult[Goal].ok goal
    check pon2Uri.parseGoal(Pon2) == StrErrorResult[Goal].ok goal
    check ishikawaUri.parseGoal(Ishikawa) == StrErrorResult[Goal].ok goal

  block: # invalid with Ishikawa/Ips
    block:
      let goal = Goal.init(Connection, GoalColor.Yellow, -1, Exact)
      check goal.toUriQuery(Pon2) == StrErrorResult[string].ok "5_5_-1_0_0"
      check goal.toUriQuery(Ishikawa).isErr
      check goal.toUriQuery(Ips).isErr

    block:
      let goal = Goal.init(AccumCount, All, 10, AtLeast, Colors)
      check goal.toUriQuery(Pon2) == StrErrorResult[string].ok "7_1_10_1_8"
      check goal.toUriQuery(Ishikawa).isErr
      check goal.toUriQuery(Ips).isErr

  block: # none goal
    check $NoneGoal == "クリア条件未設定"
    check "クリア条件未設定".parseGoal == StrErrorResult[Goal].ok NoneGoal
    check "".parseGoal == StrErrorResult[Goal].ok NoneGoal

    check NoneGoal.toUriQuery(Pon2) == StrErrorResult[string].ok "0_0_0_0_0"
    check NoneGoal.toUriQuery(Ishikawa) == StrErrorResult[string].ok ""
    check NoneGoal.toUriQuery(Ips) == StrErrorResult[string].ok ""

    check "0_0_0_0_0".parseGoal(Pon2) == StrErrorResult[Goal].ok NoneGoal
    check "".parseGoal(Pon2) == StrErrorResult[Goal].ok NoneGoal
    check "".parseGoal(Ishikawa) == StrErrorResult[Goal].ok NoneGoal
    check "".parseGoal(Ips) == StrErrorResult[Goal].ok NoneGoal
