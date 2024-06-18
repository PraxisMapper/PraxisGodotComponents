extends Node2D

#TODO: Use the scrolling map view, add a randomly colored paint splat to the
#map where the user is standing when they push a button. Save splat data and 
#load it when opening so it persists locally.
#This is pretty close, though it looks like splats aren't centered as expected
#and I may need a little bit of buffer vertically still?

#NOTE: this is still occasionally failing to draw map tiles again.
#re-check that I have stuff in place that should minimize that.


#Preload images in here, so we can draw them faster later.
var splats = []

var saveEntry = {
	coords = "22334455+66", #centered in the Cell10, not on a corner
	color = "FFEECC", #randomized per splat
	shape = 0, #random 0-35
	angle= 0, #rotate splats randomly for additional visual variety.
}

#Dict of saveEntry items to reference when drawing.
#Each cell10 can have 1 splat, can be overwritten by future splat calls.
var saveData = {}


# Called when the node enters the scene tree for the first time.
func _ready():
	#load up splats pngs into array for later reference.
	#These are kenney.nl splat pack sprites, CC0/PD.
	splats.append(preload("res://Scenes/SplatScene/splat00.png"))
	splats.append(preload("res://Scenes/SplatScene/splat01.png"))
	splats.append(preload("res://Scenes/SplatScene/splat02.png"))
	splats.append(preload("res://Scenes/SplatScene/splat03.png"))
	splats.append(preload("res://Scenes/SplatScene/splat04.png"))
	splats.append(preload("res://Scenes/SplatScene/splat05.png"))
	splats.append(preload("res://Scenes/SplatScene/splat06.png"))
	splats.append(preload("res://Scenes/SplatScene/splat07.png"))
	splats.append(preload("res://Scenes/SplatScene/splat08.png"))
	splats.append(preload("res://Scenes/SplatScene/splat09.png"))
	splats.append(preload("res://Scenes/SplatScene/splat10.png"))
	splats.append(preload("res://Scenes/SplatScene/splat11.png"))
	splats.append(preload("res://Scenes/SplatScene/splat12.png"))
	splats.append(preload("res://Scenes/SplatScene/splat13.png"))
	splats.append(preload("res://Scenes/SplatScene/splat14.png"))
	splats.append(preload("res://Scenes/SplatScene/splat15.png"))
	splats.append(preload("res://Scenes/SplatScene/splat16.png"))
	splats.append(preload("res://Scenes/SplatScene/splat17.png"))
	splats.append(preload("res://Scenes/SplatScene/splat18.png"))
	splats.append(preload("res://Scenes/SplatScene/splat19.png"))
	splats.append(preload("res://Scenes/SplatScene/splat20.png"))
	splats.append(preload("res://Scenes/SplatScene/splat21.png"))
	splats.append(preload("res://Scenes/SplatScene/splat22.png"))
	splats.append(preload("res://Scenes/SplatScene/splat23.png"))
	splats.append(preload("res://Scenes/SplatScene/splat24.png"))
	splats.append(preload("res://Scenes/SplatScene/splat25.png"))
	splats.append(preload("res://Scenes/SplatScene/splat26.png"))
	splats.append(preload("res://Scenes/SplatScene/splat27.png"))
	splats.append(preload("res://Scenes/SplatScene/splat28.png"))
	splats.append(preload("res://Scenes/SplatScene/splat29.png"))
	splats.append(preload("res://Scenes/SplatScene/splat30.png"))
	splats.append(preload("res://Scenes/SplatScene/splat31.png"))
	splats.append(preload("res://Scenes/SplatScene/splat32.png"))
	splats.append(preload("res://Scenes/SplatScene/splat33.png"))
	splats.append(preload("res://Scenes/SplatScene/splat34.png"))
	splats.append(preload("res://Scenes/SplatScene/splat35.png"))
	
	PraxisCore.plusCode_changed.connect(plusCode_changed)
	
	#load save data and draw for area.
	var saveData = PraxisCore.LoadData("user://Data/splats.json")

func Splat():
	var splat = {
		color = Color(randf(), randf(), randf(), 0.53), #randomized per splat
		shape = randi_range(0, 35),
		angle= randf_range(-TAU, TAU), #rotate splats randomly for additional visual variety.
	}
	saveData[PraxisCore.currentPlusCode] = splat
	PraxisCore.SaveData("user://Data/splats.json", saveData)
	
	#Now update drawing with new splat.
	#May just be adding a splat texture as a chile to splats.
	
	#TODO: If there was an existing splat in the same spot, how do I remove that sprite?
	var sprite = MakeSprite(splat, PraxisCore.currentPlusCode)
	$splats.add_child(sprite)
	
func redrawSplats(plusCodeCenter):
	#if we have moved to the next cell8, drop and re-calc which splats to draw and where to draw them
	var drop = $splats.get_children()
	for splat in drop:
		splat.queue_free()
	
	var drawSplats = []
	for coord in saveData: #this gets keys.
		if abs(PlusCodes.GetDistanceDegrees(plusCodeCenter, coord)) < (PraxisCore.resolutionCell8 * 4):
			drawSplats.append(coord)
	
	for drawThis in drawSplats:
		var splat = saveData[drawThis]
		#create the actual texture now and append it to splats node.
		var sprite = MakeSprite(splat, drawThis)
		$splats.add_child(sprite)

func MakeSprite(splat, plusCode):
	var sprite = Sprite2D.new()
	sprite.texture = splats[splat.shape] #ImageTexture.create_from_image(splats[splat.shape])
	sprite.rotation = splat.angle
	sprite.modulate = splat.color
	
	#IGNORE THIS - this offset is what the splats node should be set to, not the children.
	#print($ScrollingCenteredMap.currentOffset) #Only applies to the current PlusCode.
	#So, would work for new splats, but not ones we made in a different Cell8.
	#sprite.position = $ScrollingCenteredMap.currentOffset #Vector2(500,600) #Temp test coords
	
	#This doesnt work if we're standing on the current plus code, so dont use that.
	#I need a few layers of stuff.
	# 1 - relative positon between drawing plus code and displayed plus code grid. This is 
	#     the accurate base data.
	# 2 - Scrolled offset of all nodes - this is the operation that gets stuff centered and 
	#     correct relative to the players vision.
	#
	var offset = PlusCodes.GetDistanceCell10s(PraxisCore.currentPlusCode.substr(0,8) + "22", plusCode)
	sprite.position = Vector2(640, 1000) + offset * Vector2(-16,25) + Vector2(8, 13) #add half to center the splat.
	#Adding that first Vector2 offset helps a lot, and confirms that these cover a Cell8, so I have
	#the offsets correct for the CURRENT cell8, not ALL of them.
	
	#Ok so maps are 5x5. For current plusCode, I'd want to shift the Cell8 value by (-2, 2), and then 
	#set the Cell10 values to 2X to get the top corner of the possible drawing area.
	#With that, I should be able to position everything else correctly based on the distance.
	
	
	#TODO: confirm position stays at its values when its added as a child to splats. 
	#Pretty sure it does but if not i need to move stuff.
	return sprite


func plusCode_changed(cur, old):
	#move splats to match new code if in same Cell8. if not, redraw whole thing.
	$splats.position = $ScrollingCenteredMap.currentOffset
	if cur.substr(0,8) != old.substr(0,8):
		redrawSplats(cur)



func Return():
	get_tree().change_scene_to_file("res://Scenes/SimpleTest.tscn")

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
