## This module implements a CUI solver.
##

import browsers
import options
import strformat
import tables

import docopt
import puyo_core

import ../core/solve

proc solve*(args: Table[string, Value]) {.inline.} =
  ## Runs a CUI solver.
  let
    url = $args["<url>"]
    solutions = url.solve(if args["-i"].to_bool: IPS else: ISHIKAWAPUYO)
  if solutions.isNone:
    echo "正しくない形式のURLが入力されました．"
    quit()

  if args["-B"].to_bool:
    url.openDefaultBrowser

  for i, sol in solutions.get:
    echo &"({i.succ}) {sol}"

    if args["-b"].to_bool:
      sol.openDefaultBrowser
