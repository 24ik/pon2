## This module implements the message table.
##

include karax/prelude

var messages*: seq[kstring]

proc messageTable*: VNode =
  ## Returns the message table.
  buildHtml(tdiv):
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
