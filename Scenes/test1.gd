extends Node2D

@onready var mapTile = $MapTile

# Called when the node enters the scene tree for the first time.
func _ready():
	print("getting new tile")
	mapTile.GetTile("86HWGGGP")
	
	var apicallScene = preload("res://PraxisMapper/Controls/PraxisAPICall.tscn")
	var apicall = apicallScene.instantiate()
	var results = apicall.call_url("/Server/Test")
	print(results.get_string_from_utf8())


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
