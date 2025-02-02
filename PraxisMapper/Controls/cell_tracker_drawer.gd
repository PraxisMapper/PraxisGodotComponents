extends Node2D

var indColor1 = Color.DARK_RED
var indColor2 = Color.LIME_GREEN

@export var showCurrentCell = false
var plusCode8
var visited = {}
var timeToSwitch = 0
var colorIndicator = indColor1
@export var transparent = true

func DrawCellTracker(cellTracker, plusCode):
	visited = cellTracker.visited
	plusCode8 = plusCode.substr(0,8)
	queue_redraw()

func _draw():
	#This is drawing cell10s in a Cell8, so this is a 20x20 grid
	#Coordinate space: 0,0 is the position of the CellTrackerDrawer node in the scene
	#bigger X is right, bigger Y is down.
	
	if plusCode8 == null or visited == null:
		return
	
	var bgColor = Color.DIM_GRAY
	var visitedColor = Color.ANTIQUE_WHITE
	if transparent:
		bgColor.a = 0.6
		visitedColor.a = 0.1
		indColor1.a = 0.5
		indColor2.a = 0.5

	#redoing this, so exploring brightens up a cell over the drawn map
	#draw_rect(Rect2(0, 0, 20 , 20), bgColor)
	var charListX = PlusCodes.CODE_ALPHABET_
	var charListY = PlusCodes.CODE_ALPHABET_
	
	for xval in charListX:
		var xCoord = PlusCodes.GetLetterIndex(xval)
		for yval in charListY:
			var yCoord = PlusCodes.GetLetterIndex(yval)
			if visited.has(plusCode8 + yval + xval):
				draw_rect(Rect2(xCoord, 19 - yCoord, 1, 1), visitedColor)
			else:
				draw_rect(Rect2(xCoord, 19 - yCoord, 1, 1), bgColor)
	
	if PraxisCore.currentPlusCode == "":
		return
	
	if (PraxisCore.currentPlusCode.begins_with(plusCode8) and showCurrentCell == true):
		var code = PraxisCore.currentPlusCode.replace("+", "")
		
		var yCoord = PlusCodes.GetLetterIndex(code[8])
		var xCoord = PlusCodes.GetLetterIndex(code[9])
		
		if code.length() == 11:
			#NOTE: centering this instead of using lower-left corner at this precision level.
			yCoord -= (0.8 -(0.20 * (int(PlusCodes.GetLetterIndex(code[10]) / 4)))) + 0.1
			xCoord += (0.25 * (PlusCodes.GetLetterIndex(code[10]) % 4)) - 0.125
			draw_rect(Rect2(xCoord, 19 - yCoord, 0.25, 0.2), colorIndicator)
		else:
			draw_rect(Rect2(xCoord, 19 - yCoord, 1, 1), colorIndicator)

func _process(delta):
	if !showCurrentCell:
		return
		
	timeToSwitch += delta
	if (timeToSwitch >= 1):
		timeToSwitch -= 1
		if colorIndicator == indColor1:
			colorIndicator = indColor2
		else:
			colorIndicator = indColor1
		queue_redraw()
