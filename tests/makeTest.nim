import os
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
    Matrix = "<MATRIX>"
    FileContentTemplate = &"""
discard {TripleQuote}
  action: "run"
  targets: "c cpp js"
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
         &"-d:bmi2={bmi2} -d:avx2={avx2} {thread} --threads:on --mm:arc --tlsEmulation:off -d:useMalloc"
    fileContent = FileContentTemplate.replace(Matrix, matrixSeq.join "; ")

  for categoryDir in (currentSourcePath().parentDir / "*").walkDirs:
    let f = (categoryDir / "test.nim").open fmWrite
    defer: f.close

    f.write fileContent
