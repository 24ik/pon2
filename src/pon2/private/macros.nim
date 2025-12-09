## This module implements macros.
##

{.push raises: [].}
{.experimental: "strictDefs".}
{.experimental: "strictFuncs".}
{.experimental: "views".}

import std/[macros, strformat, sugar]
import ./[strutils]

export macros

# ------------------------------------------------
# Replace
# ref: https://github.com/status-im/nim-stew/blob/master/stew/staticfor.nim
# ------------------------------------------------
# 
func replaced*(node, before, after: NimNode): NimNode {.inline, noinit.} =
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

func replace*(node: var NimNode, before, after: NimNode) {.inline, noinit.} =
  ## Replaces `before` by `after` in the node.
  node = node.replaced(before, after)

# ------------------------------------------------
# Expand
# ------------------------------------------------

macro defineExpand*(
    macroIdentSuffix: untyped, expandSuffixes: varargs[untyped]
): untyped =
  ## Defines expand macro.
  runnableExamples:
    defineExpand("Example", "Foo", "Bar")
    # This defines the following macro:
    #[
    macro expandExample(identsAndBody: varargs[untyped]): untyped =
      ## Runs in sequence with the body (the last argument) changed to the specified
      ## identifiers (the rest arguments) with the suffix Foo, Bar.
      ## Underscore in the body is replaced by the index of the suffix.
      let
        body = identsAndBody[^1]
        idents = identsAndBody[0 ..^ 2]
        stmts = nnkStmtList.newNimNode body

      var bodyFoo = body.replaced("_".ident, 0.newLit)
      for id in idents:
        bodyFoo.replace id, (id.strVal & "Foo").ident

      add(stmts, bodyFoo)

      var bodyBar = body.replaced("_".ident, 1.newLit)
      for id in idents:
        bodyBar.replace id, (id.strVal & "Bar").ident

      add(stmts, bodyBar)

      stmts
    ]#

    let
      xFoo = 10
      xBar = 20
      yFoo = 100
      yBar = 200

    expandExample x, y:
      assert x == _.succ * 10
      assert y == _.succ * 100

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
    comment =
      "Runs in sequence with the body (the last argument) changed to the specified\nidentifiers (the rest arguments) with the suffix " &
      suffixes.join(", ") &
      ".\nUnderscore in the body is replaced by the index of the suffix."
    macroBody = newStmtList comment.newCommentStmtNode
  macroBody.add quote do:
    let
      `bodyIdent` = `identsAndBodyIdent`[^1]
      `identsIdent` = `identsAndBodyIdent`[0 ..^ 2]
      `stmtsIdent` = nnkStmtList.newNimNode `bodyIdent`
  for suffixIndex, suffix in suffixes:
    let expandedBodyIdent = ("body" & suffix).ident

    macroBody.add quote do:
      var `expandedBodyIdent` = `bodyIdent`.replaced("_".ident, `suffixIndex`.newLit)

    let idIdent = "id".ident
    macroBody.add nnkForStmt.newTree(
      idIdent,
      identsIdent,
      quote do:
        `expandedBodyIdent`.replace `idIdent`, (`idIdent`.strVal & `suffix`).ident
      ,
    )

    macroBody.add "add".newCall(stmtsIdent, expandedBodyIdent)

  macroBody.add stmtsIdent

  nnkMacroDef.newTree(
    ("expand" & macroIdentSuffix.strVal).ident,
    newEmptyNode(),
    newEmptyNode(),
    formalParams,
    newEmptyNode(),
    newEmptyNode(),
    macroBody,
  )
