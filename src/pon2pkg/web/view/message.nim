## This module implements a message table.
##

include karax/prelude

var messages*: seq[kstring]

proc messageTable*: VNode =
  ## Returns a message table.
  buildHtml(tdiv):
    tdiv(class = "table-container"):
      table(class = "table"):
        for message in messages:
          tr:
            td:
              if message.startsWith "http":
                a(href = message, target = "_blank", rel = "noopener noreferrer"):
                  text message
              else:
                text message
