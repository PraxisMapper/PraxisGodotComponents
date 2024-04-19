extends Node2D

#This is the TIBO style "load multiple mapTiles, scroll them around to center the user'
#view. Create enough tiles to fill the map and then set them to load data

#TODO: may check this object's W/H instead of the viewports? Alter view size?
#or is that better served as a separate thing?

@onready var camera : Camera2D = $Camera2D
var startX = 0
var startY = 0
@export var refreshTiles = false #TODO: test if this can/must be set before adding the node to the tree

func _unhandled_input(event):
	return #ignoring this for now.
	if event is InputEventScreenTouch and event.is_pressed() == true:
		print(event.position) #Screen coordinates. 0,0 is top left.
		get_viewport().set_input_as_handled()
		
		var size = get_viewport_rect().size
		#TODO: numbers here may need shifted later to match scroll offsets.
		#TODO: this is grabbing from anchor, needs to get tile relative to center offset.
		var innerX =  floor((int(event.position.x) - (size.x / 2)) / PraxisCore.mapTileWidth) # - position.x
		var innerY =  floor((int(event.position.y) - (size.y / 2))  / PraxisCore.mapTileHeight) #- position.y
		
		var subX =  int(event.position.x) % PraxisCore.mapTileWidth # - position.x
		var subY =  int(event.position.y) % PraxisCore.mapTileHeight #- position.y
		
		var innerNode = get_node("mapTile_" + str(innerX) + "_" + str(innerY))
		var tappedCode = innerNode.getTappedCode(subX, subY)

# Called when the node enters the scene tree for the first time.
func _ready():
	var mapTileScene = preload("res://PraxisMapper/Controls/MapTile.tscn")
	var size = get_viewport_rect().size
	
	#godot default anchor is top-left.
	#PlusCode anchors are bottom-left, so there's a little work in mapping them together nicely.
	
	#5x7 tiles for a 1080p screen.
	var tilesX = ceil(size.x / PraxisCore.mapTileWidth) + 1
	var tilesY = ceil(size.y / PraxisCore.mapTileHeight) + 1
	
	if (int(tilesX) % 2 == 0):
		tilesX += 1
	if (int(tilesY) % 2 == 0):
		tilesY += 1
	
	startX = -size.x /2 + (PraxisCore.mapTileWidth / 2)
	startY = -size.y /2 + (PraxisCore.mapTileHeight / 2)
	
	for x in range(tilesX / -2, (tilesX /2) + 1):
		for y in range(tilesY / -2, (tilesY / 2) + 1):
			var tile = mapTileScene.instantiate()
			tile.name = "mapTile_" + str(x) + "_" + str(y)
			tile.autoRefresh = refreshTiles
			add_child(tile)
			tile.xOffset = x
			tile.yOffset = y
			tile.position.x = x * PraxisCore.mapTileWidth + x + x
			tile.position.y = -y * PraxisCore.mapTileHeight - y -y
			PraxisCore.plusCode_changed.connect(tile.OnPlusCodeChanged)
			tile.GetTile(PraxisCore.currentPlusCode)
			
	camera.position.x = startX
	camera.position.y = startY
	
	PraxisCore.plusCode_changed.connect(CameraScroll)
	CameraScroll(PraxisCore.currentPlusCode, "")

func CameraScroll(currentPlusCode, previousPlusCode):
	print("scrolling camera to " + currentPlusCode)
	currentPlusCode = PlusCodes.RemovePlus(currentPlusCode)
	var currentXPos = currentPlusCode.substr(9,1)
	var xIndex = PlusCodes.CODE_ALPHABET_.find(currentXPos)
	var xShift = (PraxisCore.mapTileWidth / 2) -  (PraxisCore.mapTileWidth / 20) * xIndex
	var currentYPos = currentPlusCode.substr(8,1)
	var yIndex = PlusCodes.CODE_ALPHABET_.find(currentYPos)
	var yShift = (PraxisCore.mapTileHeight / 2) - (PraxisCore.mapTileHeight / 20) * yIndex
	
	print("current pos:" + currentXPos + "," + currentYPos)
	
	camera.position.x = startX - xShift
	camera.position.y = startY + yShift
