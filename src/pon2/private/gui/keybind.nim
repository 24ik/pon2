## This module implements key bind views.
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
  import karax/[karaxdsl, kbase, vdom]
  import ./[localstorage, utils]
  import ../[strutils]
  import ../../[app]

  export vdom

  proc setKeyBindPattern(self: ref Studio, keyBindPattern: SimulatorFqdn) =
    ## Sets the key bind pattern.
    self[].simulator.keyBindPattern = keyBindPattern
    self[].replaySimulator.keyBindPattern = keyBindPattern

    StudioLocalStorage.keyBindPattern = keyBindPattern

  proc setKeyBindPattern[T: Marathon or Grimoire](
      self: ref T, keyBindPattern: SimulatorFqdn
  ) =
    ## Sets the key bind pattern.
    self[].simulator.keyBindPattern = keyBindPattern

    when T is Marathon:
      MarathonLocalStorage.keyBindPattern = keyBindPattern
    else:
      GrimoireLocalStorage.keyBindPattern = keyBindPattern

  proc toKeyBindVNode*[T: Studio or Marathon or Grimoire](self: ref T): VNode =
    ## Returns the key bind node.
    const
      BtnClass = "button".kstring
      SelectBtnClass = "button is-primary is-selected".kstring

    let pon2BtnClass, ipsBtnClass: kstring
    case self[].simulator.keyBindPattern
    of Pon2:
      pon2BtnClass = SelectBtnClass
      ipsBtnClass = BtnClass
    of IshikawaPuyo, Ips:
      pon2BtnClass = BtnClass
      ipsBtnClass = SelectBtnClass

    buildHtml tdiv(class = "field has-addons"):
      tdiv(class = "control"):
        button(class = pon2BtnClass, onclick = () => self.setKeyBindPattern Pon2):
          text "Pon!通"
      tdiv(class = "control"):
        button(class = ipsBtnClass, onclick = () => self.setKeyBindPattern IshikawaPuyo):
          text "IPS"

  proc toKeyBindDescVNode*(keys: openArray[KeyEvent]): VNode =
    ## Returns the node of the key bind description.
    if keys.len == 0:
      return buildHtml tdiv:
        discard

    let
      key = keys[0]
      code =
        if key.code.startsWith "Key":
          key.code.substr 3
        elif key.code.startsWith "Digit":
          key.code.substr 5
        elif key.code == "Semicolon":
          ";"
        else:
          key.code
    var txts = newSeqOfCap[string](5)
    if key.ctrl:
      txts.add "Ctrl"
    if key.alt:
      txts.add "Alt"
    if key.shift:
      txts.add "Shift"
    if key.meta:
      txts.add "Meta"
    txts.add code

    buildHtml span(style = counterStyle):
      text txts.join "+"
