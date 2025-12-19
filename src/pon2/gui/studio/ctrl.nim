## This module implements studio controller views.
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
  import ./[setting]
  import ../[helper]
  import ../../[app]
  import ../../private/[dom, gui]

  {.push warning[UnusedImport]: off.}
  import karax/[kbase]
  {.pop.}

  export vdom

  const CheckIntervalMs = 1000

  func initCheckHandler(self: ref Studio, interval: Interval): () -> void =
    ## Returns a handler to check the progress and redraw.
    () => (
      block:
        if self[].progress.now > 0 and self[].progress.now == self[].progress.total:
          interval.clearInterval
        safeRedraw()
    )

  proc runSolve(self: ref Studio) =
    ## Solves the nazo puyo.
    ## This function requires that the field is settled.
    self.asyncSolve

    var interval: Interval
    {.push warning[Uninit]: off.}
    interval = setInterval(self.initCheckHandler interval, CheckIntervalMs)
    {.pop.}

  proc runPermute(self: ref Studio, helper: VNodeHelper) =
    ## Permutes the nazo puyo.
    ## This function requires that the field is settled.
    let settings = helper.getStudioSetting
    self.asyncPermute settings.fixIndices, settings.allowDoubleIndices

    var interval: Interval
    {.push warning[Uninit]: off.}
    interval = setInterval(self.initCheckHandler interval, CheckIntervalMs)
    {.pop.}

  proc toStudioCtrlVNode*(self: ref Studio, helper: VNodeHelper): VNode =
    ## Returns the studio controller node.
    let workDisabled =
      self[].simulator.nazoPuyo.goal == NoneGoal or
      self[].simulator.nazoPuyo.puyoPuyo.steps.len == 0

    buildHtml tdiv:
      if not helper.mobile:
        tdiv(class = "block"):
          tdiv(class = "field is-grouped"):
            tdiv(class = "control"):
              button(
                class =
                  (if self[].focusReplay: "button is-primary" else: "button").kstring,
                onclick = () => self[].toggleFocus,
              ):
                text "解答を操作"
                span(style = counterStyle):
                  text "Sft+Tab"
      tdiv(class = "block"):
        tdiv(class = "field is-grouped"):
          tdiv(class = "control"):
            button(
              class = (
                if self[].solving: "button is-loading"
                elif self[].working: "button is-static"
                else: "button"
              ).kstring,
              disabled = workDisabled,
              onclick = () => self.runSolve,
            ):
              text "解探索"
          tdiv(class = "control"):
            button(
              class = (
                if self[].permuting: "button is-loading"
                elif self[].working: "button is-static"
                else: "button"
              ).kstring,
              disabled = workDisabled,
              onclick = () => self.runPermute helper,
            ):
              text "ツモ並べ替え"
          tdiv(class = "control"):
            button(
              class = "button",
              disabled = not self[].working,
              onclick = () => self.stopWork,
            ):
              span(class = "icon"):
                italic(class = "fa-solid fa-power-off")
              span:
                text "停止"
      tdiv(class = "block"):
        progress(
          class = "progress is-primary",
          value = ($self[].progress.now).kstring,
          max = ($self[].progress.total).kstring,
        ):
          discard
