extends Node2D

func _ready() -> void:
	PraxisCore.plusCode_changed.connect($ScrollingCenteredMap.plusCode_changed)
	$crHeader/btnZoomIn.pressed.connect($ScrollingCenteredMap.zoomIn)
	$crHeader/btnZoomOut.pressed.connect($ScrollingCenteredMap.zoomOut)
	$crHeader/btnCtdToggle.pressed.connect($ScrollingCenteredMap.ToggleShowCellTrackerDrawers)
