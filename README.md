# PraxisGodotComponents
A set of pre-built scenes and scripts for using a PraxisMapper server from a Godot 4.2 client. Currently matches up to Release 11+ of PraxisMapper.

## How To Use These:
1) Download this repo.
2) Open the project in Godot
3) Click Project/Install Android Build Template and let it copy the necessary files in place
4) Export the project to an Android device! (Or debug it from your PC.)
   
 -- OR --
 
1) Download the latest release zip and extract everything there to the top level of your Godot project.
2) Enable the PraxisMapperGPSPlugin in the Plugins tab
3) Start using the nodes as you need

## Debug/Development Use:
When running from a PC, instead of using the GPS Provider, a small set of buttons will appear in the upper left corner of the screen. These can be clicked to navigate 1 10-digit PlusCode (Cell10) in that direction.
You can also push an Arrow key to move 1 cell per frame.

In Scripts/PraxisMapper.gd, you can change debugStartingPlusCode to set where your client begins play at in debug/development. Several Places are available in comments as quick reference options, but feel free to set your to a more relevant coordinate.

# Script Documentation

## PraxisCore
PraxisCore is intended to be an Autoload entry, always present and available. It handles the common functionality across all modes and basic GPS interaction.

### Signals
* plusCode_changed(current, previous): Fires off when the player moves into a new PlusCode10. PlusCode10s are roughly 45 feet (15 meters) in length or width, and are the minimum reliable area you can detect on phones. More precise grid coordinates require ideal conditions and good GPS hardware. 
* location_changed: Fires off each time the GPS location changes. May fire up to twice a second with the current native GPS plugin. PraxisMapper generally does not do anything directly related to GPS coordinates, but this is provided so you can if you choose.

### Vars 
* debugStartingPlusCode: when debugging on a PC, which PlusCode to use as the current position on start. Has several options available in comments.
* currentPlusCode: The current recorded PlusCode visited. Any component can use this to identify where the user is currently at.
* lastPlusCode: The previous recorded PlusCode visited. Can be useful to identify when leaving areas.
* const resolutionCell12Lat = .000025 / 5 :The height in degrees of a Cell12
* const resolutionCell12Lon = .00003125 / 4 :The width in degrees of a Cell12
* const resolutionCell11Lat = .000025 :The height in degrees of a Cell11
* const resolutionCell11Lon = .00003125 :The width in degrees of a Cell11 
* const resolutionCell10 = .000125 :The size in degrees of a Cel10, square
* const resolutionCell8 = .0025 :The size in degrees of a Cell8, square
* const resolutionCell6 = .05: The size in degrees of a Cell6, square
* const resolutionCell4 = 1 : The size in degrees of a Cell4, square
* const resolutionCell2 = 20: The size in degrees of a Cell2, square
* const metersPerDegree = 111111 :The count of meters in 1 degree of longitude at the equator.
* const oneMeterLat = 1 / metersPerDegree : How many degrees one meter takes up at the equator.

### Functions
* GetCompassHeading(): Returns the compass heading for the direction the device is facing. Is in radians, so can be directly set to a Texture2D's rotation property.
* ForceChange(plusCode): Sets currentPlusCode to the given PlusCode value. Used by the debug GPS control.
* GetFixedRNGForPluscode(plusCode): Returns an RNG instance seeded with the hash of the given PlusCode. Useful for ensuring all players see the same thing at the same place. Not guarenteed to be universally unique on Cell6 or bigger cells, duplicate results will appear somewhere on the planet with Cell8 or smaller cells.
* GetStyle(styleName): Loads JSON style data to be used by another node. PraxisGodotComponents current has 3: mapTiles (duplicates mapTiles drawing on the server, roughly based on OSMCarto), suggestedmini(specific for minimized offline data), adminBoundsFilled(mirrors the same style on the server).
* MakeMinimizedOfflineTiles(plusCode): Given a Cell6 PlusCode, creates the images used to display and identify locations and names.
* MakeOfflineTiles(plusCode, scale = 1): Given a Cell6 or Cell8 PlusCode, creates the visible map tile. If a Cell6, draws all 400 Cell8 maptiles contained. If a Cell8, draws only the requested one (though all Cell6 data must be loaded and draw to do this)
* DistanceDegreesToMetersLat(degrees): Returns the distance in meters that the given degrees distance is long.
* DistanceDegreesToMetersLon(degrees, lat): Returns the distance in meters that the given degrees distance is long, adjusting for the current latitude.
* DistanceMetersToDegreesLat(meters): Returns the distance in degrees that the given meters distance is long.
* DistanceMetersToDegreesLon(meters, lat): Returns the distance in degrees that the given meters distance is long, adjusting for the current latitude.
* MetersToFeet(meters): A convenience method for getting imperial values from metric distances.

## PraxisOfflineData
PraxisOfflineData is the static class for checking full, drawable offline data, either bundled with the game in the res://OfflineData folder when it was compiled or downloaded and placed in user://Data while running. Minimzed offline data is handled elsewhere for now.

### Functions
* GetDataFromZip(plusCode6): Loads the map data on the given Cell6 area for processing. Either the data will be in res://OfflineData/Cell2/Cell4.zip, or in user://Data/Cell4.zip. EX: 223344 is a JSON file in res://OfflineData/22/2233.zip or user://Data/2233.zip
* GetPlacesPresent(plusCode10): returns a list of entries of places found at the given Cell10. Can return both mapData and adminBounds entries at once if both are in the source data. Entries are {name, category, typeId}. category is the style the entry is in, and typeId is the id value in the style. EX: category = adminBoundsFilled and typeId = 1 indicates a Country, where category = mapTiles and typeID = 10 indicates a tertiary road.
* IsPlusCodeInPlace(plusCode, place): Returns true if the given place (an entry from the dataset loaded by GetDataFromZip) contains the given 10-digit PlusCode.
* IsPointInPlace(point, place): Returns true if the given place (an entry from the dataset loaded by GetDataFromZip) contains the given Vector2 point. This point must be in the area coordinates used by the dataset, returned by PlusCodeToDataCoords.
* PlusCodeToDataCoords(plusCode): Transforms the PlusCode given into localized coordinates usable for other functions in this method. Will be a point in the 6400x10000 grid made by the Cell6 data loaded.

## PlusCodes
PlusCodes is the static class that handles all things related to Open Location Codes, called PlusCodes because of the + between the 8th and 9th character to help readability. Full PlusCodes can be dropped directly into Google Maps to find a location.

### Vars
* CODE_ALPHABET_: The character used by PlusCodes, in grid order.

### Functions
* ShiftCode(code, xChange, yChange): Returns the PlusCode that is X and Y cells away from the given one, at the same size. EX: if passed in (223344, 1,1), it returns 223355. Can handle negative numbers for going west/south.
* Decode(plusCode): return a Vector2(lon,lat) for the coord pair representing the southwest corner of the given PlusCode
* EncodeLatLon(lat, lon): returns the Cell10 PlusCode (format 22334455+66) for the given coordinate point
* EncodeLatLonSize(lat, lon, size): returns the Cell(size) PlusCode for the given coordinate point. Takes 2,4,6,8,10, or 11 as size values. Cell-11 values are possible on mobile devices, but these are only accurate under ideal conditions and the PraxisGodotComponents do not currently support Cell-11 resolution values everywhere.
* RemovePlus(plusCode): a helper to trim the + out of a plusCode, so that processing the string can be done with a simple incrementing index without consideration for the + in position 8.
* GetLetterIndex(character): Returns the index of the given letter in CODE_ALPHABET_, or -1 if its not in that string.

# Controls and Nodes
* PraxisMapper/APICalls/PraxisEndpoints: A node with a function for each default PraxisMapper API endpoint. All call the same response_data signal when completed, so one node can handle one request at a time. The preferred class to use right now.
* PraxisMapper/APICalls/PraxisAPICall: A class with a function for each default PraxisMapper API endpoint that waits for a response and returns a properly-shaped object in the same call. Not properly async, but slightly simpler to use. Not recommended but available.
* PraxisMapper/Controls/DebugMovement: A small box with 4 directional arrows and a label indicating the current PlusCode. Arrows will shift the game's current position 1 cell in the appropriate direction. Automatically attached by PraxisCore when no GPS hardware is found, as on a PC.
* PraxisMapper/Controls/MapTile: A node that handles display a MapTile from the PraxisMapper server. Can be set to draw from an offset of the current PlusCode automatically, to refresh on a timer, and more.
* PraxisMapper/Controls/CellTracker: Tracks Cell10s visited by calling Add(plusCode) and Delete(plusCode) as necessary. Auto-saves on each call.
* PraxisMapper/FullOffline/FullOfflineTiles: Creates all map tiles for a Cell6 when GetAndProcessData(plusCode6, scale = 1) is called. Scale can be increased for higher-res textures. Has its own display banner to inform the user of processing. Automatically added and removed from the tree by PraxisCore.MakeOfflineTiles(plusCode6, scale = 1)
* PraxisMapper/MinimizedOffline/MinOfflineTiles: Creates all map tiles for a Cell6 when GetAndProcessData(plusCode6, styleSet) is called. styleSet must be "suggestedmini" with the default styles. Processes silently and invisibly, no notification to the user is given. Automatically added and removed from the tree by PraxisCore.MakeMinimizedOfflineTiles(plusCode6)
* PraxisMapper/Scripts/PlusCodes: A script with static methods for manipulating PlusCodes. 
* PraxisMapper/Scripts/PraxisMapper: The core class for PraxisMapper. Should probably be an autoload class in your project to maintain global availability. Many static methods and properties, as the instanced stuff is primarily for communicating with the Android GPS plugin.

## Scenes:
* PraxisMapper/Scenes/LoadingModal: A simple blocking popup. Discards inputs while it's visible on-screen.
* PraxisMapper/Scenes/LoginScene: An example login screen. Takes a username and password (and for development, a server URL) to connect with. Can create an account by filling in username and password and clicking Create instead of Login. Auto-saves successful credentials and auto-connects on future launches. The default screen in the included project

