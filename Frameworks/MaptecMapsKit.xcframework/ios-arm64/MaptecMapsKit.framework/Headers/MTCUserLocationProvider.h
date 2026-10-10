#import <CoreLocation/CoreLocation.h>
#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@protocol MTCUserLocationProvider;

/**
 用户定位数据源回调。

 Delegate callbacks for a user location provider.

 Provider 可在任意线程回调；SDK 会在主线程消费定位更新并刷新定位 marker 与相机跟随。
 A provider may call back on any thread; the SDK consumes updates on the main thread before refreshing the user-location marker and camera tracking.
 */
NS_SWIFT_NAME(MTCUserLocationProviderDelegate)
@protocol MTCUserLocationProviderDelegate <NSObject>

/**
 定位数据更新。

 Called when a new location is available.

 @param provider 产生定位更新的数据源。The provider that produced the update.
 @param location 新的定位数据。The new location.
 */
- (void)userLocationProvider:(id<MTCUserLocationProvider>)provider
           didUpdateLocation:(CLLocation *)location;

@optional

/**
 设备 heading 更新。

 Called when a new device heading is available.

 对于 GPS 行进方向，请设置 `CLLocation.course` 并通过 `didUpdateLocation:` 上报；此回调用于指南针/设备朝向。
 For GPS travel direction, set `CLLocation.course` and report it through `didUpdateLocation:`; this callback is for compass/device heading.

 @param provider 产生 heading 更新的数据源。The provider that produced the update.
 @param heading 新的设备 heading，单位为度，真北顺时针。The new device heading in degrees clockwise from true north.
 */
- (void)userLocationProvider:(id<MTCUserLocationProvider>)provider
            didUpdateHeading:(CLLocationDirection)heading;

/**
 定位数据源失败。

 Called when the provider fails.

 @param provider 失败的数据源。The provider that failed.
 @param error 错误信息。The error.
 */
- (void)userLocationProvider:(id<MTCUserLocationProvider>)provider
            didFailWithError:(NSError *)error;

@end

/**
 用户定位数据源。

 User location provider.

 将对象赋值给 `MTCMapView.userLocationProvider` 后，SDK 会使用该数据源替代内置系统定位，并复用 SDK 内部的定位 marker、精度圈、过期态和相机跟随逻辑。传入 `nil` 时恢复内置系统定位。
 Assign an object to `MTCMapView.userLocationProvider` to replace the built-in system location source while still using the SDK's user-location marker, accuracy circle, stale state, and camera tracking logic. Assign `nil` to restore the built-in system provider.
 */
NS_SWIFT_NAME(MTCUserLocationProvider)
@protocol MTCUserLocationProvider <NSObject>

/**
 定位数据源回调代理。

 Delegate for delivering provider updates.

 SDK 设置该属性；provider 不应强引用 delegate。
 The SDK sets this property; providers should not strongly retain the delegate.
 */
@property (nonatomic, weak, nullable) id<MTCUserLocationProviderDelegate> delegate;

/**
 开始更新定位。

 Starts location updates.

 SDK 会在该 provider 成为当前定位数据源且 SDK 准备消费外部定位数据时调用，通常发生在赋值给 `MTCMapView.userLocationProvider` 后。Provider 应通过 delegate 上报 `CLLocation`。
 The SDK calls this when the provider becomes the current user-location source and the SDK is ready to consume external updates, typically after it is assigned to `MTCMapView.userLocationProvider`. Providers should report `CLLocation` values through the delegate.
 */
- (void)startUpdatingLocation;

/**
 停止更新定位。

 Stops location updates.

 SDK 会在数据源被替换、地图释放或不再需要外部定位时调用。
 The SDK calls this when the provider is replaced, the map is released, or external updates are no longer needed.
 */
- (void)stopUpdatingLocation;

@optional

/**
 开始更新设备 heading。

 Starts device-heading updates.
 */
- (void)startUpdatingHeading;

/**
 停止更新设备 heading。

 Stops device-heading updates.
 */
- (void)stopUpdatingHeading;

@end

NS_ASSUME_NONNULL_END
