extends Node2D

@onready var lb_location_info: Label = $lblLocInfo

func on_monitoring_location_result(location: Dictionary) -> void:
	print_location_info(location)
	
func print_location_info(location: Dictionary) -> void:
	var text: String = "Coordinates: " + str(location["latitude"]) + " , " + str(location["longitude"])
	text += "\n"
	text += "Accuracy: " + str(location["accuracy"]) + " m"
	text += "\n"
	text += "Altitude: " + str(location["altitude"]) + " m ( Accuracy: " + str(location["verticalAccuracyMeters"]) + " m )"
	text += "\n"
	text += "Bearing: " + str(location["bearing"]) + "º"
	text += "\n"
	text += "Speed: " + str(location["speed"]) + " m/s"
	text += "\n"
	text += "Time: " + str(location["time"])
	text += "\n\n\n"
	text += "PlusCode:" + PlusCodes.EncodeLatLon(location["latitude"], location["longitude"])
	
	lb_location_info.text = text

func _ready():
	if PraxisCore.last_location != null:
		on_monitoring_location_result(PraxisCore.last_location)
	PraxisCore.location_changed.connect(on_monitoring_location_result)

func Close():
	get_tree().change_scene_to_file("res://Scenes/SimpleTest.tscn")
