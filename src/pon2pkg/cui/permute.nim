## This module implements the permuter CUI.
##

import browsers
import options
import sequtils
import strformat
import tables

import docopt
import puyo_core

import ./util
import ../core/permute

# ------------------------------------------------
# Entry Point
# ------------------------------------------------

proc runPermuter*(args: Table[string, Value]) {.inline.} =
  ## Runs the permuter CUI.
  let url = $args["<url>"]

  var idx = 1
  for res in url.permute(
    args["-f"].mapIt(it.parseNatural.Positive),
    not args["-D"].to_bool,
    args["-d"].to_bool,
    not args["-S"].to_bool,
    if args["-i"].to_bool: IPS else: ISHIKAWAPUYO,
  ):
    if res.isNone:
      echo "正しくない形式のURLが入力されました．"
      return

    echo &"(Q{idx}) {res.get.problem}"
    echo &"(A{idx}) {res.get.solution}"
    echo ""

    if args["-B"].to_bool:
      res.get.problem.openDefaultBrowser
    if args["-b"].to_bool:
      res.get.solution.openDefaultBrowser

    idx.inc
