extends Node2D

#FUTURE TODO:
#Godot cannot do draws on a separate thread yet. I can have threads run, but
#they must eventually put results on-screen somehow to get a proper texture drawn.
#Once RenderingServer is properly threaded, try working that out again

#FUTURE TODO:
#test all features in one scene for regressions, instead of single tests here.

# Called when the node enters the scene tree for the first time.
func _ready():
	#This is a better way to confirm this than saving the results to file like WSC(P) does.
	#The old way wont check if the user rescinded perms from setting. This will.
	var perms = OS.get_granted_permissions()
	if perms.has("android.permission.ACCESS_FINE_LOCATION"):
		HavePerms()
		
	
func HavePerms():
	$btnGpsTest.disabled = false
	$btnProxyTest.disabled = false
	$btnStyleTest.disabled = false
	$btnSplatDemo.disabled = false
	
func RunTest():
	#Working
	#await $MinOfflineTiles.GetAndProcessData("85633Q")
	#await $FullOfflineTiles.GetAndProcessData("85633Q", 2) #can be 6 or 8 characters long
	#var test3 = await PraxisOfflineData.GetPlacesPresent("85633QGP5M")
	#print(test3)
	#await RenderingServer.frame_post_draw
	#var styleData = await PraxisCore.GetStyle("mapTiles")
	#$drawtest.style = styleData
	#var mapData = await PraxisOfflineData.GetDataFromZip("85633Q")
	#await $drawtest.DrawOfflineTile(mapData.entries["mapTiles"], 0.08)
	#var place  = await $AreaScanner.PickPlace("85633Q", "mapTiles", 0, "")
	#var places  = await $AreaScanner.ReadPlaces("85633Q", "mapTiles", 0, "")
	#for place in places:
	#print(place)	
	#$testbgdraw.FastDraw("85633Q2222")
	

	pass
	

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	$TextureRect.rotation_degrees += 360 * delta

func GPSDemo():
	get_tree().change_scene_to_file("res://Scenes/GpsTest.tscn")

func StyleDemo():
	get_tree().change_scene_to_file("res://Scenes/StyleTest.tscn")

func SplatDemo():
	get_tree().change_scene_to_file("res://Scenes/SplatScene/SplatDemo.tscn")

func ProxyDemo():
	PraxisCore.SetProxyPlay(true) #Set proxyplay on AND sets current plus code to proxyBase.
	get_tree().change_scene_to_file("res://Scenes/ProxyPlayTest.tscn")

func RequestPerms():
	var granted = OS.request_permissions()
	if granted == true:
		PraxisCore.perm_check("android.permission.ACCESS_FINE_LOCATION", true)
		HavePerms()
