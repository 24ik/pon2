## This module implements common stuff.
##

import logging
import options
import strutils

import docopt
import nazopuyo_core
import puyo_core

import ../core/generate

let logger = newConsoleLogger(lvlNotice, verboseFmtStr)

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
      logger.log lvlError, "必須の数値入力が省略されています．"
      quit()
  of vkStr:
    try:
      return some ($val).parseInt.Natural
    except ValueError:
      logger.log lvlError, "数値を入力すべき箇所に数値以外が入力されています．"
      quit()
  else:
    doAssert false

proc parseNatural*(val: char or string): Natural {.inline.} =
  ## Converts `val` to the integer.
  ## If the conversion fails, quits the application.
  try:
    return ($val).parseInt
  except ValueError:
    logger.log lvlError, "数値を入力すべき箇所に数値以外が入力されています．"
    quit()

proc parseRequirementKind*(val: Value, allowNone = false): Option[RequirementKind] {.inline.} =
  ## Converts `val` to the requirement kind.
  ## If the conversion fails, quits the application.
  ## If `val` is `vkNone` and `allowNone` is `true`, returns `none`.
  let idx = val.parseNatural allowNone
  if idx.isNone:
    return

  if idx.get notin RequirementKind.low.ord .. RequirementKind.high.ord:
    logger.log lvlError, "クリア条件を表す整数が不適切な値です．"
    quit()

  return some RequirementKind.low.succ idx.get

proc parseRequirementKind*(val: char or string): RequirementKind {.inline.} =
  ## Converts `val` to the requirement kind.
  ## If the conversion fails, quits the application.
  let idx = val.parseNatural
  if idx notin RequirementKind.low.ord .. RequirementKind.high.ord:
    logger.log lvlError, "クリア条件を表す整数が不適切な値です．"
    quit()

  return RequirementKind.low.succ idx

proc parseAbstractRequirementColor*(val: Value, allowNone = false): Option[AbstractRequirementColor] {.inline.} =
  ## Converts `val` to the abstract requirement color.
  ## If the conversion fails, quits the application.
  ## If `val` is `vkNone` and `allowNone` is `true`, returns `none`.
  let idx = val.parseNatural allowNone
  if idx.isNone:
    return

  if idx.get notin AbstractRequirementColor.low.ord .. AbstractRequirementColor.high.ord:
    logger.log lvlError, "クリア条件の色を表す整数が不適切な値です．"
    quit()

  return some AbstractRequirementColor idx.get

proc parseRequirementNumber*(val: Value, allowNone = false): Option[RequirementNumber] {.inline.} =
  ## Converts `val` to the requirement number.
  ## If the conversion fails, quits the application.
  ## If `val` is `vkNone` and `allowNone` is `true`, returns `none`.
  let idx = val.parseNatural allowNone
  if idx.isNone:
    return

  if idx.get notin RequirementNumber.low.ord .. RequirementNumber.high.ord:
    logger.log lvlError, "クリア条件の数字を表す整数が不適切な値です．"
    quit()

  return some RequirementNumber idx.get

proc parseRule*(val: Value, allowNone = false): Option[Rule] {.inline.} =
  ## Converts `val` to the rule.
  ## If the conversion fails, quits the application.
  ## If `val` is `vkNone` and `allowNone` is `true`, returns `none`.
  let idx = val.parseNatural allowNone
  if idx.isNone:
    return

  if idx.get notin Rule.low.ord .. Rule.high.ord:
    logger.log lvlError, "ルールを表す整数が不適切な値です．"
    quit()

  return some Rule idx.get

proc parseRule*(val: char or string): Rule {.inline.} =
  ## Converts `val` to the requirement kind.
  ## If the conversion fails, quits the application.
  let idx = val.parseNatural
  if idx notin Rule.low.ord .. Rule.high.ord:
    logger.log lvlError, "クリア条件を表す整数が不適切な値です．"
    quit()

  return Rule.low.succ idx
