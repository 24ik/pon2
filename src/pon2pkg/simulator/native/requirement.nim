## This module implements the requirement control.
##

{.experimental: "strictDefs".}

import std/[options, sequtils, sugar]
import nigui
import ../[simulator]
import ../../core/[misc]
import ../../core/nazoPuyo/[nazoPuyo]

type RequirementControl* = ref object of LayoutContainer
  ## Requirement control.
  simulator: ref Simulator

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
  control.descriptionLabel.text = $control.simulator[].requirement

proc kindHandler(control: RequirementControl, event: ComboBoxChangeEvent) =
  ## Changes the requirement kind.
  let
    kindBox = control.kindComboBox 
    newKind = RequirementKind kindBox.index

  control.simulator[].requirementKind = newKind

  control.colorComboBox.enabled = newKind in ColorKinds
  control.numberComboBox.enabled = newKind in NumberKinds

  control.updateDescription

proc colorHandler(control: RequirementControl, event: ComboBoxChangeEvent) =
  ## Changes the requirement color.
  control.simulator[].requirementColor =
    control.colorComboBox.index.RequirementColor

  control.updateDescription

proc numberHandler(control: RequirementControl, event: ComboBoxChangeEvent) =
  ## Changes the requirement number.
  control.simulator[].requirementNumber =
    control.numberComboBox.index.RequirementNumber

  control.updateDescription

func initKindHandler(control: RequirementControl):
    (event: ComboBoxChangeEvent) -> void =
  ## Returns the kind handler.
  # NOTE: inline handler does not work due to specifications.
  (event: ComboBoxChangeEvent) => control.kindHandler event

func initColorHandler(control: RequirementControl):
    (event: ComboBoxChangeEvent) -> void =
  ## Returns the color handler.
  # NOTE: inline handler does not work due to specifications.
  (event: ComboBoxChangeEvent) => control.colorHandler event

func initNumberHandler(control: RequirementControl):
    (event: ComboBoxChangeEvent) -> void =
  ## Returns the number handler.
  # NOTE: inline handler does not work due to specifications.
  (event: ComboBoxChangeEvent) => control.numberHandler event

proc initRequirementControl*(simulator: ref Simulator): RequirementControl
                            {.inline.} =
  ## Returns a requirement control.
  result = new RequirementControl
  result.init
  result.layout = Layout_Vertical

  result.simulator = simulator

  result.spacing = 10.scaleToDpi
  result.padding = 10.scaleToDpi

  # row=0
  let desc = newLabel $simulator[].requirement
  result.add desc

  # row=1
  let kind = newComboBox((RequirementKind.low..RequirementKind.high).toSeq.mapIt $it)
  result.add kind

  kind.onChange = result.initKindHandler

  # row=2
  let thirdRow = newLayoutContainer Layout_Horizontal
  result.add thirdRow

  thirdRow.spacing = 10.scaleToDpi
  thirdRow.padding = 0.scaleToDpi

  let
    color = newComboBox(
      @["全"] & (RequirementColor.low.succ..RequirementColor.high).mapIt $it)
    num = newComboBox((RequirementNumber.low..RequirementNumber.high).mapIt $it)
  thirdRow.add color
  thirdRow.add num

  color.onChange = result.initColorHandler
  num.onChange = result.initNumberHandler

  # set index
  if simulator[].mode != IzumiyaSimulatorMode.Edit:
    kind.enabled = false
    color.enabled = false
    num.enabled = false
  else:
    let req = simulator[].requirement

    kind.index = req.kind.ord
    if req.kind in ColorKinds:
      color.index = req.color.get.ord
    else:
      color.enabled = false
    if req.kind in NumberKinds:
      num.index = req.number.get.ord
    else:
      num.enabled = false

# ------------------------------------------------
# API
# ------------------------------------------------

proc setWidth*(control: RequirementControl, width: Natural) {.inline.} =
  control.descriptionLabel.width = width
  control.kindComboBox.width = width
  control.colorComboBox.width = width div 2 - 5.scaleToDpi
  control.numberComboBox.width = width - width div 2 - 5.scaleToDpi

proc updateRequirementControl*(control: RequirementControl, event: ClickEvent)
                              {.inline.} =
  ## Updates the requirement control.
  let
    descLabel = control.descriptionLabel
    kindBox = control.kindComboBox 
    colorBox = control.colorComboBox 
    numberBox = control.numberComboBox 

  if control.simulator[].kind == Regular:
    descLabel.text = ""
    kindBox.enabled = false
    colorBox.enabled = false
    numberBox.enabled = false
  else:
    descLabel.text = $control.simulator[].requirement
    if control.simulator[].mode == IzumiyaSimulatorMode.Edit:
      kindBox.enabled = true
      colorBox.enabled = control.simulator[].requirement.kind in ColorKinds
      numberBox.enabled =
        control.simulator[].requirement.kind in NumberKinds
    else:
      kindBox.enabled = false
      colorBox.enabled = false
      numberBox.enabled = false
