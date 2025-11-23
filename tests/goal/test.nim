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
  check Goal.init(Connection, Colors, 8, true, GoalColor.Green) ==
    Goal(
      kindOpt: Opt[GoalKind].ok Connection,
      color: Colors,
      val: 8,
      exact: true,
      clearColorOpt: Opt[GoalColor].ok GoalColor.Green,
    )
  check Goal.init(Place, All, 1, false) ==
    Goal(
      kindOpt: Opt[GoalKind].ok Place,
      color: All,
      val: 1,
      exact: false,
      clearColorOpt: Opt[GoalColor].err,
    )
  check Goal.init(Chain, 3, true, All) ==
    Goal(
      kindOpt: Opt[GoalKind].ok Chain,
      color: GoalColor.low,
      val: 3,
      exact: true,
      clearColorOpt: Opt[GoalColor].ok All,
    )
  check Goal.init(AccumColor, 2, false) ==
    Goal(
      kindOpt: Opt[GoalKind].ok AccumColor,
      color: GoalColor.low,
      val: 2,
      exact: false,
      clearColorOpt: Opt[GoalColor].err,
    )
  check Goal.init(GoalColor.Red) ==
    Goal(
      kindOpt: Opt[GoalKind].err,
      color: GoalColor.low,
      val: 0,
      exact: true,
      clearColorOpt: Opt[GoalColor].ok GoalColor.Red,
    )
  check Goal.init == NoneGoal

# ------------------------------------------------
# Property
# ------------------------------------------------

block: # isSupported
  check Goal.init(Place, GoalColor.Red, 3, true).isSupported
  check not Goal.init(Place, Garbages, 3, true).isSupported
  check Goal.init(Place, Colors, 3, true).isSupported

  check Goal.init(AccumCount, GoalColor.Red, 3, true).isSupported
  check Goal.init(AccumCount, Garbages, 3, true).isSupported
  check Goal.init(AccumCount, Colors, 3, true).isSupported

  check not NoneGoal.isSupported

# ------------------------------------------------
# Normalize
# ------------------------------------------------

block: # isNormalized, normalize, normalized
  let
    goal1 = Goal.init(Connection, GoalColor.Green, 5, false, All)

    goal2 = Goal.init(Chain, GoalColor.Green, 5, false, GoalColor.Purple)
    goal3 = Goal.init(Chain, 5, false, GoalColor.Purple)

    goal4 = Goal(
      kindOpt: Opt[GoalKind].err,
      color: GoalColor.Red,
      val: 0,
      exact: true,
      clearColorOpt: Opt[GoalColor].ok Colors,
    )
    goal5 = Goal(
      kindOpt: Opt[GoalKind].err,
      color: GoalColor.low,
      val: 0,
      exact: true,
      clearColorOpt: Opt[GoalColor].ok Colors,
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
      goal = Goal.init(Count, GoalColor.Green, 5, false)
      str = "緑ぷよ5個以上同時に消すべし"
      pon2Uri = "2_2_5_0_"
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
      goal = Goal.init(AccumColor, 2, true)
      str = "累計ちょうど2色消すべし"
      pon2Uri = "5_0_2_1_"
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
      goal = Goal.init(Colors)
      str = "色ぷよ全て消すべし"
      pon2Uri = "_0_0_1_7"
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
      goal = Goal.init(Chain, 3, false, GoalColor.Red)
      str = "3連鎖以上する&赤ぷよ全て消すべし"
      pon2Uri = "0_0_3_0_1"
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
      let goal = Goal.init(Connection, GoalColor.Yellow, -1, true)
      check goal.toUriQuery(Pon2) == StrErrorResult[string].ok "4_4_-1_1_"
      check goal.toUriQuery(Ishikawa).isErr
      check goal.toUriQuery(Ips).isErr

    block:
      let goal = Goal.init(AccumCount, All, 10, false, Colors)
      check goal.toUriQuery(Pon2) == StrErrorResult[string].ok "6_0_10_0_7"
      check goal.toUriQuery(Ishikawa).isErr
      check goal.toUriQuery(Ips).isErr

  block: # none goal
    check $NoneGoal == "クリア条件未設定"
    check "クリア条件未設定".parseGoal == StrErrorResult[Goal].ok NoneGoal

    check NoneGoal.toUriQuery(Pon2) == StrErrorResult[string].ok "_0_0_1_"
    check NoneGoal.toUriQuery(Ishikawa) == StrErrorResult[string].ok ""
    check NoneGoal.toUriQuery(Ips) == StrErrorResult[string].ok ""

    check "_0_0_1_".parseGoal(Pon2) == StrErrorResult[Goal].ok NoneGoal
    check "".parseGoal(Pon2) == StrErrorResult[Goal].ok NoneGoal
    check "".parseGoal(Ishikawa) == StrErrorResult[Goal].ok NoneGoal
    check "".parseGoal(Ips) == StrErrorResult[Goal].ok NoneGoal
