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
      mainOpt: Opt[GoalMain].ok GoalMain(
        kind: Connection, color: Colors, val: 8, valOperator: Exact
      ),
      clearColorOpt: Opt[GoalColor].ok GoalColor.Green,
    )
  check Goal.init(Place, All, 1, AtLeast) ==
    Goal(
      mainOpt:
        Opt[GoalMain].ok GoalMain(kind: Place, color: All, val: 1, valOperator: AtLeast),
      clearColorOpt: Opt[GoalColor].err,
    )
  check Goal.init(Chain, 3, Exact, All) ==
    Goal(
      mainOpt: Opt[GoalMain].ok GoalMain(
        kind: Chain, color: GoalColor.low, val: 3, valOperator: Exact
      ),
      clearColorOpt: Opt[GoalColor].ok All,
    )
  check Goal.init(AccumColor, 2, AtLeast) ==
    Goal(
      mainOpt: Opt[GoalMain].ok GoalMain(
        kind: AccumColor, color: GoalColor.low, val: 2, valOperator: AtLeast
      ),
      clearColorOpt: Opt[GoalColor].err,
    )
  check Goal.init(GoalColor.Red) ==
    Goal(mainOpt: Opt[GoalMain].err, clearColorOpt: Opt[GoalColor].ok GoalColor.Red)
  check Goal.init == NoneGoal

# ------------------------------------------------
# Property
# ------------------------------------------------

block: # isSupported
  check Goal.init(Place, GoalColor.Red, 3, Exact).isSupported
  check not Goal.init(Place, Garbages, 3, Exact).isSupported
  check Goal.init(Place, Colors, 3, Exact).isSupported

  check Goal.init(AccumCount, GoalColor.Red, 3, AtLeast).isSupported
  check Goal.init(AccumCount, Garbages, 3, AtLeast).isSupported
  check Goal.init(AccumCount, Colors, 3, AtLeast).isSupported

  check Goal.init(Chain, 3, Exact).isSupported
  check Goal.init(All).isSupported
  check not NoneGoal.isSupported

# ------------------------------------------------
# Normalize
# ------------------------------------------------

block: # isNormalized, normalize, normalized
  let
    goal1 = Goal.init(Connection, GoalColor.Green, 5, AtLeast, All)
    goal2 = Goal.init(Chain, GoalColor.Green, 5, AtLeast, GoalColor.Purple)
    goal3 = Goal.init(Chain, 5, AtLeast, GoalColor.Purple)

  check goal1.isNormalized
  check not goal2.isNormalized
  check goal3.isNormalized

  check goal2.normalized == goal3
  check goal2.dup(normalize) == goal3

  check NoneGoal.isNormalized

# ------------------------------------------------
# Goal <-> string / URI
# ------------------------------------------------

block: # `$`, toUriQuery, parseGoal
  block: # w/ color and val
    let
      goal = Goal.init(Count, GoalColor.Green, 5, AtLeast)
      str = "緑ぷよ5個以上同時に消すべし"
      pon2Uri = "2_2_5_1_"
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
      pon2Uri = "5_0_2_0_"
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
      pon2Uri = "_7"
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
      pon2Uri = "0_0_3_1_1"
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
      check goal.toUriQuery(Pon2) == StrErrorResult[string].ok "4_4_-1_0_"
      check goal.toUriQuery(Ishikawa).isErr
      check goal.toUriQuery(Ips).isErr

    block:
      let goal = Goal.init(AccumCount, All, 10, AtLeast, Colors)
      check goal.toUriQuery(Pon2) == StrErrorResult[string].ok "6_0_10_1_7"
      check goal.toUriQuery(Ishikawa).isErr
      check goal.toUriQuery(Ips).isErr

  block: # none goal
    check $NoneGoal == "クリア条件未設定"
    check "クリア条件未設定".parseGoal == StrErrorResult[Goal].ok NoneGoal
    check "".parseGoal == StrErrorResult[Goal].ok NoneGoal

    check NoneGoal.toUriQuery(Pon2) == StrErrorResult[string].ok "_"
    check NoneGoal.toUriQuery(Ishikawa) == StrErrorResult[string].ok ""
    check NoneGoal.toUriQuery(Ips) == StrErrorResult[string].ok ""

    check "_".parseGoal(Pon2) == StrErrorResult[Goal].ok NoneGoal
    check "".parseGoal(Pon2) == StrErrorResult[Goal].ok NoneGoal
    check "".parseGoal(Ishikawa) == StrErrorResult[Goal].ok NoneGoal
    check "".parseGoal(Ips) == StrErrorResult[Goal].ok NoneGoal
