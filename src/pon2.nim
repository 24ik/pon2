## The `pon2` module provides the applications and the APIs of
## [Puyo Puyo](https://puyo.sega.jp/) and
## [Nazo Puyo](https://vc.sega.jp/3ds/nazopuyo/).
##
## To access the APIs, either `import pon2` as an "all-in-one" or import the following
## submodules individually:
## - [pon2/gui](./pon2/gui.html)
## - [pon2/app](./pon2/app.html)
## - [pon2/core](./pon2/core.html)
##
## Note that these submodules are listed in descending order of "layers".
## Importing a higher-level module automatically imports all modules below it.
##
## Compile Options:
## | Option                            | Description                            | Default                |
## | --------------------------------- | -------------------------------------- | ---------------------- |
## | `-d:pon2.waterheight=<int>`       | Height of the water.                   | `8`                    |
## | `-d:pon2.fqdn=<str>`              | FQDN of the web simulator.             | `24ik.github.io`       |
## | `-d:pon2.garbagerate.tsu=<int>`   | Garbage rate in Tsu rule.              | `70`                   |
## | `-d:pon2.garbagerate.water=<int>` | Garbage rate in Water rule.            | `90`                   |
## | `-d:pon2.simd=<int>`              | SIMD level. (1: SSE4.2, 0: None)       | 1                      |
## | `-d:pon2.bmi=<int>`               | BMI level. (2: BMI2, 1: BMI1, 0: None) | 2                      |
## | `-d:pon2.clmul=<bool>`            | Uses CLMUL.                            | `true`                 |
## | `-d:pon2.path=<str>`              | Path of the web studio.                | `/pon2/stable/studio/` |
## | `-d:pon2.assets=<str>`            | Assets directory.                      | `../assets`            |
## | `-d:pon2.build.marathon`          | Builds marathon pages.                 | `<undefined>`          |
## | `-d:pon2.build.worker`            | Builds web workers.                    | `<undefined>`          |
##

{.experimental: "strictDefs".}
{.experimental: "strictFuncs".}
{.experimental: "views".}

import std/[parsecfg, streams]
import ./pon2/private/[paths]

when defined(pon2.build.worker):
  import ./pon2/[app]
else:
  import ./pon2/[gui]

  export gui

proc getNimbleFile(): Path =
  ## Returns the path to `pon2.nimble`.
  let
    head = srcPath().splitPath.head
    (head2, tail2) = head.splitPath

  (if tail2 == "src".Path: head2 else: head).joinPath "pon2.nimble".Path

const Pon2Ver* = ($getNimbleFile()).staticRead.newStringStream.loadConfig.getSectionValue(
  "", "version"
)

when isMainModule:
  # ------------------------------------------------
  # JS backend
  # ------------------------------------------------

  when defined(js) or defined(nimsuggest):
    import std/[strformat]

    when defined(pon2.build.worker):
      import ./pon2/private/[app, results2, webworkers]
    else:
      import std/[sugar]
      import karax/[karax, karaxdsl, vdom]
      import ./pon2/private/[dom, gui]
      when defined(pon2.build.marathon):
        import std/[asyncjs, jsfetch, random]
        import ./pon2/private/[strutils]
      else:
        import ./pon2/private/[assign]

    # ------------------------------------------------
    # JS - Utils
    # ------------------------------------------------

    when not defined(pon2.build.worker):
      proc initErrorNode(msg: string): VNode =
        ## Returns the error node.
        buildHtml section(class = "section"):
          tdiv(class = "content"):
            h1(class = "title"):
              text("Pon!通 URL形式エラー")
            tdiv(class = "field"):
              label(class = "label"):
                text "エラー内容"
              tdiv(class = "control"):
                textarea(class = "textarea is-large", readonly = true):
                  text msg.cstring

      proc initFooterNode(): VNode =
        ## Returns the footer node.
        buildHtml footer(class = "footer"):
          tdiv(class = "content has-text-centered"):
            p:
              text "Pon!通 Version {Pon2Ver}".fmt

    # ------------------------------------------------
    # JS - Main
    # ------------------------------------------------

    when defined(pon2.build.worker):
      # ------------------------------------------------
      # JS - Main - Worker
      # ------------------------------------------------

      proc task(args: seq[string]): StrErrorResult[seq[string]] =
        let errorMsg = "Invalid run args: {args}".fmt

        if args.len == 0:
          return err errorMsg

        let (rule, goal, steps) = ?args.parseSolveInfo.context errorMsg

        var answers = newSeq[SolveAnswer]()
        case rule
        of Tsu:
          let node = ?parseSolveNode[TsuField](args).context errorMsg
          node.solveSingleThread answers, steps.len, true, goal, steps
        of Water:
          let node = ?parseSolveNode[WaterField](args).context errorMsg
          node.solveSingleThread answers, steps.len, true, goal, steps

        ok answers.toStrs

      task.register
    elif defined(pon2.build.marathon):
      # ------------------------------------------------
      # JS - Main - Marathon
      # ------------------------------------------------

      proc keyHandler(marathon: ref Marathon, event: Event) =
        ## Runs the keyboard event handler.
        let
          keyboardEvent = cast[KeyboardEvent](event)
          focusInput = document.activeElement.className == "input"
        if not focusInput or keyboardEvent.code == "Enter":
          if marathon[].operate keyboardEvent.toKeyEvent:
            safeRedraw()
            event.preventDefault
            if focusInput:
              document.activeElement.blur

      randomize()
      var rng = int64.rand.initRand
      let globalMarathonRef = new Marathon
      globalMarathonRef[] = Marathon.init rng

      const ChunkCount = 16
      var
        errorMsgs = newSeqOfCap[string](ChunkCount)
        completes = newSeqOfCap[bool](ChunkCount)

      for chunkIndex in 0 ..< ChunkCount:
        {.push warning[Uninit]: off.}
        {.push warning[ProveInit]: off.}
        discard "{AssetsDir}/marathon/swap{chunkIndex:02}.txt".fmt.cstring.fetch
          .then((r: Response) => r.text)
          .then(
            (s: cstring) => (
              block:
                globalMarathonRef[].load ($s).splitLines
                completes.add true
                if completes.len == ChunkCount:
                  globalMarathonRef[].isReady = true
                  safeRedraw()
            )
          )
          .catch(
            (error: Error) => errorMsgs.add "[Chunk {chunkIndex}] {error.message}".fmt
          )
        {.pop.}
        {.pop.}

      document.onkeydown = (event: Event) => globalMarathonRef.keyHandler event

      proc renderer(): VNode =
        ## Returns the root node.
        let errorMsg = errorMsgs.join "\n"

        buildHtml tdiv:
          if errorMsg == "":
            let helper = VNodeHelper.init(globalMarathonRef, "pon2-main")
            section(
              class = (if helper.mobile: "section pt-3 pl-3" else: "section").cstring
            ):
              globalMarathonRef.toMarathonVNode helper
          else:
            errorMsg.initErrorNode

          initFooterNode()

      renderer.setRenderer
    else:
      # ------------------------------------------------
      # JS - Main - Studio
      # ------------------------------------------------

      proc keyHandler(studio: ref Studio, event: Event) =
        ## Runs the keyboard event handler.
        if studio.operate(cast[KeyboardEvent](event).toKeyEvent):
          safeRedraw()
          event.preventDefault

      let globalStudioRef = new Studio

      var
        errorMsg = ""
        initialized = false

      document.onkeydown = (event: Event) => globalStudioRef.keyHandler event

      proc renderer(routerData: RouterData): VNode =
        ## Returns the root node.
        if not initialized:
          var uri = initUri()
          uri.scheme.assign "https"
          uri.hostname.assign $Pon2
          uri.path.assign Pon2Path

          let rawQuery = $routerData.queryString
          uri.query.assign (
            if rawQuery in ["", "?"]:
              "mode=ee&goal"
            else:
              rawQuery[1 ..^ 1]
          )

          let simRes = uri.parseSimulator
          if simRes.isOk:
            globalStudioRef[] = Studio.init simRes.unsafeValue
          else:
            errorMsg.assign simRes.error

          initialized.assign true

        buildHtml tdiv:
          if errorMsg == "":
            let (helper, replayHelper) = VNodeHelper.init2(globalStudioRef, "pon2-main")
            section(
              class = (if helper.mobile: "section pt-3 pl-3" else: "section").cstring
            ):
              globalStudioRef.toStudioVNode(helper, replayHelper)
          else:
            errorMsg.initErrorNode

          initFooterNode()

      renderer.setRenderer

  # ------------------------------------------------
  # Native backend
  # ------------------------------------------------

  when not defined(js):
    import std/[random, sequtils, strformat, sugar, uri]
    import cligen
    import ./pon2/private/[arrayutils, assign, browsers, strutils]

    # ------------------------------------------------
    # Native - Solve
    # ------------------------------------------------

    proc runSolver(urls: seq[string], openQuestion = false, openAnswer = false) =
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

      unwrapNazoPuyo sim.nazoPuyoWrap:
        let
          answers = itNazo.solve
          stepsSeq = collect:
            for answer in answers:
              var steps = it.steps
              for stepIndex, optPlcmt in answer:
                if it.steps[stepIndex].kind == PairPlacement:
                  steps[stepIndex].optPlacement.assign optPlcmt

              steps

        for answerIndex, steps in stepsSeq:
          var nazo = itNazo
          nazo.puyoPuyo.steps.assign steps

          let answerUri = Simulator.init(nazo, EditorEdit).toUri.unsafeValue
          echo "({answerIndex.succ}) {answerUri}".fmt

          if openAnswer:
            answerUri.openDefaultBrowser.isOkOr:
              echo "ブラウザの起動に失敗しました．"

    # ------------------------------------------------
    # Native - Permute
    # ------------------------------------------------

    proc runPermuter(
        urls: seq[string],
        fixMoves = newSeq[int](),
        allowDoubleNotLast = true,
        allowDoubleLast = false,
        openQuestion = false,
        openAnswer = false,
    ) =
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

      let fixIndices = fixMoves.mapIt it.pred
      unwrapNazoPuyo sim.nazoPuyoWrap:
        var index = 0
        for nazo in itNazo.permute(fixIndices, allowDoubleNotLast, allowDoubleLast):
          let
            sim = Simulator.init(nazo, EditorEdit)
            questionUri = sim.toUri(clearPlacements = true).unsafeValue
            answerUri = sim.toUri.unsafeValue

          echo "(Q{index.succ}) {questionUri}".fmt
          echo "(A{index.succ}) {answerUri}".fmt
          echo ""

          if openQuestion:
            questionUri.openDefaultBrowser.isOkOr:
              echo "ブラウザの起動に失敗しました．"
          if openAnswer:
            answerUri.openDefaultBrowser.isOkOr:
              echo "ブラウザの起動に失敗しました．"

          index.inc

    # ------------------------------------------------
    # Native - Generate
    # ------------------------------------------------

    func negToError(val: int): Opt[int] =
      ## Returns `err` if `val` is negative; otherwise, returns `ok(val)`.
      if val < 0:
        err()
      else:
        ok val

    proc runGenerator(
        count = 5,
        rule = 0,
        goalKind = 5,
        goalColor = 0,
        goalVal = 3,
        moveCount = 2,
        colorCount = 2,
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
        allowDoubleNotLast = true,
        allowDoubleLast = false,
        sg = newSeq[int](),
        sh = newSeq[int](),
        sr = newSeq[int](),
        sc = newSeq[int](),
        openQuestion = false,
        openAnswer = false,
        seed = 0,
    ) =
      ## なぞぷよを生成する．
      let
        puyoCountColor = pc
        puyoCountGarbage = pg
        puyoCountHard = ph

        connection2Count = c2
        connection2CountV = c2v
        connection2CountH = c2h
        connection3Count = c3
        connection3CountV = c3v
        connection3CountH = c3h
        connection3CountL = c3l

        stepGarbages = sg.mapIt it.pred
        stepHards = sh.mapIt it.pred
        stepRotate = sr.mapIt it.pred
        stepCrossRotate = sc.mapIt it.pred

      let errorMsg =
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
        elif puyoCountColor < 0 and
          goalKind.GoalKind notin {Chain, ChainMore, ClearChain, ClearChainMore}:
          "連鎖問題でない場合は色ぷよ数の指定が必要です．"
        else:
          ""
      if errorMsg != "":
        echo errorMsg
        return

      let
        heightWeights: Opt[array[Col, int]]
        heightPositives: Opt[array[Col, bool]]
      if heights.allIt it.isDigit:
        var weights = Col.initArrayWith 0
        for col in Col:
          weights[col].assign ($heights[col.ord]).parseInt.unsafeValue

        heightWeights = Opt[array[Col, int]].ok weights
        heightPositives = Opt[array[Col, bool]].err
      else:
        var positives = Col.initArrayWith false
        for col in Col:
          positives[col].assign heights[col.ord] != '0'

        heightWeights = Opt[array[Col, int]].err
        heightPositives = Opt[array[Col, bool]].ok positives

      let
        rule2 = rule.Rule
        puyoCountColor2 =
          if puyoCountColor < 0:
            goalVal * 4
          else:
            puyoCountColor

        connection2Counts = (
          total: connection2Count.negToError,
          vertical: connection2CountV.negToError,
          horizontal: connection2CountH.negToError,
        )
        connection3Counts = (
          total: connection3Count.negToError,
          vertical: connection3CountV.negToError,
          horizontal: connection3CountH.negToError,
          lShape: connection3CountL.negToError,
        )

        settings = GenerateSettings.init(
          GenerateGoal.init(
            goalKind.GoalKind, goalColor.GenerateGoalColor, goalVal.GoalVal
          ),
          moveCount,
          colorCount,
          (weights: heightWeights, positives: heightPositives),
          (colors: puyoCountColor2, garbage: puyoCountGarbage, hard: puyoCountHard),
          connection2Counts,
          connection3Counts,
          stepGarbages,
          stepHards,
          stepRotate,
          stepCrossRotate,
          allowDoubleNotLast,
          allowDoubleLast,
        )

      let seed2: int64
      if seed == 0:
        randomize()
        seed2 = int64.rand
      else:
        seed2 = seed.int64
      var rng = seed2.initRand

      for index in 0 ..< count:
        let nazoRes = rng.generate(settings, rule2)
        if nazoRes.isErr:
          echo "生成に失敗しました．エラー内容："
          echo nazoRes.error
          return

        let
          sim = Simulator.init(nazoRes.unsafeValue, EditorEdit)
          questionUri = sim.toUri(clearPlacements = true).unsafeValue
          answerUri = sim.toUri.unsafeValue

        echo "(Q{index.succ}) {questionUri}".fmt
        echo "(A{index.succ}) {answerUri}".fmt
        echo ""

        if openQuestion:
          questionUri.openDefaultBrowser.isOkOr:
            echo "ブラウザの起動に失敗しました．"
        if openAnswer:
          answerUri.openDefaultBrowser.isOkOr:
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
          "fixMoves": 'f',
          "allowDoubleNotLast": 'D',
          "allowDoubleLast": 'd',
          "openQuestion": 'B',
          "openAnswer": 'b',
        },
        help = {
          "fixMoves": "何手目を固定するか",
          "allowDoubleNotLast": "最終手以外のゾロを許可",
          "allowDoubleLast": "最終手のゾロを許可",
          "openQuestion": "問題をブラウザで開く",
          "openAnswer": "解をブラウザで開く",
          "urls": "{なぞぷよのURL}",
        },
      ],
      [
        runGenerator,
        cmdName = "g",
        short = {
          "count": 'n',
          "rule": 'r',
          "goalKind": 'K',
          "goalColor": 'C',
          "goalVal": 'V',
          "moveCount": 'm',
          "colorCount": 'c',
          "heights": 'H',
          "allowDoubleNotLast": 'D',
          "allowDoubleLast": 'd',
          "openQuestion": 'B',
          "openAnswer": 'b',
          "seed": 's',
        },
        help = {
          "count": "生成数",
          "rule": "ルール（0:通 1:水中）",
          "goalKind":
            "クリア条件の種類（0:cぷよ全て消すべし 1:n色消すべし 2:n色以上消すべし 3:cぷよn個消すべし 4:cぷよn個以上消すべし 5:n連鎖するべし 6:n連鎖以上するべし 7:n連鎖&cぷよ全て消すべし 8:n連鎖以上&cぷよ全て消すべし 9:n色同時に消すべし 10:n色以上同時に消すべし 11:cぷよn個同時に消すべし 12:cぷよn個以上同時に消すべし 13:cぷよn箇所同時に消すべし 14:cぷよn箇所以上同時に消すべし 15:cぷよn連結で消すべし 16:cぷよn連結以上で消すべし）",
          "goalColor":
            "クリア条件の色（0:全 1:どれか1色 2:お邪魔 3:色ぷよ）",
          "goalVal": "クリア条件の数",
          "moveCount": "手数",
          "colorCount": "色数",
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
          "sg": "何手目でお邪魔ぷよを落下させるか",
          "sh": "何手目で固ぷよを落下させるか",
          "sr": "何手目で大回転させるか",
          "sc": "何手目でクロス回転させるか",
          "allowDoubleNotLast": "最終手以外のゾロを許可",
          "allowDoubleLast": "最終手のゾロを許可",
          "openQuestion": "問題をブラウザで開く",
          "openAnswer": "解をブラウザで開く",
          "seed": "シード",
        },
      ]
    {.pop.}
    {.pop.}
