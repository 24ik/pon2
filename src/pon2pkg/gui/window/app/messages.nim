## This module implements the messages control.
##

import sugar

import nigui

import ./common
import ../resource
import ../../setting/main
import ../../setting/theme

type
  MessageKind* {.pure.} = enum
    ## Message kind.
    MARK
    RECORD
    MISC

  MessagesControl* = ref object of LayoutContainer
    ## Messages control.
    setting: ref Setting

    messages*: array[MessageKind, string]

# ------------------------------------------------
# Property
# ------------------------------------------------

proc messagesControl(event: DrawEvent): MessagesControl {.inline.} =
  ## Returns the messages control from the :code:`event`.
  let control = event.control.parentWindow.control.childControls[2]
  assert control of MessagesControl
  return cast[MessagesControl](control)

# ------------------------------------------------
# Constructor
# ------------------------------------------------

proc messageDrawHandler(event: DrawEvent, kind: MessageKind) {.inline.} =
  ## Draws the message.
  let
    control = event.messagesControl
    theme = control.setting[].theme
    canvas = event.control.canvas

  # background color
  canvas.areaColor = theme.bgControl
  canvas.fill

  canvas.drawText control.messages[kind]

proc newMessageControl(kind: MessageKind, fontSize: float): Control {.inline.} =
  ## Returns a new single message control.
  result = newControl()
  result.onDraw = (event: DrawEvent) => event.messageDrawHandler kind

  # NOTE: width should be set in the root; cannot determine it here
  result.fontSize = fontSize
  result.height = fontSize.px

proc newMessagesControl*(
  setting: ref Setting, resource: ref Resource, messages = [MARK: "", RECORD: "", MISC: ""]
): MessagesControl {.inline.} =
  ## Returns a new messages control.
  result = new MessagesControl
  result.init
  result.layout = Layout_Vertical

  result.setting = setting

  result.messages = messages

  for kind in MessageKind:
    result.add kind.newMessageControl resource[].cellImageHeight.pt
