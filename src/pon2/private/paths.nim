## This module implements path-related functions.
##

{.experimental: "strictDefs".}
{.experimental: "strictFuncs".}
{.experimental: "views".}
{.push raises: [].}

import std/[paths]

when defined(js):
  import std/[strformat]
  import ./[strutils]

export paths except splitPath

template srcPath*(): Path =
  ## Returns the file's path.
  instantiationInfo(-1, true).filename.Path

func splitPath*(path: Path): tuple[head, tail: Path] {.inline, noinit.} =
  ## Returns the split paths.
  when defined(js):
    if '\\' in $path:
      let paths = ($path).rsplit('\\', 1)
      (head: paths[0].Path, tail: paths[1].Path)
    else:
      paths.splitPath path
  else:
    paths.splitPath path

func joinPath*(head, tail: Path): Path {.inline, noinit.} =
  ## Returns the concatenated path.
  when defined(js):
    if '\\' in $head:
      "{head}\\{tail}".fmt.Path
    else:
      head / tail
  else:
    head / tail
