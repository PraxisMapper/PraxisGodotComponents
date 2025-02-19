extends Control
#Version 2 of the scrolling centered map control
#Differences:
# - This version centers itself, so you do not need to adjust it from the upper left corner
# - This version can have its size in tiles set externally, and it will scale appropriate
# - This version can be given a width and adjust the grid automatically if grid is set to -1
# - This version includes the player indicator arrow
# - This version can toggle the celltrackerdrawers and create those as well. IMPLEMENT/TEST
# - This version includes built-in zoom options. The controls for those can be connected via signals. IMPLEMENT/TEST

#TODO: this should use the queued tile drawer, not the normal one.

#TODO: set up whatever special logic is needed for grids of size 1 and 2
#--For 2 and even grids, where the current plus code is the center of 4 tiles, I probably
#want to make the 'current' cell8 tile be the lower-left one? You'll always have that tile on screen for sure.

var cellTrackerDrawerPL = preload("res://PraxisMapper/Controls/CellTrackerDrawer.tscn")

## If true, will also create CellTrackerDrawers for each tile that can have their visiblity set by showCellTrackers
@export var useCellTrackers = false
## If true, and useCellTrackers is true, displays the CellTrackerDrawers overtop each tile
@export var showCellTrackers = false
## How many map tiles to use in this grid. 3 is the expected minimum. Use -1 to have this control auto-determine the size based on the control's size
@export var tileGridSize = -1
#TODO: may need to be passed in specific CellTracker object to draw?
## If true, displays an arrow showing the location and direction of the player
@export var showPlayerArrow = true

@export var zoomFactor = 1.0

var process = true
var lastPlusCode = '' #Might be replaceable with odl in the change call
var currentOffset = Vector2(0,0) #Pixels offset for scrolling purposes, referenced by other controls
var plusCodeBase = '22334455+2X' #The plusCode used for the upper-left corner of the area and referenced by other

#This is actually the ADJUSTMENT to center the controls. Not the literal center.
var controlCenter = Vector2(0,0)

func _ready():
	Setup()
	$playerIndicator.visible = showPlayerArrow
	$centerIndicator.visible = false
	plusCode_changed(PraxisCore.currentPlusCode, PraxisCore.lastPlusCode)
	$TileDrawer.tile_created.connect(UpdateTexture)

func _process(delta):
	$playerIndicator.rotation = PraxisCore.GetCompassHeading()
	
func Setup():
	#Do all the one-time stuff here. Clear out child objects just in case we're changing after _ready()
	for c in $mapBase.get_children():
		$mapBase.remove_child(c)
	for c in $cellTrackerDrawers.get_children():
		$cellTrackerDrawers.remove_child(c)
	
	if tileGridSize <= 0:
		#auto-determine size
		print("auto-pick size based on: " + str(size))
		var gridSize = max(size.x / 320, size.y / 500) 
		if (gridSize > int(gridSize) or gridSize == 0): #check for any remainder 
			gridSize = int(gridSize) + 1 #scale up to whole tile.
		print("Size is " + str(gridSize))
		tileGridSize = gridSize
	
	#Create all tiles
	for x in tileGridSize:
		#for y in tileGridSize:
		for y in range(tileGridSize, -1, -1):
			#create the new tile
			var newTile = TextureRect.new()
			newTile.scale = Vector2(zoomFactor, zoomFactor)
			newTile.anchor_left = 1
			newTile.anchor_right = 0
			newTile.anchor_top = 1
			newTile.anchor_bottom = 0
			print(newTile.offset_left)
			newTile.set_name("MapTile" + str(x) + "_" + str(y))
			#newTile.position = Vector2(x * 320 * zoomFactor, (tileGridSize * 500) - (y+1) * 500 * zoomFactor) #this looks closer but still isnt right?
			newTile.position = Vector2(x * 320 * zoomFactor + x, y * 500 * zoomFactor + y)
			print(newTile.name + " at " + str(newTile.position))
			$mapBase.add_child(newTile)
			print(newTile.name + " at " + str(newTile.position) + " / " +str(newTile.global_position))
			
			if (useCellTrackers):
				var newCellTracker = cellTrackerDrawerPL.instantiate()
				newCellTracker.set_name("CTD" + str(x) + "_" + str(y))
				newCellTracker.scale = Vector2(16,25) #defaults to a 20x20px square.
				 #TODO: will need to fix this to be the same Y position logic above.
				newCellTracker.position = Vector2(x * 320 * zoomFactor, y * 500 * zoomFactor)
				$cellTrackerDrawers.add_child(newCellTracker)
	
	#var mapCenter = Vector2(tileGridSize * 160, tileGridSize * 250)
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
	print(shift)
	controlCenter = shift

	$mapBase.position = controlCenter
	$cellTrackerDrawers.position = controlCenter #Vector2(tileGridSize * 180, tileGridSize * 200)
	
	$playerIndicator.global_position = visibleCenter + Vector2(16, -20)
	$playerIndicator.z_index = 2
	RefreshTiles(PraxisCore.currentPlusCode) 

func plusCode_changed(current, old):
	if process == false:
		print("skipping a process run, busy.")
		return

	if !visible:
		return
	
	#var cur = PlusCodes.RemovePlus(current) # stack overflows? why?
	process = false #Block this from being called again while we run.
	if current.substr(0,8) != lastPlusCode.substr(0,8): # old.substr(0,8):
		#process = false
		await RefreshTiles(current)
		var children = $trackedChildren.get_children()
		for c in children:
			var offset = getDrawingOffset(c.get_meta("originalLocation", ""))
			if offset != null:
				c.position = offset

	#Now scroll mapBase to the right spot.
	var currentXPos = PlusCodes.RemovePlus(current).substr(9,1)
	var xIndex = PlusCodes.CODE_ALPHABET_.find(currentXPos)
	var xShift = (PraxisCore.mapTileWidth / 2) -  (PraxisCore.mapTileWidth / 20) * xIndex #* zoomFactor
	var currentYPos = PlusCodes.RemovePlus(current).substr(8,1)
	var yIndex = PlusCodes.CODE_ALPHABET_.find(currentYPos)
	var yShift = (PraxisCore.mapTileHeight / 2) - (PraxisCore.mapTileHeight / 20) * yIndex #* zoomFactor
	
	if PlusCodes.RemovePlus(current).length() == 11:
		var lastIndex = PlusCodes.CODE_ALPHABET_.find(PlusCodes.RemovePlus(current).substr(10,1))
		xShift += lastIndex % 4
		yShift += lastIndex / 4
	
	#print("current pos:" + currentXPos + "," + currentYPos)
	
	#print($trackedChildren.get_children().size())
	
	currentOffset = Vector2(xShift, -yShift) #How many pixels to move in each direction
	print(currentOffset)
	var shifting = currentOffset * Vector2(zoomFactor, zoomFactor)
	print("Shifting mapBase pixels: " + str(shifting))
	$mapBase.position = controlCenter + shifting
	$trackedChildren.position = $mapBase.position - position #works but doesnt feel right for some reason.
	
	
	lastPlusCode = current
	if process == false:
		process = true
		if current != PraxisCore.currentPlusCode:
			print("refreshing scrolling centered map after process run")
			plusCode_changed(PraxisCore.currentPlusCode, lastPlusCode)

func getDrawingOffset(plusCode):
	var offset = PlusCodes.GetDistanceCell10s(plusCodeBase, plusCode)
	#First vector converts to Cell12 pixels, 2nd accommodates non-origin position of map
	return offset * Vector2(-16,25) * Vector2(zoomFactor, zoomFactor) + position  #TODO: may need updated to handle grid no longer having negative entries
	
	#Dont move the map for Cell11s right now.
	#if PlusCodes.RemovePlus(plusCode).length == 11:
		#var charVal = PlusCodes.GetLetterIndex(plusCode.right(1))
		#offset += Vector2(charVal % 4, charVal / 4)
	#else:
		#centers item in cell10 instead of lower-left corner
		#offset += Vector2(8, 13)
	
func trackChildOnMap(node, plusCodePosition):
	if (plusCodePosition == null):
		return
	var offset = getDrawingOffset(plusCodePosition)
	node.position = offset
	node.set_meta("originalLocation", plusCodePosition)
	$trackedChildren.add_child(node)

func clearAllTrackedChildren():
	for tc in $trackedChildren.get_children():
		tc.queue_free()

func RefreshTiles(current):
	#ISSUE 4: Tiles aren't in the center of the control (this needs fixed in Setup)
	var baseShift = int(tileGridSize / 2)
	print("shifting " + str(baseShift) + " from grid size " + str(tileGridSize))
	if current == null:
		current = PraxisCore.currentPlusCode
	plusCodeBase = PlusCodes.ShiftCode(current.substr(0,8), -baseShift, baseShift) + "X2" #correct
	var base = plusCodeBase.substr(0,8) #current.substr(0,8)
	var node
	var code
	var tex
	var textures = {}
	#NEW: to try to minimize disruptions, we're gonna draw missing tiles first.
	#THen update the visible display.
	for x in tileGridSize:
		print("x row " + str(x))
		textures[x] = {}
		for y in tileGridSize:
			var checkCode = PlusCodes.ShiftCode(base, x, -y) #y #what is wrong with this math
			#print("Checking code " + checkCode)
			#if !FileAccess.file_exists("user://MapTiles/" + checkCode + ".png"):
			tex = await $TileDrawer.GetAndProcessData(checkCode, 1)
				#node = get_node("mapBase/MapTile" + str(x) + str(y))
				#node.texture = ImageTexture.create_from_image(tex) #update might be faster?
			textures[x][y] = tex #await $TileDrawer.tile_created
			#else:
				#$TileDrawer.AddToQueue(checkCode)
			
			#code = PlusCodes.ShiftCode(base, x, y)
			
	for x in tileGridSize:
		for y in tileGridSize:
		#for y in range(tileGridSize-1, -1, -1):
			var t = textures[x][y]
			if t != null:
				node = get_node("mapBase/MapTile" + str(x) + "_" + str(y))
				node.texture = ImageTexture.create_from_image(t) #update might be faster?

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

var zoomFactors = [0.5, 1.0, 1.5, 2.0]

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
	Setup()
	plusCode_changed(PraxisCore.currentPlusCode, PraxisCore.lastPlusCode)
	#TODO: OK, changing zoom does NOT mean the center changed. That value stays the same.
	#BUT we need to move all the tile components to stay touching or else 
	#zoomFactor is a multiplier, so zooming IN means the number is bigger to make tiles bigger
	#and zooming OUT means the number is smaller to make tiles smaller.
	#HMM: do I want to draw more tiles if we zoom out? That might be a later step in figuring this out.
	#actually, that wasn't too hard to get the map layer set. Now I need to figure out how to reposition
	#it correctly to match the map size.
	

func UpdateTexture(code, texture):
	var center = PraxisCore.currentPlusCode #lastPlusCode
	var coords = PlusCodes.GetDistanceCell8s(code, center) 
	var addendum = str(int(coords.x)) + str(int(coords.y)) #TODO: sometimes has 3 in the x coords, which fails.
	var tilenode = get_node("mapBase/MapTile" + addendum)
	if (tilenode != null):
		tilenode.texture = ImageTexture.create_from_image(texture) #update might be faster?
	else:
		print("couldnt get node for tile at " + addendum)

func DrawGrid():
	pass
	#TODO: Overlay a grid to help indicate Cell10s on each tile. Maybe Cell8s as an option?
