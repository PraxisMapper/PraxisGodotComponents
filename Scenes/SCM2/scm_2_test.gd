extends Node2D

#These are the on-map nodes to track.
var test1
var test2
var test3

func _ready() -> void:
	await get_tree().process_frame
	$crHeader/btnZoomIn.pressed.connect($ScrollingCenteredMap.zoomIn)
	$crHeader/btnZoomOut.pressed.connect($ScrollingCenteredMap.zoomOut)
	$crHeader/btnCtdToggle.pressed.connect($ScrollingCenteredMap.ToggleShowCellTrackerDrawers)
	
	$ScrollingCenteredMap.AdjustBanner(Vector2(0, 337), Vector2(1080, 80))
	
	test1 = ColorRect.new()
	test1.color = "FF0000"
	test1.size = Vector2(48,75)
	test1.set_meta("location", "85633QG4+VV")
	
	test2 = ColorRect.new()
	test2.color = "00FF00"
	test2.size = Vector2(48,75)
	test2.set_meta("location", "85633QH4+VV")
	
	test3 = ColorRect.new()
	test3.color = "0000FF"
	test3.size = Vector2(48,75)
	test3.set_meta("location", "85633QH3+VV")
	
	#To use manual tracking, you'd call these here
	#$ScrollingCenteredMap.trackChildOnMap(test1, "85633QG4+VV") #Red shoud be centered where the player starts
	#$ScrollingCenteredMap.trackChildOnMap(test2, "85633QH4+VV") #Green is a cell8 north of start.
	#$ScrollingCenteredMap.trackChildOnMap(test3, "85633QH3+VV") #Blue is a cell8 northwest of start.
	
	#Instead, we're using auto-tracking now like this:
	$ScrollingCenteredMap.SetLoadableSource(AutoTrack)

#This is the easiest example for auto-tracking: A function that returns a fixed set of nodes
#Most games will probably want to do some logic to pick out which ones to send over for given areas.
#NOTE: we have turned off FreeRemovedTrackables on the map, because this scene keep them around.
func AutoTrack(location, gridSize):
	return [test1, test2, test3]

func ToggleTileOverlay():
	$ScrollingCenteredMap.ShowTileOverlay = !$ScrollingCenteredMap.ShowTileOverlay
	$ScrollingCenteredMap.RefreshTiles(PraxisCore.currentPlusCode)

func ToggleCellOverlay():
	$ScrollingCenteredMap.ShowCellsOverlay = !$ScrollingCenteredMap.ShowCellsOverlay
	$ScrollingCenteredMap.RefreshTiles(PraxisCore.currentPlusCode)

func ToggleProxyPlay():
	PraxisCore.SetProxyPlay(!PraxisCore.proxyPlay)
	
func Close():
	get_tree().change_scene_to_file("res://Scenes/SimpleTest.tscn")
