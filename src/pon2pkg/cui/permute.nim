## This module implements a CUI permuter.
##

import browsers
import options
import sequtils
import sets
import strformat
import tables

import docopt
import puyo_core

import ./util
import ../core/permute

proc permute*(args: Table[string, Value]) {.inline.} =
  ## Runs a CUI permuter.
  let url = $args["<url>"]

  var idx = 1
  for res in url.permute(
    args["-f"].mapIt(it.parseNatural.Positive).toHashSet,
    not args["-D"].to_bool,
    args["-d"].to_bool,
    not args["-S"].to_bool,
    if args["-i"].to_bool: IPS else: ISHIKAWAPUYO,
  ):
    if res.isNone:
      echo "正しくない形式のURLが入力されました．"
      quit()

    echo &"(Q{idx}) {res.get.problem}"
    echo &"(A{idx}) {res.get.solution}"
    echo ""

    if args["-B"].to_bool:
      res.get.problem.openDefaultBrowser
    if args["-b"].to_bool:
      res.get.solution.openDefaultBrowser

    idx.inc
