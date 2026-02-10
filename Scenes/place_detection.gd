extends Node2D


#TODO: update this to use new offline format, I may have existing bugs in here too from lables
#not lining up anyways.
var styleData
var downloading = false
var scanner = FullAreaScanner.new()

func _ready():
	PraxisCore.plusCode_changed.connect(OnGpsUpdate)
	styleData = {
		mapTiles = PraxisCore.GetStyle("mapTiles"), #TODO: keep for backwards compatibility?
		adminBoundsFilled = PraxisCore.GetStyle("adminBoundsFilled"),
		offline = PraxisCore.GetStyle("offline")
	}

func OnGpsUpdate(current, old):
	$lblLoc.text = "Location: " + current

#TODO: this should be an external function or something, maybe a signal to listen for when its done.
	#Place Lookup and download logic
	if downloading == true:
		return

	if !FileAccess.file_exists("user://Data/Full/" + current.substr(0,6) + ".json"):
		$lblLoc3.text = "Data Present: No"
		downloading = true
		if await $GetFile.getCell6File(current.substr(0,6)):
			await $GetFile.file_downloaded
		downloading = false
	var fa = FileAccess.open("user://Data/Full/" + current.substr(0,6) + ".json", FileAccess.READ)
	$lblLoc3.text = "Data Present: Yes (" + str(fa.get_length()) + ")"
	fa.close()
	
	var rawData = await PraxisOfflineData.GetDataFromZip(current.substr(0,6))
	var styles = rawData.entries.keys().size()
	var totalEntries = 0
	$lblDataCounts.text = ""
	for key in rawData.entries.keys():
		$lblDataCounts.text += key + ": " + str(rawData.entries[key].size()) + "\n"
		totalEntries += rawData.entries[key].size()
	$lblDataCounts.text += "Total: " + str(totalEntries)
	
	$lblPlaceList.text = ""
	var places = await PraxisOfflineData.GetPlacesPresent(current)
	for place in places:
		var placeType = styleData[place.category][str(int(place.typeId))].name
		$lblPlaceList.text += place.category + ": " + place.name + "- " + placeType + "\n"
		

func Close():
	get_tree().change_scene_to_file("res://Scenes/SimpleTest.tscn")
	
