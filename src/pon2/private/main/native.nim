## This module implements helper functions for the native main file.
##

{.experimental: "inferGenericTypes".}
{.experimental: "notnil".}
{.experimental: "strictCaseObjects".}
{.experimental: "strictDefs".}
{.experimental: "strictFuncs".}
{.experimental: "views".}

import std/[browsers, options, random, sequtils, strformat, strutils, uri]
import docopt
import nigui
import ../[misc]
import ../../app/[generate, ide, nazopuyo, permute, simulator, solve]
import ../../app/ide/[native]
import
  ../../core/[field, fieldtype, nazopuyo, pairposition, puyopuyo, requirement, rule]

# ------------------------------------------------
# Parse
# ------------------------------------------------

func parseSomeInt[T: SomeInteger or Natural or Positive](
    val: Value, allowNone = false
): Option[T] {.inline.} =
  ## Converts the value to the given type `T`.
  ## If the conversion fails, `ValueError` will be raised.
  ## If `allowNone` is `true`, `vkNone` is accepted as `val` and `none` is returned.
  result = none T

  case val.kind
  of vkNone:
    if not allowNone:
      raise newException(ValueError, "`val` should have a value.")
  of vkStr:
    result = some parseSomeInt[T] $val
  else:
    raise newException(ValueError, "`val` should be `vkNone` or `vkStr`.")

func parseRequirementKind(val: Value): RequirementKind {.inline.} =
  ## Converts the value to the requirement kind.
  ## If the conversion fails, `ValueError` will be raised.
  let idx = parseSomeInt[int](val).get
  if idx notin RequirementKind.low.ord .. RequirementKind.high.ord:
    raise newException(ValueError, "Invalid requirement kind: " & $idx)

  result = idx.RequirementKind

func parseGenerateRequirementColor(val: Value): GenerateRequirementColor {.inline.} =
  ## Converts the value to the generate requirement color.
  ## If the conversion fails, `ValueError` will be raised.
  let idx = parseSomeInt[int](val).get
  if idx notin GenerateRequirementColor.low.ord .. GenerateRequirementColor.high.ord:
    raise newException(ValueError, "Invalid requirement color: " & $idx)

  result = idx.GenerateRequirementColor

func parseRequirementNumber(val: Value): RequirementNumber {.inline.} =
  ## Converts the value to the requirement number.
  ## If the conversion fails, `ValueError` will be raised.
  let idx = parseSomeInt[int](val).get
  if idx notin RequirementNumber.low.ord .. RequirementNumber.high.ord:
    raise newException(ValueError, "Invalid requirement number: " & $idx)

  result = idx.RequirementNumber

func parseRule(val: Value): Rule {.inline.} =
  ## Converts the value to the rule.
  ## If the conversion fails, `ValueError` will be raised.
  let idx = parseSomeInt[int](val).get
  if idx notin Rule.low.ord .. Rule.high.ord:
    raise newException(ValueError, "Invalid rule: " & $idx)

  result = idx.Rule

# ------------------------------------------------
# Solve
# ------------------------------------------------

proc runSolver*(args: Table[string, Value]) {.inline.} =
  ## Runs the CUI solver.
  let questionUriStr = $args["<question>"]
  if args["-B"].to_bool:
    questionUriStr.openDefaultBrowser

  let ide = questionUriStr.parseUri.parseIde
  if ide.simulator.kind != Nazo:
    raise newException(ValueError, "The question should be a Nazo Puyo.")

  ide.simulator.nazoPuyoWrap.get:
    for answerIdx, answer in wrappedNazoPuyo.solve(showProgress = true):
      var nazo = wrappedNazoPuyo
      nazo.puyoPuyo.pairsPositions.positions = answer

      let answerUri = nazo.newSimulator(PlayEditor).newIde.toUri(withPositions = true)
      echo &"({answerIdx.succ}) {answerUri}"

      if args["-b"].to_bool:
        ($answerUri).openDefaultBrowser

# ------------------------------------------------
# Generate
# ------------------------------------------------

proc runGenerator*(args: Table[string, Value]) {.inline.} =
  ## Runs the CUI generator.
  # RNG
  var rng =
    if args["-s"].kind == vkNone:
      initRand()
    else:
      parseSomeInt[Natural](args["-s"]).get.initRand

  # requirement
  let
    kind = args["--rk"].parseRequirementKind
    req =
      if kind in NoColorKinds:
        initGenerateRequirement(kind, args["--rn"].parseRequirementNumber)
      elif kind in NoNumberKinds:
        initGenerateRequirement(kind, args["--rc"].parseGenerateRequirementColor)
      else:
        initGenerateRequirement(
          kind,
          args["--rc"].parseGenerateRequirementColor,
          args["--rn"].parseRequirementNumber,
        )

  # heights
  if ($args["-H"]).len != 6:
    raise newException(ValueError, "`-H` option should be the length 6.")
  var heights: array[Column, Option[Natural]]
  heights[Column.low] = none Natural # HACK: dummy to suppress warning
  for i, c in ($args["-H"]):
    heights[Column i] =
      if c == '+':
        none Natural
      else:
        some parseSomeInt[Natural](c)

  # option
  let option = GenerateOption(
    requirement: req,
    moveCount: parseSomeInt[Positive](args["-m"]).get,
    colorCount: parseSomeInt[int](args["-c"]).get,
    heights: heights,
    puyoCounts: (
      color: parseSomeInt[Natural](args["--nc"], true),
      garbage: parseSomeInt[Natural](args["--ng"]).get,
    ),
    connect2Counts: (
      total: parseSomeInt[Natural](args["-2"], true),
      vertical: parseSomeInt[Natural](args["--2v"], true),
      horizontal: parseSomeInt[Natural](args["--2h"], true),
    ),
    connect3Counts: (
      total: parseSomeInt[Natural](args["-3"], true),
      vertical: parseSomeInt[Natural](args["--3v"], true),
      horizontal: parseSomeInt[Natural](args["--3h"], true),
      lShape: parseSomeInt[Natural](args["--3l"], true),
    ),
    allowDouble: not args["-D"].to_bool,
    allowLastDouble: args["-d"].to_bool,
  )

  # generate
  let rule = args["-r"].parseRule
  for nazoIdx in 0 ..< parseSomeInt[Natural](args["-n"]).get:
    let
      ide = option
        .generate(rule, (rng.rand int.low .. int.high))
        .newSimulator(PlayEditor).newIde
      questionUri = ide.toUri(withPositions = false)
      answerUri = ide.toUri(withPositions = true)

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

proc runPermuter*(args: Table[string, Value]) {.inline.} =
  ## Runs the CUI permuter.
  let
    questionUriStr = $args["<question>"]
    ide = questionUriStr.parseUri.parseIde

  var idx = 0
  {.push warning[UnsafeDefault]: off.}
  {.push warning[UnsafeSetLen]: off.}
  ide.simulator.nazoPuyoWrap.get:
    for pairsPositions in wrappedNazoPuyo.permute(
      args["-f"].mapIt parseSomeInt[Positive](it),
      not args["-D"].to_bool,
      args["-d"].to_bool,
      showProgress = true,
    ):
      var nazo = wrappedNazoPuyo
      nazo.puyoPuyo.pairsPositions = pairsPositions

      let
        ide2 = nazo.newSimulator(PlayEditor).newIde
        questionUri = ide2.toUri(withPositions = false)
        answerUri = ide2.toUri(withPositions = true)
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
# IDE
# ------------------------------------------------

proc runIde*(args: Table[string, Value]) {.inline.} =
  ## Runs the IDE.
  let ide: Ide
  case args["<uri>"].kind
  of vkNone:
    ide = newIde()
  of vkStr:
    ide = ($args["<uri>"]).parseUri.parseIde
  else:
    ide = newIde() # HACK: dummy to suppress warning
    assert false

  app.init
  ide.newIdeWindow.show
  app.run

# ------------------------------------------------
# Command-line Arguments
# ------------------------------------------------

const Document =
  """
ぷよぷよ・なぞぷよ用アプリケーション．
機能一覧（使用方法はUsageの節を参照）：
* なぞぷよ解探索
* なぞぷよ生成
* なぞぷよツモ探索
* IDE

Usage:
  pon2 (solve | s) <question> [-bB] [-h | --help] [-V | --version]
  pon2 (generate | g) [-bBdD] [options] [-h | --help] [-V | --version]
  pon2 (permute | p) <question> [(-f <>)... -bBdD] [-h | --help] [-V | --version]
  pon2 [<uri>] [-h | --help] [-V | --version]

Options:
  -h --help      このヘルプ画面を表示する．
  -V --version   バージョン情報を表示する．

  -b             解をブラウザで開く．
  -B             問題をブラウザで開く．

  -d             最終手のゾロを許可．
  -D             ゾロを許可．                [default: true]

  -n <>          生成数．                    [default: 5]
  -r <>          ルール．                    [default: 0]
  -m <>          手数．                      [default: 3]
  --rk <>        クリア条件．                [default: 5]
  --rc <>        クリア条件の色．            [default: 0]
  --rn <>        クリア条件の数．            [default: 6]
  -c <>          色数．                      [default: 3]
  -H <>          各列の高さの割合．          [default: 0++++0]
  --nc <>        色ぷよの数．
  --ng <>        お邪魔ぷよの数．            [default: 2]
  -2 <>          2連結の数．
  --2v <>        縦2連結の数．
  --2h <>        横2連結の数．
  -3 <>          3連結の数．
  --3v <>        縦3連結の数．
  --3h <>        横3連結の数．
  --3l <>        L字3連結の数．
  -s <>          シード．

  -f <>...       何手目を固定するか．

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

proc getCommandLineArguments*(): Table[string, Value] {.inline.} =
  ## Returns the command line arguments.
  Document.docopt
