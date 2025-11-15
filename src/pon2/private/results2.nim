## This module implements Result's helpers.
## 

{.push raises: [].}
{.experimental: "strictDefs".}
{.experimental: "strictFuncs".}
{.experimental: "views".}

import std/[strformat, sugar]
import results

export results

type StrErrorResult*[T] = Result[T, string]

func context*[T](
    self: StrErrorResult[T], contextMsg: string
): StrErrorResult[T] {.inline, noinit.} =
  ## Returns the result with the context error message added to the `self`.
  self.mapErr (error: string) => "{contextMsg}\n{error}".fmt
