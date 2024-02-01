## This module implements auxiliary things for the web main file.
##

{.experimental: "strictDefs".}
{.experimental: "strictFuncs".}
{.experimental: "views".}

import std/[options, sequtils, strformat, strutils, sugar, uri]
import karax/[karax, karaxdsl, vdom]
import ../[misc, webworker]
import ../app/editorpermuter/web/editor/[webworker]
import ../nazopuyo/[node]
import ../../apppkg/[editorpermuter, marathon, simulator]
import ../../corepkg/[environment, field, misc, pair, position]
import ../../nazopuyopkg/[nazopuyo, permute, solve]

# ------------------------------------------------
# Web - Worker
# ------------------------------------------------

proc workerTask*(args: seq[string]): tuple[returnCode: WorkerReturnCode,
                                           messages: seq[string]] =
  ## Worker's task.
  # NOTE: cannot inline due to the type of `assignWebWorker` argument
  if args.len == 0:
    result.returnCode = Failure
    result.messages = @["No arguments."]
    return

  let args2 = args[1..^1]
  case args[0]
  of $Solve:
    if args2.len == 2:
      result.messages = case args2[0].parseRule
      of Tsu:
        args2[1].parseNode[:TsuField].solve.mapIt it.toUriQuery Izumiya
      of Water:
        args2[1].parseNode[:WaterField].solve.mapIt it.toUriQuery Izumiya

      result.returnCode = Success
    else:
      result.returnCode = Failure
      result.messages = @["Caught invalid number of arguments: " & $args]
  of $Permute:
    if args2.len >= 3:
      let fixMoves =
        if args2.len == 3: newSeq[Positive](0)
        else: args2[3..^1].mapIt it.parseSomeInt[:Positive]

      result.returnCode = Success
      args2[0].parseUri.parseNazoPuyos.nazoPuyos.flattenAnd:
        let permuteRes = collect:
          for (pairs, answer) in nazoPuyo.permute(
              fixMoves, args2[1].parseBool, args2[2].parseBool):
            @[pairs.toUriQuery Izumiya, answer.toUriQuery Izumiya]
        result.messages = permuteRes.concat
    else:
      result.returnCode = Failure
      result.messages = @["Caught invalid number of arguments: " & $args]
  else:
    result.returnCode = Failure
    result.messages = @["Caught invalid task: " & args[0]]

# ------------------------------------------------
# Web - Main
# ------------------------------------------------

proc initFooterNode: VNode {.inline.} =
  ## Returns the footer node.
  buildHtml(footer(class = "footer")):
    tdiv(class = "content has-text-centered"):
      text &"Pon!通 Version {Version}"

proc initMainEditorPermuterNode*(
    routerData: RouterData, pageInitialized: var bool,
    editorPermuter: var EditorPermuter): VNode {.inline.} =
  ## Returns the main editor&permuter node.
  if pageInitialized:
    return editorPermuter.initEditorPermuterNode

  pageInitialized = true
  let query =
    if routerData.queryString == cstring"": ""
    else: ($routerData.queryString)[1..^1]

  var uri = initUri()
  uri.scheme = "https"
  uri.hostname = $Izumiya
  uri.path = "/pon2/playground/index.html"
  uri.query = query

  try:
    let parseRes = uri.parseNazoPuyos
    parseRes.nazoPuyos.flattenAnd:
      editorPermuter =
        if parseRes.positions.isSome:
          nazoPuyo.initEditorPermuter(parseRes.positions.get, parseRes.mode,
                                      parseRes.editor)
        else:
          nazoPuyo.initEditorPermuter(parseRes.mode, parseRes.editor)
  except ValueError:
    try:
      let parseRes = uri.parseEnvironments
      parseRes.environments.flattenAnd:
        editorPermuter =
          if parseRes.positions.isSome:
            environment.initEditorPermuter(parseRes.positions.get,
                                          parseRes.mode, parseRes.editor)
          else:
            environment.initEditorPermuter(parseRes.mode, parseRes.editor)
    except ValueError:
      return buildHtml(tdiv):
        text "URL形式エラー"

  result = buildHtml(tdiv):
    editorPermuter.initEditorPermuterNode
    initFooterNode()

proc initMainMarathonNode*(marathon: var Marathon): VNode {.inline.} =
  ## Returns the main marathon node.
  buildHtml(tdiv):
    marathon.initMarathonNode
    initFooterNode()
