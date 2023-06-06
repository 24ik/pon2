## This module implements the message table.
##

include karax/prelude

var messages* = newSeq[kstring](0)

proc messageTable*: VNode =
  ## Returns the message table.
  buildHtml(tdiv):
    h2(class = "subtitle"):
      text "解"
    tdiv(class = "table-container"):
      table(class = "table"):
        for message in messages:
          tr:
            td:
              if message.cstring.startsWith "http":
                a(href = message, target = "_blank", rel = "noopener noreferrer"):
                  text message
              else:
                text message
