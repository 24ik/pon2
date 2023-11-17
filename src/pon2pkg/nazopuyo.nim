## This module implements Nazo Puyo.
## With `import pon2pkg/nazopuyo`, you can use all features provided by this
## module.
## Also, you can write such as `import pon2pkg/nazopuyopkg/nazopuyo` to import
## submodules individually.
##
## Submodule Documentations:
## - [Generate](./nazopuyopkg/generate.html)
## - [NazoPuyo Core](./nazopuyopkg/nazopuyo.html)
## - [Marking](./nazopuyopkg/mark.html)
## - [Permute](./nazopuyopkg/permute.html)
## - [Solve](./nazopuyopkg/solve.html)
##

{.experimental: "strictDefs".}

import ./nazopuyopkg/[generate, mark, nazopuyo, permute, solve]

export generate.GenerateError, generate.GenerateRequirementColor,
  generate.GenerateRequirement, generate.generate
export mark.MarkResult, mark.mark
export nazopuyo.RequirementKind, nazopuyo.RequirementColor,
  nazopuyo.RequirementNumber, nazopuyo.Requirement, nazopuyo.NazoPuyo,
  nazopuyo.NazoPuyos, nazopuyo.NoColorKinds, nazopuyo.NoNumberKinds,
  nazopuyo.ColorKinds, nazopuyo.NumberKinds, nazopuyo.initNazoPuyo,
  nazopuyo.initTsuNazoPuyo, nazopuyo.initWaterNazoPuyo,
  nazopuyo.toTsuNazoPuyo, nazopuyo.toWaterNazoPuyo, nazopuyo.moveCount,
  nazopuyo.isSupported, nazopuyo.flattenAnd, nazopuyo.`$`,
  nazopuyo.parseRequirement, nazopuyo.toString, nazopuyo.parseNazoPuyo,
  nazopuyo.parseTsuNazoPuyo, nazopuyo.parseWaterNazoPuyo, nazopuyo.toUriQuery,
  nazopuyo.toUri, nazopuyo.parseNazoPuyos
export permute.permute
export solve.solve
