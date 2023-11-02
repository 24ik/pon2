{.experimental: "strictDefs".}

import std/[algorithm, dirs, paths, strformat, strutils, sugar]

type TestMode = enum
  Off
  On
  Both

const
  avx2 {.intdefine.} = Both
  bmi2 {.intdefine.} = Both

when isMainModule:
  const
    # file content
    TripleQuote = '"'.repeat 3
    Matrix = "<MATRIX>"
    Targets = "<TARGETS>"
    FileContentTemplate = &"""
discard {TripleQuote}
  action: "run"
  targets: "{Targets}"
  matrix: "{Matrix}"
{TripleQuote}

import ./main

main()
"""

    # boolean flags
    BoolValues = [Off: @[false], On: @[true], Both: @[true, false]]
    Avx2Seq = BoolValues[avx2]
    Bmi2Seq = BoolValues[bmi2]

  let
    matrixSeq = collect:
      for values in product([Avx2Seq, Bmi2Seq]):
        &"-d:avx2={values[0]} -d:bmi2={values[1]}"

    # NOTE: On Windows and cpp backend, the test fails due to Nim's bug
    fileContent = FileContentTemplate.replace(
      Matrix, matrixSeq.join "; ").replace(
        Targets, when defined(windows): "c js" else: "c cpp js")

  for kind, path in currentSourcePath().Path.parentDir.walkDir:
    case kind
    of pcDir:
      (path / "test.nim".Path).string.writeFile fileContent
    else:
      discard
