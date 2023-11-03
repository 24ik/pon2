## This module implements Nazo Puyo.
## With `import pon2pkg/nazopuyo`, you can use all features provided by this
## module.
##
## Submodule Documentations:
## - [NazoPuyo Core](./nazopuyopkg/nazopuyo.html)
## - [Marking](./nazopuyopkg/mark.html)
##

import ./nazopuyopkg/[mark, nazopuyo]

export mark.MarkResult, mark.mark
export nazopuyo.RequirementKind, nazopuyo.RequirementColor,
  nazopuyo.RequirementNumber, nazopuyo.Requirement, nazopuyo.NazoPuyo,
  nazopuyo.NazoPuyos, nazopuyo.NoColorKinds, nazopuyo.NoNumberKinds,
  nazopuyo.ColorKinds, nazopuyo.NumberKinds, nazopuyo.initNazoPuyo,
  nazopuyo.initTsuNazoPuyo, nazopuyo.initWaterNazoPuyo,
  nazopuyo.toTsuNazoPuyo, nazopuyo.toWaterNazoPuyo, nazopuyo.moveCount,
  nazopuyo.`$`, nazopuyo.parseRequirement, nazopuyo.toString,
  nazopuyo.parseNazoPuyo, nazopuyo.parseTsuNazoPuyo,
  nazopuyo.parseWaterNazoPuyo, nazopuyo.toUriQuery, nazopuyo.toUri,
  nazopuyo.parseNazoPuyos
