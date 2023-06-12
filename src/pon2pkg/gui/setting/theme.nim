## This module implements GUI theme settings.
##

import nigui

type ThemeSetting* = tuple
  ## Theme settings.
  bg: Color
  bgControl: Color
  bgGhost: Color
  bgSelect: Color

# ------------------------------------------------
# Default
# ------------------------------------------------

const DefaultThemeSetting* = (
  bg: rgb(255, 255, 255),
  bgControl: rgb(240, 240, 240),
  bgGhost: rgb(230, 230, 230),
  bgSelect: rgb(205, 205, 205)).ThemeSetting
