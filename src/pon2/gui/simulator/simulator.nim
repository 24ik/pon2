## This module implements simulator views.
##

{.push raises: [].}
{.experimental: "strictDefs".}
{.experimental: "strictFuncs".}
{.experimental: "views".}

# ------------------------------------------------
# JS backend
# ------------------------------------------------

when defined(js) or defined(nimsuggest):
  import std/[jsffi]
  import karax/[karaxdsl, vdom, vstyles]
  import ./[ctrl, field, goal, msg, next, operating, palette, setting, share, step]
  import ../[helper]
  import ../../[app]
  import ../../private/[gui]

  {.push warning[UnusedImport]: off.}
  import karax/[kbase]
  {.pop.}

  export vdom

  proc toSimulatorVNode*[S: Simulator or Studio or Marathon](
      self: ref S, helper: VNodeHelper
  ): VNode =
    ## Returns the simulator node.
    let
      mode = self.derefSimulator(helper).mode
      wideCtrl = helper.mobile and mode in PlayModes
      isReplaySimulator =
        helper.studioOpt.isOk and helper.studioOpt.unsafeValue.isReplaySimulator
      showGoal =
        mode == EditEditor or self.derefSimulator(helper).nazoPuyo.goal != NoneGoal

    buildHtml tdiv:
      if showGoal:
        tdiv(class = (if helper.mobile: "block mb-2" else: "block").kstring):
          self.toGoalVNode helper
      tdiv(class = "block"):
        tdiv(
          class = (if helper.mobile: "columns is-mobile is-1" else: "columns is-mobile").kstring,
          style = style(StyleAttr.overflowX, "auto"),
        ):
          tdiv(class = "column is-narrow"):
            if mode notin EditModes:
              tdiv(class = "block"):
                self.toOperatingVNode helper
            tdiv(class = "block"):
              self.toFieldVNode helper
            tdiv(class = "block"):
              self.toMsgVNode helper
            if mode != Replay:
              tdiv(class = "block"):
                self.toSettingsVNode helper
            tdiv(class = "block"):
              self.toShareVNode helper
          if not wideCtrl and mode notin EditModes:
            tdiv(class = "column is-narrow"):
              self.toNextVNode helper
          tdiv(class = "column is-narrow"):
            if wideCtrl:
              tdiv(class = "block"):
                self.toSideCtrlVNode helper
            tdiv(class = "block"):
              tdiv(
                class = (
                  if helper.mobile: "columns is-mobile is-1" else: "columns is-mobile"
                ).kstring
              ):
                if wideCtrl:
                  tdiv(class = "column is-narrow"):
                    self.toNextVNode helper
                tdiv(
                  class =
                    "column is-narrow is-flex is-flex-direction-column is-align-items-flex-start"
                ):
                  if mode in EditModes and not helper.mobile:
                    tdiv(class = "block"):
                      self.toPaletteVNode helper
                  if not helper.mobile or isReplaySimulator or mode == EditEditor:
                    tdiv(class = "block"):
                      self.toSideCtrlVNode helper
                  tdiv(class = "block"):
                    self.toStepsVNode helper
      if helper.mobile and not isReplaySimulator:
        tdiv(style = bottomFixStyle):
          tdiv(class = "columns is-mobile is-1 is-vcentered"):
            if mode in EditModes:
              tdiv(class = "column is-narrow"):
                self.toPaletteVNode helper
            if mode != EditEditor:
              tdiv(class = "column is-narrow"):
                self.toBottomCtrlVNode helper
      tdiv(
        id = helper.simulator.cameraReadyId,
        style = style(
          (StyleAttr.display, "none".kstring), (StyleAttr.width, "fit-content".kstring)
        ),
      ):
        if showGoal:
          tdiv(class = "block"):
            self.toGoalVNode(helper, cameraReady = true)
        tdiv(class = "block"):
          tdiv(class = "columns is-mobile is-1"):
            tdiv(class = "column is-narrow"):
              tdiv(class = "block"):
                self.toFieldVNode(helper, cameraReady = true)
              tdiv(class = "block"):
                self.toMsgVNode helper
            tdiv(class = "column is-narrow"):
              self.toStepsVNode(helper, cameraReady = true)
