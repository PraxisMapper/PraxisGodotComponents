extends Node2D

var currentStyleSet
var currentMatchOrder
var currentDrawOp


func _ready() -> void:
	pass
	
func _process(delta: float) -> void:
	pass
	
func LoadStyle():
	pass
	
func SaveStyle():
	pass
	
func newStyleEntry():
	var nse
	nse.drawOps = []
	nse.drawOps.append(newDrawOp())
	return nse
	
func newDrawOp():
	var ndo
	ndo.color = "000000"
	ndo.sizePx = 1
	ndo.drawOrder = 99
	return ndo


func drawPreview():
	#There should be an object that draws a point marker at Cell10 size, a square, a polygon, and a line
	#so we can see what these changes look like isolated, and maybe one that draws a little bit of everything?
	pass

#Style entries look like this in an object, where the name is the matchOrder in PraxisMapper's StyleSet
#"10": {
	#"name": "tertiary",
	#"drawOps": [
	  #{
		#"color": "ddddff",
		#"sizePx": 7.5,
		#"drawOrder": 99
	  #},
	  #{
		#"color": "2222FF",
		#"sizePx": 2.5,
		#"drawOrder": 98
	  #}
	#]
  #},
