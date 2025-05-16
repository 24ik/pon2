## This module implements utility functions.
## 

{.push raises: [].}
{.experimental: "strictDefs".}
{.experimental: "strictFuncs".}
{.experimental: "views".}

import ./[assign3]

func toggle*(b: var bool) {.inline.} =
  ## Toggles the bool variable.
  b.assign not b

func incRot*[T: Ordinal](x: var T) {.inline.} =
  ## Increments `x`.
  ## If `x` is `T.high`, assigns `T.low` to `x`.
  if x == T.high:
    x.assign T.low
  else:
    x.inc

func decRot*[T: Ordinal](x: var T) {.inline.} =
  ## Decrements `x`.
  ## If `x` is `T.low`, assigns `T.high` to `x`.
  if x == T.low:
    x.assign T.high
  else:
    x.dec
