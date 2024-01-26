{.experimental: "strictDefs".}
{.experimental: "strictFuncs".}
{.experimental: "views".}

import std/[algorithm, dirs, paths, strformat, strutils, sugar]

type TestMode = enum
  Off
  On
  Both

const
  Pon2Avx2 {.intdefine.} = Both
  Pon2Bmi2 {.intdefine.} = Both

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
    Avx2Seq = BoolValues[Pon2Avx2]
    Bmi2Seq = BoolValues[Pon2Bmi2]

  let
    matrixSeq = collect:
      for values in product([Avx2Seq, Bmi2Seq]):
        &"-d:Pon2Avx2={values[0]} -d:Pon2Bmi2={values[1]}"

    # NOTE: On Windows and non-c backend, the test fails due to Nim's bug
    fileContent = FileContentTemplate.replace(
      Matrix, matrixSeq.join "; ").replace(
        Targets, when defined(windows): "c" else: "c cpp js")

  for kind, path in currentSourcePath().Path.parentDir.walkDir:
    case kind
    of pcDir:
      (path / "test.nim".Path).string.writeFile fileContent
    else:
      discard
