## This module implements helpers of [nim-results](https://github.com/arnetheduck/nim-results).
## 

{.experimental: "strictDefs".}
{.experimental: "strictFuncs".}
{.experimental: "views".}
{.push raises: [].}

import ../private/[macros]
import results

export results

type Pon2Result*[T] = Result[T, string]

template context*[T](self: Pon2Result[T], contextMsg: untyped): Pon2Result[T] =
  ## Returns the result with the context error message added.
  block:
    let selfEval = self
    if selfEval.isOk:
      selfEval
    else:
      Pon2Result[T].err contextMsg & '\n' & selfEval.unsafeError

macro catch*(args: varargs[untyped]): untyped =
  ## Returns `err` if an exception raised.
  runnableExamples:
    let x = catch(ValueError, OSError):
      1 + 2
    assert x.containsValue 3

  if args.len == 0:
    error "引数が必要"

  let
    exceptTypes =
      if args.len == 1:
        @["CatchableError".ident]
      else:
        args[0 ..^ 2]
    body = args[^1]

    bodyType = quote:
      typeof(
        block:
          `body`
      )
    resultType = quote:
      Pon2Result[`bodyType`]

    happyBody = quote:
      when `bodyType` is void:
        `body`
        `resultType`.ok
      else:
        `resultType`.ok `body`
    tryStmt = nnkTryStmt.newTree happyBody

  for exceptType in exceptTypes:
    let
      exIdent = "ex".ident

      asExpr = quote:
        `exceptType` as `exIdent`
      exceptBody = quote:
        `resultType`.err `exIdent`.msg

    tryStmt.add nnkExceptBranch.newTree(asExpr, exceptBody)

  tryStmt
