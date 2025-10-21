## The `pon2` module provides the applications and the APIs for
## [Puyo Puyo](https://puyo.sega.jp/) and
## [Nazo Puyo](https://vc.sega.jp/3ds/nazopuyo/).
##
## To access the APIs, either `import pon2` as an "all-in-one" or import the following
## submodules individually:
## - [pon2/app](./pon2/app.html)
## - [pon2/core](./pon2/core.html)
## - [pon2/gui](./pon2/gui.html)
##
## Compile Options:
## | Option                            | Description                            | Default             |
## | --------------------------------- | -------------------------------------- | ------------------- |
## | `-d:pon2.waterheight=<int>`       | Height of the water.                   | `8`                 |
## | `-d:pon2.fqdn=<str>`              | FQDN of the web simulator.             | `24ik.github.io`    |
## | `-d:pon2.garbagerate.tsu=<int>`   | Garbage rate in Tsu rule.              | `70`                |
## | `-d:pon2.garbagerate.water=<int>` | Garbage rate in Water rule.            | `90`                |
## | `-d:pon2.simd=<int>`              | SIMD level. (1: SSE4.2, 0: None)       | 1                   |
## | `-d:pon2.bmi=<int>`               | BMI level. (2: BMI2, 1: BMI1, 0: None) | 2                   |
## | `-d:pon2.clmul=<bool>`            | Uses CLMUL.                            | `true`              |
## | `-d:pon2.path=<str>`              | Path of the web simulator.             | `/pon2/stable/ide/` |
## | `-d:pon2.assets=<str>`            | Assets directory.                      | `../assets`         |
##

{.experimental: "strictDefs".}
{.experimental: "strictFuncs".}
{.experimental: "views".}

import ./pon2/[app, core, gui]

export app, core, gui

when isMainModule:
  import std/[parsecfg, streams]
  import ./pon2/private/[paths2]

  # ------------------------------------------------
  # Utils
  # ------------------------------------------------

  proc getNimbleFile(): Path {.inline.} =
    ## Returns the path to `pon2.nimble`.
    let
      head = srcPath().splitPath2.head
      (head2, tail2) = head.splitPath2

    (if tail2 == "src".Path: head2 else: head).joinPath "pon2.nimble".Path

  const Pon2Ver = ($getNimbleFile()).staticRead.newStringStream.loadConfig.getSectionValue(
    "", "version"
  )

  # ------------------------------------------------
  # JS backend
  # ------------------------------------------------

  when defined(js) or defined(nimsuggest):
    import std/[strformat, sugar]
    import karax/[karax, karaxdsl, kdom, vdom]
    import ./pon2/private/[assign3]
    import ./pon2/private/gui/[utils]

    # ------------------------------------------------
    # JS - Utils
    # ------------------------------------------------

    proc initFooterNode(): VNode {.inline.} =
      ## Returns the footer node.
      buildHtml footer(class = "footer"):
        tdiv(class = "columns"):
          tdiv(class = "column is-narrow"):
            text "Pon!通 Version {Pon2Ver}".fmt
          tdiv(class = "column is-narrow"):
            a(
              href = "../docs/simulator/",
              target = "_blank",
              rel = "noopener noreferrer",
            ):
              text "操作方法"

    proc keyHandler(ide: ref Ide, event: Event) {.inline.} =
      ## Runs the keyboard event handler.
      ## Returns `true` if the event is handled.
      if ide[].operate(cast[KeyboardEvent](event).toKeyEvent):
        if not kxi.surpressRedraws:
          kxi.redraw
        event.preventDefault

    # ------------------------------------------------
    # JS - Main
    # ------------------------------------------------

    let
      globalSimRef = new Simulator
      globalIdeRef = new Ide
    globalIdeRef[] = Ide.init globalSimRef

    let globalIdeView = IdeView.init(globalIdeRef, not isMobile())
    var
      initialized = false
      parseFailed = false

    proc renderer(routerData: RouterData): VNode =
      ## Returns the root node.
      if not initialized:
        document.onkeydown = (event: Event) => globalIdeRef.keyHandler event

        var uri = initUri()
        uri.scheme.assign "https"
        uri.hostname.assign $Pon2
        uri.path.assign Pon2Path

        let routerQuery = $routerData.queryString
        uri.query.assign routerQuery.substr(1, routerQuery.high)

        let simRes = uri.parseSimulator
        if simRes.isOk:
          globalSimRef[] = simRes.unsafeValue
        else:
          parseFailed = true

        initialized = true

      buildHtml tdiv:
        if parseFailed:
          text("URL形式エラー")
        else:
          globalIdeView.toVNode "pon2-main"
          initFooterNode()

    renderer.setRenderer

  # ------------------------------------------------
  # Native backend
  # ------------------------------------------------

  when not defined(js):
    import std/[random, sequtils, strformat, sugar, uri]
    import cligen
    import ./pon2/private/[arrayops2, assign3, browsers2, strutils2]

    # ------------------------------------------------
    # Native - Solve
    # ------------------------------------------------

    proc runSolver(
        urls: seq[string], openQuestion = false, openAnswer = false
    ) {.inline.} =
      ## なぞぷよの解を求める．
      if urls.len != 1:
        echo "URLを一つ入力してください．"
        return

      let simRes = urls[0].parseUri.parseSimulator
      if simRes.isErr:
        echo "URL形式が間違っています．エラー内容："
        echo simRes.error
        return

      let sim = simRes.unsafeValue
      if sim.nazoPuyoWrap.optGoal.isErr:
        echo "なぞぷよのURLを入力してください．"
        return

      if openQuestion:
        urls[0].parseUri.openDefaultBrowser.isOkOr:
          echo "ブラウザの起動に失敗しました．"

      runIt sim.nazoPuyoWrap:
        let
          answers = itNazo.solve
          stepsSeq = collect:
            for ans in answers:
              var steps = it.steps
              for stepIdx, optPlcmt in ans:
                if it.steps[stepIdx].kind == PairPlacement:
                  steps[stepIdx].optPlacement.assign optPlcmt

              steps

        for ansIdx, steps in stepsSeq:
          var nazo = itNazo
          nazo.puyoPuyo.steps.assign steps

          let ansUri = Simulator.init(nazo, EditorEdit).toUri.unsafeValue
          echo "({ansIdx.succ}) {ansUri}".fmt

          if openAnswer:
            ansUri.openDefaultBrowser.isOkOr:
              echo "ブラウザの起動に失敗しました．"

    # ------------------------------------------------
    # Native - Permute
    # ------------------------------------------------

    proc runPermuter(
        urls: seq[string],
        fixIndices = newSeq[int](),
        allowDblNotLast = true,
        allowDblLast = false,
        openQuestion = false,
        openAnswer = false,
    ) {.inline.} =
      ## なぞぷよのツモを並べ替える．
      if urls.len != 1:
        echo "URLを一つ入力してください．"
        return

      let simRes = urls[0].parseUri.parseSimulator
      if simRes.isErr:
        echo "URL形式が間違っています．エラー内容："
        echo simRes.error
        return

      let sim = simRes.unsafeValue
      if sim.nazoPuyoWrap.optGoal.isErr:
        echo "なぞぷよのURLを入力してください．"
        return

      runIt sim.nazoPuyoWrap:
        var idx = 0
        for nazo in itNazo.permute(fixIndices, allowDblNotLast, allowDblLast):
          let
            sim = Simulator.init(nazo, EditorEdit)
            questionUri = sim.toUri(clearPlacements = true).unsafeValue
            ansUri = sim.toUri.unsafeValue

          echo "(Q{idx.succ}) {questionUri}".fmt
          echo "(A{idx.succ}) {ansUri}".fmt
          echo ""

          if openQuestion:
            questionUri.openDefaultBrowser.isOkOr:
              echo "ブラウザの起動に失敗しました．"
          if openAnswer:
            ansUri.openDefaultBrowser.isOkOr:
              echo "ブラウザの起動に失敗しました．"

          idx.inc

    # ------------------------------------------------
    # Native - Generate
    # ------------------------------------------------

    func negToErr(val: int): Opt[int] {.inline.} =
      ## Returns `err` if `val` is negative; otherwise, returns `ok(val)`.
      if val < 0:
        err()
      else:
        ok val

    proc runGenerator(
        cnt = 5,
        rule = 0,
        goalKind = 5,
        goalColor = 0,
        goalVal = 3,
        moveCnt = 2,
        colorCnt = 2,
        heights = "0++++0",
        pc = -1,
        pg = 2,
        ph = 0,
        c2 = 1,
        c2v = -1,
        c2h = -1,
        c3 = 1,
        c3v = 0,
        c3h = -1,
        c3l = -1,
        allowDblNotLast = true,
        allowDblLast = false,
        sg = false,
        sh = false,
        openQuestion = false,
        openAnswer = false,
        seed = 0,
    ) {.inline.} =
      ## なぞぷよを生成する．
      let
        puyoCntColor = pc
        puyoCntGarbage = pg
        puyoCntHard = ph

        conn2Cnt = c2
        conn2CntV = c2v
        conn2CntH = c2h
        conn3Cnt = c3
        conn3CntV = c3v
        conn3CntH = c3h
        conn3CntL = c3l

        stepGarbages = sg
        stepHards = sh

      let errMsg =
        if rule notin 0 .. Rule.high.ord:
          "ルールが不正です．"
        elif goalKind notin 0 .. GoalKind.high.ord:
          "クリア条件の種類が不正です．"
        elif goalColor notin 0 .. GenerateGoalColor.high.ord:
          "クリア条件の色が不正です．"
        elif goalVal notin 0 .. GoalVal.high.ord:
          "クリア条件の色が不正です．"
        elif heights.len != Width:
          "高さ指定が不正です．"
        elif puyoCntColor < 0 and
          goalKind.GoalKind notin {Chain, ChainMore, ClearChain, ClearChainMore}:
          "連鎖問題でない場合は色ぷよ数の指定が必要です．"
        else:
          ""
      if errMsg != "":
        echo errMsg
        return

      let
        heightWeights: Opt[array[Col, int]]
        heightPositives: Opt[array[Col, bool]]
      if heights.allIt it.isDigit:
        var weights = initArrWith[Col, int](0)
        for col in Col:
          weights[col].assign ($heights[col.ord]).parseIntRes.unsafeValue

        heightWeights = Opt[array[Col, int]].ok weights
        heightPositives = Opt[array[Col, bool]].err
      else:
        var positives = initArrWith[Col, bool](false)
        for col in Col:
          positives[col].assign heights[col.ord] != '0'

        heightWeights = Opt[array[Col, int]].err
        heightPositives = Opt[array[Col, bool]].ok positives

      let
        rule2 = rule.Rule
        puyoCntColor2 =
          if puyoCntColor < 0:
            goalVal * 4
          else:
            puyoCntColor

        conn2Cnts = (
          total: conn2Cnt.negToErr,
          vertical: conn2CntV.negToErr,
          horizontal: conn2CntH.negToErr,
        )
        conn3Cnts = (
          total: conn3Cnt.negToErr,
          vertical: conn3CntV.negToErr,
          horizontal: conn3CntH.negToErr,
          lShape: conn3CntL.negToErr,
        )

        settings = GenerateSettings.init(
          GenerateGoal.init(
            goalKind.GoalKind, goalColor.GenerateGoalColor, goalVal.GoalVal
          ),
          moveCnt,
          colorCnt,
          (weights: heightWeights, positives: heightPositives),
          (colors: puyoCntColor2, garbage: puyoCntGarbage, hard: puyoCntHard),
          conn2Cnts,
          conn3Cnts,
          allowDblNotLast,
          allowDblLast,
          stepGarbages,
          stepHards,
        )

      let seed2: int64
      if seed == 0:
        randomize()
        seed2 = int64.rand
      else:
        seed2 = seed.int64
      var rng = seed2.initRand

      for idx in 0 ..< cnt:
        let nazoRes = rng.generate(settings, rule2)
        if nazoRes.isErr:
          echo "生成に失敗しました．エラー内容："
          echo nazoRes.error
          return

        let
          sim = Simulator.init(nazoRes.unsafeValue, EditorEdit)
          questionUri = sim.toUri(clearPlacements = true).unsafeValue
          ansUri = sim.toUri.unsafeValue

        echo "(Q{idx.succ}) {questionUri}".fmt
        echo "(A{idx.succ}) {ansUri}".fmt
        echo ""

        if openQuestion:
          questionUri.openDefaultBrowser.isOkOr:
            echo "ブラウザの起動に失敗しました．"
        if openAnswer:
          ansUri.openDefaultBrowser.isOkOr:
            echo "ブラウザの起動に失敗しました．"

    # ------------------------------------------------
    # Native - Main
    # ------------------------------------------------

    {.push warning[Uninit]: off.}
    {.push warning[ProveInit]: off.}
    dispatchMulti [
      "multi",
      doc = "Pon!通 Ver. {Pon2Ver}".fmt,
      usage =
        """${doc}

Usage:
  pon2 {SUBCMD} [args]

{SUBCMD}:
$subcmds""",
    ],
      [
        runSolver,
        cmdName = "s",
        short = {"openQuestion": 'B', "openAnswer": 'b'},
        help = {
          "openQuestion": "問題をブラウザで開く",
          "openAnswer": "解をブラウザで開く",
          "urls": "{なぞぷよのURL}",
        },
      ],
      [
        runPermuter,
        cmdName = "p",
        short = {
          "allowDblNotLast": 'D',
          "allowDblLast": 'd',
          "openQuestion": 'B',
          "openAnswer": 'b',
        },
        help = {
          "allowDblNotLast": "最終手以外のゾロを許可",
          "allowDblLast": "最終手のゾロを許可",
          "openQuestion": "問題をブラウザで開く",
          "openAnswer": "解をブラウザで開く",
          "urls": "{なぞぷよのURL}",
        },
      ],
      [
        runGenerator,
        cmdName = "g",
        short = {
          "cnt": 'n',
          "rule": 'r',
          "goalKind": 'K',
          "goalColor": 'C',
          "goalVal": 'V',
          "moveCnt": 'm',
          "colorCnt": 'c',
          "heights": 'H',
          "allowDblNotLast": 'D',
          "allowDblLast": 'd',
          "openQuestion": 'B',
          "openAnswer": 'b',
          "seed": 's',
        },
        help = {
          "cnt": "生成数",
          "rule": "ルール（0:通 1:水中）",
          "goalKind":
            "クリア条件の種類（0:cぷよ全て消すべし 1:n色消すべし 2:n色以上消すべし 3:cぷよn個消すべし 4:cぷよn個以上消すべし 5:n連鎖するべし 6:n連鎖以上するべし 7:n連鎖&cぷよ全て消すべし 8:n連鎖以上&cぷよ全て消すべし 9:n色同時に消すべし 10:n色以上同時に消すべし 11:cぷよn個同時に消すべし 12:cぷよn個以上同時に消すべし 13:cぷよn箇所同時に消すべし 14:cぷよn箇所以上同時に消すべし 15:cぷよn連結で消すべし 16:cぷよn連結以上で消すべし）",
          "goalColor":
            "クリア条件の色（0:全 1:どれか1色 2:お邪魔 3:色ぷよ）",
          "goalVal": "クリア条件の数",
          "moveCnt": "手数",
          "colorCnt": "色数",
          "heights": "高さ比率（例：「012210」「0---00」）",
          "pc": "色ぷよ数（飽和連鎖問題では省略可）",
          "pg": "お邪魔ぷよ数",
          "ph": "固ぷよ数",
          "c2": "2連結数",
          "c2v": "縦2連結数",
          "c2h": "横2連結数",
          "c3": "3連結数",
          "c3v": "縦3連結数",
          "c3h": "横3連結数",
          "c3l": "L字3連結数",
          "allowDblNotLast": "最終手以外のゾロを許可",
          "allowDblLast": "最終手のゾロを許可",
          "sg": "お邪魔ぷよ落下を許可",
          "sh": "固ぷよ落下を許可",
          "openQuestion": "問題をブラウザで開く",
          "openAnswer": "解をブラウザで開く",
          "seed": "シード",
        },
      ]
    {.pop.}
    {.pop.}
