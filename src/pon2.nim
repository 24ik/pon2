## The `pon2` module provides the applications and the APIs of
## [Puyo Puyo](https://puyo.sega.jp/) and
## [Nazo Puyo](https://vc.sega.jp/3ds/nazopuyo/).
##
## To access the APIs, either `import pon2` as an "all-in-one" or import the following
## submodules individually:
## - [pon2/gui](./pon2/gui.html)
## - [pon2/app](./pon2/app.html)
## - [pon2/core](./pon2/core.html)
## - [pon2/utils](./pon2/utils.html)
##
## Note that these submodules are listed in descending order of "layers".
## Importing a higher-level module automatically imports all modules below it.
##
## Compile Options:
## | Option                                   | Description                            | Default                |
## | ---------------------------------------- | -------------------------------------- | ---------------------- |
## | `-d:pon2.waterheight=<int>`              | Height of the water.                   | `8`                    |
## | `-d:pon2.fqdn=<str>`                     | FQDN of the web simulator.             | `24ik.github.io`       |
## | `-d:pon2.garbagerate.tsu=<int>`          | Garbage rate in Tsu rule.              | `70`                   |
## | `-d:pon2.garbagerate.spinner=<int>`      | Garbage rate in Spinner rule.          | `120`                  |
## | `-d:pon2.garbagerate.crossspinner=<int>` | Garbage rate in Cross Spinner rule.    | `120`                  |
## | `-d:pon2.garbagerate.water=<int>`        | Garbage rate in Water rule.            | `90`                   |
## | `-d:pon2.simd=<int>`                     | SIMD level. (1: SSE4.2, 0: None)       | 1                      |
## | `-d:pon2.bmi=<int>`                      | BMI level. (2: BMI2, 1: BMI1, 0: None) | 2                      |
## | `-d:pon2.clmul=<bool>`                   | Uses CLMUL.                            | `true`                 |
## | `-d:pon2.path=<str>`                     | Path of the web studio.                | `/pon2/stable/studio/` |
## | `-d:pon2.assets=<str>`                   | Assets directory.                      | `../assets`            |
## | `-d:pon2.build.marathon`                 | Builds marathon pages.                 | `<undefined>`          |
## | `-d:pon2.build.worker`                   | Builds web workers.                    | `<undefined>`          |
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
      import ./pon2/private/[app, webworkers]
    else:
      import std/[sugar]
      import karax/[karax, karaxdsl, kbase, vdom]
      import ./pon2/private/[dom, gui, strutils]
      when defined(pon2.build.marathon):
        import std/[asyncjs, jsfetch, random]
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
                  text msg.kstring

      proc initFooterNode(): VNode =
        ## Returns the footer node.
        buildHtml footer(class = "footer"):
          tdiv(class = "content has-text-centered"):
            p:
              text "Pon!通 Version {Pon2Ver}".fmt
            tdiv(class = "field is-grouped is-grouped-centered"):
              tdiv(class = "control"):
                a(
                  class = "button",
                  href = "https://github.com/24ik/pon2",
                  target = "_blank",
                  rel = "noopener noreferrer",
                ):
                  span(class = "icon"):
                    italic(class = "fab fa-github")
                  span:
                    text "GitHub"

    # ------------------------------------------------
    # JS - Main
    # ------------------------------------------------

    when defined(pon2.build.worker):
      # ------------------------------------------------
      # JS - Main - Worker
      # ------------------------------------------------

      proc task(args: seq[string]): Pon2Result[seq[string]] =
        let errorMsg = "Invalid run args: {args}".fmt

        if args.len == 0:
          return err errorMsg

        let (goal, steps) = ?args.parseSolveInfo.context errorMsg

        let node = ?args.parseSolveNode.context errorMsg
        var answers = newSeq[SolveAnswer]()
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
              class = (if helper.mobile: "section pt-3 pl-3" else: "section").kstring
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

          uri.query.assign ($routerData.queryString).strip(
            trailing = false, chars = {'?'}
          )
          if uri.query == "":
            uri.query.assign "mode={EditorEdit.ord}".fmt

          let simulatorResult = uri.parseSimulator
          if simulatorResult.isOk:
            globalStudioRef[] = Studio.init simulatorResult.unsafeValue
            globalStudioRef[].simulator.normalizeGoal
          else:
            errorMsg.assign simulatorResult.error

          initialized.assign true

        buildHtml tdiv:
          if errorMsg == "":
            let (helper, replayHelper) = VNodeHelper.init2(globalStudioRef, "pon2-main")
            section(
              class = (if helper.mobile: "section pt-3 pl-3" else: "section").kstring
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
    import ./pon2/private/[assign, browsers, staticfor, strutils]

    # ------------------------------------------------
    # Native - Solve
    # ------------------------------------------------

    proc runSolver(urls: seq[string], openQuestion = false, openAnswer = false) =
      ## なぞぷよの解を求める．
      if urls.len != 1:
        echo "URLを一つ入力してください．"
        return

      let simulatorResult = urls[0].parseUri.parseSimulator
      if simulatorResult.isErr:
        echo "URL形式が間違っています．エラー内容："
        echo simulatorResult.error
        return
      let simulator = simulatorResult.unsafeValue

      if openQuestion:
        urls[0].parseUri.openDefaultBrowser.isOkOr:
          echo "ブラウザの起動に失敗しました．"

      let
        answers = simulator.nazoPuyo.solve
        stepsSeq = collect:
          for answer in answers:
            var steps = simulator.nazoPuyo.puyoPuyo.steps
            for stepIndex, placement in answer:
              if simulator.nazoPuyo.puyoPuyo.steps[stepIndex].kind == PairPlace:
                steps[stepIndex].placement.assign placement

            steps

      for answerIndex, steps in stepsSeq:
        var nazoPuyo = simulator.nazoPuyo
        nazoPuyo.puyoPuyo.steps.assign steps

        let answerUri = Simulator.init(nazoPuyo, EditorEdit).toUri.unsafeValue
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
        allowDoubleMoves = newSeq[int](),
        openQuestion = false,
        openAnswer = false,
    ) =
      ## なぞぷよのツモを並べ替える．
      if urls.len != 1:
        echo "URLを一つ入力してください．"
        return

      let simulatorResult = urls[0].parseUri.parseSimulator
      if simulatorResult.isErr:
        echo "URL形式が間違っています．エラー内容："
        echo simulatorResult.error
        return
      let simulator = simulatorResult.unsafeValue

      var index = 0
      for nazoPuyo in simulator.nazoPuyo.permute(
        fixMoves.mapIt it.pred, allowDoubleMoves.mapIt it.pred
      ):
        let
          resultSimulator = Simulator.init(nazoPuyo, EditorEdit)
          questionUri = resultSimulator.toUri(clearPlacements = true).unsafeValue
          answerUri = resultSimulator.toUri.unsafeValue

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
        rule = 1,
        goalKindOpt = 1,
        goalColor = 1,
        goalVal = 3,
        goalOperator = 1,
        goalClearColorOpt = 0,
        moveCount = 2,
        colorCount = 2,
        heights = "0....0",
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
        md = newSeq[int](),
        mg = newSeq[int](),
        mh = newSeq[int](),
        mr = newSeq[int](),
        mc = newSeq[int](),
        openQuestion = false,
        openAnswer = false,
        seed = 0,
    ) =
      ## なぞぷよを生成する．
      # rule
      var rule2 = Rule.low
      if rule - 1 notin Rule.low.ord .. Rule.high.ord:
        echo "ルールが不正です．"
        return
      rule2.assign (rule - 1).Rule

      # goal kind
      var goalKindOpt2 = Opt[GoalKind].err
      if goalKindOpt == 0:
        discard
      elif goalKindOpt - 1 notin GoalKind.low.ord .. GoalKind.high.ord:
        echo "クリア条件の種類が不正です．"
        return
      else:
        goalKindOpt2.ok (goalKindOpt - 1).GoalKind

      # goal color
      var goalColor2 = GoalColor.low
      if goalColor - 1 notin GoalColor.low.ord .. GoalColor.high.ord:
        echo "クリア条件の色が不正です．"
        return
      goalColor2.assign (goalColor - 1).GoalColor

      # goal operator
      var goalOperator2 = GoalOperator.low
      if goalOperator - 1 notin GoalOperator.low.ord .. GoalOperator.high.ord:
        echo "クリア条件の演算子が不正です．"
        return
      goalOperator2.assign (goalOperator - 1).GoalOperator

      # goal clear color
      var goalClearColorOpt2 = Opt[GoalColor].err
      if goalClearColorOpt == 0:
        discard
      elif goalClearColorOpt - 1 notin GoalColor.low.ord .. GoalColor.high.ord:
        echo "全消し条件の色が不正です．"
        return
      else:
        goalClearColorOpt2.ok (goalClearColorOpt - 1).GoalColor

      # goal
      var goal =
        if goalKindOpt2.isOk:
          Goal.init(
            goalKindOpt2.unsafeValue, goalColor2, goalVal, goalOperator2,
            goalClearColorOpt2,
          )
        else:
          Goal.init goalClearColorOpt2
      goal.normalize

      # height
      if heights.len != Width:
        echo "高さ指定が不正です．"
        return
      var heights2 {.noinit.}: array[Col, int]
      staticFor(col, Col):
        heights2[col].assign if heights[col.ord].isDigit:
          ($heights[col.ord]).parseInt.unsafeValue
        else:
          -1

      # puyo counts
      var puyoCounts = (colored: pc, garbage: pg, hard: ph)
      if goalKindOpt2.isOk and goalKindOpt2.unsafeValue == Chain and
          puyoCounts.colored < 0:
        puyoCounts.colored.assign goalVal * 4

      # connections, indices
      let
        connection2Counts = (
          totalOpt: c2.negToError,
          verticalOpt: c2v.negToError,
          horizontalOpt: c2h.negToError,
        )
        connection3Counts = (
          totalOpt: c3.negToError,
          verticalOpt: c3v.negToError,
          horizontalOpt: c3h.negToError,
          lShapeOpt: c3l.negToError,
        )
        indices = (
          allowDouble: md.mapIt it - 1,
          garbage: mg.mapIt it - 1,
          hard: mh.mapIt it - 1,
          rotate: mr.mapIt it - 1,
          crossRotate: mc.mapIt it - 1,
        )

      # settings
      let settings = GenerateSettings.init(
        rule2, goal, moveCount, colorCount, heights2, puyoCounts, connection2Counts,
        connection3Counts, indices,
      )

      let seed2: int64
      if seed == 0:
        randomize()
        seed2 = int64.rand
      else:
        seed2 = seed.int64
      var rng = seed2.initRand

      for problemIndex in 0 ..< count:
        let nazoPuyoResult = rng.generate settings
        if nazoPuyoResult.isErr:
          echo "生成に失敗しました．エラー内容："
          echo nazoPuyoResult.error
          return

        let
          simulator = Simulator.init(nazoPuyoResult.unsafeValue, EditorPlay)
          questionUri = simulator.toUri(clearPlacements = true).unsafeValue
          answerUri = simulator.toUri.unsafeValue

        echo "(Q{problemIndex+1}) {questionUri}".fmt
        echo "(A{problemIndex+1}) {answerUri}".fmt
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
          "allowDoubleMoves": 'd',
          "openQuestion": 'B',
          "openAnswer": 'b',
        },
        help = {
          "fixMoves": "何手目を固定するか",
          "allowDoubleMoves": "何手目のゾロを許可するか",
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
          "goalKindOpt": 'K',
          "goalColor": 'C',
          "goalVal": 'V',
          "goalOperator": 'O',
          "goalClearColorOpt": 'L',
          "moveCount": 'm',
          "colorCount": 'c',
          "heights": 'H',
          "openQuestion": 'B',
          "openAnswer": 'b',
          "seed": 's',
        },
        help = {
          "count": "生成数",
          "rule": "ルール（1:通 2:大回転 3:クロス回転 4:水中）",
          "goalKindOpt":
            "クリア条件の種類（0:条件なし 1:n連鎖 2:n色同時 3:n個同時 4:n箇所 5:n連結 6:累計n色 7:累計n個）",
          "goalColor":
            "クリア条件の色（1:全 2:赤 3:緑 4:青 5:黄 6:紫 7:お邪魔 8:色）",
          "goalVal": "クリア条件の値",
          "goalOperator": "クリア条件の演算子（1:ちょうど 2:以上）",
          "goalClearColorOpt":
            "全消し条件の色（0: 条件なし 1:全 2:赤 3:緑 4:青 5:黄 6:紫 7:お邪魔 8:色）",
          "moveCount": "手数",
          "colorCount": "色数",
          "heights": "高さ比率（例：「012210」「0...00」）",
          "pc": "色ぷよ数（飽和連鎖問題では省略可）",
          "pg": "お邪魔ぷよ数",
          "ph": "固ぷよ数",
          "c2": "2連結数（負の数ならランダム．以下同じ）",
          "c2v": "縦2連結数",
          "c2h": "横2連結数",
          "c3": "3連結数",
          "c3v": "縦3連結数",
          "c3h": "横3連結数",
          "c3l": "L字3連結数",
          "md": "何手目でゾロを許可するか",
          "mg": "何手目でお邪魔ぷよを落下させるか",
          "mh": "何手目で固ぷよを落下させるか",
          "mr": "何手目で大回転させるか",
          "mc": "何手目でクロス回転させるか",
          "openQuestion": "問題をブラウザで開く",
          "openAnswer": "解をブラウザで開く",
          "seed": "シード",
        },
      ]
    {.pop.}
    {.pop.}
