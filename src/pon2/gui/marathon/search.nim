## This module implements marathon search views.
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

  export vdom

  proc toMarathonSearchVNode*(self: ref Marathon, helper: VNodeHelper): VNode =
    ## Returns the marathon search bar node.
    let rate =
      if self[].isReady:
        self[].matchQueryCount / self[].allQueryCount
      else:
        0.0

    buildHtml tdiv(class = "field is-horizontal"):
      tdiv(class = "field has-addons"):
        tdiv(class = "control"):
          input(
            id = helper.marathonOpt.unsafeValue.searchBarId,
            class = "input",
            `type` = "text",
            placeholder = "例：rgrb もしくは abac",
            maxlength = "16",
            oninput =
              () =>
              self[].match $helper.marathonOpt.unsafeValue.searchBarId.getVNodeById.getInputText,
            disabled = not self[].isReady,
          )
        tdiv(class = "control"):
          a(class = "button is-static"):
            text "{rate*100:.1f}%".fmt.cstring
