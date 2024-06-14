extends Node2D

var process = true

#TODO: I may want to pause movement/change scenes to draw all the tiles in the Cell6. Doing
#them one at a time mid-op means they occasionally fail to draw.

var lastPlusCode = '' #Might be replaceable with odl in the change call

func _ready():
	plusCode_changed(PraxisCore.currentPlusCode, PraxisCore.lastPlusCode)
	PraxisCore.plusCode_changed.connect(plusCode_changed)

func plusCode_changed(current, old):
	if process == false:
		return
	#TODO: check for data files. Download them if possible/configured, otherwise static.
	#TODO: ponder scrollview instead of repositioning mapBase node and children.
	
	if current.substr(0,8) != lastPlusCode.substr(0,8): # old.substr(0,8):
		#We need to reset all the bg tiles now
		process = false
		var base = current.substr(0,8)
		var node
		var code
		var tex
		for x in [-2,-1,0,1,2]:
			for y in [-2,-1,0,1,2]:
				code = PlusCodes.ShiftCode(base, x, y)
				tex = await $TileDrawer.GetAndProcessData(code, 1)
				node = get_node("mapBase/MapTile" + str(x) + str(y))
				node.texture = ImageTexture.create_from_image(tex) #update might be faster?
	
	#Now scroll mapBase to the right spot.
	var currentXPos = PlusCodes.RemovePlus(current).substr(9,1)
	var xIndex = PlusCodes.CODE_ALPHABET_.find(currentXPos)
	var xShift = (PraxisCore.mapTileWidth / 2) -  (PraxisCore.mapTileWidth / 20) * xIndex
	var currentYPos = PlusCodes.RemovePlus(current).substr(8,1)
	var yIndex = PlusCodes.CODE_ALPHABET_.find(currentYPos)
	var yShift = (PraxisCore.mapTileHeight / 2) - (PraxisCore.mapTileHeight / 20) * yIndex
	
	print("current pos:" + currentXPos + "," + currentYPos)
	
	$mapBase.position.x = xShift
	$mapBase.position.y = -yShift
	
	lastPlusCode = current
	if process == false:
		process = true
		if current != PraxisCore.currentPlusCode:
			plusCode_changed(PraxisCore.currentPlusCode, lastPlusCode)
			
