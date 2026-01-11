## This module implements grimoire match views.
##

{.push raises: [].}
{.experimental: "strictDefs".}
{.experimental: "strictFuncs".}
{.experimental: "views".}

# ------------------------------------------------
# JS backend
# ------------------------------------------------

when defined(js) or defined(nimsuggest):
  import std/[sugar]
  import karax/[karax, karaxdsl, vdom]
  import ../[helper]
  import ../../[app]
  import ../../private/[dom, strutils]
  import ../../private/gui/[hash]

  {.push warning[UnusedImport]: off.}
  import karax/[kbase]
  {.pop.}

  export vdom

  const InputMaxLen = 16

  func toSolvedId(helper: VNodeHelper): kstring =
    ## Returns the ID of the solve status.
    "pon2-grimoire-search-solved-" & helper.grimoireOpt.unsafeValue.searchId

  func toRuleId(helper: VNodeHelper): kstring =
    ## Returns the ID of the rule.
    "pon2-grimoire-search-rule-" & helper.grimoireOpt.unsafeValue.searchId

  func toMoveCountId(helper: VNodeHelper): kstring =
    ## Returns the ID of the move count.
    "pon2-grimoire-search-movecount-" & helper.grimoireOpt.unsafeValue.searchId

  func toKindId(helper: VNodeHelper): kstring =
    ## Returns the ID of the goal kind.
    "pon2-grimoire-search-kind-" & helper.grimoireOpt.unsafeValue.searchId

  func toClearColorId(helper: VNodeHelper): kstring =
    ## Returns the ID of the goal clear color.
    "pon2-grimoire-search-clearcolor-" & helper.grimoireOpt.unsafeValue.searchId

  func toTitleId(helper: VNodeHelper): kstring =
    ## Returns the ID of the title.
    "pon2-grimoire-search-title-" & helper.grimoireOpt.unsafeValue.searchId

  func toCreatorId(helper: VNodeHelper): kstring =
    ## Returns the ID of the creator.
    "pon2-grimoire-search-creator-" & helper.grimoireOpt.unsafeValue.searchId

  func toSourceId(helper: VNodeHelper): kstring =
    ## Returns the ID of the source.
    "pon2-grimoire-search-source-" & helper.grimoireOpt.unsafeValue.searchId

  func toSourceDatalistId(helper: VNodeHelper): kstring =
    ## Returns the ID of the source datalist.
    "pon2-grimoire-search-source-datalist-" & helper.grimoireOpt.unsafeValue.searchId

  proc toGrimoireMatchVNode*(self: ref Grimoire, helper: VNodeHelper): VNode =
    ## Returns the grimoire match node.
    let
      solvedId = helper.toSolvedId
      ruleId = helper.toRuleId
      moveCountId = helper.toMoveCountId
      kindId = helper.toKindId
      clearColorId = helper.toClearColorId
      titleId = helper.toTitleId
      creatorId = helper.toCreatorId
      sourceId = helper.toSourceId
      sourceDatalistId = helper.toSourceDatalistId

    buildHtml tdiv:
      tdiv(class = "field is-grouped"):
        label(`for` = solvedId):
          bold:
            text "クリア状況"
        tdiv(class = "select"):
          select(
            id = solvedId,
            disabled = not self[].isReady,
            onchange =
              () => (
                block:
                  let
                    index = solvedId.getSelectedIndex
                    solvedOpt =
                      if index == 0:
                        Opt[bool].err
                      else:
                        Opt[bool].ok (index - 1).bool
                  solvedOpt.updateGrimoireHashWithSolved
                  0.updateGrimoireHashWithPageIndex
              ),
          ):
            option(selected = helper.grimoireOpt.unsafeValue.matchSolvedOpt.isErr):
              text "全て"
            option(
              selected =
                helper.grimoireOpt.unsafeValue.matchSolvedOpt == Opt[bool].ok false
            ):
              text "未クリア"
            option(
              selected =
                helper.grimoireOpt.unsafeValue.matchSolvedOpt == Opt[bool].ok true
            ):
              text "クリア済"
      tdiv(class = "field is-grouped"):
        label(`for` = moveCountId):
          bold:
            text "ルール"
        tdiv(class = "select"):
          select(
            id = ruleId,
            disabled = not self[].isReady,
            onchange =
              () => (
                block:
                  let
                    index = ruleId.getSelectedIndex
                    ruleOpt =
                      if index == 0: Opt[Rule].err
                      else: Opt[Rule].ok (index - 1).Rule
                  ruleOpt.updateGrimoireHashWithRule
                  0.updateGrimoireHashWithPageIndex
              ),
          ):
            option(selected = helper.grimoireOpt.unsafeValue.matcher.ruleOpt.isErr):
              text "全て"
            for rule in Rule:
              option(
                selected =
                  helper.grimoireOpt.unsafeValue.matcher.ruleOpt == Opt[Rule].ok rule
              ):
                text ($rule).kstring
      tdiv(class = "field is-grouped"):
        label(`for` = moveCountId):
          bold:
            text "手数"
        tdiv(class = "select"):
          select(
            id = moveCountId,
            disabled = not self[].isReady,
            onchange =
              () => (
                block:
                  let
                    index = moveCountId.getSelectedIndex
                    moveCountOpt =
                      if index == 0: Opt[int].err
                      else: Opt[int].ok self[].moveCounts[index - 1]
                  moveCountOpt.updateGrimoireHashWithMoveCount
                  0.updateGrimoireHashWithPageIndex
              ),
          ):
            option(selected = helper.grimoireOpt.unsafeValue.matcher.moveCountOpt.isErr):
              text "全て"
            for moveCount in self[].moveCounts:
              option(
                selected =
                  helper.grimoireOpt.unsafeValue.matcher.moveCountOpt ==
                  Opt[int].ok moveCount
              ):
                text ($moveCount).kstring
      tdiv(class = "field is-grouped"):
        label(`for` = kindId):
          bold:
            text "クリア条件"
        tdiv(class = "select"):
          select(
            id = kindId,
            disabled = not self[].isReady,
            onchange =
              () => (
                block:
                  let
                    index = kindId.getSelectedIndex
                    kindOptOpt =
                      case index
                      of 0:
                        Opt[Opt[GoalKind]].err
                      of 1:
                        Opt[Opt[GoalKind]].ok Opt[GoalKind].err
                      else:
                        Opt[Opt[GoalKind]].ok Opt[GoalKind].ok (index - 2).GoalKind
                  kindOptOpt.updateGrimoireHashWithKind
                  0.updateGrimoireHashWithPageIndex
              ),
          ):
            option(selected = helper.grimoireOpt.unsafeValue.matcher.kindOptOpt.isErr):
              text "全て"
            option(
              selected =
                helper.grimoireOpt.unsafeValue.matcher.kindOptOpt ==
                Opt[Opt[GoalKind]].ok Opt[GoalKind].err
            ):
              text "メイン条件なし"
            for kind in GoalKind:
              option(
                selected =
                  helper.grimoireOpt.unsafeValue.matcher.kindOptOpt ==
                  Opt[Opt[GoalKind]].ok Opt[GoalKind].ok kind
              ):
                text ($kind).kstring
      tdiv(class = "field is-grouped"):
        label(`for` = clearColorId):
          bold:
            text "全消し条件"
        tdiv(class = "select"):
          select(
            id = clearColorId,
            disabled = not self[].isReady,
            onchange =
              () => (
                block:
                  let
                    index = clearColorId.getSelectedIndex
                    hasClearColorOpt =
                      if index == 0:
                        Opt[bool].err
                      else:
                        Opt[bool].ok (index - 1).bool
                  hasClearColorOpt.updateGrimoireHashWithClearColor
                  0.updateGrimoireHashWithPageIndex
              ),
          ):
            option(
              selected = helper.grimoireOpt.unsafeValue.matcher.hasClearColorOpt.isErr
            ):
              text "全て"
            option(
              selected =
                helper.grimoireOpt.unsafeValue.matcher.hasClearColorOpt ==
                Opt[bool].ok false
            ):
              text "なし"
            option(
              selected =
                helper.grimoireOpt.unsafeValue.matcher.hasClearColorOpt ==
                Opt[bool].ok true
            ):
              text "あり"
      tdiv(class = "field is-grouped"):
        label(`for` = titleId):
          bold:
            text "タイトル"
        input(
          id = titleId,
          class = "input",
          `type` = "text",
          maxlength = ($InputMaxLen).kstring,
          value = helper.grimoireOpt.unsafeValue.matcher.titleOpt
            .value("")
            .substr(0, InputMaxLen - 1).kstring,
          disabled = not self[].isReady,
          oninput =
            () => (
              block:
                let
                  title = ($titleId.getVNodeById.getInputText).strip
                  titleOpt =
                    if title == "":
                      Opt[string].err
                    else:
                      Opt[string].ok title
                titleOpt.updateGrimoireHashWithTitle
                0.updateGrimoireHashWithPageIndex
            ),
        )
      tdiv(class = "field is-grouped"):
        label(`for` = creatorId):
          bold:
            text "作問者"
        input(
          id = creatorId,
          class = "input",
          `type` = "text",
          maxlength = ($InputMaxLen).kstring,
          disabled = not self[].isReady,
          value = helper.grimoireOpt.unsafeValue.matcher.creatorOpt
            .value("")
            .substr(0, InputMaxLen - 1).kstring,
          oninput =
            () => (
              block:
                let
                  creator = ($creatorId.getVNodeById.getInputText).strip
                  creatorOpt =
                    if creator == "":
                      Opt[string].err
                    else:
                      Opt[string].ok creator
                creatorOpt.updateGrimoireHashWithCreator
                0.updateGrimoireHashWithPageIndex
            ),
        )
      tdiv(class = "field is-grouped"):
        label(`for` = sourceId):
          bold:
            text "出典"
        input(
          id = sourceId,
          list = sourceDatalistId,
          class = "input",
          `type` = "text",
          maxlength = ($InputMaxLen).kstring,
          value = helper.grimoireOpt.unsafeValue.matcher.sourceOpt
            .value("")
            .substr(0, InputMaxLen - 1).kstring,
          disabled = not self[].isReady,
          oninput =
            () => (
              block:
                let
                  source = ($sourceId.getVNodeById.getInputText).strip
                  sourceOpt =
                    if source == "":
                      Opt[string].err
                    else:
                      Opt[string].ok source
                sourceOpt.updateGrimoireHashWithSource
                0.updateGrimoireHashWithPageIndex
            ),
        )
      datalist(id = sourceDatalistId):
        for source in self[].sources:
          option(value = source.kstring)
