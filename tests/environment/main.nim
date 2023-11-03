{.experimental: "strictDefs".}

import std/[options, sequtils, strformat, strutils, unittest, uri]
import ../../src/pon2pkg/corepkg/[cell, environment {.all.}, field, misc,
                                  moveresult, pair, position]

proc main* =
  # ------------------------------------------------
  # Convert
  # ------------------------------------------------

  # toTsuEnvironment, toWaterEnvironment
  block:
    let
      str = "......\n".repeat(12) & "rgbypo\n------\nrg"
      tsuEnv = str.parseTsuEnvironment.environment
      waterEnv = str.parseWaterEnvironment.environment

    check tsuEnv.toWaterEnvironment == waterEnv
    check waterEnv.toTsuEnvironment == tsuEnv

  # ------------------------------------------------
  # Flatten
  # ------------------------------------------------

  # flattenAnd
  block:
    let
      str = "......\n".repeat(12) & "r.....\n------\ngb"
      tsuEnv = str.parseTsuEnvironment.environment
      waterEnv = str.parseWaterEnvironment.environment
    var envs = Environments(rule: Tsu, tsu: tsuEnv, water: waterEnv)

    envs.flattenAnd:
      check environment.type is Environment[TsuField]

    envs.rule = Water
    envs.flattenAnd:
      check environment.type is Environment[WaterField]

  # ------------------------------------------------
  # Pair
  # ------------------------------------------------

  # addPair
  block:
    var env = parseTsuEnvironment(
      "......\n".repeat(12) & "o.....\n------\nbb").environment
    env.addPair
    check env.pairs.len == 2

  # ------------------------------------------------
  # Constructor
  # ------------------------------------------------

  # reset
  block:
    var env = parseTsuEnvironment(
      "......\n".repeat(12) & "....y.\n------\nbb").environment
    env.reset
    check env.field == zeroTsuField()
    check env.pairs.len == 3

  # initEnvironment, initWaterEnvironment
  block:
    let env = initTsuEnvironment(setPairs = false)
    check env.field == zeroTsuField()
    check env.pairs.len == 0

    let env2 = initWaterEnvironment(123, setPairs = true)
    check env2.field == zeroWaterField()
    check env2.pairs.len == 3

  # ------------------------------------------------
  # Count
  # ------------------------------------------------

  # cellCount, puyoCount, colorCount, garbageCount
  block:
    let env = parseTsuEnvironment(
      "......\n".repeat(11) & "rrb...\noogg..\n------\nry\ngg").environment

    check env.cellCount(Red) == 3
    check env.cellCount(Blue) == 1
    check env.cellCount(Purple) == 0
    check env.cellCount == Height * Width + env.pairs.len * 2
    check env.puyoCount == 11
    check env.colorCount == 9
    check env.garbageCount == 2

  # ------------------------------------------------
  # Move
  # ------------------------------------------------

  # move, moveWithRoughTracking, moveWithDetailTracking, moveWithFullTracking
  block:
    # Tsu
    block:
      let
        envBefore = parseTsuEnvironment("""
....g.
....g.
....pg
....rg
....gr
....go
....gp
....bg
....bp
...bgp
...bgr
...orb
...gbb
------
rb
rg""").environment
        envAfter = parseTsuEnvironment(
          "......\n".repeat(10) & ".....r\n.....b\n...gbb\n------\nrg").
          environment

        pos = Down3

        chainCount = 3
        totalDisappearCounts: array[Puyo, Natural] = [0, 2, 4, 10, 5, 0, 4]

      # NOTE: somehow declaration with initialization does not work on cpp
      var disappearCounts = newSeq[array[Puyo, Natural]] 0
      disappearCounts.add [0.Natural, 1, 0, 0, 5, 0, 0]
      disappearCounts.add [0.Natural, 0, 0, 10, 0, 0, 0]
      disappearCounts.add [0.Natural, 1, 4, 0, 0, 0, 4]
      var detailDisappearCounts = newSeq[array[ColorPuyo, seq[Natural]]] 0
      detailDisappearCounts.add [@[], @[], @[5.Natural], @[], @[]]
      detailDisappearCounts.add [@[], @[4.Natural, 6], @[], @[], @[]]
      detailDisappearCounts.add [@[4.Natural], @[], @[], @[], @[4.Natural]]

      block:
        var env = envBefore
        let res = env.move(pos, false)
        check env == envAfter
        check res.chainCount == chainCount

      block:
        var env = envBefore
        let res = env.moveWithRoughTracking(pos, false)
        check env == envAfter
        check res.chainCount == chainCount
        check res.totalDisappearCounts == totalDisappearCounts

      block:
        var env = envBefore
        let res = env.moveWithDetailTracking(pos, false)
        check env == envAfter
        check res.chainCount == chainCount
        check res.totalDisappearCounts == totalDisappearCounts
        check res.disappearCounts == disappearCounts

      block:
        var env = envBefore
        let res = env.moveWithFullTracking(pos, false)
        check env == envAfter
        check res.chainCount == chainCount
        check res.totalDisappearCounts == totalDisappearCounts
        check res.disappearCounts == disappearCounts
        check res.detailDisappearCounts == detailDisappearCounts

    # Water
    block:
      let
        envBefore = parseWaterEnvironment("""
......
......
......
......
......
yggb..
roob..
rbb...
.gb...
.oo...
.og...
.yy...
..y...
------
rb
rg""").environment
        envAfter = parseWaterEnvironment("""
......
......
......
......
......
yor...
ryy...
r.y...
......
......
......
......
......
------
rg""").environment

        pos = Right2

        chainCount = 2
        totalDisappearCounts: array[Puyo, Natural] = [0, 4, 0, 4, 6, 0, 0]

      # NOTE: somehow declaration with initialization does not work on cpp
      var disappearCounts = newSeq[array[Puyo, Natural]] 0
      disappearCounts.add [0.Natural, 3, 0, 0, 6, 0, 0]
      disappearCounts.add [0.Natural, 1, 0, 4, 0, 0, 0]
      var detailDisappearCounts = newSeq[array[ColorPuyo, seq[Natural]]] 0
      detailDisappearCounts.add [@[], @[], @[6.Natural], @[], @[]]
      detailDisappearCounts.add [@[], @[4.Natural], @[], @[], @[]]

      var env = envBefore
      let res = env.moveWithFullTracking(pos, false)
      check env == envAfter
      check res.chainCount == chainCount
      check res.totalDisappearCounts == totalDisappearCounts
      check res.disappearCounts == disappearCounts
      check res.detailDisappearCounts == detailDisappearCounts

  # ------------------------------------------------
  # Environment <-> string/URI
  # ------------------------------------------------

  # $, toString, parseEnvironment, parseTsuEnvironment, parseWaterEnvironment,
  # parseEnvironments, toUri
  block:
    # normal
    block:
      let
        fieldStr = "......\n".repeat(12) & "rg.bo."
        pairsStr = "yy\ngp"
        pairsWithPosStr = "yy|..\ngp|21"
        envStr = &"{fieldStr}\n------\n{pairsStr}"
        envWithPosStr = &"{fieldStr}\n------\n{pairsWithPosStr}"

        env = parseEnvironment[TsuField](envStr).environment
        positions = @[none Position, some Left1]
        kind = Regular
        izumiyaMode = IzumiyaSimulatorMode.Edit
        ishikawaMode = IshikawaSimulatorMode.Edit

        izumiyaUri1 = parseUri "https://izumiya-keisuke.github.io" &
          "/puyo-simulator/playground/index.html?" &
          &"kind={kind}&" &
          &"mode={izumiyaMode}&" &
          &"field=t-" & "rg.bo.&" &
          "pairs=yygp"
        izumiyaUri2 = parseUri "https://izumiya-keisuke.github.io" &
          "/puyo-simulator/playground/index.html?" &
          &"kind={kind}&" &
          &"mode={izumiyaMode}&" &
          &"field=t-" & ".".repeat(72) & "rg.bo.&" &
          "pairs=yygp"
        izumiyaUriWithPos = parseUri "https://izumiya-keisuke.github.io" &
          "/puyo-simulator/playground/index.html?" &
          &"kind={kind}&" &
          &"mode={izumiyaMode}&" &
          &"field=t-" & "rg.bo.&" &
          "pairs=yygp&" &
          "positions=..21"
        ishikawaUri = parseUri "https://ishikawapuyo.net" &
          &"/simu/p{ishikawaMode}.html?a3M_G1O1"
        ishikawaUriWithPos = parseUri "https://ishikawapuyo.net" &
          &"/simu/p{ishikawaMode}.html?a3M_G1OC"
        ipsUri = parseUri "http://ips.karou.jp" &
          &"/simu/p{ishikawaMode}.html?a3M_G1O1"
        ipsUriWithPos = parseUri "http://ips.karou.jp" &
          &"/simu/p{ishikawaMode}.html?a3M_G1OC"

      # env -> string
      check $env == envStr
      check env.toString == envStr
      check env.toString(positions) == envWithPosStr

      # env <- string
      check parseEnvironment[TsuField](envWithPosStr) == (
        environment: env, positions: some positions)
      check envWithPosStr.parseTsuEnvironment == (
        environment: env, positions: some positions)

      # env -> URI
      check env.toUri(Izumiya, kind, izumiyaMode) == izumiyaUri1
      check env.toUri(Ishikawa, kind, ishikawaMode) == ishikawaUri
      check env.toUri(Ips, kind, ishikawaMode) == ipsUri
      check env.toUri(positions, Izumiya, kind, izumiyaMode) ==
        izumiyaUriWithPos
      check env.toUri(positions, Ishikawa, kind, ishikawaMode) ==
        ishikawaUriWithPos
      check env.toUri(positions, Ips, kind, mode = ishikawaMode) ==
        ipsUriWithPos

      # env <- URI
      check izumiyaUriWithPos.parseTsuEnvironment == (
        environment: env,
        positions: some positions,
        kind: some kind,
        izumiyaMode: some izumiyaMode,
        ishikawaMode: none IshikawaSimulatorMode)
      check ishikawaUriWithPos.parseTsuEnvironment == (
        environment: env,
        positions: some positions,
        kind: none IzumiyaSimulatorKind,
        izumiyaMode: none IzumiyaSimulatorMode,
        ishikawaMode: some ishikawaMode)
      check ipsUriWithPos.parseTsuEnvironment == (
        environment: env,
        positions: some positions,
        kind: none IzumiyaSimulatorKind,
        izumiyaMode: none IzumiyaSimulatorMode,
        ishikawaMode: some ishikawaMode)
      check izumiyaUri1.parseTsuEnvironment == (
        environment: env,
        positions: none Positions,
        kind: some kind,
        izumiyaMode: some izumiyaMode,
        ishikawaMode: none IshikawaSimulatorMode)
      check izumiyaUri2.parseTsuEnvironment == (
        environment: env,
        positions: none Positions,
        kind: some kind,
        izumiyaMode: some izumiyaMode,
        ishikawaMode: none IshikawaSimulatorMode)
      check ishikawaUri.parseTsuEnvironment == (
        environment: env,
        positions: some Position.none.repeat env.pairs.len,
        kind: none IzumiyaSimulatorKind,
        izumiyaMode: none IzumiyaSimulatorMode,
        ishikawaMode: some ishikawaMode)
      check ipsUri.parseTsuEnvironment == (
        environment: env,
        positions: some Position.none.repeat env.pairs.len,
        kind: none IzumiyaSimulatorKind,
        izumiyaMode: none IzumiyaSimulatorMode,
        ishikawaMode: some ishikawaMode)
      check parseEnvironment[TsuField](izumiyaUriWithPos) == (
        environment: env,
        positions: some positions,
        kind: some kind,
        izumiyaMode: some izumiyaMode,
        ishikawaMode: none IshikawaSimulatorMode)
      expect ValueError:
        discard izumiyaUriWithPos.parseWaterEnvironment
      expect ValueError:
        discard parseEnvironment[WaterField](izumiyaUriWithPos)
      block:
        let res = izumiyaUriWithPos.parseEnvironments
        check res.environments.rule == Tsu
        check res.environments.tsu == env
        check res.positions == some positions
        check res.kind == some kind
        check res.izumiyaMode == some izumiyaMode
        check res.ishikawaMode == none IshikawaSimulatorMode

    # empty field
    block:
      let
        fieldStr = "......\n".repeat(13)[0 .. ^2]
        pairsStr = "rg\nby\npp"
        envStr = fieldStr & "\n------\n" & pairsStr

        env = envStr.parseTsuEnvironment.environment
        kind = Regular
        izumiyaMode = IzumiyaSimulatorMode.Edit
        ishikawaMode = IshikawaSimulatorMode.Edit

        izumiyaUri1 = parseUri "https://izumiya-keisuke.github.io" &
          "/puyo-simulator/playground/index.html?" &
          &"kind={kind}&" &
          &"mode={izumiyaMode}&" &
          &"field=t-&" &
          "pairs=rgbypp"
        izumiyaUri2 = parseUri "https://izumiya-keisuke.github.io" &
          "/puyo-simulator/playground/index.html?" &
          &"kind={kind}&" &
          &"mode={izumiyaMode}&" &
          &"field=t-" & ".".repeat(78) & "&" &
          "pairs=rgbypp"
        ishikawaUri = parseUri "https://ishikawapuyo.net" &
          &"/simu/p{ishikawaMode}.html?_c1E1U1"

      # env <-> string
      check $env == envStr
      check envStr.parseTsuEnvironment.environment == env

      # env <-> URI
      check env.toUri(Izumiya, kind, izumiyaMode) == izumiyaUri1
      check env.toUri(Ishikawa, kind, ishikawaMode) == ishikawaUri
      check izumiyaUri1.parseTsuEnvironment.environment == env
      check izumiyaUri2.parseTsuEnvironment.environment == env
      check ishikawaUri.parseTsuEnvironment.environment == env

    # empty pairs
    block:
      let
        fieldStr = "......\n".repeat(12) & "rgbyp."
        pairsStr = ""
        envStr = fieldStr & "\n------\n" & pairsStr

        env = envStr.parseTsuEnvironment.environment
        kind = Regular
        izumiyaMode = IzumiyaSimulatorMode.Edit
        ishikawaMode = IshikawaSimulatorMode.Edit

        izumiyaUri1 = parseUri "https://izumiya-keisuke.github.io" &
          "/puyo-simulator/playground/index.html?" &
          &"kind={kind}&" &
          &"mode={izumiyaMode}&" &
          &"field=t-rgbyp.&" &
          "pairs"
        izumiyaUri2 = parseUri $izumiyaUri1 & "="
        ishikawaUri1 = parseUri "https://ishikawapuyo.net" &
          &"/simu/p{ishikawaMode}.html?asE_"
        ishikawaUri2 = parseUri ($ishikawaUri1)[0 .. ^2]

      # env <-> string
      check $env == envStr
      check envStr.parseTsuEnvironment.environment == env

      # env <-> URI
      check env.toUri(Izumiya, kind, izumiyaMode) == izumiyaUri1
      check env.toUri(Ishikawa, kind, ishikawaMode) == ishikawaUri1
      check izumiyaUri1.parseTsuEnvironment.environment == env
      check izumiyaUri2.parseTsuEnvironment.environment == env
      check ishikawaUri1.parseTsuEnvironment.environment == env
      check ishikawaUri2.parseTsuEnvironment.environment == env

    # empty field and pairs
    block:
      let
        fieldStr = "......\n".repeat(13)[0 .. ^2]
        pairsStr = ""
        envStr = fieldStr & "\n------\n" & pairsStr

        env = envStr.parseTsuEnvironment.environment
        kind = Regular
        izumiyaMode = IzumiyaSimulatorMode.Edit
        ishikawaMode = IshikawaSimulatorMode.Edit

        izumiyaUri1 = parseUri "https://izumiya-keisuke.github.io" &
          "/puyo-simulator/playground/index.html?" &
          &"kind={kind}&" &
          &"mode={izumiyaMode}&" &
          &"field=t-&" &
          "pairs"
        izumiyaUri2 = parseUri $izumiyaUri1 & "="
        ishikawaUri1 = parseUri "https://ishikawapuyo.net" &
          &"/simu/p{ishikawaMode}.html?_"
        ishikawaUri2 = parseUri ($ishikawaUri1)[0 .. ^2]
        ishikawaUri3 = parseUri ($ishikawaUri1)[0 .. ^3]

      # env <-> string
      check $env == envStr
      check envStr.parseTsuEnvironment.environment == env

      # env <-> URI
      check env.toUri(Izumiya, kind, izumiyaMode) == izumiyaUri1
      check env.toUri(Ishikawa, kind, ishikawaMode) == ishikawaUri1
      check izumiyaUri1.parseTsuEnvironment.environment == env
      check izumiyaUri2.parseTsuEnvironment.environment == env
      check ishikawaUri1.parseTsuEnvironment.environment == env
      check ishikawaUri2.parseTsuEnvironment.environment == env
      check ishikawaUri3.parseTsuEnvironment.environment == env

    # Water
    block:
      let
        fieldStr = "......\n".repeat(4) &
          "rg....\n....by\n" & "......\n".repeat(7)[0 .. ^2]
        pairsStr = "pp"
        envStr = fieldStr & "\n------\n" & pairsStr

        env = envStr.parseWaterEnvironment.environment
        kind = Regular
        izumiyaMode = IzumiyaSimulatorMode.Edit

        izumiyaUri1 = parseUri "https://izumiya-keisuke.github.io" &
          "/puyo-simulator/playground/index.html?" &
          &"kind={kind}&" &
          &"mode={izumiyaMode}&" &
          &"field=w-rg....~....by&" &
          "pairs=pp"
        izumiyaUri2 = parseUri "https://izumiya-keisuke.github.io" &
          "/puyo-simulator/playground/index.html?" &
          &"kind={kind}&" &
          &"mode={izumiyaMode}&" &
          &"field=w-" & "......".repeat(4) & "rg....~....by&" &
          "pairs=pp"
        izumiyaUri3 = parseUri "https://izumiya-keisuke.github.io" &
          "/puyo-simulator/playground/index.html?" &
          &"kind={kind}&" &
          &"mode={izumiyaMode}&" &
          &"field=w-rg....~....by" & "......".repeat(7) & "&" &
          "pairs=pp"

      # env <-> string
      check $env == envStr
      check envStr.parseWaterEnvironment.environment == env
      check parseEnvironment[WaterField](envStr).environment == env

      # env <-> URI
      check env.toUri(Izumiya, kind, izumiyaMode) == izumiyaUri1
      check izumiyaUri1.parseWaterEnvironment.environment == env
      check izumiyaUri2.parseWaterEnvironment.environment == env
      check izumiyaUri3.parseWaterEnvironment.environment == env
      block:
        let res = izumiyaUri1.parseEnvironments
        check res.environments.rule == Water
        check res.environments.water == env

  # toArrays, parseEnvironment
  block:
    var arr: array[Row, array[Column, Cell]]
    arr[12][0] = Garbage
    arr[12][2] = Purple
    let env = parseTsuEnvironment(
      "......\n".repeat(12) & "o.p...\n------\nbr").environment

    check env.toArrays == (field: arr, pairs: @[[Blue, Red]])
    check parseEnvironment[TsuField](arr, [[ColorPuyo Blue, Red]]) == env
    check arr.parseTsuEnvironment([[ColorPuyo Blue, Red]]) == env
