## This module implements macros.
##

{.push raises: [].}
{.experimental: "strictDefs".}
{.experimental: "strictFuncs".}
{.experimental: "views".}

import std/[macros, strformat, sugar]
import ./[strutils2]

export macros

# ------------------------------------------------
# Replace
# ref: https://github.com/status-im/nim-stew/blob/master/stew/staticfor.nim
# ------------------------------------------------
# 
func replaced*(node, before, after: NimNode): NimNode {.inline.} =
  ## Returns the nim node with `before` replaced by `after`.
  case node.kind
  of nnkIdent, nnkSym:
    if node.eqIdent before: after else: node
  of nnkEmpty, nnkLiterals:
    node
  else:
    let rTree = node.kind.newNimNode node
    for child in node:
      rTree.add child.replaced(before, after)

    rTree

func replace*(node: var NimNode, before, after: NimNode) {.inline.} =
  ## Replaces `before` by `after` in the node.
  node = node.replaced(before, after)

# ------------------------------------------------
# Expand
# ------------------------------------------------

macro defineExpand*(
    macroIdentSuffix: untyped, expandSuffixes: varargs[untyped]
): untyped =
  ## Defines expand macro.
  # identifiers
  let
    identsAndBodyIdent = "identsAndBody".ident
    bodyIdent = "body".ident
    identsIdent = "idents".ident
    stmtsIdent = "stmts".ident

  # macro parameters
  let formalParams = nnkFormalParams.newNimNode
  formalParams.add "untyped".ident
  formalParams.add nnkIdentDefs.newTree(
    identsAndBodyIdent,
    nnkBracketExpr.newTree("varargs".ident, "untyped".ident),
    newEmptyNode(),
  )

  # macro body
  let
    suffixes = collect:
      for suffix in expandSuffixes:
        suffix.strVal
    cmnt =
      """
Runs in sequence with the body (the last argument) changed to the specified
identifiers (the rest arguments) with the suffix """ &
      suffixes.join(", ") &
      ".\nUnderscore in the body is replaced by the index of the suffix."
    macroBody = newStmtList cmnt.newCommentStmtNode
  macroBody.add quote do:
    let
      `bodyIdent` = `identsAndBodyIdent`[^1]
      `identsIdent` = `identsAndBodyIdent`[0 ..^ 2]
      `stmtsIdent` = nnkStmtList.newNimNode `bodyIdent`
  for suffixIdx, suffix in suffixes:
    let expandedBodyIdent = ("body" & suffix).ident

    macroBody.add quote do:
      var `expandedBodyIdent` = `bodyIdent`.replaced("_".ident, `suffixIdx`.newLit)

    let idIdent = "id".ident
    macroBody.add nnkForStmt.newTree(
      idIdent,
      identsIdent,
      quote do:
        `expandedBodyIdent`.replace `idIdent`, (`idIdent`.strVal & `suffix`).ident
      ,
    )

    macroBody.add "add".newCall(stmtsIdent, expandedBodyIdent)

  nnkMacroDef.newTree(
    ("expand" & macroIdentSuffix.strVal).ident,
    newEmptyNode(),
    newEmptyNode(),
    formalParams,
    newEmptyNode(),
    newEmptyNode(),
    macroBody,
  )

# ------------------------------------------------
# Case
# ------------------------------------------------

macro staticCase*(caseStmt: typed): untyped =
  ## Converts the `case` statement to compile-time branching.
  caseStmt.expectKind nnkCaseStmt
  let caseExpr = caseStmt[0]

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
