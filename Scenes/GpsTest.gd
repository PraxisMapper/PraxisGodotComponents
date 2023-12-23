extends Node2D

#TODO: should no longer need these values here, just listen for PraxisMapper.plusCode_changed
var gps_provider
var last_latitude
var last_longitude
var accumulated_distance

@onready var lb_location_info: Label = $lblLocInfo

func on_monitoring_location_result(location: Dictionary) -> void:
	print_location_info(location)
	
func print_location_info(location: Dictionary) -> void:
	if last_latitude and last_longitude:
		accumulated_distance += gps_provider.get_distance_between(last_latitude, last_longitude, location["latitude"], location["longitude"])
	
	var text: String = "Coordinates: " + str(location["latitude"]) + " , " + str(location["longitude"])
	text += "\n"
	text += "Accuracy: " + str(location["accuracy"]) + " m"
	text += "\n"
	text += "Altitude: " + str(location["altitude"]) + " m ( Accuracy: " + str(location["altitude_accuracy"]) + " m )"
	text += "\n"
	text += "Bearing: " + str(location["bearing"]) + "º ( Accuracy: " + str(location["bearing_accuracy"]) + "º )"
	text += "\n"
	text += "Speed: " + str(location["speed"]) + " m/s ( Accuracy: " + str(location["speed_accuracy"]) + " m/s )"
	text += "\n"
	text += "Is Mock: " + str(location["is_mock"])
	text += "\n"
	text += "\n"
	text += "\n"
	text += "Accumulated distance: " + str(accumulated_distance) + " m"
	text += "\n"
	text += "PlusCode:" + PlusCodes.EncodeLatLon(location["latitude"], location["longitude"])
	
	lb_location_info.text = text

# Called when the node enters the scene tree for the first time.
func _ready():
	print("_ready called on GPSTest")
	if Engine.has_singleton("GodotAndroidGpsProvider"):
		print("GPS Singleton found!")
		gps_provider = Engine.get_singleton("GodotAndroidGpsProvider")
		print("Reference set")
		gps_provider.request_precise_gps_permission()
		print("Permission Requested")
	else:
		print("singleton list")
		var singletons = ProjectSettings.get_setting("_global_script_classes")
		if (singletons != null):
			for s in singletons:
				print(s)
		
		lb_location_info.text = "No GPS support"
		

var hasSetup = false
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if (!hasSetup && gps_provider != null):
		gps_provider.on_monitoring_location_result.connect(on_monitoring_location_result)
		print("Monitor location connected")
		gps_provider.start_monitoring(gps_provider.get_accuracy_high(), 5000, 10.0, true)
		print("Now Monitoring....")
		hasSetup = true
