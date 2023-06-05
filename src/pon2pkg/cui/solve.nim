## This module implements the solver CUI.
##

import browsers
import options
import strformat
import tables

import docopt
import puyo_core

import ../core/solve

# ------------------------------------------------
# Entry Point
# ------------------------------------------------

proc solve*(args: Table[string, Value]) {.inline.} =
  ## Runs the solver CUI.
  let
    url = $args["<url>"]
    solutions = url.solve(if args["-i"].to_bool: IPS else: ISHIKAWAPUYO)
  if solutions.isNone:
    echo "正しくない形式のURLが入力されました．"
    return

  if args["-B"].to_bool:
    url.openDefaultBrowser

  for i, sol in solutions.get:
    echo &"({i.succ}) {sol}"

    if args["-b"].to_bool:
      sol.openDefaultBrowser
