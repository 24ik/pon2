## This module implements helper functions for the web main file.
##

{.experimental: "inferGenericTypes".}
{.experimental: "notnil".}
{.experimental: "strictCaseObjects".}
{.experimental: "strictDefs".}
{.experimental: "strictFuncs".}
{.experimental: "views".}

when defined(pon2.worker):
  import std/[deques, sequtils, strutils]
  import ../[webworker]
  import ../app/[solve]
  import ../app/ide/web/[webworker]
  import ../../app/[nazopuyo, solve]
  import ../../core/[field, fqdn, nazopuyo, pairposition, rule]

  # ------------------------------------------------
  # Web Worker
  # ------------------------------------------------

  proc workerTask*(
      args: seq[string]
  ): tuple[returnCode: WorkerReturnCode, messages: seq[string]] =
    ## Worker's task.
    result = (returnCode: Failure, messages: @["No arguments."])
    if args.len == 0:
      return

    let args2 = args[1 ..^ 1]
    case args[0]
    of $Solve:
      if args2.len == 4:
        let
          moveCount = args2[1].parseInt
          answers =
            case args2[0].parseRule
            of Tsu:
              parseNode[TsuField](args2[3]).solve moveCount
            of Water:
              parseNode[WaterField](args2[3]).solve moveCount

        result.messages = @[$answers.len, args2[2]]
        for answer in answers:
          result.messages.add $answer.len
          for pos in answer:
            result.messages.add $pos

        result.returnCode = Success
      else:
        result.returnCode = Failure
        result.messages = @["Caught invalid number of arguments: " & $args]
    of $Permute:
      if args2.len == 2:
        result.returnCode = Success

        let nazoPuyoWrap: NazoPuyoWrap
        case args2[1].parseRule
        of Tsu:
          nazoPuyoWrap = parseNazoPuyo[TsuField](args2[0], Pon2).initNazoPuyoWrap
        of Water:
          nazoPuyoWrap = parseNazoPuyo[WaterField](args2[0], Pon2).initNazoPuyoWrap

        nazoPuyoWrap.get:
          let answers = wrappedNazoPuyo.solve(earlyStopping = true)
          if answers.len == 1:
            var nazo = wrappedNazoPuyo
            nazo.puyoPuyo.pairsPositions.positions = answers[0]
            result.messages = @[$true, nazo.puyoPuyo.pairsPositions.toUriQuery]
          else:
            result.messages = @[$false]
      else:
        result.returnCode = Failure
        result.messages = @["Caught invalid number of arguments: " & $args]
    else:
      result.returnCode = Failure
      result.messages = @["Caught invalid task: " & args[0]]

else:
  import std/[strformat]
  import karax/[karaxdsl, vdom]
  import ../[misc]

  # ------------------------------------------------
  # Main
  # ------------------------------------------------

  proc newFooterNode(): VNode {.inline.} =
    ## Returns the footer node.
    buildHtml(footer(class = "footer")):
      tdiv(class = "content has-text-centered"):
        text &"Pon!通 Version {Pon2Version}"

  when defined(pon2.marathon):
    import std/[sugar]
    import karax/[karax]
    import ../../app/[marathon]

    # ------------------------------------------------
    # Main - Marathon
    # ------------------------------------------------

    let globalMarathon = newMarathon()
    globalMarathon.asyncLoadData () => (if not kxi.surpressRedraws: kxi.redraw
    )

    proc newMainMarathonNode(marathon: Marathon): VNode {.inline.} =
      ## Returns the main marathon node.
      buildHtml(tdiv):
        marathon.newMarathonNode()
        newFooterNode()

    proc marathonRenderer*(): VNode =
      ## Renderer procedure for the marathon.
      globalMarathon.newMainMarathonNode

  else:
    import std/[uri]
    import karax/[karax]
    import ../../app/[ide]
    import ../../core/[fqdn]

    # ------------------------------------------------
    # Main - IDE
    # ------------------------------------------------

    var
      globalIde = newIde()
      globalIdeIsSet = false
      globalIdeIsInvalid = false

    proc newMainIdeNode(ide: Ide, error: bool): VNode {.inline.} =
      ## Returns the main IDE node.
      buildHtml(tdiv):
        if error:
          text "URL形式エラー"
        else:
          ide.newIdeNode()
          newFooterNode()

    proc setGlobalIde(routerData: RouterData) {.inline.} =
      ## Sets the global IDE.
      ## If the URI is invalid, `none` is set.
      if globalIdeIsSet:
        return

      let query =
        if routerData.queryString == cstring"":
          ""
        else:
          ($routerData.queryString)[1 ..^ 1]

      var uri = initUri()
      uri.scheme = "https"
      uri.hostname = $Pon2
      uri.path = IdeUriPath
      uri.query = query

      try:
        globalIde = uri.parseIde
      except ValueError:
        globalIdeIsInvalid = true
      globalIdeIsSet = true

    proc ideRenderer*(routerData: RouterData): VNode =
      ## Renderer procedure for the IDE.
      routerData.setGlobalIde
      result = globalIde.newMainIdeNode globalIdeIsInvalid
