## This module implements the requirement control.
##

{.experimental: "inferGenericTypes".}
{.experimental: "notnil".}
{.experimental: "strictCaseObjects".}
{.experimental: "strictDefs".}
{.experimental: "strictFuncs".}
{.experimental: "views".}

import std/[sequtils, sugar]
import nigui
import ../../../../app/[nazopuyo, simulator]
import ../../../../core/[requirement]

type RequirementControl* = ref object of LayoutContainer ## Requirement control.
  simulator: Simulator

# ------------------------------------------------
# Control
# ------------------------------------------------

proc descriptionLabel(control: RequirementControl): Label {.inline.} =
  ## Returns the description label.
  let rawControl = control.childControls[0]
  assert rawControl of Label

  result = cast[Label](rawControl)

proc kindComboBox(control: RequirementControl): ComboBox {.inline.} =
  ## Returns the combo box for the requirement kind.
  let rawControl = control.childControls[1]
  assert rawControl of ComboBox

  result = cast[ComboBox](rawControl)

proc colorComboBox(control: RequirementControl): ComboBox {.inline.} =
  ## Returns the combo box for the requirement color.
  let rawControl = control.childControls[2].childControls[0]
  assert rawControl of ComboBox

  result = cast[ComboBox](rawControl)

proc numberComboBox(control: RequirementControl): ComboBox {.inline.} =
  ## Returns the combo box for the requirement number.
  let rawControl = control.childControls[2].childControls[1]
  assert rawControl of ComboBox

  result = cast[ComboBox](rawControl)

proc updateDescription(control: RequirementControl) =
  ## Changes the requirement description.
  let req = control.simulator.nazoPuyoWrap.get:
    wrappedNazoPuyo.requirement
  control.descriptionLabel.text = $req

proc kindHandler(control: RequirementControl, event: ComboBoxChangeEvent) =
  ## Changes the requirement kind.
  let
    kindBox = control.kindComboBox
    newKind = RequirementKind kindBox.index

  control.simulator.requirementKind = newKind

  control.colorComboBox.enabled = newKind in ColorKinds
  control.numberComboBox.enabled = newKind in NumberKinds

  control.updateDescription

proc colorHandler(control: RequirementControl, event: ComboBoxChangeEvent) =
  ## Changes the requirement color.
  control.simulator.requirementColor = control.colorComboBox.index.RequirementColor

  control.updateDescription

proc numberHandler(control: RequirementControl, event: ComboBoxChangeEvent) =
  ## Changes the requirement number.
  control.simulator.requirementNumber = control.numberComboBox.index.RequirementNumber

  control.updateDescription

func newKindHandler(control: RequirementControl): (event: ComboBoxChangeEvent) -> void =
  ## Returns the kind handler.
  # NOTE: cannot inline due to lazy evaluation
  (event: ComboBoxChangeEvent) => control.kindHandler event

func newColorHandler(
    control: RequirementControl
): (event: ComboBoxChangeEvent) -> void =
  ## Returns the color handler.
  # NOTE: cannot inline due to lazy evaluation
  (event: ComboBoxChangeEvent) => control.colorHandler event

func newNumberHandler(
    control: RequirementControl
): (event: ComboBoxChangeEvent) -> void =
  ## Returns the number handler.
  # NOTE: cannot inline due to lazy evaluation
  (event: ComboBoxChangeEvent) => control.numberHandler event

proc newRequirementControl*(simulator: Simulator): RequirementControl {.inline.} =
  ## Returns a requirement control.
  result = new RequirementControl
  result.init
  result.layout = Layout_Vertical

  result.simulator = simulator

  result.spacing = 10.scaleToDpi
  result.padding = 10.scaleToDpi

  # row=0
  let
    req = simulator.nazoPuyoWrap.get:
      wrappedNazoPuyo.requirement
    desc = newLabel $req
  result.add desc

  # row=1
  let kind = newComboBox((RequirementKind.low .. RequirementKind.high).toSeq.mapIt $it)
  result.add kind

  kind.onChange = result.newKindHandler

  # row=2
  let thirdRow = newLayoutContainer Layout_Horizontal
  result.add thirdRow

  thirdRow.spacing = 10.scaleToDpi
  thirdRow.padding = 0.scaleToDpi

  let
    color = newComboBox(
      @["全"] & (RequirementColor.low.succ .. RequirementColor.high).mapIt $it
    )
    num = newComboBox((RequirementNumber.low .. RequirementNumber.high).mapIt $it)
  thirdRow.add color
  thirdRow.add num

  color.onChange = result.newColorHandler
  num.onChange = result.newNumberHandler

  # set index
  if simulator.mode == Edit:
    let req = simulator.nazoPuyoWrap.get:
      wrappedNazoPuyo.requirement

    kind.index = req.kind.ord
    if req.kind in ColorKinds:
      color.index = req.color.ord
    else:
      color.enabled = false
    if req.kind in NumberKinds:
      num.index = req.number.ord
    else:
      num.enabled = false
  else:
    kind.enabled = false
    color.enabled = false
    num.enabled = false

# ------------------------------------------------
# API
# ------------------------------------------------

proc setWidth*(control: RequirementControl, width: Natural) {.inline.} =
  control.descriptionLabel.width = width
  control.kindComboBox.width = width
  control.colorComboBox.width = width div 2 - 5.scaleToDpi
  control.numberComboBox.width = width - width div 2 - 5.scaleToDpi

proc updateRequirementControl*(
    control: RequirementControl, event: ClickEvent
) {.inline.} =
  ## Updates the requirement control.
  let
    descLabel = control.descriptionLabel
    kindBox = control.kindComboBox
    colorBox = control.colorComboBox
    numberBox = control.numberComboBox

  if control.simulator.kind == Regular:
    descLabel.text = ""
    kindBox.enabled = false
    colorBox.enabled = false
    numberBox.enabled = false
  else:
    let req = control.simulator.nazoPuyoWrap.get:
      wrappedNazoPuyo.requirement
    descLabel.text = $req

    if control.simulator.mode == Edit:
      kindBox.enabled = true
      colorBox.enabled = req.kind in ColorKinds
      numberBox.enabled = req.kind in NumberKinds
    else:
      kindBox.enabled = false
      colorBox.enabled = false
      numberBox.enabled = false
