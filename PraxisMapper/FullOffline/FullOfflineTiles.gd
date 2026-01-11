extends Node2D
class_name OfflineDataV3

#This is the refined version of drawing offline data. This will display status to
#the user on-screen (with toggle to display or not), use toggles to determine which 
#tiles are drawn, and indicate via on-screen banner what the current status is on image
#drawing progress (drawing tile, saving tiles by code, etc)
#This will also assume the data is already present for now, and skip downloading it from
#a server.

signal style_saved()
signal style_ready()
signal data_saved()
signal data_ready()
signal tiles_saved()

signal tile_created(texture)

var plusCode6 = ""
var scaleVal = 1
var mapData

@export var drawnStyle = "mapTiles"
@export var makeThumbnail = false
@export var thumbnailScale = 0.08

func GetAndProcessData(plusCode, scale = 1):
	var oneTile = null
	$Banner.visible = true
	$Banner/lblStatus.text = "Preparing to draw...."
	print("processing full offline data")
	plusCode6 = plusCode.substr(0,6)
	if (plusCode.length() == 8):
		oneTile = plusCode.substr(6,2)
	scaleVal = scale
	await RenderingServer.frame_post_draw
	
	$Banner/lblStatus.text = "Getting Style"
	var styleData = await PraxisCore.GetStyle(drawnStyle)
	$Banner/lblStatus.text = "Style loaded."
	$svc/SubViewport/fullMap.style = styleData
	
	mapData = await PraxisOfflineData.GetDataFromZip(plusCode6) 
	if (mapData == null):
		$Banner/lblStatus.text = "Error getting map data. Try again." 
		return
		
	$Banner/lblStatus.text = "Data Loaded. Processing " + str(mapData.entries["offline"].size()) + " items, please wait...." 
	await RenderingServer.frame_post_draw
	#Game is probably going to freeze for a couple seconds here while Godot draws stuff to the node

	await CreateAllTiles(oneTile) #Godot runs slow while this does work and waits for frames.
	
	if makeThumbnail:
		$svc/SubViewport/fullMap.scale = Vector2((1 / scale) * thumbnailScale, (1 / scale) * thumbnailScale)
		$svc/SubViewport/subcam.position = Vector2(0,-500 * 20 * (1 / scale) * thumbnailScale)
		$svc/SubViewport.size = Vector2i(320 * 20 * (1 / scale) * thumbnailScale, 500 * 20 * (1 / scale) * thumbnailScale)
		print(str($svc/SubViewport.size))
		print(str($svc/SubViewport/subcam.position))
		await RenderingServer.frame_post_draw
		var img = await $svc/SubViewport.get_texture().get_image() # Get rendered image
		await img.save_webp("user://MapTiles/" + plusCode6 + "-" + drawnStyle + "-thumb.webp") # Save to disk
		#NOTE: WebP format is limited to 16k x 16k pixels for a single image on all platforms. 
		#This defaults to 6400 * 10000, so should be savable at full size regardless if I really wanted to.
		print("thumbnail saved")
	
	$Banner/lblStatus.text = "Tiles Drawn for " + plusCode
	await get_tree().create_timer(2).timeout
	var fade_tween = create_tween()
	fade_tween.tween_property($Banner, 'modulate:a', 0.0, 1.0)
	fade_tween.tween_callback($Banner.hide)
	
func CreateAllTiles(oneTile = null):
	#Fullmap at 0, name map at 40k, bounds map at 80k, terrain at 120k
	$svc/SubViewport/fullMap.position.y = 0
	
	var viewport1 = $svc/SubViewport
	var camera1 = $svc/SubViewport/subcam
	var scale = scaleVal
	
	camera1.position = Vector2(0,0)
	viewport1.size = Vector2i(320 * scale, 500 * scale)
	await RenderingServer.frame_post_draw #set this before loading entities, skips a wasted draw call.
	
	$Banner/lblStatus.text = "Drawing " + plusCode6 + "..."
	print("drawing map (full)")
	await $svc/SubViewport/fullMap.DrawOfflineTile(mapData.entries["offline"], scaleVal, plusCode6)
	
	var xList = PlusCodes.CODE_ALPHABET_
	var yList = PlusCodes.CODE_ALPHABET_
	
	if (oneTile != null):
		xList = oneTile[1]
		yList = oneTile[0]

	var threads = []
	var tex1
	for yChar in yList:
		#This kept complaining about can't - a Vector2 and an Int so I had to do this.
		#yPos -= (PlusCodes.CODE_ALPHABET_.find(yChar) * 20 * scale)
		camera1.position.y -= (500 * scale)
			
		for xChar in xList:
			camera1.position.x = (PlusCodes.CODE_ALPHABET_.find(xChar) * 320 * scale)
			await RenderingServer.frame_post_draw
			var start = Time.get_unix_time_from_system()
			tex1 = viewport1.get_texture()
			var img1 = tex1.get_image() # Get rendered image
			img1.save_webp("user://MapTiles/" + plusCode6 + yChar + xChar + "-" + drawnStyle + ".webp") # Save to disk
			var end = Time.get_unix_time_from_system()
			print("tile done in " + str(end-start))
			$Banner/lblStatus.text = "Saved Tiles for " + plusCode6 + yChar + xChar
			tile_created.emit(tex1) #Exclusive logic to this prototype.

	for thread in threads:
		WorkerThreadPool.wait_for_task_completion(thread)
		
	tiles_saved.emit()

func xDownloadFullData(plusCode6):
	#TODO: figure out the URL for these files. Possibly a PraxisMapper URL, possibly just a filehost.
	pass
