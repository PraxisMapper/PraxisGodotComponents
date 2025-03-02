extends Node2D

func _ready() -> void:
	PraxisCore.plusCode_changed.connect($ScrollingCenteredMap.plusCode_changed)
	$crHeader/btnZoomIn.pressed.connect($ScrollingCenteredMap.zoomIn)
	$crHeader/btnZoomOut.pressed.connect($ScrollingCenteredMap.zoomOut)
	$crHeader/btnCtdToggle.pressed.connect($ScrollingCenteredMap.ToggleShowCellTrackerDrawers)
	
	$ScrollingCenteredMap.AdjustBanner(Vector2(0, 337), Vector2(1080, 80))
	#Now testing out the auto-tracking for child nodes
	
	var test1 = ColorRect.new()
	test1.color = "FF0000"
	test1.size = Vector2(48,75)
	$ScrollingCenteredMap.trackChildOnMap(test1, "85633QG4+VV") #Red shoud be centered where the player starts
	
	var test2 = ColorRect.new()
	test2.color = "00FF00"
	test2.size = Vector2(48,75)
	$ScrollingCenteredMap.trackChildOnMap(test2, "85633QH4+VV") #Green is a cell8 north of start.
	
	var test3 = ColorRect.new()
	test3.color = "0000FF"
	test3.size = Vector2(48,75)
	$ScrollingCenteredMap.trackChildOnMap(test3, "85633QH3+VV") #Blue is a cell8 northwest of start.
