extends Node2D

@onready var lb_location_info: Label = $lblLocInfo

var lastTime = 0

func on_monitoring_location_result(location: Dictionary) -> void:
	if (location.timestamp != lastTime):
		$AudioStreamPlayer2D.play()
		print_location_info(location)
	
func print_location_info(location: Dictionary) -> void:
	var timeDiff = 0
	if location.has("timestamp") and location.timestamp != null:
		timeDiff = location.timestamp - lastTime
		lastTime = location.timestamp
	elif location.has("time") and location.time != null:
		timeDiff = location.time - lastTime
		lastTime = location.time
	
	$lblRawDump.text = JSON.stringify(location) + "\n" + JSON.stringify(PraxisCore.web_location)
	if !location.has("accuracy"): #not a full packet
		return
	var text: String = "Coordinates: " + str(location["latitude"]) + " , " + str(location["longitude"])
	text += "\n"
	text += "Accuracy: " + str(location["accuracy"]) + " m"
	text += "\n"
	text += "Altitude: " + str(location["altitude"]) 
	if (location.has("verticalAccuracyMeters") and location["verticalAccuracyMeters"] != null):
		text += " m ( Accuracy: " + str(location["verticalAccuracyMeters"]) + " m )"
	elif (location.has("altitudeAccuracy") and location["altitudeAccuracy"] != null):
		text += " m ( Accuracy: " + str(location["altitudeAccuracy"]) + " m )"
	text += "\n"
	if (location.has("bearing") and location["bearing"] != null):
		text += "Bearing: " + str(location["bearing"]) + "º"
	elif (location.has("heading") and location["heading"] != null):
		text += "Bearing: " + str(location["heading"]) + "º"
	text += "\n"
	text += "Speed: " + str(location["speed"]) + " m/s"
	text += "\n"
	if (location.has("time") and location["time"] != null):
		text += "Time: " + str(location["time"])
	elif (location.has("timestamp") and location["timestamp"] != null):
		text += "Time: " + str(location["timestamp"])
	text += "\n\n\n"
	text += "PlusCode:" + PlusCodes.EncodeLatLon(location["latitude"], location["longitude"])
	text += "\nTime between updates: " + str(timeDiff) 
	lb_location_info.text = text

func SensorData():
	var text = ""
	var gravity: Vector3 = Input.get_gravity()
	text += "Gravity: " + str(gravity) + " m/s"
	text += "\n"
	var pitch = atan2(gravity.z, -gravity.y) #rotation.x
	text += "Pitch: " + str(pitch)
	text += "\n"
	var roll = atan2(-gravity.x, -gravity.y)  #rotation.z
	text += "Roll: " + str(roll)
	text += "\n"
	var magnet = Input.get_magnetometer().rotated(-Vector3.FORWARD, roll).rotated(Vector3.RIGHT, pitch)
	text += "Magnet: " + str(magnet)
	text += "\n"
	
	var yaw_magnet = atan2(-magnet.x, magnet.z)
	text += "Heading: " + str(-yaw_magnet) # negative to match Godot rotations
	text += "\n"
	text += "Heading (Degrees): " + str(rad_to_deg(-yaw_magnet))
	$lblSensorInfo.text = text

func _process(_delta):
	SensorData()

func _ready():
	if PraxisCore.last_location != null:
		on_monitoring_location_result(PraxisCore.last_location)
	PraxisCore.location_changed.connect(on_monitoring_location_result)

func Close():
	get_tree().change_scene_to_file("res://Scenes/SimpleTest.tscn")

func timeout500():
	var evalString = "startListening(500, true);"
	var evalResults = JavaScriptBridge.eval(evalString)

func timeout1000():
	var evalString = "startListening(1000, true);"
	var evalResults = JavaScriptBridge.eval(evalString)
	
func timeout5000():
	var evalString = "startListening(5000, true);"
	var evalResults = JavaScriptBridge.eval(evalString)
	
func timeout1000Low():
	var evalString = "startListening(1000, false);"
	var evalResults = JavaScriptBridge.eval(evalString)
