## This module implements GUI settings.
##

import os
import streams

import nigui
import yaml
import yaml/serialization

import ./key
import ./theme

type Setting* = tuple
  ## GUI settings.
  key: KeySetting
  theme: ThemeSetting

# ------------------------------------------------
# Default
# ------------------------------------------------

const DefaultSetting = (key: DefaultKeySetting, theme: DefaultThemeSetting).Setting

# ------------------------------------------------
# Save / Load
# ------------------------------------------------

const
  SettingDir = (
    when defined windows: "APPDATA".getEnv getHomeDir() / "AppData" / "Roaming"
    elif defined macos: getHomeDir() / "Application Support"
    else: "XDG_CONFIG_HOME".getEnv getHomeDir() / ".config") / "pon2"
  SettingFileName = "setting.yaml"

proc save*(setting: Setting, settingFile = SettingDir / SettingFileName) {.inline.} =
  ## Saves the :code:`setting` to the :code:`settingFile`.
  settingFile.parentDir.createDir

  var s = settingFile.newFileStream fmWrite
  defer: s.close

  setting.dump s

proc loadSetting*(settingFile = SettingDir / SettingFileName): Setting {.inline.} =
  ## Returns the settings loaded from the :code:`settingFile`.
  ## If the :code:`settingFile` does not exist, returns the default settings.
  if not settingFile.fileExists:
    return DefaultSetting

  var s = settingFile.newFileStream
  defer: s.close

  try:
    s.load result
  except YamlConstructionError, YamlParserError:
    return DefaultSetting
