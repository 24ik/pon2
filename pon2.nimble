# Package

version       = "0.5.3"
author        = "Keisuke Izumiya"
description   = "Nazo Puyo Tool"
license       = "Apache-2.0 OR MPL-2.0"

srcDir        = "src"
installExt    = @["nim"]
bin           = @["pon2"]


# Dependencies

requires "nim ^= 2.0.0"

requires "nigui ^= 0.2.7"
requires "https://github.com/izumiya-keisuke/docopt.nim#c50d709"
requires "https://github.com/izumiya-keisuke/nazopuyo-core ^= 0.10.0"
requires "https://github.com/izumiya-keisuke/puyo-core ^= 0.15.0"
requires "https://github.com/izumiya-keisuke/puyo-simulator ^= 0.11.5"
requires "https://github.com/karaxnim/karax#7dd0c83"


# Tasks

import os
import strformat

task test, "Test":
  let mainFile = "./src/pon2.nim".unixToNativePath
  exec &"nim doc --project --index {mainFile}"
  rmDir "./src/htmldocs".unixToNativePath

  let defineOptions = case buildOS
  of "linux": ""
  of "windows": "-d:avx2=false"
  of "macosx": "-d:avx2=false -d:bmi2=false"
  else: ""
  exec &"nimble -y build {defineOptions}"

  if buildOS != "windows": # HACK: now we cannot pass the test on Windows due to Nim's bug
    exec "testament all"
