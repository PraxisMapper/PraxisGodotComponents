# PraxisGodotComponents
A set of pre-built scenes and scripts for using a PraxisMapper server from a Godot 4.2 client. Currently matches up to Release 11 of PraxisMapper.

## How To Use These:
1) Download this repo.
2) Open the project in Godot
3) Click Project/Install Android Build Template and let it copy the necessary files in place
4) Export the project to an Android device! (Or debug it from your PC.)
   
 -- OR --
 
1) Drop all of the folders in this repo (NOT files in the top-level folder, like project.godot and export_presets.cfg) into your existing game template
2) Enable the PraxisMapperGPSPlugin in the Plugins tab
3) Start using the nodes as you need

## Debug/Development Use:
When running from a PC, instead of using the GPS Provider, a small set of buttons will appear in the upper left corner of the screen. These can be clicked to navigate 1 10-digit PlusCode (Cell10) in that direction.
You can also push an Arrow key to move 1 cell per frame.

In Scripts/PraxisMapper.gd, you can change debugStartingPlusCode to set where your client begins play at in debug/development. Several Places are available in comments as quick reference options, but feel free to set your to a more relevant coordinate.

# Nodes
* PraxisMapper/APICalls/PraxisEndpoints: A node with a function for each default PraxisMapper API endpoint. All call the same response_data signal when completed, so one node can handle one request at a time. The preferred class to use right now.
* PraxisMapper/APICalls/PraxisAPICall: A class with a function for each default PraxisMapper API endpoint that waits for a response and returns a properly-shaped object in the same call. Not properly async, but slightly simpler to use. Not recommended but available.
* PraxisMapper/Controls/DebugMovement: A small box with 4 directional arrows and a label indicating the current PlusCode. Arrows will shift the game's current position 1 cell in the appropriate direction.
* PraxisMapper/Controls/MapTile: A node that handles display a MapTile from the PraxisMapper server. Can be set to draw from an offset of the current PlusCode automatically, to refresh on a timer, and more.
* PraxisMapper/Scripts/PlusCodes: A script with static methods for manipulating PlusCodes. 
* PraxisMapper/Scripts/PraxisMapper: The core class for PraxisMapper. Should probably be an autoload class in your project to maintain global availability. Many static methods and properties, as the instanced stuff is primarily for communicating with the Android GPS plugin.

## Scenes:
* PraxisMapper/Scenes/LoadingModal: A simple blocking popup. Discards inputs while it's visible on-screen.
* PraxisMapper/Scenes/LoginScene: An example login screen. Takes a username and password (and for development, a server URL) to connect with. Can create an account by filling in username and password and clicking Create instead of Login. Auto-saves successful credentials and auto-connects on future launches. The default screen in the included project
* Scenes/OverheadView: The second screen visible when running the default project. Loads a grid of Maptiles from the server centered on the current PlusCode. 
