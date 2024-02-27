## This module implements the progress bar.
##

{.experimental: "strictDefs".}
{.experimental: "strictFuncs".}
{.experimental: "views".}

import std/[strformat]
import karax/[karaxdsl, kbase, vdom]
import ../../../../../apppkg/[editorpermuter]

proc initEditorProgressBarNode*(editorPermuter: var EditorPermuter): VNode
                               {.inline.} =
  ## Returns the editor progress bar node.
  let
    now = editorPermuter.progressBarData.now
    total = editorPermuter.progressBarData.total

  result = buildHtml(progress(class = "progress is-primary",
                              value = kstring $now, max = kstring $total)):
    text &"{now} / {total}"
