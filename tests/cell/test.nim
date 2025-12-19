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
  check ".".parseCell == Pon2Result[Cell].ok None
  check "h".parseCell == Pon2Result[Cell].ok Hard
  check "o".parseCell == Pon2Result[Cell].ok Garbage
  check "r".parseCell == Pon2Result[Cell].ok Red
  check "g".parseCell == Pon2Result[Cell].ok Green
  check "b".parseCell == Pon2Result[Cell].ok Blue
  check "y".parseCell == Pon2Result[Cell].ok Yellow
  check "p".parseCell == Pon2Result[Cell].ok Purple

  check "".parseCell.isErr
  check "O".parseCell.isErr
