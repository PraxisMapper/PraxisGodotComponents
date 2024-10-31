extends Node2D
class_name PlaceTracker

#keys are [plusCode6][placeName], value is dictionary (default: time = unix system time of visit.
#EX: [223344][Main Park]
var allPlaces = {} 
var fileName = "user://Data/Visited.json"
var styleData = {}
var styleDataFull = {}
var checkedPlusCode = ""
#These store the image used, so we don't have to load all of these from disk every call
var currentData
var currentNameTile
var currentTerrainTile
var currentPlaces = []

signal place_changed(newplace)

func _ready():
	styleData = PraxisCore.GetStyle("suggestedmini") 
	styleDataFull = PraxisCore.GetStyle("mapTiles") 
	Load()

func Load():
	var recentFile = FileAccess.open(fileName, FileAccess.READ_WRITE)
	if (recentFile == null):
		return
	else:
		var json = JSON.new()
		json.parse(recentFile.get_as_text())
		allPlaces = json.get_data()
		recentFile.close()
	
func Save():
	var recentFile = FileAccess.open(fileName, FileAccess.WRITE)
	if (recentFile == null):
		print(FileAccess.get_open_error())
		return
	
	var json = JSON.new()
	recentFile.store_string(json.stringify(allPlaces))
	recentFile.close()
	
func Clear():
	allPlaces = {}

func Add(place, plusCode6):
	if (allPlaces.has(plusCode6) == false):
		allPlaces[plusCode6] = {}
	if (allPlaces[plusCode6].has(place) == false):
		allPlaces[plusCode6][place] = { timeFirstVisited = Time.get_unix_time_from_system()}
	Save()

func isFirstVisit(place, plusCode6):
	if (allPlaces.has(plusCode6) and allPlaces[plusCode6].has(place)):
		return false
	
	Add(place, plusCode6)
	return true;

func GetInfo(place, plusCode6):
	if !allPlaces.has(plusCode6):
		return {}
	if !allPlaces[plusCode6].has(place):
		return {}
	
	return allPlaces[plusCode6][place]

func SetInfo(place, plusCode6, data_dict):
	allPlaces[plusCode6][place] = data_dict
	Save()
	
func HasVisited(name, plusCode6):
	if allPlaces.has(plusCode6) == false:
		return false
	if allPlaces[plusCode6].has(name) == false:
		return false
	
	return true

func CheckForPlace(plusCode10):
	plusCode10 = plusCode10.replace("+", "")
	#if we have full data, use it instead. TODO: check
	if PraxisOfflineData.OfflineDataExists(plusCode10.substr(0,4)):
		return await CheckForPlaceFull(plusCode10)
	
	#This math here uses my minimized offline format image
	#400x400, each pixel is a Cell10.
	
	var filename = PraxisCore.currentPlusCode.substr(0,6)
	if (filename != checkedPlusCode.substr(0,6)):
		#load new data. These are drawn by GameGlobals if they're available to draw
		currentData = MinimizedOffline.GetDataFromZip(filename)
		currentNameTile = Image.load_from_file("user://NameTiles/" + filename + ".png")
		currentTerrainTile = Image.load_from_file("user://TerrainTiles/" + filename + ".png")
		checkedPlusCode = filename
	
	var currentPlace = GetDataOnPoint(plusCode10)
	var placeInfo = []
	if (currentPlace == ""):
		return [""]
		
	if (currentPlace != "|"):
		placeInfo = currentPlace.split("|")
		if (placeInfo[0] == ""):
			placeInfo[0] = "unnamed " + placeInfo[1]
	return placeInfo

func GetDataOnPoint(plusCode10):
	var filename = plusCode10.substr(0,6)
	var pixelX = (PlusCodes.GetLetterIndex(plusCode10[7]) * 20)  + PlusCodes.GetLetterIndex(plusCode10[9])
	var pixelY = 399 - (PlusCodes.GetLetterIndex(plusCode10[6]) * 20) - PlusCodes.GetLetterIndex(plusCode10[8])

	var name = ""
	var terrain = ""

	var pixel = currentNameTile.get_pixel(pixelX, pixelY)
	var nameTableId = pixel.r8 + (pixel.g8 * 255) + (pixel.b8 * 65535)
	if nameTableId > 0:
		name = currentData.nameTable[str(nameTableId)]
	pixel = currentTerrainTile.get_pixel(pixelX, pixelY)
	var terrainTableId = pixel.r8 + (pixel.g8 * 255) + (pixel.b8 * 65535)
	if terrainTableId > 0:
		terrain = styleData[str(terrainTableId)].name
	
	if (name == "" and terrainTableId == 0):
		return ""
	
	return name + "|" + terrain
	
func CheckForPlaceFull(plusCode10):
	#this is for using the full drawable data to detect which place you're at
	
	plusCode10 = plusCode10.replace("+", "")
	var data = await GetDataOnPointFull(plusCode10)
	currentPlaces = data
	if data.size() == 0:
		return [""]
		
	var smallest = data.back()
	return smallest.split("|") #if split, doesnt updateCurrentPlace?

func GetDataOnPointFull(plusCode10):
	var results = []
	var places = await PraxisOfflineData.GetPlacesPresent(plusCode10)
	for place in places:
		if place.category == "mapTiles":
			results.push_back(place.name + "|" + str(place.typeId))
	
	return results
