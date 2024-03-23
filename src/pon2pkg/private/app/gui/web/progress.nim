## This module implements the progress bar.
##

{.experimental: "strictDefs".}
{.experimental: "strictFuncs".}
{.experimental: "views".}

import std/[strformat]
import karax/[karaxdsl, kbase, vdom]
import ../../../../app/[gui]

proc initEditorProgressBarNode*(guiApplication: var GuiApplication): VNode {.inline.} =
  ## Returns the editor progress bar node.
  let
    now = guiApplication.progressBar.now
    total = guiApplication.progressBar.total

  result = buildHtml(
    progress(class = "progress is-primary", value = kstring $now, max = kstring $total)
  ):
    text &"{now} / {total}"
