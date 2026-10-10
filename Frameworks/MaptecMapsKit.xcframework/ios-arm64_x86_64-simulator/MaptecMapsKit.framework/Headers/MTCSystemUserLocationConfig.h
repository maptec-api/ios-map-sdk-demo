#import <CoreLocation/CoreLocation.h>
#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/**
 系统定位源配置。

 System user location source configuration.

 该对象只影响内置系统定位源的 `CLLocationManager`。当使用自定义 `userLocationProvider` 时，这里的配置不会自动生效。
 This object only affects the built-in system location source's `CLLocationManager`. It does not automatically apply when using a custom `userLocationProvider`.
 */
NS_SWIFT_NAME(MTCSystemUserLocationConfig)
@interface MTCSystemUserLocationConfig : NSObject <NSCopying>

/**
 期望的定位精度，对应 `CLLocationManager.desiredAccuracy`。

 Desired location accuracy, mapped to `CLLocationManager.desiredAccuracy`.

 默认值为 `kCLLocationAccuracyBest`。
 The default is `kCLLocationAccuracyBest`.
 */
@property (nonatomic) CLLocationAccuracy desiredAccuracy;

/**
 最小位移阈值，单位为米，对应 `CLLocationManager.distanceFilter`。

 Minimum distance filter in meters, mapped to `CLLocationManager.distanceFilter`.

 默认值为 `kCLDistanceFilterNone`。
 The default is `kCLDistanceFilterNone`.
 */
@property (nonatomic) CLLocationDistance distanceFilter;

@end

NS_ASSUME_NONNULL_END
