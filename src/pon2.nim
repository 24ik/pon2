## The :code:`pon2` module provides a standalone application and some APIs relating to Nazo Puyo.
## The main features are as follows:
## * Solver
## * Permuter
## * Database
##
## With :code:`import pon2`, you can access all APIs provides by this module.
## Documentations for all features are as follows:
## * `Permute <./pon2pkg/core/permute.html>`_
## * `Solve <./pon2pkg/core/solve.html>`_
## * `Database <./pon2pkg/core/db.html>`_
##
## This module uses multiple threads by default.
## To have only one thread used, specify :code:`-d:singleThread` to the compile options.
##

const Document = """
なぞぷよツール．ソルバー・ツモ並べ替え・データベース機能が提供されている．

Usage:
  pon2 (solve | s) <url> [-hibB]
  pon2 (permute | p) <url> [(-f <>)... -hibBdDS]
  pon2 (database | d) (add | a) <urls>... [-h]
  pon2 (database | d) (remove | r) <urls>... [-h]
  pon2 (database | d) (find | f) [(--fk <>)... (--fm <>)... --fs --fS -h]
  pon2 [-h]

Options:
  -h        このヘルプ画面を表示する．
  -i        IPS形式のURLで出力する．
  -b        解をブラウザで開く．
  -B        問題をブラウザで開く．

  -d        最終手のゾロを許可．
  -D        ゾロを許可．                [default: true]

  -f <>...  何手目を固定するか．
  -S        ハチイチを同一視するか．    [default: true]

  --fk <>...  検索したいクリア条件．
  --fm <>...  検索したい手数．
  --fs        検索対象に飽和問題を含める．
  --fS        検索対象に不飽和問題を含める．

非自明なオプションの指定方法は以下の通り．

  クリア条件（--fk）：以下の表を参照して整数値を入力する．
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
"""

when not defined(js):
  import ./pon2pkg/core/db
  export db.connectDb, db.insert, db.delete, db.search

import ./pon2pkg/core/permute
export permute.permute

import ./pon2pkg/core/solve
export solve.Solution, solve.Solutions, solve.InspectSolutions, solve.`$`, solve.solve, solve.inspectSolve

when isMainModule:
  when defined(js):
    import ./pon2pkg/web/main as webMain

    makeWebPage()
  else:
    import docopt

    import ./pon2pkg/cui/db as cuiDb
    import ./pon2pkg/cui/permute as cuiPermute
    import ./pon2pkg/cui/solve as cuiSolve

    let args = Document.docopt
    if args["-h"]:
      echo Document
    elif args["solve"] or args["s"]:
      args.solve
    elif args["permute"] or args["p"]:
      args.permute
    elif args["database"] or args["d"]:
      args.operateDb
    else:
      echo Document
