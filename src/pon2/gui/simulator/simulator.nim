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
  import ../../[app]
  import ../../private/[gui]

  proc toSimulatorVNode*[S: Simulator or Studio](
      self: ref S, helper: VNodeHelper
  ): VNode {.inline.} =
    ## Returns the simulator node.
    let wideCtrl =
      self.derefSimulator(helper).mode == Replay or
      (self.derefSimulator(helper).mode in PlayModes and helper.mobile)

    buildHtml tdiv:
      if self.derefSimulator(helper).nazoPuyoWrap.optGoal.isOk:
        tdiv(class = (if helper.mobile: "block mb-2" else: "block").cstring):
          self.toGoalVNode helper
      tdiv(class = "block"):
        tdiv(
          class = "columns is-mobile is-1", style = style(StyleAttr.overflowX, "auto")
        ):
          tdiv(class = "column is-narrow"):
            if self.derefSimulator(helper).mode notin EditModes:
              tdiv(class = "block"):
                self.toOperatingVNode helper
            tdiv(class = "block"):
              self.toFieldVNode helper
            tdiv(class = "block"):
              self.toMsgVNode helper
            if self.derefSimulator(helper).mode != Replay:
              tdiv(class = "block"):
                self.toSettingsVNode helper
            tdiv(class = "block"):
              self.toShareVNode helper
          if not helper.mobile and self.derefSimulator(helper).mode in PlayModes:
            tdiv(class = "column is-narrow"):
              self.toNextVNode helper
          tdiv(class = "column is-narrow"):
            if wideCtrl:
              tdiv(class = "block"):
                self.toSideCtrlVNode helper
            tdiv(class = "block"):
              tdiv(class = "columns is-mobile is-1"):
                if wideCtrl:
                  tdiv(class = "column is-narrow"):
                    self.toNextVNode helper
                tdiv(
                  class =
                    "column is-narrow is-flex is-flex-direction-column is-align-items-flex-start"
                ):
                  if self.derefSimulator(helper).mode in EditModes and not helper.mobile:
                    tdiv(class = "block"):
                      self.toPaletteVNode helper
                  if self.derefSimulator(helper).mode == EditorEdit or
                      (self.derefSimulator(helper).mode != Replay and not helper.mobile):
                    tdiv(class = "block"):
                      self.toSideCtrlVNode helper
                  tdiv(class = "block"):
                    self.toStepsVNode helper
      if helper.mobile and self.derefSimulator(helper).mode != Replay:
        tdiv(style = bottomFixStyle):
          tdiv(class = "columns is-mobile is-1"):
            if self.derefSimulator(helper).mode in EditModes:
              tdiv(class = "column is-narrow"):
                self.toPaletteVNode helper
            if self.derefSimulator(helper).mode != EditorEdit:
              tdiv(class = "column is-narrow"):
                self.toBottomCtrlVNode helper
      tdiv(
        id = helper.simulator.cameraReadyId,
        style = style(
          (StyleAttr.display, "none".cstring), (StyleAttr.width, "fit-content".cstring)
        ),
      ):
        if self.derefSimulator(helper).nazoPuyoWrap.optGoal.isOk:
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
