{.experimental: "strictDefs".}
{.experimental: "strictFuncs".}
{.experimental: "views".}

import std/[unittest]
import results
import ../../src/pon2/core/[cell]

proc main*() =
  # ------------------------------------------------
  # Cell <-> string
  # ------------------------------------------------

  # parseCell
  block:
    for cell in Cell:
      let cellRes = parseCell $cell
      check cellRes.isOk and cellRes.value == cell

    check "".parseCell.isErr
    check "H".parseCell.isErr
