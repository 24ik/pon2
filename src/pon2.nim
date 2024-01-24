## The `pon2` module provides applications and APIs for
## [Puyo Puyo](https://puyo.sega.jp/) and
## [Nazo Puyo](https://vc.sega.jp/3ds/nazopuyo/).
##
## API Documentations:
## - [Puyo Puyo](./pon2pkg/core.html)
## - [Nazo Puyo](./pon2pkg/nazopuyo.html)
## - [GUI Application](./pon2pkg/app.html)
##
## To generate a static web page, compile this file on JS backend.
## With the compile option `-d:Pon2Worker`, generates the web worker file
## instead of the main JS file.
##

{.experimental: "strictDefs".}
{.experimental: "strictFuncs".}
{.experimental: "views".}

when isMainModule:
  when defined(js):
    when defined(Pon2Worker):
      import ./pon2pkg/private/app/web/[webworker]
      import ./pon2pkg/private/main/[web]

      assignToWorker workerTask
    else:
      import std/[sugar]
      import ./pon2pkg/apppkg/[editorpermuter]
      import ./pon2pkg/private/main/[web]
      import karax/[karax]

      var
        pageInitialized = false
        globalEditorPermuter: EditorPermuter

      setRenderer (routerData: RouterData) => routerData.initEditorPermuterNode(
        pageInitialized, globalEditorPermuter)

when defined(js):
  discard
else:
  import std/[browsers, options, random, sequtils, strformat, strutils, uri]
  import docopt
  import nigui
  import ./pon2pkg/apppkg/[editorpermuter]
  import ./pon2pkg/corepkg/[environment, field, misc]
  import ./pon2pkg/nazopuyopkg/[generate, nazopuyo, permute, solve]
  import ./pon2pkg/private/[misc]

  # ------------------------------------------------
  # Parse
  # ------------------------------------------------

  func parseRequirementKind(val: Value, allowNone = false):
      Option[RequirementKind] {.inline.} =
    ## Converts the value to the requirement kind.
    ## If the conversion fails, `ValueError` will be raised.
    ## If `allowNone` is `true`, `vkNone` is accepted as `val` and `none` is
    ## returned.
    let idx = val.parseSomeInt[:int](allowNone)
    {.push warning[ProveInit]: off.}
    if idx.isNone:
      return none RequirementKind
    {.pop.}

    if idx.get notin RequirementKind.low.ord..RequirementKind.high.ord:
      raise newException(ValueError, "Invalid requirement kind.")

    result = some RequirementKind idx.get

  func parseGenerateRequirementColor(
      val: Value, allowNone = false): Option[GenerateRequirementColor]
      {.inline.} =
    ## Converts the value to the generate requirement color.
    ## If the conversion fails, `ValueError` will be raised.
    ## If `allowNone` is `true`, `vkNone` is accepted as `val` and `none` is
    ## returned.
    let idx = val.parseSomeInt[:int](allowNone)
    {.push warning[ProveInit]: off.}
    if idx.isNone:
      return none GenerateRequirementColor
    {.pop.}

    if idx.get notin GenerateRequirementColor.low.ord ..
        GenerateRequirementColor.high.ord:
      raise newException(ValueError, "Invalid requirement color.")

    result = some GenerateRequirementColor idx.get

  func parseRequirementNumber(val: Value, allowNone = false):
      Option[RequirementNumber] {.inline.} =
    ## Converts the value to the requirement number.
    ## If the conversion fails, `ValueError` will be raised.
    ## If `allowNone` is `true`, `vkNone` is accepted as `val` and `none` is
    ## returned.
    let idx = val.parseSomeInt[:int](allowNone)
    {.push warning[ProveInit]: off.}
    if idx.isNone:
      return none RequirementNumber
    {.pop.}

    if idx.get notin RequirementNumber.low.ord..RequirementNumber.high.ord:
      raise newException(ValueError, "Invalid requirement number.")

    result = some RequirementNumber idx.get

  func parseRule(val: Value, allowNone = false): Option[Rule] {.inline.} =
    ## Converts the value to the rule.
    ## If the conversion fails, `ValueError` will be raised.
    ## If `allowNone` is `true`, `vkNone` is accepted as `val` and `none` is
    ## returned.
    let idx = val.parseSomeInt[:int](allowNone)
    {.push warning[ProveInit]: off.}
    if idx.isNone:
      return none Rule
    {.pop.}

    if idx.get notin Rule.low.ord..Rule.high.ord:
      raise newException(ValueError, "Invalid rule.")

    result = some Rule idx.get

  # ------------------------------------------------
  # Solve
  # ------------------------------------------------

  proc runSolver(args: Table[string, Value]) {.inline.} =
    ## Runs the CUI solver.
    let questionUriStr = $args["<question>"]
    if args["-B"].to_bool:
      questionUriStr.openDefaultBrowser

    questionUriStr.parseUri.parseNazoPuyos.nazoPuyos.flattenAnd:
      for answerIdx, answer in nazoPuyo.solve(showProgress = true):
        let answerUri = nazoPuyo.toUri(answer, mode = Replay, editor = true)
        echo &"({answerIdx.succ}) {answerUri}"

        if args["-b"].to_bool:
          ($answerUri).openDefaultBrowser

  # ------------------------------------------------
  # Generate
  # ------------------------------------------------

  proc runGenerator(args: Table[string, Value]) {.inline.} =
    ## Runs the CUI generator.
    # RNG
    var rng =
      if args["-s"].kind == vkNone: initRand()
      else: args["-s"].parseSomeInt[:Natural].get.initRand

    # requirement
    {.push warning[ProveInit]: off.}
    let
      kind = args["--rk"].parseRequirementKind.get
      color =
        if kind in ColorKinds: args["--rc"].parseGenerateRequirementColor
        else: none GenerateRequirementColor
      number =
        if kind in NumberKinds: args["--rn"].parseRequirementNumber
        else: none RequirementNumber
      req = GenerateRequirement(kind: kind, color: color, number: number)
    {.pop.}

    # heights
    if ($args["-H"]).len != 6:
      raise newException(ValueError, "`-H` option should be the length 6.")
    var heights: array[Column, Option[Natural]]
    {.push warning[ProveInit]: off.}
    heights[Column.low] = none Natural # HACK: dummy to remove warning
    for i, c in ($args["-H"]):
      heights[Column i] =
        if c == '+': none Natural
        else: some c.parseSomeInt[:Natural]
    {.pop.}

    # generate
    for nazoIdx in 0..<args["-n"].parseSomeInt[:Natural].get:
      let (question, answer) = generates(
        (rng.rand int.low..int.high),
        args["-r"].parseRule.get,
        req,
        args["-m"].parseSomeInt[:Natural].get,
        args["-c"].parseSomeInt[:Natural].get,
        heights,
        (color: args["--nc"].parseSomeInt[:Natural].get,
         garbage: args["--ng"].parseSomeInt[:Natural].get),
        (
          total: args["--tt"].parseSomeInt[:Natural](true),
          vertical: args["--tv"].parseSomeInt[:Natural](true),
          horizontal: args["--th"].parseSomeInt[:Natural](true),
          lShape: args["--tl"].parseSomeInt[:Natural](true)),
        not args["-D"].to_bool,
        args["-d"].to_bool)

      let
        questionUri: Uri
        answerUri: Uri
      question.flattenAnd:
        questionUri = nazoPuyo.toUri
        answerUri = nazoPuyo.toUri answer
      echo &"(Q{nazoIdx.succ}) {questionUri}"
      echo &"(A{nazoIdx.succ}) {answerUri}"
      echo ""

      if args["-B"].to_bool:
        openDefaultBrowser $questionUri
      if args["-b"].to_bool:
        openDefaultBrowser $answerUri

  # ------------------------------------------------
  # Permute
  # ------------------------------------------------

  proc runPermuter(args: Table[string, Value]) {.inline.} =
    ## Runs the CUI permuter.
    var idx = 0
    {.push warning[UnsafeDefault]: off.}
    {.push warning[UnsafeSetLen]: off.}
    ($args["<question>"]).parseUri.parseNazoPuyos.nazoPuyos.flattenAnd:
      for (pairs, answer) in nazoPuyo.permute(
          args["-f"].mapIt(it.parseSomeInt[:Positive]),
          not args["-D"].to_bool, args["-d"].to_bool, showProgress = true):
        var nazo = nazoPuyo
        nazo.environment.pairs = pairs

        let
          questionUri = nazo.toUri
          answerUri = nazo.toUri answer
        echo &"(Q{idx.succ}) {questionUri}"
        echo &"(A{idx.succ}) {answerUri}"
        echo ""

        if args["-B"].to_bool:
          openDefaultBrowser $questionUri
        if args["-b"].to_bool:
          openDefaultBrowser $answerUri

        idx.inc
    {.pop.}
    {.pop.}

  # ------------------------------------------------
  # Editor
  # ------------------------------------------------

  proc runEditorPermuter(args: Table[string, Value]) {.inline.} =
    ## Runs the GUI editor&permuter.
    let editorPermuter = new EditorPermuter
    case args["<uri>"].kind
    of vkNone:
      editorPermuter[] = initTsuEnvironment().initEditorPermuter
    of vkStr:
      let inputUri = ($args["<uri>"]).parseUri
      try:
        let parseRes = inputUri.parseNazoPuyos
        parseRes.nazoPuyos.flattenAnd:
          if parseRes.positions.isSome:
            editorPermuter[] = nazoPuyo.initEditorPermuter(
              parseRes.positions.get, parseRes.mode, parseRes.editor)
          else:
            editorPermuter[] = nazoPuyo.initEditorPermuter(
              parseRes.mode, parseRes.editor)
      except ValueError:
        let parseRes = inputUri.parseEnvironments
        parseRes.environments.flattenAnd:
          if parseRes.positions.isSome:
            editorPermuter[] = environment.initEditorPermuter(
              parseRes.positions.get, parseRes.mode, parseRes.editor)
          else:
            editorPermuter[] = environment.initEditorPermuter(
              parseRes.mode, parseRes.editor)
    else:
      assert false

    app.init
    editorPermuter.initEditorPermuterWindow.show
    app.run

  # ------------------------------------------------
  # Entry Point
  # ------------------------------------------------

  when isMainModule:
    const Document = """
ぷよぷよ・なぞぷよ用アプリケーション．
機能一覧（使用方法はUsageの節を参照）：
* なぞぷよ解探索
* なぞぷよ生成
* なぞぷよツモ探索
* GUIアプリケーション

Usage:
  pon2 (solve | s) <question> [-bB] [-h | --help]
  pon2 (generate | g) [-bBdD] [options] [-h | --help]
  pon2 (permute | p) <question> [(-f <>)... -bBdD] [-h | --help]
  pon2 [<uri>] [-h | --help]

Options:
  -h --help   このヘルプ画面を表示する．

  -b          解をブラウザで開く．
  -B          問題をブラウザで開く．

  -d          最終手のゾロを許可．
  -D          ゾロを許可．                [default: true]

  -n <>       生成数．                    [default: 5]
  -r <>       ルール．                    [default: 0]
  -m <>       手数．                      [default: 3]
  --rk <>     クリア条件．                [default: 5]
  --rc <>     クリア条件の色．            [default: 0]
  --rn <>     クリア条件の数．            [default: 6]
  -c <>       色数．                      [default: 3]
  -H <>       各列の高さの割合．          [default: 0++++0]
  --nc <>     色ぷよの数．                [default: 24]
  --ng <>     お邪魔ぷよの数．            [default: 2]
  --tt <>     3連結の数．
  --tv <>     縦3連結の数．
  --th <>     横3連結の数．
  --tl <>     L字3連結の数．
  -s <>       シード．

  -f <>...    何手目を固定するか．

非自明なオプションの指定方法は以下の通り．

  ルール（-r --fr）：以下の表を参照して整数値を入力する．
    [0] 通
    [1] すいちゅう

  クリア条件（--rk --fk）：以下の表を参照して整数値を入力する．
    [0]  cぷよ全て消すべし
    [1]  n色消すべし
    [2]  n色以上消すべし
    [3]  cぷよn個消すべし
    [4]  cぷよn個以上消すべし
    [5]  n連鎖するべし
    [6]  n連鎖以上するべし
    [7]  n連鎖&cぷよ全て消すべし
    [8]  n連鎖以上&cぷよ全て消すべし
    [9]  n色同時に消すべし
    [10] n色以上同時に消すべし
    [11] cぷよn個同時に消すべし
    [12] cぷよn個以上同時に消すべし
    [13] cぷよn箇所同時に消すべし
    [14] cぷよn箇所以上同時に消すべし
    [15] cぷよn連結で消すべし
    [16] cぷよn連結以上で消すべし

  クリア条件の色（--rc）：以下の表を参照して整数値を入力する．
    [0] 全てのぷよ
    [1] 色ぷよのうちランダムに1色
    [2] お邪魔ぷよ
    [3] 色ぷよ

  各列の高さの割合（-H）：
    各列の高さの比を表す数字を並べた6文字で指定する．
    「000000」を指定した場合は全ての列の高さをランダムに決定する．
    「+」も指定でき，これを指定した列は高さが1以上のランダムとなる．
    なお，「+」を指定する場合は，6文字全て「+」か「0」のいずれかである必要がある．"""

    let args = Document.docopt
    if args["solve"] or args["s"]:
      args.runSolver
    elif args["generate"] or args["g"]:
      args.runGenerator
    elif args["permute"] or args["p"]:
      args.runPermuter
    else:
      args.runEditorPermuter

when defined(nimdoc):
  # HACK: to generate documentation
  import ./pon2pkg/app as appDoc
  import ./pon2pkg/core as coreDoc
  import ./pon2pkg/nazopuyo as nazoDoc
  discard coreDoc.Cell.None
  discard nazoDoc.MarkResult.Accept
  discard appDoc.SimulatorState.Stable
