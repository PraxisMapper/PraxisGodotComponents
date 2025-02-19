extends Node2D


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	PraxisCore.plusCode_changed.connect($ScrollingCenteredMap.plusCode_changed)
	$btnZoomIn.pressed.connect($ScrollingCenteredMap.zoomIn)
	$btnZoomOut.pressed.connect($ScrollingCenteredMap.zoomOut)
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	
	pass
