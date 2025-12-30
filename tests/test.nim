{.experimental: "strictDefs".}
{.experimental: "strictFuncs".}
{.experimental: "views".}

import std/[appdirs, dirs, os, osproc, random, sequtils, strformat, strutils]
import ../src/pon2/private/[bitops, math, paths]
import unittest2

const
  SimdLevelMax = 1
  BmiLevelMax = 2
  ClmulLevelMax = 1

  SimdLevelValMax = 2 ^ (SimdLevelMax + 1) - 1
  BmiLevelValMax = 2 ^ (BmiLevelMax + 1) - 1
  ClmulLevelValMax = 2 ^ (ClmulLevelMax + 1) - 1

  SimdLevel {.define: "pon2.testsimd".} = SimdLevelValMax
  BmiLevel {.define: "pon2.testbmi".} = BmiLevelValMax
  ClmulLevel {.define: "pon2.testclmul".} = ClmulLevelValMax

  TestC {.define: "pon2.testc".} = true
  TestCpp {.define: "pon2.testcpp".} = true
  TestJs {.define: "pon2.testjs".} = true

static:
  doAssert SimdLevel in 1 .. SimdLevelValMax
  doAssert BmiLevel in 1 .. BmiLevelValMax
  doAssert ClmulLevel in 1 .. ClmulLevelValMax

type Backend {.pure.} = enum
  ## Compile backend.
  C = "c"
  Cpp = "cpp"
  Js = "js"

proc nimCacheDir(): Path =
  ## Returns a cache directory used by running.
  appdirs.getCacheDir() / "nim".Path / "pon2".Path / "test".Path / ($rand(uint64)).Path

func suiteName(backend: Backend, simdLevel, bmiLevel, clmulLevel: int): string =
  ## Returns the suite's name.
  "{backend}-simd-{simdLevel}-bmi-{bmiLevel}-clmul-{clmulLevel}".fmt

proc outDir(file: Path, backend: Backend, simdLevel, bmiLevel, clmulLevel: int): Path =
  ## Returns the output directory used by running.
  appdirs.getTempDir() / "pon2".Path / "test".Path / file.parentDir.splitFile.name /
    suiteName(backend, simdLevel, bmiLevel, clmulLevel).Path

func filePath(testDir: Path): Path =
  ## Returns the path of the entry file.
  testDir / "test.nim".Path

proc run(file: Path, backend: Backend, simdLevel, bmiLevel, clmulLevel: int): string =
  ## Runs the test file and returns the output.
  let
    cacheDir = nimCacheDir()
    output =
      "nim {backend} --nimcache:{cacheDir} -w:off --hints:off --styleCheck:error -d:pon2.simd={simdLevel} -d:pon2.bmi={bmiLevel} -d:pon2.clmul={clmulLevel} -d:pon2.build.worker -r --outdir:{outDir(file, backend, simdLevel, bmiLevel, clmulLevel)} {file}".fmt.execCmdEx.output

  cacheDir.removeDir

  output

template tests(
    testDirs: seq[Path], backend: Backend, simdLevel, bmiLevel, clmulLevel: int
): untyped =
  ## Runs tests of all modules.
  for testDir in testDirs:
    test $testDir.splitFile.name:
      check:
        testDir.filePath.run(backend, simdLevel, bmiLevel, clmulLevel) == ""

template suites(backend: Backend): untyped =
  ## Runs the suites of specified implementation levels.
  let
    testDirs = currentSourcePath().Path.parentDir.walkDir.toSeq
    .filterIt(it.kind in {pcDir, pcLinkToDir}).mapIt it.path

    simdLevels, bmiLevels, clmulLevels: seq[int]
  case backend
  of C, Cpp:
    simdLevels = (0 .. SimdLevelMax).toSeq.filterIt SimdLevel.testBit it
    bmiLevels = (0 .. BmiLevelMax).toSeq.filterIt BmiLevel.testBit it
    clmulLevels = (0 .. ClmulLevelMax).toSeq.filterIt ClmulLevel.testBit it
  of Js:
    simdLevels = @[0]
    bmiLevels = @[0]
    clmulLevels = @[0]

  for simdLevel in simdLevels:
    for bmiLevel in bmiLevels:
      for clmulLevel in clmulLevels:
        suite suiteName(backend, simdLevel, bmiLevel, clmulLevel):
          tests testDirs, backend, simdLevel, bmiLevel, clmulLevel

proc main() =
  randomize()
  when TestC:
    suites C
  when TestCpp:
    suites Cpp
  when TestJs:
    suites Js

when isMainModule:
  main()
