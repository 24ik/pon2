## The :code:`pon2` module provides some tools for Nazo Puyo.
## With :code:`import pon2`, you can use all features provides by this module.
## Documentations:
## * `Database <./pon2pkg/core/db.html>`_
## * `Generate <./pon2pkg/core/generate.html>`_
## * `Permute <./pon2pkg/core/permute.html>`_
## * `Solve <./pon2pkg/core/solve.html>`_
##
## This module uses multiple threads by default.
## To prevent this, specify :code:`-d:singleThread` to the compile options.
##

when not defined(js):
  import ./pon2pkg/core/db
  export db.connectDb, db.insert, db.delete, db.find

import ./pon2pkg/core/generate
export generate.generate

import ./pon2pkg/core/permute
export permute.permute

import ./pon2pkg/core/solve
export solve.Solution, solve.Solutions, solve.InspectSolutions, solve.solve, solve.inspectSolve, solve.`$`

when isMainModule:
  when defined(js):
    import ./pon2pkg/web/main as webMain

    makeWebPage()
  else:
    import docopt

    import ./pon2pkg/cui/db as cuiDb
    import ./pon2pkg/cui/generate as cuiGenerate
    import ./pon2pkg/cui/permute as cuiPermute
    import ./pon2pkg/cui/solve as cuiSolve
    import ./pon2pkg/gui/main as guiMain

    const Document = """
なぞぷよツール．ソルバー・ジェネレーター・ツモ探索・データベース機能とGUIアプリケーションが提供されている．

Usage:
  pon2 (solve | s) <url> [-ibB] [-h | --help]
  pon2 (generate | g) [options]
  pon2 (permute | p) <url> [(-f <>)... -ibBdDS] [-h | --help]
  pon2 (database | d) (add | a) <urls>... [-h | --help]
  pon2 (database | d) (remove | r) <urls>... [-h | --help]
  pon2 (database | d) (find | f) [(--fk <>)... (--fm <>)... --fs --fS] [-h | --help]
  pon2 [<url>] [-h | --help]

Options:
  -h --help   このヘルプ画面を表示する．

  -i          IPS形式のURLで出力する．
  -b          解をブラウザで開く．
  -B          問題をブラウザで開く．

  -d          最終手のゾロを許可．
  -D          ゾロを許可．                [default: true]

  -n <>       生成数．                    [default: 5]
  -m <>       手数．                      [default: 3]
  --rk <>     クリア条件．                [default: 5]
  --rc <>     クリア条件の色．            [default: 0]
  --rn <>     クリア条件の数．            [default: 6]
  -c <>       色数．                      [default: 3]
  -H <>       各列の高さの割合．          [default: 0++++0]
  --nc <>     色ぷよの数．                [default: 24]
  --ng <>     お邪魔ぷよの数．            [default: 2]
  --tt <>     3連結の数．                 [default: 4]
  --tv <>     縦3連結の数．               [default: 0]
  --th <>     横3連結の数．
  --tl <>     L字3連結の数．
  -s <>       シード．

  -f <>...    何手目を固定するか．
  -S          ハチイチを同一視するか．    [default: true]

  --fk <>...  検索したいクリア条件．
  --fm <>...  検索したい手数．
  --fs        検索対象に飽和問題を含める．
  --fS        検索対象に不飽和問題を含める．

非自明なオプションの指定方法は以下の通り．

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
    [0]  全てのぷよ
    [1]  色ぷよのうちランダムに1色
    [2]  お邪魔ぷよ
    [3]  色ぷよ

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
    elif args["database"] or args["d"]:
      args.runDb
    else:
      args.runGui
