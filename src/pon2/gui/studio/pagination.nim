## This module implements studio pagination views.
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
  import ../../private/[gui]

  proc toStudioPaginationVNode*(
      self: ref Studio, helper: VNodeHelper
  ): VNode {.inline.} =
    ## Returns the studio pagination node.
    let replayNum =
      if self[].replayStepsCnt == 0:
        0
      else:
        self[].replayStepsIdx.succ

    buildHtml nav(class = "pagination"):
      button(class = "button pagination-link", onclick = () => self[].prevReplay):
        span(class = "icon"):
          italic(class = "fa-solid fa-backward-step")
          if not helper.mobile:
            span(style = counterStyle):
              text "A"
      button(class = "button pagination-link is-static"):
        text "{replayNum} / {self[].replayStepsCnt}".fmt
      button(class = "button pagination-link", onclick = () => self[].nextReplay):
        span(class = "icon"):
          italic(class = "fa-solid fa-forward-step")
          if not helper.mobile:
            span(style = counterStyle):
              text "D"
