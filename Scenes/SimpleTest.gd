extends Node2D


# Called when the node enters the scene tree for the first time.
func _ready():
	#Working
	#await $MinOfflineTiles.GetAndProcessData("85633Q", "suggestedmini")
	await $FullOfflineTiles.GetAndProcessData("85633Q", 4) #can be 6 or 8 characters long
	#var test3 = await PraxisOfflineData.GetPlacesPresent("85633QGP5M")
	#print(test3)
	#in testing now
	
	pass
	



# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	$TextureRect.rotation_degrees += 10
