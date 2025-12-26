extends Node
class_name PraxisHelpers

#TODO: Determine better name 
#This is for functions I end up using a lot and don't want to copy-paste
#into a bunch of other files
const yearDivisor = (60 * 60 * 24 * 365)
const weekDivisor = (60 * 60 * 24 * 7)

#TODO: test this, confirm its right. Should be faster this way when I dont do string conversions twice.
static func GetWeeksIntoYear():
	var secondsIntoYear = int(Time.get_unix_time_from_system()) % yearDivisor
	var weeksIntoYear = int(secondsIntoYear / weekDivisor)
	return weeksIntoYear

#This is going to be important and might need to be moves to a PraxisGeometry class later.
#TODO: Num-sides may become a calculated value. Plan on num_sides == Cell10s in circumference, should make 1 point
#for each Cell10, might look better at all sizes. Can do faster point_in_circle() calls instead of polygon intersects.
static func generate_circle_polygon(radius: float, num_sides: int, position: Vector2):
	var angle_delta: float = (PI * 2) / num_sides
	var vector: Vector2 = Vector2(radius, 0)
	var polygon: PackedVector2Array

	for _i in num_sides:
		polygon.append(vector + position)
		vector = vector.rotated(angle_delta)

	return polygon

#should let me quickly time-check functions
static func RunTimerFor(callable, args):
	var start = Time.get_unix_time_from_system()
	var result = callable.callv(args)
	var end = Time.get_unix_time_from_system()
	print("ran " + str(callable) + " in " + str(end - start) + "s")
	return result
	
#NOTE: Requires scaling on receiver's side
static func TranslateLatLonToScreenPixel(geoVector2, baseLatLon):
	var resultDist = baseLatLon - geoVector2
	var screenPix = resultDist * Vector2(-1,1) / Vector2(PraxisCore.resolutionCell12Lon, PraxisCore.resolutionCell12Lat) #cell12 values
	return screenPix

static func TranslatePlusCodeToScreenPixel(plusCode, baseLatLon):
	return TranslateLatLonToScreenPixel(PlusCodes.Decode(plusCode), baseLatLon)

static func TranslatePlusCodeToScreenPixelViaBasePlusCode(plusCodeDest, plusCodeBase):
	return TranslateLatLonToScreenPixel(PlusCodes.Decode(plusCodeDest), PlusCodes.Decode(plusCodeBase))

static func GetRadiusForCircleArea(areaMeters2):
	return sqrt(areaMeters2 / PI) #/ PraxisCore.resolutionCell10 #was for covering full tiles, ignoring now.

#this is unused, consider deleting it.
static func MakeAreaCircle(geoVector2, areaTotalMeters):
	var radius = GetRadiusForCircleArea(areaTotalMeters)
	var height = PraxisCore.DistanceMetersToDegreesLat(radius)
	var width = PraxisCore.DistanceMetersToDegreesLon(radius, geoVector2.x)
	var segmentsPerQuarter = 8
	
	var topSegment = Vector2(0, -height)
	var rightSegment = Vector2(width, 0)
	var bottomSegment = Vector2(0, height)
	var leftSegment = Vector2(-width, 0)
	var results = [topSegment]
	var center = Vector2(0,0)
	#circle.draw_arc(center, ) #May need to do this a few times? or will that look like shit?
	
	#for each point in a segment, calculate the length to that between current and next segment
	#(circles are so much easier than this)
	#Whats the trig for this?
	# xa = r(a)cos(a)
	# ya = r(a)sin(a)
	# ra = some harder sqrt math.
