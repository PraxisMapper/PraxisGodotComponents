extends Node2D

#TODO:
#When entered, set proxyPlay to true, pick a base location, and grab the next/last
#position as the proxyBase.
#When closing, set proxyPlay to false.
#May pick a map location to use to with offline tile data

# Called when the node enters the scene tree for the first time.
func _ready():
	$lblProxy.text = "Proxied to: " + PraxisCore.currentPlusCode
	PraxisCore.plusCode_changed.connect(onPluscodeChanged)
	
	#Move the banner to match the scenes layout.
	$ScrollingCenteredMap.AdjustBanner(Vector2(0,337), Vector2(1080, 150))

func onPluscodeChanged(current, _old):
	$lblProxy.text = "Proxied to: " + current

func Close():
	PraxisCore.SetProxyPlay(false)
	get_tree().change_scene_to_file("res://Scenes/SimpleTest.tscn")
