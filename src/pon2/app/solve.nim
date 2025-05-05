## This module implements Nazo Puyo solvers.
##

{.push raises: [].}
{.experimental: "strictDefs".}
{.experimental: "strictFuncs".}
{.experimental: "views".}

import ../[core]
import ../private/app/[solve]

export SolveAnswer

func solve*[F: TsuField or WaterField](
    nazo: NazoPuyo[F], earlyStopping: static bool = false
): seq[SolveAnswer] {.inline.} =
  ## Solves the nazo puyo.
  ## This function requires that the field is settled.
  SolveNode[F].init(nazo.puyoPuyo).solve(earlyStopping, nazo.goal, nazo.puyoPuyo.steps)
