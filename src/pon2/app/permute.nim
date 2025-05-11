## This module implements Nazo Puyo permuters.
##

{.push raises: [].}
{.experimental: "strictDefs".}
{.experimental: "strictFuncs".}
{.experimental: "views".}

import ./[solve]
import ../[core]
import ../private/[assign3]
import ../private/app/[permute]

when not defined(js):
  import ../private/[suru2]

iterator permute*[F: TsuField or WaterField](
    nazo: NazoPuyo[F],
    fixIndices: openArray[int],
    allowDblNotLast, allowDblLast: bool,
    showProgressBar: static bool = false,
): NazoPuyo[F] {.inline.} =
  ## Yields Nazo Puyo that is obtained by permuting steps and has a unique answer.
  ## `showProgressBar` is ignored on JS backend.
  const ShowSuruBar = showProgressBar and not defined(js)

  let stepsSeq =
    nazo.puyoPuyo.steps.allStepsSeq(fixIndices, allowDblNotLast, allowDblLast)

  when ShowSuruBar:
    var suruBar = initSuruBar()
    suruBar[0].total = stepsSeq.len
    suruBar.setup2

  for steps in stepsSeq:
    var nazo2 = nazo
    nazo2.puyoPuyo.steps.assign steps

    let answers = nazo2.solve(calcAllAnswers = false)
    if answers.len == 1:
      for stepIdx, step in nazo2.puyoPuyo.steps.mpairs:
        if step.kind == PairPlacement:
          step.optPlacement = answers[0][stepIdx]

      yield nazo2

    when ShowSuruBar:
      suruBar.inc
      suruBar.update2

  when ShowSuruBar:
    suruBar.finish2
