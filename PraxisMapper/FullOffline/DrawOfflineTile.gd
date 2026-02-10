extends Node2D
class_name DrawOfflineTile

#This is for drawing map tiles directly in the client from Offline/V2 data
#TODO: 
# Add support for a style to force polys to draw as lines. For adminbounds.
# add support to draw places by name, also for adminbounds
# --that code is 
#		var r = (int(entry.nid) % 256) / 256.0
#		var g = (int(entry.nid / 256) % 256) / 256.0
#		var b = (int(entry.nid / 65536) % 256) / 256.0 
#		var nameColor = Color(r, g, b)

var theseentries = null
var thisscale = 1

var commands = []

#NOTE: drawOps are drawn in order, so the earlier one has the higher LayerId in PraxisMapper style language.
#the value/id/order is the MatchOrder for the style in PraxisMapper server

#Perf-testing: objects are drawn in 1.1759s as part of the _draw call.
#
#This is set from outside.
var style #same logic as for NameTiles
var plusCode6 = ''

func DrawSingleTile(entries, scale, plusCode = ''):
	DrawOfflineTile(entries, scale, plusCode)

func DrawOfflineTile(entries, scale, plusCode = ''):
	theseentries = entries
	thisscale = scale
	plusCode6 = plusCode
	queue_redraw()

func _draw():
	if theseentries == null:
		return
	
	var scale = thisscale
	var width = 320 * 20 # 6400 # should be scaled?
	var height = 500 * 20 #= 10000
	#REMEMBER: PlusCode origin is at the BOTTOM-left, these draw calls use the TOP left.
	#This should do the same invert drawing that PraxisMapper does server-side.
	draw_set_transform(Vector2(0,0), 0, Vector2(1,-1))

	var bgCoords = PackedVector2Array()
	bgCoords.append(Vector2(0,0))
	bgCoords.append(Vector2(width * scale,0))
	bgCoords.append(Vector2(width * scale,height * scale))
	bgCoords.append(Vector2(0,height * scale))
	bgCoords.append(Vector2(0,0))
	draw_colored_polygon(bgCoords, style["9999"].drawOps[0].color) 
	var orderedDrawCommands = {}
	
	for key in style.keys():
		if (key == "colorByName"):
			continue
		for op in style[key].drawOps:
			orderedDrawCommands[op.drawOrder] = []
	
	var start = Time.get_unix_time_from_system()
	#entries has a dictionary, each entry is a big list of coord pairs
	for entry in theseentries:
		#If this entry isn't in our current style, skip it.
		if !style.has(str(int(entry.tid))):
			continue
		
		var thisStyle = style[str(int(entry.tid))]
		var lineSize = 1.0 * scale

		#for possibleDraw in style:
			#var pd = style[possibleDraw].drawOps
			#for do in pd:
				#if !orderedDrawCommands.has(do.drawOrder):
					#orderedDrawCommands[do.drawOrder] = []
		
		for s in thisStyle.drawOps:
			#TODO: check forceLines first and set GT, or do it on draw?
			#var gt = 2 if (entry.gt == 3 and s.forceLines) else entry.gt
			#print(str(entry.nid) + " - layer " + str(s.drawOrder))
			#TODO: load actual name string from data, hash it, use first 6 bytes from that for color.
			var color = s.color
			if style.has("colorByName"):
				if (entry.nid == 0.0):
					continue
				var name = PraxisOfflineData.GetName(plusCode6, entry.nid)
				var hash = name.hash()
				var r = (hash % 256) / 256.0
				var g = ((hash / 256) % 256) / 256.0
				var b = ((hash / 65536) % 256) / 256.0
				color = Color(r, g, b, 0.4)
			orderedDrawCommands[s.drawOrder].push_back({gt = entry.gt, p = entry.p, size = s.sizePx, color = color})
		
	var drawLevels = orderedDrawCommands.keys()
	drawLevels.sort()
	drawLevels.reverse()
	for entries in drawLevels:
		#These items are sorted server-side when the JSON is created, don't re-order them again.
		#orderedDrawCommands[entries].sort_custom(func(a,b) : return a.size > b.size)

		for odc in orderedDrawCommands[entries]:
			var points = odc.p
			if (scale != 1):
				points = odc.p.duplicate()
				for i in points.size():
					points[i] = points[i] * Vector2(scale, scale)
			
			if (odc.gt == 1):
				#this is just a circle for single points, size is roughly a Cell10
				#4.5 looks good for POIs, but bad for Trees, which there are quite a few of.
				#trees are size 0.2, so I should probably make other elements larger?
				#MOST of them shouldn't be points, but lines shouldn't be a Cell10 wide either.
				draw_circle(points[0], odc.size * 5.0 * scale, odc.color)
			elif (odc.gt == 2):
				#This is significantly faster than calling draw_line for each of these.
				draw_polyline(points, odc.color, odc.size * scale, true) #antialias display image only.
			elif odc.gt == 3:
				#A single color, which is what I generally use.
				draw_colored_polygon(points, odc.color) 

	var end = Time.get_unix_time_from_system()
	print("all objects draw in " + str(end-start))
