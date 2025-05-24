# Package

version = "0.23.14"
author = "Keisuke Izumiya"
description = "Application for Puyo Puyo and Nazo Puyo"
license = "Apache-2.0"

srcDir = "src"
installExt = @["nim"]
bin = @["pon2"]

# Dependencies

requires "nim ^= 2.2.4"

requires "chronos ^= 4.0.4"
requires "docopt ^= 0.7.1"
requires "karax ^= 1.5.0"
requires "nigui ^= 0.2.8"
requires "nimsimd ^= 1.3.2"
requires "puppy ^= 2.1.2"
requires "results ^= 0.5.1"
requires "stew ^= 0.3.0"
requires "suru ^= 0.3.2"
requires "unittest2 ^= 0.2.4"

# Tasks

import std/[os, sequtils, strformat, strutils]

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
    cmds &= [&"-o:{rawJs}", src]

    exec cmds.join " "

    if minify:
      var cmds2 = @["npx", "--yes", "google-closure-compiler"]
      if not verbose:
        cmds2 &= ["-W", "QUIET"]
      cmds2 &= ["--js", rawJs, "--js_output_file", dst]

      exec cmds2.join " "
    else:
      cpFile rawJs, dst

  # GUI application
  "src/pon2.nim".compile "www/index.min.js"
  "src/pon2.nim".compile "www/worker.min.js", "-d:pon2.worker"

  # marathon
  "src/pon2.nim".compile "www/marathon/index.min.js", "-d:pon2.marathon", "-d:pon2.assets.web=../assets"

  # documentation
  rmDir "www/docs/native"
  exec &"nim doc --project --outdir:www/docs/native src/pon2.nim"
  rmDir "www/docs/web"
  exec &"nim doc --project --outdir:www/docs/web --backend:js src/pon2.nim"
  "www/docs/simulator/main.nim".compile "www/docs/simulator/index.min.js"

  # assets
  cpDir "assets", "www/assets"
