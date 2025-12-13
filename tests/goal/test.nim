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
  check GoalMain.init(AccumCount, GoalColor.Yellow, 4, AtLeast) ==
    GoalMain(kind: AccumCount, color: GoalColor.Yellow, val: 4, operator: AtLeast)
  check GoalMain.init(Chain, 2, Exact) ==
    GoalMain(kind: Chain, color: GoalColor.low, val: 2, operator: Exact)

  check Goal.init(Connection, Colored, 8, Exact) ==
    Goal(
      mainOpt: Opt[GoalMain].ok GoalMain.init(Connection, Colored, 8, Exact),
      clearColorOpt: NoneGoalColor,
    )
  check Goal.init(Chain, 3, Exact, All) ==
    Goal(
      mainOpt: Opt[GoalMain].ok GoalMain.init(Chain, GoalColor.low, 3, Exact),
      clearColorOpt: Opt[GoalColor].ok All,
    )
  check Goal.init(Place, All, 1, AtLeast, Nuisance) ==
    Goal(
      mainOpt: Opt[GoalMain].ok GoalMain.init(Place, All, 1, AtLeast),
      clearColorOpt: Opt[GoalColor].ok Nuisance,
    )
  check Goal.init(AccumColor, 2, AtLeast, Colored) ==
    Goal(
      mainOpt: Opt[GoalMain].ok GoalMain.init(AccumColor, GoalColor.low, 2, AtLeast),
      clearColorOpt: Opt[GoalColor].ok Colored,
    )
  check Goal.init(Opt[GoalColor].ok GoalColor.Blue) ==
    Goal(mainOpt: NoneGoalMain, clearColorOpt: Opt[GoalColor].ok GoalColor.Blue)
  check Goal.init == NoneGoal
  check Goal.init(GoalColor.Red) ==
    Goal(mainOpt: NoneGoalMain, clearColorOpt: Opt[GoalColor].ok GoalColor.Red)

# ------------------------------------------------
# Property
# ------------------------------------------------

block: # isSupported
  check Goal.init(Place, GoalColor.Red, 3, Exact).isSupported
  check not Goal.init(Place, Nuisance, 3, Exact).isSupported
  check Goal.init(Place, Colored, 3, Exact).isSupported

  check Goal.init(AccumCount, GoalColor.Red, 3, AtLeast).isSupported
  check Goal.init(AccumCount, Nuisance, 3, AtLeast).isSupported
  check Goal.init(AccumCount, Colored, 3, AtLeast).isSupported

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
      pon2Uri = "2_4_5_1_"
      ishikawaUri = "H25"

    check $goal == str
    check goal.toUriQuery(Pon2) == Pon2Result[string].ok pon2Uri
    check goal.toUriQuery(IshikawaPuyo) == Pon2Result[string].ok ishikawaUri
    check goal.toUriQuery(Ips) == Pon2Result[string].ok ishikawaUri
    check str.parseGoal == Pon2Result[Goal].ok goal
    check pon2Uri.parseGoal(Pon2) == Pon2Result[Goal].ok goal
    check ishikawaUri.parseGoal(IshikawaPuyo) == Pon2Result[Goal].ok goal

  block: # w/ val
    let
      goal = Goal.init(AccumColor, 2, Exact)
      str = "累計ちょうど2色消すべし"
      pon2Uri = "5_0_2_0_"
      ishikawaUri = "a02"

    check $goal == str
    check goal.toUriQuery(Pon2) == Pon2Result[string].ok pon2Uri
    check goal.toUriQuery(IshikawaPuyo) == Pon2Result[string].ok ishikawaUri
    check goal.toUriQuery(Ips) == Pon2Result[string].ok ishikawaUri
    check str.parseGoal == Pon2Result[Goal].ok goal
    check pon2Uri.parseGoal(Pon2) == Pon2Result[Goal].ok goal
    check ishikawaUri.parseGoal(IshikawaPuyo) == Pon2Result[Goal].ok goal

  block: # only clear
    let
      goal = Goal.init Colored
      str = "色ぷよ全て消すべし"
      pon2Uri = "_2"
      ishikawaUri = "270"

    check $goal == str
    check goal.toUriQuery(Pon2) == Pon2Result[string].ok pon2Uri
    check goal.toUriQuery(IshikawaPuyo) == Pon2Result[string].ok ishikawaUri
    check goal.toUriQuery(Ips) == Pon2Result[string].ok ishikawaUri
    check str.parseGoal == Pon2Result[Goal].ok goal
    check pon2Uri.parseGoal(Pon2) == Pon2Result[Goal].ok goal
    check ishikawaUri.parseGoal(IshikawaPuyo) == Pon2Result[Goal].ok goal

  block: # chain w/ clear
    let
      goal = Goal.init(Chain, 3, AtLeast, GoalColor.Red)
      str = "3連鎖以上する&赤ぷよ全て消すべし"
      pon2Uri = "0_0_3_1_3"
      ishikawaUri = "x13"

    check $goal == str
    check goal.toUriQuery(Pon2) == Pon2Result[string].ok pon2Uri
    check goal.toUriQuery(IshikawaPuyo) == Pon2Result[string].ok ishikawaUri
    check goal.toUriQuery(Ips) == Pon2Result[string].ok ishikawaUri
    check str.parseGoal == Pon2Result[Goal].ok goal
    check pon2Uri.parseGoal(Pon2) == Pon2Result[Goal].ok goal
    check ishikawaUri.parseGoal(IshikawaPuyo) == Pon2Result[Goal].ok goal

  block: # invalid with Ishikawa/Ips
    block:
      let goal = Goal.init(Connection, GoalColor.Yellow, -1, Exact)
      check goal.toUriQuery(Pon2) == Pon2Result[string].ok "4_6_-1_0_"
      check goal.toUriQuery(IshikawaPuyo).isErr
      check goal.toUriQuery(Ips).isErr

    block:
      let goal = Goal.init(AccumCount, All, 10, AtLeast, Colored)
      check goal.toUriQuery(Pon2) == Pon2Result[string].ok "6_0_10_1_2"
      check goal.toUriQuery(IshikawaPuyo).isErr
      check goal.toUriQuery(Ips).isErr

  block: # none goal
    check $NoneGoal == "クリア条件未設定"
    check "クリア条件未設定".parseGoal == Pon2Result[Goal].ok NoneGoal
    check "".parseGoal == Pon2Result[Goal].ok NoneGoal

    check NoneGoal.toUriQuery(Pon2) == Pon2Result[string].ok "_"
    check NoneGoal.toUriQuery(IshikawaPuyo) == Pon2Result[string].ok ""
    check NoneGoal.toUriQuery(Ips) == Pon2Result[string].ok ""

    check "_".parseGoal(Pon2) == Pon2Result[Goal].ok NoneGoal
    check "".parseGoal(Pon2) == Pon2Result[Goal].ok NoneGoal
    check "".parseGoal(IshikawaPuyo) == Pon2Result[Goal].ok NoneGoal
    check "".parseGoal(Ips) == Pon2Result[Goal].ok NoneGoal
