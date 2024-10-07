{.experimental: "inferGenericTypes".}
{.experimental: "notnil".}
{.experimental: "strictCaseObjects".}
{.experimental: "strictDefs".}
{.experimental: "strictFuncs".}
{.experimental: "views".}

import std/[unittest]
import ../../src/pon2/core/[cell]

proc main*() =
  # ------------------------------------------------
  # Cell <-> string
  # ------------------------------------------------

  # parseCell
  block:
    for cell in Cell:
      check ($cell).parseCell == cell

    expect ValueError:
      discard "".parseCell
    expect ValueError:
      discard "H".parseCell
