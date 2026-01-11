extends Node2D

#Uses the scrolling map view, add a randomly colored paint splat to the
#map where the user is standing when they push a button. Save splat data and 
#load it when opening so it persists locally.

var downloading = false

#Preload images in here, so we can draw them faster later.
var splats = []

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
	
	#This puts the drawing banner on-screen.
	$ScrollingCenteredMap/TileDrawer/Banner.position = Vector2(260,485)
	$ScrollingCenteredMap/TileDrawer/Banner.visible = false
	PraxisCore.plusCode_changed.connect(plusCode_changed)
	
	#load save data and draw for area.
	saveData = PraxisCore.LoadData("user://Data/splats.json")
	if saveData == null:
		saveData = {}
	plusCode_changed(PraxisCore.currentPlusCode, PraxisCore.lastPlusCode)
	redrawSplats(PraxisCore.currentPlusCode) #force-loads them on start.

func Splat():
	var splat = {
		color = Color(randf(), randf(), randf(), 0.53).to_html(), #randomized per splat
		shape = randi_range(0, 35),
		angle= randf_range(-TAU, TAU), #rotate splats randomly for additional visual variety.
	}
	saveData[PraxisCore.currentPlusCode] = splat
	PraxisCore.SaveData("user://Data/splats.json", saveData)
	
	#Now update drawing with new splat.
	var sprite = MakeSprite(splat)
	$ScrollingCenteredMap.trackChildOnMap(sprite, PraxisCore.currentPlusCode)

func redrawSplats(plusCodeBase):
	#plusCodeBase should be the upper-left corner of the area being drawn, to match up with
	#ScrollableMap positions.
	#if we have moved to the next cell8, drop and re-calc which splats to draw and where to draw them
	
	$ScrollingCenteredMap.clearAllTrackedChildren()
	
	if saveData == null:
		return
	
	var drawSplats = []
	var drawDist = PraxisCore.resolutionCell8 * 4
	for coord in saveData: #this gets keys.
		if PlusCodes.GetDistanceDegrees(plusCodeBase, coord) < drawDist:
			drawSplats.append(coord)
	
	for drawThis in drawSplats:
		var splat = saveData[drawThis]
		var sprite = MakeSprite(splat)
		$ScrollingCenteredMap.trackChildOnMap(sprite, drawThis)

func MakeSprite(splat):
	var sprite = Sprite2D.new()
	sprite.texture = splats[splat.shape]
	sprite.rotation = splat.angle
	sprite.modulate = splat.color

	return sprite

func plusCode_changed(cur, old):
	#NOTE: the map scrolls independely of this, so I may need to chain it to 
	#this call if I want it to wait until there's data to draw. Get downloads working first.
	if downloading == true:
		return
	
	#TODO: This should use the built-in data if its present.
	if !FileAccess.file_exists("user://Data/Full/" + cur.substr(0,6) + ".json"):
		downloading = true
		$ScrollingCenteredMap.process = false
		if await $GetFile.getCell6File(cur.substr(0,6)): #NOTE: this is a weird race condition. Dont do this.
			await $GetFile.file_downloaded
		$ScrollingCenteredMap.process = true
		downloading = false
	#move splats to match new code if in same Cell8. if not, redraw whole thing.
	#$splats.position = $ScrollingCenteredMap.currentOffset
	
	$ScrollingCenteredMap.plusCode_changed(cur, old)
	if cur.substr(0,8) != old.substr(0,8):
		redrawSplats(cur)

func Return():
	get_tree().change_scene_to_file("res://Scenes/SimpleTest.tscn")

func _process(delta):
	$playerArrow.rotation = PraxisCore.GetCompassHeading()
