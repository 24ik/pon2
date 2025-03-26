{.experimental: "strictDefs".}
{.experimental: "strictFuncs".}
{.experimental: "views".}

import std/[unittest]
import ../../src/pon2/core/[cell]
import ../../src/pon2/private/[results2]

proc main*() =
  # ------------------------------------------------
  # Cell <-> string
  # ------------------------------------------------

  # parseCell
  block:
    for cell in Cell:
      let cellRes = parseCell $cell
      check cellRes == Res[Cell].ok cell

    check "".parseCell.isErr
    check "H".parseCell.isErr
