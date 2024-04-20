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
#signal nametiles_saved()

var plusCode6 = ""
var scaleVal = 1
var mapData

@export var drawnStyle = "mapTiles"
@export var makeMapTile = true
@export var makeTerrainTile = true
@export var makeNameTile = true
@export var makeBoundsTile = true

func GetAndProcessData(plusCode):
	var oneTile = null
	$Banner.visible = true
	$Banner/lblStatus.text = "Preparing to draw...."
	print("processing full offline data")
	plusCode6 = plusCode.substr(0,6)
	if (plusCode.length() == 8):
		oneTile = plusCode.substr(6,2)
	scaleVal = 1
	await RenderingServer.frame_post_draw
	var styleData = PraxisCore.GetStyle(drawnStyle)
	$svc/SubViewport/fullMap.style = styleData
	$svc2/SubViewport/nameMap.style = styleData
	$svc4/SubViewport/terrainMap.style = styleData
	if makeBoundsTile: #Always uses its own style
		$svc3/SubViewport/boundsMap.style = PraxisCore.GetStyle("adminBoundsFilled")
	
	await GetDataFromZip(plusCode6) 
	print("being tile making")
	await CreateAllTiles(oneTile)
	
	$Banner/lblStatus.text = "Tiles Drawn for " + plusCode
	await get_tree().create_timer(2).timeout
	var fade_tween = create_tween()
	fade_tween.tween_property($Banner, 'modulate:a', 0.0, 1.0)
	fade_tween.tween_callback($Banner.hide)
	
func GetDataFromZip(plusCode):
	#This needs to live nicely with the MinOffline version, and if the game is limited in
	#scope it could use the same source folder. The odds of the game using both built-in are 0.
	#though its possible it could include the minimum format as a fallback and download the full data.
	#Plus its unruly to handle the biggest zipped full-data files at the CEll2 level (8F is 5GB alone)
	#so these will be Cell4s in OfflineData or a downloaded directory TBD
	var code2 = plusCode.substr(0, 2)
	var code4 = plusCode.substr(2, 2)
	var zipReader = ZIPReader.new()
	
	var err = zipReader.open("res://OfflineData/" + code2 + "/" + code2 + code4 + ".zip")
	if (err != OK):
		if FileAccess.file_exists("user://Data/" + code2 + code4 + ".zip"):
			err = zipReader.open("user://Data/" + code2 + code4 + ".zip")
			if err != OK:
				print("No FullOffline data found built-in or downloaded for " + plusCode)
				return 
		
	var rawdata := zipReader.read_file(plusCode + ".json")
	var realData = rawdata.get_string_from_utf8()
	var json = JSON.new()
	json.parse(realData)
	mapData = json.data
	data_ready.emit()
	
func CreateAllTiles(oneTile = null):
	#Fullmap at 0, name map at 40k, bounds map at 80k, terrain at 120k
	print("CreateAllTilesCalled")
	$svc/SubViewport/fullMap.position.y = 0
	$svc2/SubViewport/nameMap.position.y = 40000
	$svc3/SubViewport/boundsMap.position.y = 80000
	$svc4/SubViewport/terrainMap.position.y = 120000
	
	$Banner/lblStatus.text = "Drawing " + plusCode6 + "..."
	if makeMapTile == true:
		print("drawing map")
		await $svc/SubViewport/fullMap.DrawOfflineTile(mapData.entries["mapTiles"], scaleVal)
	if makeNameTile == true:
		print("drawing name")
		await $svc2/SubViewport/nameMap.DrawOfflineNameTile(mapData.entries["mapTiles"], scaleVal)
	if makeBoundsTile == true:
		print("drawing bounds")
		await $svc3/SubViewport/boundsMap.DrawOfflineBoundsTile(mapData.entries["adminBoundsFilled"], scaleVal)
	if makeTerrainTile == true:
		print("drawing terrain")
		await $svc4/SubViewport/terrainMap.DrawOfflineTerrainTile(mapData.entries["mapTiles"], scaleVal)
	
	var viewport1 = $svc/SubViewport
	var viewport2 = $svc2/SubViewport
	var viewport3 = $svc3/SubViewport
	var viewport4 = $svc4/SubViewport
	var camera1 = $svc/SubViewport/subcam
	var camera2 = $svc2/SubViewport/subcam
	var camera3 = $svc3/SubViewport/subcam
	var camera4 = $svc4/SubViewport/subcam
	var scale = scaleVal
	
	camera1.position = Vector2(0,0)
	camera2.position = Vector2(0,40000)
	camera3.position = Vector2(0,80000)
	camera4.position = Vector2(0,120000)
	viewport1.size = Vector2i(320 * scale, 500 * scale)
	viewport2.size = Vector2i(320 * scale, 500 * scale)
	viewport3.size = Vector2i(320 * scale, 500 * scale)
	viewport4.size = Vector2i(320 * scale, 500 * scale)
	await RenderingServer.frame_post_draw
	
	var xList = PlusCodes.CODE_ALPHABET_
	var yList = PlusCodes.CODE_ALPHABET_
	
	if (oneTile != null):
		xList = oneTile[1]
		yList = oneTile[0]

	for yChar in yList:
		#This kept complaining about can't - a Vector2 and an Int so I had to do this.
		#yPos -= (PlusCodes.CODE_ALPHABET_.find(yChar) * 20 * scale)
		camera1.position.y -= (500 * scale)
		camera2.position.y -= (500 * scale)
		camera3.position.y -= (500 * scale)
		camera4.position.y -= (500 * scale)
			
		for xChar in xList:
			camera1.position.x = (PlusCodes.CODE_ALPHABET_.find(xChar) * 320 * scale)
			camera2.position.x = (PlusCodes.CODE_ALPHABET_.find(xChar) * 320 * scale)
			camera3.position.x = (PlusCodes.CODE_ALPHABET_.find(xChar) * 320 * scale)
			camera4.position.x = (PlusCodes.CODE_ALPHABET_.find(xChar) * 320 * scale)
			await RenderingServer.frame_post_draw
			if makeMapTile == true:
				var img1 = viewport1.get_texture().get_image() # Get rendered image
				img1.save_png("user://MapTiles/" + plusCode6 + yChar + xChar + ".png") # Save to disk
			if makeNameTile == true:
				var img2 = viewport2.get_texture().get_image() # Get rendered image
				img2.save_png("user://NameTiles/" + plusCode6 + yChar + xChar + ".png") # Save to disk
			if makeBoundsTile == true:
				var img3 = viewport3.get_texture().get_image() # Get rendered image
				img3.save_png("user://BoundsTiles/" + plusCode6 + yChar + xChar + ".png") # Save to disk
			if makeTerrainTile == true:
				var img4 = viewport4.get_texture().get_image() # Get rendered image
				img4.save_png("user://TerrainTiles/" + plusCode6 + yChar + xChar + ".png") # Save to disk
			$Banner/lblStatus.text = "Saved Tiles for " + plusCode6 + yChar + xChar
	
	tiles_saved.emit()

func DownloadFullData(plusCode6):
	#TODO: figure out the URL for these files. Possibly a PraxisMapper URL, possibly just a filehost.
	pass
