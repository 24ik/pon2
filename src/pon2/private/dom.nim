## This module implements DOM operations.
##

{.push raises: [].}
{.experimental: "strictDefs".}
{.experimental: "strictFuncs".}
{.experimental: "views".}

import std/[dom, jsffi]

export dom, jsffi

proc getSelectedIndex*(
  selectId: cstring
): int {.inline, noinit, importjs: "document.getElementById(#).selectedIndex".}
  ## Returns the selected index.

proc getNavigator*(): JsObject {.inline, noinit, importjs: "(navigator)".}
  ## Returns the navigator.

proc getClipboard*(): JsObject {.inline, noinit.} =
  ## Returns the clipboard.
  getNavigator().clipboard

proc getElemJsObjById*(
  id: cstring
): JsObject {.inline, noinit, importjs: "document.getElementById(#)".}
  ## Returns the element.

proc createElemJsObj*(
  id: cstring
): JsObject {.inline, noinit, importjs: "document.createElement(#)".}
  ## Creates an element and returns it.
