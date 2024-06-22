extends Node2D

#TODO: should this be used/a child of the PraxisCore node?
#Add cell2/cell4.zip to this URL, like: 2C/2CP2.zip
var serverPath = "https://global.praxismapper.org/"
var cell4Path = "Content/OfflineData/"
var cell6Path = "Offline/FromZip/"
var isActive = false

signal file_downloaded()

#OK, immediately upon trying to do this, I realize I'm gonna hit issues with files overlapping
#so I can't do both of these nicely. I'll need to pick a folder or something.
func getCell4File(plusCode4):
	if isActive:
		return false
		
	var cell2 = plusCode4.substr(0,2)
	if FileAccess.file_exists("user://Data/Full/" + plusCode4 + ".zip"):
		var reader = ZIPReader.new()
		var isGoodFile = reader.open("user://Data/Full/" + plusCode4 + ".zip")
		if isGoodFile == OK:
			file_downloaded.emit()
			return true #already downloaded this! May have a future setup to force this.
	
	$client.request_completed.connect(request_complete)
	$client.download_file = "user://Data/Full/" + plusCode4 + ".zip"
	var status = $client.request(serverPath + cell4Path + cell2 + "/" + plusCode4 + ".zip")
	if status != Error.OK:
		#TODO error stuff
		print("error calling download:" + str(status))
		return
	isActive = true
	$Banner.visible = true
	return true
	
func getCell6File(plusCode6):
	if isActive:
		return false
	#Uses a different path to pull single files
	var cell2 = plusCode6.substr(0,2)
	if FileAccess.file_exists("user://Data/Full/" + plusCode6 + ".json"):
		file_downloaded.emit()
		return true #already downloaded this! May have a future setup to force this.
	
	$client.request_completed.connect(request_complete)
	$client.download_file = "user://Data/Full/" + plusCode6 + ".json"
	var status = $client.request(serverPath + cell6Path + plusCode6)
	if status != Error.OK:
		#TODO error stuff
		print("error calling download:" + str(status))
		return
	isActive = true
	$Banner.visible = true
	return true
	
func getCell6FileSync(plusCode6):
	if isActive:
		return false
	#Uses a different path to pull single files
	var cell2 = plusCode6.substr(0,2)
	if FileAccess.file_exists("user://Data/Full/" + plusCode6 + ".json"):
		file_downloaded.emit()
		return true #already downloaded this! May have a future setup to force this.
	
	#$client.request_completed.connect(request_complete)
	$client.download_file = "user://Data/Full/" + plusCode6 + ".json"
	var status = $client.request(serverPath + cell6Path + plusCode6)
	if status != Error.OK:
		#TODO error stuff
		print("error calling download:" + str(status))
		return
	isActive = true
	$Banner.visible = true
	
	await $client.request_completed
	return
		
	$Banner/Label.text = "Download Complete"
	await get_tree().create_timer(2).timeout
	var fade_tween = create_tween()
	fade_tween.tween_property($Banner, 'modulate:a', 0.0, 1.0)
	fade_tween.tween_callback($Banner.hide)
	
	return true

func request_complete(result, response_code, headers, body):
	isActive = false
	$client.request_completed.disconnect(request_complete)
	print("complete:" + str(result))
	if result != HTTPRequest.RESULT_SUCCESS:
		#TODO: error stuff.
		return
		
	$Banner/Label.text = "Download Complete"
	await get_tree().create_timer(2).timeout
	var fade_tween = create_tween()
	fade_tween.tween_property($Banner, 'modulate:a', 0.0, 1.0)
	fade_tween.tween_callback($Banner.hide)
	file_downloaded.emit()
	
	
func _process(delta):
	if isActive:
		var body_size = $client.get_body_size() * 1.0
		if body_size > -1:
			$Banner/Label.text = "Downloaded: " + str(snapped(($client.get_downloaded_bytes() / body_size) * 100, 0.01))  + " percent"
		else:
			$Banner/Label.text = "Downloaded: " + str($client.get_downloaded_bytes()) + " bytes"
		pass
