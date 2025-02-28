extends Node2D

func _ready() -> void:
	PraxisCore.plusCode_changed.connect($ScrollingCenteredMap.plusCode_changed)
	$crHeader/btnZoomIn.pressed.connect($ScrollingCenteredMap.zoomIn)
	$crHeader/btnZoomOut.pressed.connect($ScrollingCenteredMap.zoomOut)
	$crHeader/btnCtdToggle.pressed.connect($ScrollingCenteredMap.ToggleShowCellTrackerDrawers)
	
	#Now testing out the auto-tracking for child nodes
	
	var test1 = ColorRect.new()
	test1.color = "FF0000"
	test1.size = Vector2(48,75)
	#Red shoud be centered where the player starts
	$ScrollingCenteredMap.trackChildOnMap(test1, "85633QG4+VV") 
