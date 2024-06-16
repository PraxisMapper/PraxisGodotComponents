extends Node
class_name PlusCodes

var SEPARATOR_ = '+'
static var CODE_ALPHABET_ = '23456789CFGHJMPQRVWX'

static func EncodeLatLon(lat, lon):
	return EncodeLatLonSize(lat, lon, 10)
	
static func EncodeLatLonSize(lat, lon, size):
	var code = ''
	var digit11 = ''
	var nextLatChar = 0
	var nextLonChar = 0
	
	var xMul = 8000
	var yMul = 8000
	if size == 11:
		xMul *= 4
		yMul *= 5
		
	var currentLat = int(floor((lat + 90) * yMul))
	var currentLon = int(floor((lon + 180) * xMul))
		
	if size == 11:
		var nextLonIndex = (currentLon % 4) 
		var nextLatIndex = (currentLat % 5)
		var indexDigit = (nextLatIndex * 4 + nextLonIndex)
		digit11 = CODE_ALPHABET_[indexDigit]
		currentLat = floor(currentLat / 5)
		currentLon = floor(currentLon / 4)
	
	for i in 5:
		nextLonChar = (currentLon % 20)
		nextLatChar = (currentLat % 20)
		
		code = CODE_ALPHABET_[nextLatChar] + CODE_ALPHABET_[nextLonChar] + code
		currentLat = floor(currentLat / 20)
		currentLon = floor(currentLon / 20)

	code = code + digit11
	
	return code.substr(0, 8) + "+" + code.substr(8, -1)
	
static func RemovePlus(code):
	return code.replace("+", "")
	
static func ShiftCode(code, xChange, yChange):
	#This function is not intended to move a code more than 20 cells in a direction to force carry
	#more than 1 carry/borrow digit right now.
	#that should be done by supplying the substring to move at that level.
	code = RemovePlus(code)
	var xVals = []
	var yVals = []
	
	for i in code.length() / 2:
		var yLet = code.substr(i * 2, 1)
		var xLet = code.substr((i * 2) + 1, 1)
		yVals.push_back(CODE_ALPHABET_.find(yLet))
		xVals.push_back(CODE_ALPHABET_.find(xLet))
		
	if xChange != 0:
		xVals[xVals.size() -1] += xChange
		for i in range(xVals.size() -1, 0, -1):
			if (xVals[i] > 19):
				xVals[i -1] = xVals[i - 1] + (1)
				xVals[i] = xVals[i] - 20
			if (xVals[i] < 0):
				xVals[i -1] = xVals[i - 1] - (1)
				xVals[i] = xVals[i] + 20
		
	if yChange != 0:
		yVals[yVals.size() -1] += yChange
		for i in range(yVals.size() -1, 0, -1):
			if (yVals[i] > 19):
				yVals[i -1] = yVals[i - 1] + (1)
				yVals[i] = yVals[i] - 20
			if (yVals[i] < 0):
				yVals[i -1] = yVals[i - 1] - (1)
				yVals[i] = yVals[i] + 20

	var newCode = ''
	for i in code.length() / 2:
		newCode = newCode + CODE_ALPHABET_[yVals[i]] + CODE_ALPHABET_[xVals[i]]
	
	return newCode
	
static func Decode(plusCode):
	var lat = -90.0
	var lon = -180.0
	plusCode = plusCode.replace("+", "")
	var totalChars = plusCode.length()
	var charsProcessed = 0
	var precision = 20
	var xVal = 0
	var yVal = 0
	while (charsProcessed < totalChars):
		if (charsProcessed < 10):
			xVal = PlusCodes.GetLetterIndex(plusCode[charsProcessed + 1])
			yVal = PlusCodes.GetLetterIndex(plusCode[charsProcessed])
			
			lat += precision * yVal
			lon += precision * xVal
			precision /= 20.0
			charsProcessed += 2
		else:			
			#lat/row is /, column/lon is %
			xVal = PlusCodes.GetLetterIndex(plusCode[charsProcessed]) % 4
			yVal = PlusCodes.GetLetterIndex(plusCode[charsProcessed]) / 4
			
			lon += (xVal * (precision / (4.0 ** (charsProcessed - 9))))
			lat += (yVal * (precision / (5.0 ** (charsProcessed - 9))))
			
			charsProcessed += 1
	return Vector2(lon, lat) #x, y!

static func GetDistanceDegrees(plusCode1, plusCode2):
	var vec1 = PlusCodes.Decode(plusCode1)
	var vec2 = PlusCodes.Decode(plusCode2)
	return vec1.distance_to(vec2)

#NOTE: 0 is NORTH on this function, whereas in most Godot values its EAST
static func GetDirection(plusCode1, plusCode2):
	#adjust the values to have north == 0 instead of east.
	var vec1 = PlusCodes.Decode(plusCode1).rotated(-PI / 2)
	var vec2 = PlusCodes.Decode(plusCode2).rotated(-PI / 2)
	var vecDir = vec1.direction_to(vec2)
	return rad_to_deg(vecDir.angle())

static func GetLetterIndex(letter):
	return CODE_ALPHABET_.find(letter)
