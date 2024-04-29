extends Node

#Any universally-helpful functions that aren't specific to an operating mode go here
#Server calls go to PraxisServer. Offline data loading goes to PraxisOfflineData.

#This variable should exist for debugging purposes, but I've provided a few choices for convenience.
#var debugStartingPlusCode = "85633QG4VV" #Elysian Park, Los Angeles, CA, USA
#var debugStartingPlusCode = "87G8Q2JMGF" #Central Park, New York City, NY, USA
#var debugStartingPlusCode = "8FW4V75W25" #Eiffel Tower Garden, France
#var debugStartingPlusCode = "9C3XGV349C" #The Green Park, London, UK
#var debugStartingPlusCode = "8Q7XMQJ595" #Kokyo Kien National Garden, Tokyo, Japan
#var debugStartingPlusCode = "8Q336FJCRV" #Peoples Park, Shanghai, China
#var debugStartingPlusCode = "7JWVP5923M" #Shalimar Bagh, Delhi, India
var debugStartingPlusCode = "86FRXXXPM8" #Ohio State University, Columbus, OH, USA

#System global values
#Resolution of PlusCode cells in degrees
const resolutionCell12Lat = .000025 / 5
const resolutionCell12Lon = .00003125 / 4; 
const resolutionCell11Lat = .000025;
const resolutionCell11Lon = .00003125; 
const resolutionCell10 = .000125; 
const resolutionCell8 = .0025; 
const resolutionCell6 = .05; 
const resolutionCell4 = 1; 
const resolutionCell2 = 20;
const metersPerDegree = 111111
const oneMeterLat = 1 / metersPerDegree

#system config values. These are for Cell12 resolution images.
var mapTileWidth = 320 
var mapTileHeight = 500

#storage values for global access at any time.
var currentPlusCode = '' #The Cell10 we are currently in.
var lastPlusCode = '' #the previous Cell10 we visited.

#signals for components that need to respond to it.
signal plusCode_changed(current, previous) #For when you just need to know your grid position changed
signal location_changed(dictionary) #For stuff that wants raw GPS data or small changes in position.

#Plugin for gps info
var gps_provider

func ForceChange(newCode):
	if newCode.find("+") == -1:
		newCode = newCode.substr(0,8) + "+" + newCode.substr(8)
	lastPlusCode = currentPlusCode
	currentPlusCode = newCode
	PraxisCore.plusCode_changed.emit(currentPlusCode, lastPlusCode)
	
func GetFixedRNGForPluscode(pluscode):
	var rng = RandomNumberGenerator.new()
	rng.seed = hash(pluscode)
	return rng
	
func on_monitoring_location_result(location: Dictionary) -> void:
	location_changed.emit(location)
	print("location changed" + str(location))
	var plusCode = PlusCodes.EncodeLatLon(location["latitude"], location["longitude"])
	if (plusCode != currentPlusCode):
		lastPlusCode = currentPlusCode
		currentPlusCode = plusCode
		plusCode_changed.emit(currentPlusCode, lastPlusCode)
		print("new plusCode: " + plusCode)
		
func perm_check(permName, wasGranted):
	print("permissions: " + permName)
	print(wasGranted)
	if permName == "android.permission.ACCESS_FINE_LOCATION" and wasGranted == true:
		print("enabling GPS")
		gps_provider.onLocationUpdates.connect(on_monitoring_location_result)
		gps_provider.StartListening()

func _ready():
	DirAccess.make_dir_absolute("user://MapTiles")
	DirAccess.make_dir_absolute("user://NameTiles")
	DirAccess.make_dir_absolute("user://BoundsTiles")
	DirAccess.make_dir_absolute("user://TerrainTiles")
	DirAccess.make_dir_absolute("user://Offline")
	DirAccess.make_dir_absolute("user://Data") #used to store tracker data in JSON, rather than images.
	
	get_tree().on_request_permissions_result.connect(perm_check)
	
	gps_provider = await Engine.get_singleton("PraxisMapperGPSPlugin")
	if gps_provider != null:
		var perms = OS.get_granted_permissions()
		if perms.find("android.permission.ACCESS_FINE_LOCATION") > -1:
			print("enabling GPS")
			gps_provider.onLocationUpdates.connect(on_monitoring_location_result)
			gps_provider.StartListening()
	else:
		print("GPS Provider not loaded (probably debugging on PC)")
		currentPlusCode = debugStartingPlusCode
		var debugControlScene = preload("res://PraxisMapper/Controls/DebugMovement.tscn")
		var debugControls = debugControlScene.instantiate()
		add_child(debugControls)
		debugControls.position.x = 0
		debugControls.position.y = 0
		debugControls.z_index = 200

func GetStyle(style):
	var styleData = FileAccess.open("res://PraxisMapper/Styles/" + style + ".json", FileAccess.READ)
	if (styleData == null):
		return null
	else:
		var json = JSON.new()
		json.parse(styleData.get_as_text())
		return json.get_data()

#This needs to be called by a node that exists in a tree, not just a static script, so its here.
func MakeMinimizedOfflineTiles(plusCode):
	var offlineNode = preload("res://PraxisMapper/MinimizedOffline/MinOfflineTiles.tscn")
	var offlineInst = offlineNode.instantiate()
	add_child(offlineInst)
	await offlineInst.GetAndProcessData(plusCode,"suggestedmini")
	remove_child(offlineInst)
	
func MakeOfflineTiles(plusCode, scale = 1):
	var offlineNode = preload("res://PraxisMapper/FullOffline/FullOfflineTiles.tscn")
	var offlineInst = offlineNode.instantiate()
	add_child(offlineInst)
	await offlineInst.GetAndProcessData(plusCode, scale)
	remove_child(offlineInst)

func DistanceDegreesToMetersLat(degrees):
	return degrees * metersPerDegree

func DistanceDegreesToMetersLon(degrees, latDegrees):
	return degrees * metersPerDegree * cos(deg_to_rad(latDegrees))

func DistanceMetersToDegreesLat(meters):
	return meters * oneMeterLat

func DistanceMetersToDegreesLon(meters, latDegrees):
	return meters * oneMeterLat * cos(deg_to_rad(latDegrees))

func MetersToFeet(meters):
	return meters * 3.281

func GetCompassHeading():
	var gravity: Vector3 = Input.get_gravity()
	var pitch = atan2(gravity.z, -gravity.y) #rotation.x
	var roll = atan2(-gravity.x, -gravity.y)  #rotation.z
	var magnet = Input.get_magnetometer().rotated(-Vector3.FORWARD, roll).rotated(Vector3.RIGHT, pitch)
	
	var yaw_magnet = atan2(-magnet.x, magnet.z)
	return -yaw_magnet #Negative to match rotation values in Godot
