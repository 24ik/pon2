## This module implements grimoire match result views.
##

{.push raises: [].}
{.experimental: "strictDefs".}
{.experimental: "strictFuncs".}
{.experimental: "views".}

# ------------------------------------------------
# JS backend
# ------------------------------------------------

when defined(js) or defined(nimsuggest):
  import std/[strformat, sugar]
  import karax/[karax, karaxdsl, vdom]
  import ../[helper]
  import ../../[app]
  import ../../private/[assign, gui, math, strutils]

  {.push warning[UnusedImport]: off.}
  import karax/[kbase]
  {.pop.}

  export vdom

  const EntryCountInPage = 5

  proc toPaginationVNode(
      self: ref Grimoire, helper: VNodeHelper, pageCount, clampedPageIndex: int
  ): VNode =
    ## Returns the pagination node.
    let pageNum =
      if pageCount == 0:
        0
      else:
        clampedPageIndex + 1

    buildHtml tdiv(class = "field is-grouped is-grouped-centered"):
      tdiv(class = "control"):
        button(
          class = "button",
          disabled = clampedPageIndex <= 0,
          onclick = () => 0.updateGrimoireHashWithPageIndex,
        ):
          span(class = "icon"):
            italic(class = "fa-solid fa-backward-fast")
      tdiv(class = "control"):
        button(
          class = "button",
          disabled = clampedPageIndex <= 0,
          onclick = () => (clampedPageIndex - 1).updateGrimoireHashWithPageIndex,
        ):
          span(class = "icon"):
            italic(class = "fa-solid fa-backward-step")
      tdiv(class = "control"):
        button(class = "button is-static is-primary"):
          text "{pageNum} / {pageCount}".fmt.kstring
      tdiv(class = "control"):
        button(
          class = "button",
          disabled = clampedPageIndex >= pageCount - 1,
          onclick =
            () => ((clampedPageIndex + 1).updateGrimoireHashWithPageIndex; safeRedraw()),
        ):
          span(class = "icon"):
            italic(class = "fa-solid fa-forward-step")
      tdiv(class = "control"):
        button(
          class = "button",
          disabled = clampedPageIndex >= pageCount - 1,
          onclick = () => (pageCount - 1).updateGrimoireHashWithPageIndex,
        ):
          span(class = "icon"):
            italic(class = "fa-solid fa-forward-fast")

  func initPlayHandler(
      self: ref Grimoire, entry: GrimoireEntry, entryIndex: int16
  ): () -> void =
    ## Returns the click handler of the play button.
    () => (
      block:
        self[].simulator.assign Simulator.init entry.query.parseNazoPuyo(Pon2).unsafeValue
        GrimoireLocalStorage.selectedEntryIndex = entryIndex
    )

  proc toGrimoireTableVNode(
      self: ref Grimoire, helper: VNodeHelper, clampedPageIndex: int
  ): VNode =
    ## Returns the grimoire table node.
    let
      beginIndex = EntryCountInPage * clampedPageIndex
      endIndex = min(
        EntryCountInPage * (clampedPageIndex + 1),
        helper.grimoireOpt.unsafeValue.matchedEntryIndices.len,
      )

    buildHtml tdiv(class = "table-container"):
      table(class = "table is-striped is-hoverable has-text-centered"):
        thead:
          tr:
            th:
              discard
            th(class = "has-text-centered"):
              text "済"
            th(class = "has-text-centered"):
              text "No."
            th(class = "has-text-centered"):
              text "タイトル"
            th(class = "has-text-centered"):
              text "ルール"
            th(class = "has-text-centered"):
              text "手数"
            th(class = "has-text-centered"):
              text "クリア条件"
            th(class = "has-text-centered"):
              text "作問者"
            th(class = "has-text-centered"):
              text "出典"
        tbody:
          for index in beginIndex ..< endIndex:
            let
              entryIndex = helper.grimoireOpt.unsafeValue.matchedEntryIndices[index]
              entry = self[][entryIndex]
              goalDescs = ($entry.goal).split '&'

            tr:
              td:
                button(
                  class = "button", onclick = self.initPlayHandler(entry, entryIndex)
                ):
                  span(class = "icon"):
                    italic(class = "fa-solid fa-gamepad")
              td:
                if entryIndex in helper.grimoireOpt.unsafeValue.solvedEntryIndices:
                  span(class = "icon"):
                    italic(class = "fa-solid fa-circle-check")
              td:
                text ($(index + 1)).kstring
              td:
                text entry.title.kstring
              td:
                text ($entry.rule).kstring
              td:
                text ($entry.moveCount).kstring
              td:
                text goalDescs[0].kstring
                for i in 1 ..< goalDescs.len:
                  br:
                    discard
                  text ('&' & goalDescs[i]).kstring
              td:
                for creatorIndex in 0 ..< entry.creators.len - 1:
                  text entry.creators[creatorIndex].kstring
                  br:
                    discard
                if entry.creators.len > 0:
                  text entry.creators[^1].kstring
              td:
                text entry.source.kstring
                if entry.sourceDetail.len > 0:
                  br:
                    discard
                  text entry.sourceDetail.kstring

  proc toGrimoireMatchResultVNode*(self: ref Grimoire, helper: VNodeHelper): VNode =
    ## Returns the grimoire match result node.
    let
      pageCount =
        helper.grimoireOpt.unsafeValue.matchedEntryIndices.len.ceilDiv EntryCountInPage
      clampedPageIndex =
        helper.grimoireOpt.unsafeValue.pageIndex.clamp(0, max(pageCount - 1, 0))

    buildHtml tdiv:
      tdiv(class = "block"):
        self.toPaginationVNode(helper, pageCount, clampedPageIndex)
      tdiv(class = "block"):
        self.toGrimoireTableVNode(helper, clampedPageIndex)
      tdiv(class = "block"):
        self.toPaginationVNode(helper, pageCount, clampedPageIndex)
