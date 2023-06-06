## This module implements common functions.
##

import math

# ------------------------------------------------
# Unit conversion
# ------------------------------------------------

func pt*(px: int): float {.inline.} =
  ## Converts :code:`px` to pt.
  px * 2 / 3

func px*(pt: float): int {.inline.} =
  ## Converts :code:`pt` to px.
  (pt * 3 / 2).round.int