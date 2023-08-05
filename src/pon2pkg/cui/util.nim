## This module implements utility functions.
##

import options
import strutils

import docopt
import nazopuyo_core

# ------------------------------------------------
# Parse
# ------------------------------------------------

proc parseNatural*(val: Value, allowNone = false): Option[Natural] {.inline.} =
  ## Converts `val` to the integer.
  ## If the conversion fails, quits the application.
  ## If `val` is `vkNone` and `allowNone` is `true`, returns `none`.
  case val.kind
  of vkNone:
    if allowNone:
      return none Natural
    else:
      echo "必須の数値入力が省略されています．"
      quit()
  of vkStr:
    try:
      return some ($val).parseInt.Natural
    except ValueError:
      echo "数値を入力すべき箇所に数値以外が入力されています．"
      quit()
  else:
    doAssert false

proc parseNatural*(val: char or string): Natural {.inline.} =
  ## Converts `val` to the integer.
  ## If the conversion fails, quits the application.
  try:
    return ($val).parseInt
  except ValueError:
    echo "数値を入力すべき箇所に数値以外が入力されています．"
    quit()

proc parseRequirementKind*(val: Value, allowNone = false): Option[RequirementKind] {.inline.} =
  ## Converts `val` to the requirement kind.
  ## If the conversion fails, quits the application.
  ## If `val` is `vkNone` and `allowNone` is `true`, returns `none`.
  let idx = val.parseNatural allowNone
  if idx.isNone:
    return

  if idx.get notin RequirementKind.low.ord .. RequirementKind.high.ord:
    echo "クリア条件を表す整数が不適切な値です．"
    quit()

  return some RequirementKind.low.succ idx.get

proc parseRequirementKind*(val: char or string): RequirementKind {.inline.} =
  ## Converts `val` to the requirement kind.
  ## If the conversion fails, quits the application.
  let idx = val.parseNatural
  if idx notin RequirementKind.low.ord .. RequirementKind.high.ord:
    echo "クリア条件を表す整数が不適切な値です．"
    quit()

  return RequirementKind.low.succ idx
