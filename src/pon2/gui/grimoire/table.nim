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
  import karax/[karax, karaxdsl, vdom, vstyles]
  import ../[helper]
  import ../../[app]
  import ../../private/[gui, math, strutils]

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
          onclick = () => (clampedPageIndex + 1).updateGrimoireHashWithPageIndex,
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

  func initPlayHandler(self: ref Grimoire, entry: GrimoireEntry): () -> void =
    ## Returns the click handler of the play button.
    () => entry.id.updateGrimoireHashWithEntryId

  proc toGrimoireTableVNode(
      self: ref Grimoire, helper: VNodeHelper, clampedPageIndex: int
  ): VNode =
    ## Returns the grimoire table node.
    let
      beginIndex = EntryCountInPage * clampedPageIndex
      endIndex = min(
        EntryCountInPage * (clampedPageIndex + 1),
        helper.grimoireOpt.unsafeValue.matchedEntryIds.len,
      )

    buildHtml tdiv(class = "table-container"):
      table(
        class = "table is-striped is-hoverable has-text-centered",
        style = style(StyleAttr.whiteSpace, "nowrap"),
      ):
        thead:
          tr:
            th:
              discard
            th(class = "has-text-centered"):
              text "済"
            th(class = "has-text-centered"):
              text "No."
            th(class = "has-text-centered"):
              text "ルール"
            th(class = "has-text-centered"):
              text "手数"
            th(class = "has-text-centered"):
              text "クリア条件"
            th(class = "has-text-centered"):
              text "タイトル"
            th(class = "has-text-centered"):
              text "作問者"
            th(class = "has-text-centered"):
              text "出典"
        tbody:
          for index in beginIndex ..< endIndex:
            let
              entryId = helper.grimoireOpt.unsafeValue.matchedEntryIds[index]
              entry = self[].getEntry(entryId).unsafeValue
              goalDescs = ($entry.goal).split '&'

              rowClass = (
                if helper.grimoireOpt.unsafeValue.entryId == entryId: "is-selected"
                else: ""
              ).kstring

            tr(class = rowClass):
              td:
                button(class = "button", onclick = self.initPlayHandler entry):
                  span(class = "icon"):
                    italic(class = "fa-solid fa-gamepad")
              td:
                if entryId in helper.grimoireOpt.unsafeValue.solvedEntryIds:
                  span(class = "icon"):
                    italic(class = "fa-solid fa-circle-check")
              td:
                text ($entry.id).kstring
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
                text entry.title.kstring
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
    ## If the page index is invalid, updates the hash part of the URI.
    let
      pageCount =
        helper.grimoireOpt.unsafeValue.matchedEntryIds.len.ceilDiv EntryCountInPage
      clampedPageIndex =
        helper.grimoireOpt.unsafeValue.pageIndex.clamp(0, max(pageCount - 1, 0))

    # update hash part
    if self[].isReady and clampedPageIndex != helper.grimoireOpt.unsafeValue.pageIndex:
      clampedPageIndex.updateGrimoireHashWithPageIndex

    buildHtml tdiv:
      tdiv(class = "block"):
        self.toPaginationVNode(helper, pageCount, clampedPageIndex)
      tdiv(class = "block"):
        self.toGrimoireTableVNode(helper, clampedPageIndex)
      tdiv(class = "block"):
        self.toPaginationVNode(helper, pageCount, clampedPageIndex)
