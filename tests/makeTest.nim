import std/dirs
import std/paths
import strformat
import strutils

const
  avx2 {.booldefine.} = true
  bmi2 {.booldefine.} = true

when isMainModule:
  const
    # file content
    TripleQuote = "\"\"\""
    Targets = "<TARGETS>"
    Matrix = "<MATRIX>"
    FileContentTemplate = &"""
discard {TripleQuote}
  action: "run"
  targets: "{TARGETS}"
  matrix: "{Matrix}"
{TripleQuote}

import ./main

main()
"""

  let fileContent = FileContentTemplate.replace(Matrix, &"-d:avx2={avx2} -d:bmi2={bmi2}")

  for kind, path in currentSourcePath().Path.parentDir.walkDir:
    if kind == pcDir:
      let content = fileContent.replace(Targets, if path.lastPathPart == "db".Path: "c cpp" else: "c cpp js")
      (path / "test.nim".Path).string.writeFile content
