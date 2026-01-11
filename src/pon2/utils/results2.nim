## This module implements helpers of [nim-results](https://github.com/arnetheduck/nim-results).
## 

{.push raises: [].}
{.experimental: "strictDefs".}
{.experimental: "strictFuncs".}
{.experimental: "views".}

import std/[sugar]
import results

export results

type Pon2Result*[T] = Result[T, string]

func context*[T](
    self: Pon2Result[T], contextMsg: string
): Pon2Result[T] {.inline, noinit.} =
  ## Returns the result with the context error message added.
  self.mapErr (error: string) => contextMsg & '\n' & error
