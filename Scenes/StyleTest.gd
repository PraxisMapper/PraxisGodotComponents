extends Node2D

#TODO: this demo draws 1 map tile in 2-3 different styles
#Default maptiles, a TRON-style one with just roads and parks, and a third?
#Should show that some areas can be ignored, and that they're the same area.


#For demo purposes, whip up 2 quick styles here ("neon" and "tbd" in the styles folder.
#var neonStyle = {"10":{"name":"tertiary","drawOps":[{"color":"8f8f8f","sizePx":7.5,"drawOrder":99},{"color":"ffffff","sizePx":2.5,"drawOrder":98}]},"1000":{"name":"park","drawOps":[{"color":"C8FACC","sizePx":2.5,"drawOrder":100}]},}
#I think style 3 should be inverted, or maybe something more bright and cartoony?


# Called when the node enters the scene tree for the first time.
func _ready():
	var plusCode8 = "85634PFW"
	var timeData = ""
	var frametime = 0.016
	
	var start = Time.get_unix_time_from_system()
	var mapTilesImg = await $FullTile.GetAndProcessData(plusCode8)
	$TextureRect.texture = ImageTexture.create_from_image(mapTilesImg)
	var end = Time.get_unix_time_from_system()
	timeData += "Pic1 drawn in " + str(end - start) + "\n"
	
	var start2 = Time.get_unix_time_from_system()
	$FullTile.drawnStyle = "neon"
	var mapImg2 = await $FullTile.GetAndProcessData(plusCode8)
	$TextureRect2.texture = ImageTexture.create_from_image(mapImg2)
	end = Time.get_unix_time_from_system()
	timeData += "Pic2 drawn in " + str(end - start2) + "\n"
	
	var start3 = Time.get_unix_time_from_system()
	$FullTile.drawnStyle = "invertedMapTiles"
	var mapImg3 = await $FullTile.GetAndProcessData(plusCode8)
	$TextureRect3.texture = ImageTexture.create_from_image(mapImg3)
	end = Time.get_unix_time_from_system()
	timeData += "Pic3 drawn in " + str(end - start3) + "\n"
	
	var start4 = Time.get_unix_time_from_system()
	$FullTile.drawnStyle = "adminBoundsFilled"
	var mapImg4 = await $FullTile.GetAndProcessData(plusCode8)
	$TextureRect4.texture = ImageTexture.create_from_image(mapImg4)
	end = Time.get_unix_time_from_system()
	timeData += "Pic4 drawn in " + str(end - start4) + "\n"
	
	var start5 = Time.get_unix_time_from_system()
	$FullTile.drawnStyle = "mapTilesAdminBoundsLines"
	var mapImg5 = await $FullTile.GetAndProcessData(plusCode8)
	$TextureRect5.texture = ImageTexture.create_from_image(mapImg5)
	end = Time.get_unix_time_from_system()
	timeData += "Pic5 drawn in " + str(end - start5) + "\n"
	
	var elapsed = end - start
	var frames = elapsed / frametime
	timeData += "StyleTest  _ready done in " + str(elapsed) + " [" + str(frames) + " frames]"
	print(timeData)

func Close():
	get_tree().change_scene_to_file("res://Scenes/SimpleTest.tscn")
