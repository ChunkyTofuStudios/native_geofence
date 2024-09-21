#import "AppDelegate.h"
#import "GeneratedPluginRegistrant.h"

#import <geofencing/NativeGeofencePlugin.h>

void registerPlugins(NSObject<FlutterPluginRegistry>* registry) {
  [GeneratedPluginRegistrant registerWithRegistry:registry];
}

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application
    didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
  [GeneratedPluginRegistrant registerWithRegistry:self];
  [NativeGeofencePlugin setPluginRegistrantCallback:registerPlugins];

  // Override point for customization after application launch.
  return [super application:application didFinishLaunchingWithOptions:launchOptions];
}

@end
