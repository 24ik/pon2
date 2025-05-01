{.experimental: "strictDefs".}
{.experimental: "strictFuncs".}
{.experimental: "views".}

import std/[appdirs, dirs, os, osproc, paths, random, sequtils, strformat, strutils]
import ../src/pon2/private/[bitops3, math2]
import unittest2

const
  SimdLvlMax = 1
  BmiLvlMax = 2
  ClmulLvlMax = 1

  SimdLvlValMax = 2 ^ SimdLvlMax.succ - 1
  BmiLvlValMax = 2 ^ BmiLvlMax.succ - 1
  ClmulLvlValMax = 2 ^ ClmulLvlMax.succ - 1

  SimdLvl {.define: "pon2.testsimd".} = SimdLvlValMax
  BmiLvl {.define: "pon2.testbmi".} = BmiLvlValMax
  ClmulLvl {.define: "pon2.testclmul".} = ClmulLvlValMax

static:
  doAssert SimdLvl in 1 .. SimdLvlValMax
  doAssert BmiLvl in 1 .. BmiLvlValMax
  doAssert ClmulLvl in 1 .. ClmulLvlValMax

type Backend {.pure.} = enum
  ## Compile backend.
  C = "c"
  Cpp = "cpp"
  Js = "js"

proc nimCacheDir(): Path =
  ## Returns a cache directory used by running.
  appdirs.getCacheDir() / "nim".Path / "pon2".Path / "test".Path / ($rand(uint64)).Path

proc outDir(file: Path, backend: Backend, simdLvl, bmiLvl: int, clmulUse: bool): Path =
  ## Returns the output directory used by running.
  appdirs.getTempDir() / "pon2".Path / "test".Path / ($backend).Path /
    file.parentDir.splitFile.name /
    "simd{simdLvl}bmi{bmiLvl}clmul{($clmulUse)[0].toUpperAscii}".fmt.Path

func filePath(testDir: Path): Path =
  ## Returns the path of the entry file.
  testDir / "test.nim".Path

proc run(file: Path, backend: Backend, simdLvl, bmiLvl: int, clmulUse: bool): string =
  ## Runs the test file and returns the output.
  let
    cacheDir = nimCacheDir()
    output =
      "nim {backend} --nimcache:{cacheDir} -w:off --hints:off -d:pon2.simd={simdLvl} -d:pon2.bmi={bmiLvl} -d:pon2.clmul={clmulUse} -r --outdir:{outDir(file, backend, simdLvl, bmiLvl, clmulUse)} {file}".fmt.execCmdEx.output

  cacheDir.removeDir

  output

template tests(
    testDirs: seq[Path], backend: Backend, simdLvl, bmiLvl: int, clmulUse: bool
): untyped =
  ## Runs tests of all modules.
  for testDir in testDirs:
    test $testDir.splitFile.name:
      check:
        testDir.filePath.run(backend, simdLvl, bmiLvl, clmulUse) == ""

func suiteName(backend: Backend, simdLvl, bmiLvl: int, clmulUse: bool): string =
  ## Returns the suite's name.
  "{backend} simd={simdLvl} bmi={bmiLvl} clmul={clmulUse}".fmt

template suites(backend: Backend): untyped =
  ## Runs the suites of specified implementation levels.
  let
    testDirs = currentSourcePath().Path.parentDir.walkDir.toSeq
    .filterIt(it.kind in {pcDir, pcLinkToDir}).mapIt it.path

    simdLvls, bmiLvls: seq[int]
    clmulUses: seq[bool]
  case backend
  of C, Cpp:
    simdLvls = (0 .. SimdLvlMax).toSeq.filterIt SimdLvl.testBit it
    bmiLvls = (0 .. BmiLvlMax).toSeq.filterIt BmiLvl.testBit it
    clmulUses = (0 .. ClmulLvlValMax).toSeq.filterIt(ClmulLvl.testBit it).mapIt it.bool
  of Js:
    simdLvls = @[0]
    bmiLvls = @[0]
    clmulUses = @[false]

  for simdLvl in simdLvls:
    for bmiLvl in bmiLvls:
      for clmulUse in clmulUses:
        suite suiteName(backend, simdLvl, bmiLvl, clmulUse):
          tests testDirs, backend, simdLvl, bmiLvl, clmulUse

proc main() =
  randomize()
  suites C
  suites Cpp
  suites Js

when isMainModule:
  main()
