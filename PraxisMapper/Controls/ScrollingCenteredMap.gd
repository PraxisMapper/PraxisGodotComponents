extends Node2D

#TODO: this hits issues if it starts drawing mid-download. It cant tell the difference between 
#a partial and complete download.

var process = true

var lastPlusCode = '' #Might be replaceable with odl in the change call
var currentOffset = Vector2(0,0) #Pixels offset for scrolling purposes, referenced by other controls
var plusCodeBase = '22334455+2X' #The plusCode used for the upper-left corner of the area,
# and referenced by other


func _ready():
	plusCode_changed(PraxisCore.currentPlusCode, PraxisCore.lastPlusCode)
	PraxisCore.plusCode_changed.connect(plusCode_changed)

func plusCode_changed(current, old):
	if process == false:
		return
	#TODO: check for data files. Download them if possible/configured, otherwise static.
	#TODO: ponder scrollview instead of repositioning mapBase node and children.
	
	if !visible:
		#If we're not visible, drawing tiles does not work.
		#TODO: may need to handle drawing tiles when visibility is enabled again later.
		return
	
	if current.substr(0,8) != lastPlusCode.substr(0,8): # old.substr(0,8):
		RefreshTiles(current)
		var children = $trackedChildren.get_children()
		for c in children:
			var offset = getDrawingOffset(c.get_meta("originalLocation", ""))
			if offset != null:
				c.position = offset
		process = true
	
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
	$trackedChildren.position = $mapBase.position - position #works but doesnt feel right for some reason.
	currentOffset = $mapBase.position
	
	lastPlusCode = current
	if process == false:
		process = true
		if current != PraxisCore.currentPlusCode:
			plusCode_changed(PraxisCore.currentPlusCode, lastPlusCode)

func getDrawingOffset(plusCode):
	var offset = PlusCodes.GetDistanceCell10s(plusCodeBase, plusCode)
	#First vector converts to Cell12 pixels, 2nd accommodates non-origin position of ma
	return offset * Vector2(-16,25) + position 
	#TODO: this never runs. remove or fix?
	if PlusCodes.RemovePlus(plusCode).length == 11:
		var charVal = PlusCodes.GetLetterIndex(plusCode.right(1))
		offset += Vector2(charVal % 4, charVal / 4)
	else:
		#centers item in cell10 instead of lower-left corner
		offset += Vector2(8, 13)
	
func trackChildOnMap(node, plusCodePosition):
	if (plusCodePosition == null):
		return
	var offset = getDrawingOffset(plusCodePosition)
	node.position = offset
	node.set_meta("originalLocation", plusCodePosition)
	$trackedChildren.add_child(node)

func clearAllTrackedChildren():
	for tc in $trackedChildren.get_children():
		tc.queue_free()
		
func RefreshTiles(current):
	if current == null:
		current = PraxisCore.currentPlusCode
	plusCodeBase = PlusCodes.ShiftCode(current.substr(0,8), -2, 2) + "X2"
	var base = current.substr(0,8)
	var node
	var code
	var tex
	for x in [-2,-1,0,1,2]:
		for y in [-2,-1,0,1,2]:
			code = PlusCodes.ShiftCode(base, x, y)
			tex = await $TileDrawer.GetAndProcessData(code, 1)
			if tex != null:
				node = get_node("mapBase/MapTile" + str(x) + str(y))
				node.texture = ImageTexture.create_from_image(tex) #update might be faster?
