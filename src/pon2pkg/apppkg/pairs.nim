## This module implements pairs database.
##

{.experimental: "strictDefs".}
{.experimental: "strictFuncs".}
{.experimental: "views".}

import std/[critbits, os, strutils]

const RawPairsTxt =
  staticRead currentSourcePath().parentDir.parentDir.parentDir.parentDir /
    "assets/pairs/haipuyo.txt"

func initPairsDatabase*: CritBitTree[void] {.inline.} =
  ## Returns a new pairs database.
  RawPairsTxt.splitLines.toCritBitTree

# ------------------------------------------------
# Backend-specific Implementation
# ------------------------------------------------

when defined(js):
  import karax/[karaxdsl, vdom]
  import ../private/app/pairs/web/[searchbar]

  # ------------------------------------------------
  # JS - Node
  # ------------------------------------------------

  proc initPairsDatabaseNode*: VNode {.inline.} =
    ## Returns the node of pairs database.
    buildHtml(tdiv):
      initSearchBarNode()
