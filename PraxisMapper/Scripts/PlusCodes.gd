extends RefCounted
class_name PlusCodes

var SEPARATOR_ = '+'
static var CODE_ALPHABET_ = '23456789CFGHJMPQRVWX'

#var GRID_COLUMNS_ = 4
#var GRID_ROWS_ = 5
#note: a reasonable alternative would be a 3x3 grid in a 9-char code set. 
#would be longer codes but could be number-only, and then indexable similar to S2 codes but 
#in regular rectangles instead.

#for decoding the 11th digit?
#var GRID_ROW_MULTIPLIER = 3125
#var GRID_COL_MULTIPLIER = 1024


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
