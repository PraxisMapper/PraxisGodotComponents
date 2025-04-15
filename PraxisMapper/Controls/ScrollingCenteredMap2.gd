extends Control
#Version 2 of the scrolling centered map control
#Differences:
# - This version centers itself, so you do not need to adjust it from the upper left corner
# - This version can have its size in tiles set externally, and it will scale appropriate
# - This version can be given a width and adjust the grid automatically if grid is set to -1
# - This version includes the player indicator arrow
# - This version can toggle the celltrackerdrawers and create those as well.
# - This version includes built-in zoom options. The controls for those can be connected via signals.
# - This version can call a function that return what object to track on the map automatically

#TODO: size may need to be + 3 to ensure the area is covered entirely instead of +1. Might be more complex?
#TODO: extreme zoom out (<0.25) reveals that positioning for player and child nodes are SLIGHTLY OFF when padding is > 0

#TODO: zooming changes the position of something after the first setup. The arrow is slighlty misaligned
#after zooming, so something's getting in an alternate position and not being corrected on later runs.
#But what? it always calls setup on zoom, so what's not getting reset?
#Doesn't seem to duplicate on PMLogistics game, so do I need to re-check taht everything copied over?
#Or that its map scene does something else?

# documentation on tracking:
# Autotracking requires a Node2D object with a meta property of "location"
# manual tracking passes in a string for the location. 

var cellTrackerDrawerPL = preload("res://PraxisMapper/Controls/CellTrackerDrawer.tscn")

## If true, will also create CellTrackerDrawers for each tile that can have their visiblity set by showCellTrackers
@export var useCellTrackers = true
## If true, and useCellTrackers is true, displays the CellTrackerDrawers overtop each tile. Toggle this to hide them.
@export var showCellTrackers = true
## How many map tiles to use in this grid. 3 is the expected minimum. Use -1 to have this control auto-determine the size based on the control's size
@export var tileGridSize = -1
## How many pixels to leave between tiles. 0 has them touching.
@export var spacing = 0
#TODO: may need to be passed in specific CellTracker object to draw?
## If true, displays an arrow showing the location and direction of the player
@export var showPlayerArrow = true
## if true, child nodes the map tracks will be scaled to match the map size.
@export var scaleAttachedChildren = true
## if true, pulls map data from the defined server automatically when tiles enter range.
@export var autoGetMapData = true
## if true, merge the outline overlay on the tiles
@export var ShowTileOverlay = false
## if true, merge the cell overlay on the tiles
@export var ShowCellsOverlay = false

## What scaling factors are available to the player. Must be in order from smallest to largest.
@export var zoomFactors = [0.25, 0.5, 1.0, 1.5, 2.0]
## The starting zoom factor. Must be one of the values in zoomFactors.
@export var zoomFactor = 1.0

#This should let the map handle loading/unloading nodes automatically.
## the Callable to pass the current plus code and tile grid size to find what to place on each map tile. 
## Must return an array of Nodes, and each much have a meta property 'location' set to a Cell10.
var loadTrackables = null
var currentlyTracked = {}

## If true, the map calls queue_free on trackable when changing map tiles. If false, they are only removed from the tree.
@export var freeRemovedTrackables = true

var lastPlusCode = '' #Might be replaceable with odl in the change call
var currentOffset = Vector2(0,0) #Pixels offset for scrolling purposes, referenced by other controls
var plusCodeBase = '22334455+2X' #The plusCode used for the upper-left corner of the area and referenced by other

var noiseTile = preload("res://PraxisMapper/Resources/noisetile.png")
#This is actually the ADJUSTMENT to center the controls. Not the literal center.
var controlCenter = Vector2(0,0)

func _ready():
	$Center.visible = false
	Setup()
	$playerIndicator.visible = showPlayerArrow
	$centerIndicator.visible = false
	$TileDrawerQueued.tile_created.connect(UpdateTexture)
	PraxisCore.plusCode_changed.connect(plusCode_changed)
	plusCode_changed(PraxisCore.currentPlusCode, PraxisCore.lastPlusCode)
	
func ToggleShowCellTrackerDrawers():
	showCellTrackers = !showCellTrackers
	if (showCellTrackers):
		RefreshTiles(PraxisCore.currentPlusCode)
	$cellTrackerDrawers.visible = showCellTrackers

func _process(delta):
	$playerIndicator.rotation = PraxisCore.GetCompassHeading() # Default behavior
	#$playerIndicator.rotation += .01 #helps when testing player positioning by spinning the arrow
	
func Setup():
	#Do all the one-time stuff here. Clear out child objects just in case we're changing after _ready()
	for c in $mapBase.get_children():
		$mapBase.remove_child(c)
	for c in $cellTrackerDrawers.get_children():
		$cellTrackerDrawers.remove_child(c)
	
	if tileGridSize <= 0:
		#auto-determine size
		print("auto-pick size based on: " + str(size))
		var gridSize = max(size.x / 320 / zoomFactor, size.y / 500 / zoomFactor) 
		if (gridSize > int(gridSize) or gridSize == 0): #check for any remainder 
			gridSize = int(gridSize) + 1 #scale up to whole tile, then add 2 for coverage
		if gridSize < 3:
			gridSize = 3
		print("Size is " + str(gridSize))
		tileGridSize = gridSize
	
	#Create all tiles
	for x in tileGridSize:
		for y in range(tileGridSize -1, -1, -1):
			#create the new tile
			var newTile = TextureRect.new()
			newTile.scale = Vector2(zoomFactor, zoomFactor)
			newTile.anchor_left = 1
			newTile.anchor_right = 0
			newTile.anchor_top = 1
			newTile.anchor_bottom = 0
			#This was set to use update() later, but performance wise it seems the same. At least on PC.
			#newTile.texture = ImageTexture.create_from_image(Image.load_from_file("res://PraxisMapper/Resources/grid template.png")) #setting this NOW so we can update it later.
			newTile.set_name("MapTile" + str(x) + "_" + str(y))
			newTile.position = Vector2(x * 320 * zoomFactor + (x * spacing), y * 500 * zoomFactor + (y * spacing))
			$mapBase.add_child(newTile)
			print(newTile.name + " at " + str(newTile.position) + " / " +str(newTile.global_position))
			
			if (useCellTrackers):
				var newCellTracker = cellTrackerDrawerPL.instantiate()
				newCellTracker.set_name("CTD" + str(x) + "_" + str(y))
				newCellTracker.scale = Vector2(16,25) * Vector2(zoomFactor, zoomFactor) #defaults to a 20x20px square, scale this to match tiles.
				newCellTracker.position = Vector2(x * 320 * zoomFactor + (x * spacing), y * 500 * zoomFactor + (y * spacing))
				$cellTrackerDrawers.add_child(newCellTracker)
	
	var expectedCenter = size / 2 * zoomFactor# The pixel we shows to the developer was the center.
	
	#Transform steps:
	#1: Get the base global position for mapBase
	#2: Identify the center of the map tiles (in global coordinates)
	#3: Identify the displayed, intended center of the map as global coordinates
	#4: Shift mapBase enough to make mapCenter = visibleCenter
	$mapBase.position = Vector2(0,0)
	var startingPoint = $mapBase.global_position
	print(startingPoint)
	var mapCenter = startingPoint + Vector2(tileGridSize * 160 * zoomFactor, tileGridSize * 250 * zoomFactor)
	print("center is at " + str(mapCenter))
	var visibleCenter = $Center.global_position
	print("center SHOULD MOVE TO " + str(visibleCenter))
	var shift = visibleCenter - mapCenter
	
	if int(tileGridSize) % 2 == 0:
		shift -= Vector2(160 * zoomFactor, 250 * zoomFactor)
	print(shift)
	controlCenter = shift

	$mapBase.position = controlCenter
	$cellTrackerDrawers.position = controlCenter #Vector2(tileGridSize * 180, tileGridSize * 200)
	
	#The actual visibleCenter position is correct for the lower-left corner of that plus code.
	$playerIndicator.rotation = 0
	$playerIndicator.global_position = visibleCenter + Vector2(0, -25 * zoomFactor) # Is 1 cell too far south without adjustment
	$playerIndicator.z_index = 2
	$playerIndicator.scale = Vector2(zoomFactor, zoomFactor)
	
	#print("Arrow at "  + str($playerIndicator.global_position))
	
	RefreshTiles(PraxisCore.currentPlusCode) 

func AdjustBanner(positionVec2, sizeVec2):
	#this is for the dev to reposition the drawing/downloading banners on the map.
	#TODO: finish testing this.
	$TileDrawerQueued/Banner.global_position = positionVec2
	$TileDrawerQueued/Banner/ColorRect.size = sizeVec2
	$TileDrawerQueued/Banner/Status.size = sizeVec2
	$TileDrawerQueued/Banner/Status.set("theme_override_font_sizes/font_size", sizeVec2.y * 0.8)
	
	$GetFile/Banner.global_position = positionVec2
	$GetFile/Banner/ColorRect.size = sizeVec2
	$GetFile/Banner/Label.size = sizeVec2
	$GetFile/Banner/Label.set("theme_override_font_sizes/font_size", sizeVec2.y * 0.8)

func plusCode_changed(current, old):
	if !visible:
		return
	
	#find the center/current tile's cell tracker drawer and update it
	if (useCellTrackers and showCellTrackers):
		var tileDist = PlusCodes.GetDistanceCell8s(current, plusCodeBase)
		var ctdNode = get_node("cellTrackerDrawers/CTD" + str(int(tileDist.x)) + "_" + str(abs(int(tileDist.y))))
		if ctdNode != null:
			ctdNode.DrawCellTracker($CellTracker, current)
	
	if autoGetMapData:
		var baseCell = current.substr(0,6)
		var cellsToLoad = PlusCodes.GetNearbyCells(baseCell, 1)
		for c2l in cellsToLoad:
			if !PraxisOfflineData.OfflineDataExists(c2l):
				print("Getting new map file")
				$GetFile.AddToQueue(c2l)

	if current.substr(0,8) != lastPlusCode.substr(0,8):
		await RefreshTiles(current)

	#Now scroll mapBase to the right spot.
	var currentXPos = PlusCodes.RemovePlus(current).substr(9,1)
	var xIndex = PlusCodes.CODE_ALPHABET_.find(currentXPos)
	var xShift = (PraxisCore.mapTileWidth / 2) -  (PraxisCore.mapTileWidth / 20) * xIndex #* zoomFactor
	var currentYPos = PlusCodes.RemovePlus(current).substr(8,1)
	var yIndex = PlusCodes.CODE_ALPHABET_.find(currentYPos)
	var yShift = (PraxisCore.mapTileHeight / 2) - (PraxisCore.mapTileHeight / 20) * yIndex #* zoomFactor
	
	#THis doenst do anything right now
	#if PlusCodes.RemovePlus(current).length() == 11:
		#var lastIndex = PlusCodes.CODE_ALPHABET_.find(PlusCodes.RemovePlus(current).substr(10,1))
		#xShift += lastIndex % 4
		#yShift += lastIndex / 4
		
	currentOffset = Vector2(xShift, -yShift) #How many pixels to move in each direction
	var shifting = currentOffset * Vector2(zoomFactor, zoomFactor)
	$mapBase.position = controlCenter + shifting
	$cellTrackerDrawers.position = controlCenter + shifting
	$trackedChildren.position = $mapBase.position
	
	lastPlusCode = current

func getDrawingOffset(plusCode):
	#TODO: is still off by a small amount at very high zoom levels (< .25) if padding > 0
	var offset = PlusCodes.GetDistanceCell10s(plusCode, plusCodeBase)
	#First vector converts to Cell12 pixels, 2nd accommodates zoom
	return offset * Vector2(16,-25) * Vector2(zoomFactor, zoomFactor)
	
func trackChildOnMap(node, plusCodePosition):
	if (plusCodePosition == null):
		return
	node.set_meta("location", plusCodePosition)
	UpdateChildNode(node)
	$trackedChildren.add_child(node)

func clearAllTrackedChildren():
	for tc in $trackedChildren.get_children():
		if freeRemovedTrackables == true:
			tc.queue_free()
		else:
			$trackedChildren.remove_child(tc)

func RefreshTiles(current):
	var baseShift = int(tileGridSize / 2)
	if current == null:
		current = PraxisCore.currentPlusCode
	plusCodeBase = PlusCodes.ShiftCode(current.substr(0,8), -baseShift, baseShift) + "X2" #correct

	var base = plusCodeBase.substr(0,8) #current.substr(0,8)
	var node
	var tex
	var textures = {}
	#NEW: to try to minimize disruptions, we're gonna draw missing tiles first.
	#THen update the visible display.
	for x in tileGridSize:
		#print("x row " + str(x))
		textures[x] = {}
		for y in tileGridSize:
			var checkCode = PlusCodes.ShiftCode(base, x, -y)
			#print("Checking code " + checkCode)
			if useCellTrackers and showCellTrackers:
				node = get_node("cellTrackerDrawers/CTD" + str(x) + "_" + str(y))
				node.DrawCellTracker($CellTracker, checkCode)
				
			node = get_node("mapBase/MapTile" + str(x) + "_" + str(y))
			if FileAccess.file_exists("user://MapTiles/" + checkCode + ".png"):
				tex = await $TileDrawerQueued.GetAndProcessData(checkCode, 1)
				node.texture = ImageTexture.create_from_image(tex) #update might be faster? Doesnt seem like it in testing.
			else:
				node.texture = noiseTile
				$TileDrawerQueued.AddToQueue(checkCode)
	
	if ShowCellsOverlay or ShowTileOverlay:
		DebugDraw()
	
	if loadTrackables != null: #Automatic tracking. May not be the most optimized behavior but should work
		clearAllTrackedChildren()
		var newTrackables = loadTrackables.call(base, tileGridSize)
		for newnode in newTrackables:
			trackChildOnMap(newnode, newnode.get_meta("location"))
	else: #manual tracking
		for child in $trackedChildren.get_children():
			UpdateChildNode(child)

#This is not intended to be a full API, but an example of how you'd check on tap
#to find which child should respond.
func GetNearestTrackedChild(event: InputEventMouseButton):
	if !event.pressed:
		return null
	
	var closestNode = null
	var closestDist = 9999999999
	
	for node in $trackedChildren.get_children():
		var dist = event.position.distance_to(node.global_position)
		if dist < closestDist:
			closestDist = dist
			closestNode = node
	return closestNode

func zoomOut():
	var zoomIdx = zoomFactors.find(zoomFactor)
	if zoomIdx == 0:
		return
	ChangeZoom(zoomFactors[zoomIdx -1])

func zoomIn():
	var zoomIdx = zoomFactors.find(zoomFactor)
	if zoomIdx >= zoomFactors.size() - 1:
		return
	ChangeZoom(zoomFactors[zoomIdx + 1])

func ChangeZoom(newZoomFactor):
	zoomFactor = newZoomFactor
	tileGridSize = -1
	Setup()
	plusCode_changed(PraxisCore.currentPlusCode, PraxisCore.lastPlusCode)

func DebugDraw():
	for child in $mapBase.get_children():
		var tex = child.get_texture().get_image()
		if ShowTileOverlay:
			var img1: Image = load("res://PraxisMapper/Resources/mapTileOutline.png").get_image()
			tex.blend_rect(img1, Rect2i(0, 0, 320, 500), Vector2i(0, 0))
		if ShowCellsOverlay:
			var img2: Image = load("res://PraxisMapper/Resources/mapTileCells.png").get_image()
			tex.blend_rect(img2, Rect2i(0, 0, 320, 500), Vector2i(0, 0))
		child.texture = ImageTexture.create_from_image(tex)

func UpdateChildNode(child):
	var offset = getDrawingOffset(child.get_meta("location", ""))
	child.position = offset
	if scaleAttachedChildren == true:
		child.scale = Vector2(zoomFactor, zoomFactor) 

func UpdateTexture(code, texture):
	var center = PraxisCore.currentPlusCode #lastPlusCode
	var coords = PlusCodes.GetDistanceCell8s(code, plusCodeBase) 
	var addendum = str(int(coords.x)) + "_" + str(abs(int(coords.y))) #TODO: sometimes has 3 in the x coords, which fails.
	var tilenode = get_node("mapBase/MapTile" + addendum)
	if (tilenode != null):
		tilenode.texture = ImageTexture.create_from_image(texture) #update might be faster?
	else:
		print("couldnt get node for tile at " + addendum)

#TODO: This may need to be done with call_deferred for safety?
#This allows for an external CellTracker to be assigned to this map
func SetCellTracker(newTracker):
	$CellTracker.set_name("old")
	$CellTracker.queue_free()
	newTracker.set_name("CellTracker")
	add_child(newTracker)

func SetLoadableSource(callable):
	loadTrackables = callable
	RefreshTiles(PraxisCore.currentPlusCode)
