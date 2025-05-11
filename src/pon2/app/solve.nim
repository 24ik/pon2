## This module implements Nazo Puyo solvers.
##

{.push raises: [].}
{.experimental: "strictDefs".}
{.experimental: "strictFuncs".}
{.experimental: "views".}

import ../[core]
import ../private/app/[solve]

export SolveAnswer

proc solve*[F: TsuField or WaterField](
    nazo: NazoPuyo[F],
    calcAllAnswers: static bool = true,
    showProgressBar: static bool = false,
): seq[SolveAnswer] {.inline.} =
  ## Solves the nazo puyo.
  ## This function requires that the field is settled.
  ## `showProgressBar` is ignored on JS backend.
  SolveNode[F].init(nazo.puyoPuyo).solve(
    calcAllAnswers, showProgressBar, nazo.goal, nazo.puyoPuyo.steps
  )
