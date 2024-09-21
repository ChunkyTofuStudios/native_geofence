#ifndef NativeGeofencePlugin_h
#define NativeGeofencePlugin_h

#import <Flutter/Flutter.h>

#import <CoreLocation/CoreLocation.h>

@interface NativeGeofencePlugin : NSObject<FlutterPlugin, CLLocationManagerDelegate>

@end
#endif
