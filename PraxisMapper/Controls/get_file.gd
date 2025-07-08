extends Node2D

var serverPath = "https://global.praxismapper.org/"
var cell4Path = "Content/OfflineData/" #Add cell2/cell4.zip to this URL, like: 2C/2CP2.zip
var cell6Path = "Offline/FromZip/" # add the Cell6 only to get the JSON file
var isActive = false
var busy = false
var skipTween = false

signal file_downloaded()

var queue = []

func AddToQueue(file):
	if !queue.has(file):
		queue.append(file)
	if (!busy):
		RunQueue()
	
func RunQueue():
	busy = true
	while queue.size() > 0:
		skipTween = true
		var next = queue.pop_front()
		print("Queued: " + next)
		if next.length() == 4:
			await getCell4FileSync(next)
		elif next.length() == 6:
			await getCell6FileSync(next)
		PraxisCore.force_redraw.emit()
	busy = false
	skipTween = false
	TweenFade()

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
	
func getCell4FileSync(plusCode4):
	if isActive:
		return false
	#Uses a different path to pull single files
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
	
	await $client.request_completed
	$client.request_completed.disconnect(request_complete)
	#return
		
	$Banner/Label.text = "Download Complete"
	TweenFade()
	return true
	
func getCell6File(plusCode6):
	if isActive:
		print("not downloading file, already running")
		return false
	#Uses a different path to pull single files
	var cell2 = plusCode6.substr(0,2)
	if FileAccess.file_exists("user://Data/Full/" + plusCode6 + ".json"):
		file_downloaded.emit()
		print("not downloading file, already exists")
		return true #already downloaded this! May have a future setup to force this.
	
	$client.request_completed.connect(request_complete)
	$client.download_file = "user://Data/Full/" + plusCode6 + ".json"
	var file = serverPath + cell6Path + plusCode6
	var status = $client.request(file)
	print(file)
	if status != Error.OK:
		#TODO error stuff
		print("error calling download:" + str(status))
		return
	isActive = true
	$Banner.visible = true
	return true
	
func getCell6FileSync(plusCode6):
	if isActive:
		print("not downloading file, already running")
		return false
	#Uses a different path to pull single files
	var cell2 = plusCode6.substr(0,2)
	if FileAccess.file_exists("user://Data/Full/" + plusCode6 + ".json"):
		file_downloaded.emit()
		print("not downloading file, already downloaded")
		return true #already downloaded this! May have a future setup to force this.
	
	$client.request_completed.connect(request_complete)
	$client.download_file = "user://Data/Full/" + plusCode6 + ".json"
	print(serverPath + cell6Path + plusCode6)
	var status = $client.request(serverPath + cell6Path + plusCode6)
	if status != Error.OK:
		#TODO error stuff
		print("error calling download:" + str(status))
		return
	isActive = true
	$Banner.visible = true
	
	await $client.request_completed
	#return
		
	print("file done:" + plusCode6)
	$Banner/Label.text = "Download Complete"
	TweenFade()	
	return true

func request_complete(result, response_code, headers, body):
	isActive = false
	$client.request_completed.disconnect(request_complete)
	print("complete:" + str(result))
	if result != HTTPRequest.RESULT_SUCCESS:
		#TODO: error stuff.
		print("ERROR:"  + str(result))
		return
		
	$Banner/Label.text = "Download Complete"
	TweenFade()
	
func _process(delta):
	if isActive:
		var body_size = $client.get_body_size() * 1.0
		if body_size > -1:
			$Banner/Label.text = "Downloaded: " + str(snapped(($client.get_downloaded_bytes() / body_size) * 100, 0.01))  + " percent"
		else:
			$Banner/Label.text = "Downloaded: " + str($client.get_downloaded_bytes()) + " bytes"
		pass

func TweenFade():
	if skipTween:
		return
		
	await get_tree().create_timer(2).timeout
	var fade_tween = create_tween()
	fade_tween.tween_property($Banner, 'modulate:a', 0.0, 1.0)
	fade_tween.tween_callback($Banner.hide)
	file_downloaded.emit()
