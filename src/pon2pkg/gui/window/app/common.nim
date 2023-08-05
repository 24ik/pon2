## This module implements common functions.
##

import math

# ------------------------------------------------
# Unit conversion
# ------------------------------------------------

const Dpi = when defined windows: 144 else: 120 # TODO: better implementation

func pt*(px: int): float {.inline.} =
  ## Converts `px` to pt.
  px / Dpi * 72

func px*(pt: float): int {.inline.} =
  ## Converts `pt` to px.
  (pt / 72 * Dpi).round.int
