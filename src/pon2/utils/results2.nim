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

func value*[T, E](self: Result[T, E], defaultVal: T): T {.inline, noinit.} =
  ## Returns the (immutable) value.
  ## If the result is error, returns `defaultVal`.
  if self.isOk: self.unsafeValue else: defaultVal

func context*[T](
    self: Pon2Result[T], contextMsg: string
): Pon2Result[T] {.inline, noinit.} =
  ## Returns the result with the context error message added.
  self.mapErr (error: string) => contextMsg & '\n' & error
