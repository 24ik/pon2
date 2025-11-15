{.push raises: [].}
{.experimental: "strictDefs".}
{.experimental: "strictFuncs".}
{.experimental: "views".}

import std/[unittest]
import ../../src/pon2/core/[cell]

# ------------------------------------------------
# Cell <-> string
# ------------------------------------------------

block: # parseCell
  for cell in Cell:
    let cellRes = parseCell $cell
    check cellRes == StrErrorResult[Cell].ok cell

  check "".parseCell.isErr
  check "H".parseCell.isErr
