# Package

version = "0.11.1"
author = "Keisuke Izumiya"
description = "Puyo Puyo Library"
license = "Apache-2.0 OR MPL-2.0"

srcDir = "src"
installExt = @["nim"]
bin = @["pon2"]


# Dependencies

requires "nim ^= 2.0.2"

requires "docopt ^= 0.7.1"
requires "karax ^= 1.3.3"
requires "nigui ^= 0.2.7"
requires "nimsimd ^= 1.2.6"
requires "suru#f6f1e607c585b2bc2f71309996643f0555ff6349"

# Tasks

import std/[os, sequtils, strformat, strutils]

task test, "Run Tests":
  const
    Pon2Avx2 {.intdefine.} = 2
    Pon2Bmi2 {.intdefine.} = 2

  exec &"nim c -r -d:Pon2Avx2={Pon2Avx2} -d:Pon2Bmi2={Pon2Bmi2} " &
    "tests/makeTest.nim"
  exec "testament all"

task benchmark, "Benchmarking":
  const
    Pon2Avx2 {.booldefine.} = true
    Pon2Bmi2 {.booldefine.} = true

  exec &"nim c -r -d:Pon2Avx2={Pon2Avx2} -d:Pon2Bmi2={Pon2Bmi2} " &
    "benchmark/main.nim"

task documentation, "Make Documentation":
  exec &"nim doc --project -d:Pon2Avx2=true src/pon2.nim"
  mvDir "src/htmldocs", "src/htmldocs2"

  exec &"nim doc --project -d:Pon2Avx2=false src/pon2.nim"
  cpDir "src/htmldocs2", "src/htmldocs"
  rmDir "src/htmldocs2"

task web, "Make Web Pages":
  const
    danger {.booldefine.} = true
    minify {.booldefine.} = true
    verbose {.booldefine.} = false

  proc compile(src: string, dst: string, options: varargs[string]) =
    let
      (_, tail) = dst.splitPath
      rawJs = getTempDir() / &"raw-{tail}"

    if verbose:
      echo "[pon2] Raw JS output file: ", rawJs

    var cmds = @["nim", "js"] & options.toSeq
    if danger:
      cmds.add "-d:danger"
    cmds &= [&"-o:{rawJs}", &"{src}"]

    exec cmds.join " "

    if minify:
      var cmds2 = @["npx", "--yes", "google-closure-compiler"]
      if not verbose:
        cmds2 &= ["-W", "QUIET"]
      cmds2 &= ["--js", &"{rawJs}", "--js_output_file", &"{dst}"]

      exec cmds2.join " "
    else:
      cpFile rawJs, dst

  # playground
  "src/pon2.nim".compile "www/playground/index.min.js"
  "src/pon2.nim".compile "www/playground/worker.min.js", "-d:Pon2Worker"

  # marathon
  "src/pon2.nim".compile "www/marathon/index.min.js", "-d:Pon2Marathon"

  # documentation
  exec "nimble -y documentation"
  cpDir "src/htmldocs", "www/docs"
  rmDir "src/htmldocs"

  # assets
  cpDir "assets", "www/assets"
