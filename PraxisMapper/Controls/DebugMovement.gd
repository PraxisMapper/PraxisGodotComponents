extends Node2D

#this control should show up when no GPS is available.
@onready var label : Label = $CanvasLayer/ColorRect/Label

func GoNorth():
	PraxisMapper.forceChange(PlusCodes.ShiftCode(PraxisMapper.currentPlusCode, 0, 1))
	
func GoSouth():
	PraxisMapper.forceChange(PlusCodes.ShiftCode(PraxisMapper.currentPlusCode, 0, -1))
	
func GoEast():
	PraxisMapper.forceChange(PlusCodes.ShiftCode(PraxisMapper.currentPlusCode, 1, 0))
	
func GoWest():
	PraxisMapper.forceChange(PlusCodes.ShiftCode(PraxisMapper.currentPlusCode, -1, 0))

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	label.text = PraxisMapper.currentPlusCode	
	pass
