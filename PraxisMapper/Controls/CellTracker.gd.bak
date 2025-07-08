extends Node
class_name CellTracker
#NOTE: use Components/CellTrackerDrawer to get a visualization on this

var fileName = "user://Data/Explored.json"
var visited = {}

func _ready():
	Load()
	PraxisCore.plusCode_changed.connect(AutoUpdate)

func Load():
	var recentFile = FileAccess.open(fileName, FileAccess.READ)
	if (recentFile == null):
		return
	else:
		var json = JSON.new()
		json.parse(recentFile.get_as_text())
		var info = json.get_data()
		visited = info
		recentFile.close()
	
func Save():
	var recentFile = FileAccess.open(fileName, FileAccess.WRITE)
	if (recentFile == null):
		print(FileAccess.get_open_error())
	
	var json = JSON.new()
	recentFile.store_string(json.stringify(visited))
	recentFile.close()
	
func AutoUpdate(current, old):
	Add(current)

func Add(plusCode10):
	plusCode10 = plusCode10.replace("+", "").substr(0,10)
	visited[plusCode10] = true
	Save()
	
func Remove(plusCode10):
	plusCode10 = plusCode10.replace("+", "").substr(0,10)
	visited.erase(plusCode10)
	Save()
