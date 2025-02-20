extends Node2D

func _ready() -> void:
	PraxisCore.plusCode_changed.connect($CellTracker.AutoUpdate)
	PraxisCore.plusCode_changed.connect($ScrollingCenteredMap.plusCode_changed)
	$btnZoomIn.pressed.connect($ScrollingCenteredMap.zoomIn)
	$btnZoomOut.pressed.connect($ScrollingCenteredMap.zoomOut)
	$btnCtdToggle.pressed.connect($ScrollingCenteredMap.ToggleShowCellTrackerDrawers)
