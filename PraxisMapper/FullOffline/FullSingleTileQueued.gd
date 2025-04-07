extends Node2D
class_name SingleTileQueued

#Single Cell8 drawing from Cell6 data. 
#Should not be so slow as to need user status displays.
#Should not need multiple tiles for full-detail data, since it can be
#checked directly now.

#TODO: should probably use a semaphor to do this properly on a background thread,
#as long as a background thread can create/save images.

signal tile_created(code, texture)

var plusCode6 = ""
var scaleVal = 1
var mapData
var busy = false
var tilesToDraw = []

@export var drawnStyle = "mapTiles"
@export var makeMapTile = true
@export var alwaysDrawNewTile = false

func AddToQueue(code):
	if !tilesToDraw.has(code):
		tilesToDraw.push_back(code)
		if (!busy):
			await RunQueue()
		else:
			print("queue is busy, not running")
		
#TODO: if this doesnt work, look at using Mutex or Semaphore instead
#Semaphore might not work since we're a Node and not necessarily different threads.
func RunQueue():
	#print("Running queue")
	busy = true
	while tilesToDraw.size() > 0:
		$Banner.visible = true
		#print("tiles queued:" + str(tilesToDraw.size()))
		var tile = tilesToDraw.pop_back()
		#print("popped " + tile)
		var img = await GetAndProcessData(tile)
		tile_created.emit(tile, img)
	#print("Queue complete")
	busy = false
	

#Get a Cell8 PlusCode, draw just that tile.
func GetAndProcessData(plusCode, scale = 1):
	#save some time
	if FileAccess.file_exists("user://MapTiles/" + plusCode + ".png") and !alwaysDrawNewTile:
		var fileForSize = FileAccess.open("user://MapTiles/" + plusCode + ".png", FileAccess.READ)
		if !fileForSize.get_length() <= 1539: #magic number that lines up to a blank image.
			var img = await Image.load_from_file("user://MapTiles/" + plusCode + ".png")
			#tile_created.emit(plusCode, img)
			fileForSize.close()
			#print("emitted existing file for " + plusCode)
			return img #ImageTexture.create_from_image(img)
		fileForSize.close()
	
	var oneTile = null
	$Banner.visible = true
	#print("banner shown, at " + str($Banner.global_position))
	$Banner/Status.text = "Drawing " + plusCode.substr(0,8)
	#print("processing full offline data for single tile " + plusCode)
	plusCode6 = plusCode.substr(0,6)
	if (plusCode.length() >= 8):
		oneTile = plusCode.substr(6,2)
	scaleVal = scale
	#also seeing if this can be removed.  SEEMS SAFE TO REMOVE.
	#await RenderingServer.frame_post_draw
	
	var styleData = await PraxisCore.GetStyle(drawnStyle)
	$svc/SubViewport/fullMap.style = styleData
	
	mapData = await PraxisOfflineData.GetDataFromZip(plusCode6) 
	if (mapData == null):
		$Banner.visible = false
		return
		
	#$Banner/lblStatus.text = "Data Loaded. Processing " + str(mapData.entries["mapTiles"].size()) + " items, please wait...." 
	#And lets test removing this one too. SEEMS OK.
	#await RenderingServer.frame_post_draw
	#Game is probably going to freeze for a couple seconds here while Godot draws stuff to the node

	#print("being tile making")
	var tex = await CreateTile(oneTile) #Godot runs slow while this does work and waits for frames.
	$Banner.visible = false
	#tile_created.emit(plusCode, tex)
	return tex
	
func CreateTile(oneTile = null):
	if mapData == null:
		print("no map data, abort create tile.")
		return
		
	#print("CreateTileCalled")
	$svc/SubViewport/fullMap.position.y = 0
	
	var viewport1 = $svc/SubViewport
	var camera1 = $svc/SubViewport/subcam
	var scale = scaleVal
	
	#print("cameras set")
	camera1.position = Vector2(0,0)
	viewport1.size = Vector2i(320 * scale, 500 * scale)
	#print("viewports set")
	
	#while im here, re-testing if this wait is necessary. SEEMS SAFE TO LEAVE OUT.
	#await RenderingServer.frame_post_draw #set this before loading entities, skips a wasted draw call.
	#print("frame waited")
	
	if makeMapTile == true:
		#print("drawing map (single)")
		await $svc/SubViewport/fullMap.DrawSingleTile(mapData.entries["mapTiles"], scaleVal, plusCode6 + oneTile)
	
	var xList = PlusCodes.CODE_ALPHABET_
	var yList = PlusCodes.CODE_ALPHABET_
	
	if (oneTile != null):
		xList = oneTile[1]
		yList = oneTile[0]

	var tex1
	var img1
	for yChar in yList:
		#This kept complaining about can't - a Vector2 and an Int so I had to do this.
		var yPos = ((PlusCodes.CODE_ALPHABET_.find(yChar) +1) * 500 * scale)
		camera1.position.y = -yPos #(500 * 20 * scale) - yPos

		for xChar in xList:
			camera1.position.x = (PlusCodes.CODE_ALPHABET_.find(xChar) * 320 * scale)
			#This one is critical, cannot remove this wait.
			await RenderingServer.frame_post_draw
			if makeMapTile == true:
				tex1 = await viewport1.get_texture()
				img1 = await tex1.get_image() # Get rendered image
				img1.convert(Image.FORMAT_RGBA8)
				if !alwaysDrawNewTile: #If you always want the tile redrawn, why save it?
					await img1.save_png("user://MapTiles/" + plusCode6 + yChar + xChar + ".png") # Save to disk
				#Also testing removing this one. SEEMS SAFE TO LEAVE OUT
				#await RenderingServer.frame_post_draw
	#tile_created.emit(img1) #WSC fired this here.
	
	#print("image done")
	return img1
