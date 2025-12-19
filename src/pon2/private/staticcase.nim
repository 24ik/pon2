## This module implements static case-statement.
##

{.push raises: [].}
{.experimental: "strictDefs".}
{.experimental: "strictFuncs".}
{.experimental: "views".}

import std/[strformat]
import ./[macros]

macro staticCase*(caseStmtOrExpr: typed): untyped =
  ## Converts the `case` statement to compile-time branching.
  ## Each `case` branch opens a new scope.
  runnableExamples:
    type MyEnum = enum
      Foo
      Bar

    const x = Foo
    staticCase:
      case x
      of Foo:
        assert x == Foo
      of Bar:
        assert x == Bar

  let
    caseStmt =
      case caseStmtOrExpr.kind
      of nnkCaseStmt:
        caseStmtOrExpr
      of nnkStmtList:
        if caseStmtOrExpr.len == 1:
          caseStmtOrExpr[0].expectKind nnkCaseStmt
          caseStmtOrExpr[0]
        else:
          error "`caseStmtOrExpr` should have single statement, but got {caseStmtOrExpr.len} statements".fmt,
            caseStmtOrExpr
      else:
        error "`caseStmtOrExpr` should be `nnkCaseStmt` or `nnkStmtList`, but got {caseStmtOrExpr.kind}".fmt,
          caseStmtOrExpr
    caseExpr = caseStmt[0]

  let whenStmt = nnkWhenStmt.newNimNode
  for caseChild in caseStmt[1 ..^ 1]:
    case caseChild.kind
    of nnkOfBranch:
      let caseBody = caseChild.last.newBlockStmt

      for ofChild in caseChild[0 ..^ 2]:
        let newCond =
          if ofChild.kind == nnkRange:
            # NOTE: `a..b` is evaluated as `range` instead of `slice`,
            # so we cannot use `contains`.
            infix(
              infix(ofChild[0], "<=", caseExpr),
              "and",
              infix(caseExpr, "<=", ofChild[1]),
            )
          else:
            # NOTE: `set`, `array`, and `seq` are expanded, so we can handle them here.
            infix(caseExpr, "==", ofChild)

        whenStmt.add nnkElifBranch.newTree(newCond, caseBody)
    of nnkElifBranch, nnkElse:
      let newChild = caseChild.kind.newNimNode
      for caseChildChild in caseChild[0 ..^ 2]:
        newChild.add caseChildChild
      newChild.add caseChild.last.newBlockStmt

      whenStmt.add newChild
    else:
      error "Invalid child of `case` detected: {caseChild.kind}".fmt, caseChild

  whenStmt
