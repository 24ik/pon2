import std/dirs
import std/paths
import strformat
import strutils
import sugar

const
  bmi2 {.booldefine.} = true
  avx2 {.booldefine.} = true

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

    # thread flags
    ThreadSeq = @["", "-d:singleThread"]

  let
    matrixSeq = collect:
      for thread in ThreadSeq:
         &"-d:bmi2={bmi2} -d:avx2={avx2} {thread}"
    fileContent = FileContentTemplate.replace(Matrix, matrixSeq.join "; ")

  for kind, path in currentSourcePath().Path.parentDir.walkDir:
    if kind == pcDir:
      let content = fileContent.replace(Targets, if path.lastPathPart == "db".Path: "c cpp" else: "c cpp js")
      (path / "test.nim".Path).string.writeFile content
