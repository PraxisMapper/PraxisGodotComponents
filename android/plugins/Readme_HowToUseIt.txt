╔════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════╗
║                                                                                                                                        ║
║                                                                                                                                        ║
║                                    ____           _       _        _              _           _     _ 					             ║
║                                   / ___| ___   __| | ___ | |_     / \   _ __   __| |_ __ ___ (_) __| |  				                 ║                  
║                                  | |  _ / _ \ / _` |/ _ \| __|   / _ \ | '_ \ / _` | '__/ _ \| |/ _` |					             ║
║                                  | |_| | (_) | (_| | (_) | |_   / ___ \| | | | (_| | | | (_) | | (_| |					             ║
║                                   \____|\___/ \__,_|\___/ \__| /_/   \_\_| |_|\__,_|_|  \___/|_|\__,_|					             ║
║                                       ____ ____  ____    ____                 _     _                 					             ║
║                                      / ___|  _ \/ ___|  |  _ \ _ __ _____   _(_) __| | ___ _ __       					             ║
║                                     | |  _| |_) \___ \  | |_) | '__/ _ \ \ / / |/ _` |/ _ \ '__|      					             ║
║                                     | |_| |  __/ ___) | |  __/| | | (_) \ V /| | (_| |  __/ |         					             ║
║                                      \____|_|   |____/  |_|   |_|  \___/ \_/ |_|\__,_|\___|_|         					             ║
║                                                                                                                                        ║
║                                                                                                                                        ║
║                                                                                                             by Lunatik Games   /\_/\   ║
║                                                                                                        lunatik.dev@gmail.com  ( o.o )  ║
║                                                                                                        www.lunatik-games.dev   > ^ <   ║
╠════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════╣
║                                                                                                                                        ║
║  Plugin name:                                                                                                                          ║
║     - GodotAndroidGpsProvider                                                                                                          ║
║                                                                                                                                        ║
║  Plugin signals:                                                                                                                       ║
║     - on_request_precise_gps_result(granted: boolean)                                                                                  ║
║     - on_request_approximate_gps_result(granted: boolean)                                                                              ║
║     - on_location_settings_check_result(available: boolean)                                                                            ║
║     - on_monitoring_location_result(location: Dictionary)                                                                              ║
║     - on_last_location_result(location: Dictionary)                                                                                    ║
║     - on_address_from_location_result(code: int, address: Dictionary)                                                                  ║
║     - on_address_from_location_failed(code: int, error: String)                                                                        ║
║                                                                                                                                        ║
║  Plugins methods:                                                                                                                      ║
║     - request_approximate_gps_permission() → Void                                                                                      ║
║     - request_precise_gps_permission()     → Void                                                                                      ║
║     - check_location_settings(accuracy: int, time_interval: int, minimal_distance: float, wait_for_accurate_location: boolean) → Void  ║
║     - open_app_settings()                  → Void                                                                                      ║
║     - get_last_location()                  → Void                                                                                      ║
║     - start_monitoring(accuracy: int, time_interval: int, minimal_distance: float, wait_for_accurate_location: boolean)        → Void  ║
║     - stop_monitoring()                    → Void                                                                                      ║
║     - is_approximate_permission_granted()  → boolean                                                                                   ║
║     - is_precise_permission_granted()      → boolean                                                                                   ║
║     - get_accuracy_high()                  → int                                                                                       ║
║     - get_accuracy_balanced_power()        → int                                                                                       ║
║     - get_accuracy_low_power()             → int                                                                                       ║
║     - get_accuracy_passive()               → int                                                                                       ║
║     - get_distance_between(latitude1: float, longitude1: float, latitude2: float, longitude2: float) → float                           ║
║     - get_address_from_location(code: int, latitude: float, longitude: float)                        → Void                            ║
║                                                                                                                                        ║
║                                                                                                                                        ║
╚════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════╝


╔════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════╗
║                                                                                                                                        ║
║          How to use it                                                                                                                 ║
║                                                                                                                                        ║
╠════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════╣
║                                                                                                                                        ║
║  1. Install Android Build Template:                                                                                                    ║
║                                                                                                                                        ║
║ 		Project > Install Android Build Template > Install                                                                               ║
║                                                                                                                                        ║
║                                                                                                                                        ║
║ 2. Copy the following files to the "{godot_project}/android/plugins" folder:                                                           ║
║		- "GodotAndroidGpsProvider.release.aar"                                                                                          ║
║		- "GodotAndroidGpsProvider.gdap"                                                                                                 ║
║                                                                                                                                        ║
║                                                                                                                                        ║
║ 3. Configure the "Export" section:                                                                                                     ║
║ 		                                                                                                                                 ║
║ 		3.1. Project > Export                                                                                                            ║
║                                                                                                                                        ║
║ 		3.2. Add > Android                                                                                                               ║
║                                                                                                                                        ║
║ 		3.3. Check "Use Custom Build" (Godot 3.5)                                                                                        ║
║ 		           "Use Gradle Build" (Godot 4.0)                                                                                        ║
║                                                                                                                                        ║
║ 		3.4. Change the MinSDK to 24 or higher                                                                                           ║
║                                                                                                                                        ║
║ 		3.5. Check "Godot Android Gps Provider" plugin                                                                                   ║
║                                                                                                                                        ║
║                                                                                                                                        ║
║ 4. Modify the Android template:                                                                                                        ║
║ 		#PRAXISMAPPER NOTE: this part is probably unnecessary and for older Godot versions.                                                                                       ║
║ 		4.1. Open the file "{godot_project}/android/build/src/com/godot/game/GodotApp.java"                                              ║
║                                                                                                                                        ║
║ 		4.2. Change import line:                                                                                                         ║
║ 				From "import org.godotengine.godot.FullScreenGodotApp;"                                                                  ║
║ 				To 	 "import dev.lunatik.godot.plugin.gps_provider.ui.BaseActivity;"                                                     ║
║                                                                                                                                        ║
║ 		4.3. Change class declaration line:                                                                                              ║
║ 				From "public class GodotApp extends FullScreenGodotApp {"                                                                ║
║ 				To 	 "public class GodotApp extends BaseActivity {"                                                                      ║
║                                                                                                                                        ║
║                                                                                                                                        ║
║ 5. Implement script on Godot (full code in example project folder)                                                                     ║
║                                                                                                                                        ║
║                                                                                                                                        ║
╚════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════╝

