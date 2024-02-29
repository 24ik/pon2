## This module implements helper functions for the web main file.
##

{.experimental: "strictDefs".}
{.experimental: "strictFuncs".}
{.experimental: "views".}

import std/[sequtils, strformat, strutils, uri]
import karax/[karax, karaxdsl, vdom]
import ../[misc, webworker]
import ../app/[solve]
import ../app/gui/web/[webworker]
import ../../app/[gui, marathon, nazopuyo, simulator, solve]
import ../../core/[field, host, nazopuyo, pairposition, puyopuyo, rule]

# ------------------------------------------------
# Web Worker
# ------------------------------------------------

proc workerTask*(
    args: seq[string]
): tuple[returnCode: WorkerReturnCode, messages: seq[string]] =
  ## Worker's task.
  # NOTE: cannot inline due to the type of `assignWebWorker` argument
  if args.len == 0:
    result.returnCode = Failure
    result.messages = @["No arguments."]
    return

  let args2 = args[1 ..^ 1]
  case args[0]
  of $Solve:
    if args2.len == 2:
      result.messages =
        case args2[0].parseRule
        of Tsu:
          parseNode[TsuField](args2[1]).solve.mapIt it.toUriQuery Izumiya
        of Water:
          parseNode[WaterField](args2[1]).solve.mapIt it.toUriQuery Izumiya

      result.returnCode = Success
    else:
      result.returnCode = Failure
      result.messages = @["Caught invalid number of arguments: " & $args]
  of $Permute:
    if args2.len == 3:
      result.returnCode = Success

      let nazoPuyoWrap: NazoPuyoWrap
      case args2[2].parseRule
      of Tsu:
        nazoPuyoWrap = parseNazoPuyo[TsuField](args2[1], Izumiya).initNazoPuyoWrap
      of Water:
        nazoPuyoWrap = parseNazoPuyo[WaterField](args2[1], Izumiya).initNazoPuyoWrap

      nazoPuyoWrap.flattenAnd:
        let answers = nazoPuyo.solve(earlyStopping = true)
        if answers.len == 1:
          result.messages = @[$true, args2[0], answers[0].toUriQuery Izumiya]
        else:
          result.messages = @[$false]
    else:
      result.returnCode = Failure
      result.messages = @["Caught invalid number of arguments: " & $args]
  else:
    result.returnCode = Failure
    result.messages = @["Caught invalid task: " & args[0]]

# ------------------------------------------------
# Main
# ------------------------------------------------

proc initFooterNode(): VNode {.inline.} =
  ## Returns the footer node.
  buildHtml(footer(class = "footer")):
    tdiv(class = "content has-text-centered"):
      text &"Pon!通 Version {Version}"

proc initGuiApplicationNode*(
    routerData: RouterData,
    pageInitialized: var bool,
    guiApplication: var GuiApplication,
): VNode {.inline.} =
  ## Returns the GUI application node.
  if pageInitialized:
    return buildHtml(tdiv):
      guiApplication.initGuiApplicationNode
      initFooterNode()

  pageInitialized = true
  let query =
    if routerData.queryString == cstring"":
      ""
    else:
      ($routerData.queryString)[1 ..^ 1]

  var uri = initUri()
  uri.scheme = "https"
  uri.hostname = $Izumiya
  uri.path = "/pon2/gui/index.html"
  uri.query = query

  try:
    guiApplication = uri.parseSimulator.nazoPuyoWrap.initGuiApplication
  except ValueError:
    return buildHtml(tdiv):
      text "URL形式エラー"

  result = buildHtml(tdiv):
    guiApplication.initGuiApplicationNode
    initFooterNode()

proc initMainMarathonNode*(marathon: var Marathon): VNode {.inline.} =
  ## Returns the main marathon node.
  buildHtml(tdiv):
    marathon.initMarathonNode
    initFooterNode()
