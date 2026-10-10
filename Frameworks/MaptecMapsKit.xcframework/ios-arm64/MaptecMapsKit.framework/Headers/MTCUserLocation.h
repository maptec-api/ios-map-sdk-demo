#import <CoreLocation/CoreLocation.h>
#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/**
 用户定位状态。

 User location state.

 该对象由 SDK 内部维护。`MTCMapView.userLocation` 返回当前用户定位状态，业务方只读访问。
 This object is maintained by the SDK. `MTCMapView.userLocation` returns the current user-location state for read-only application access.
 */
NS_SWIFT_NAME(MTCUserLocation)
@interface MTCUserLocation : NSObject

/**
 位置信息。

 Location information.

 如果 `MTCMapView.showsUserLocation` 为 `NO`，或者尚未定位成功，则该值为 `nil`。
 This value is `nil` when `MTCMapView.showsUserLocation` is `NO`, or when the user location has not been successfully determined.
 */
@property (nonatomic, strong, readonly, nullable) CLLocation *location;

/**
 Heading 信息。

 Heading information.

 如果 SDK 尚未收到有效 heading，则该值为 `nil`。
 This value is `nil` until the SDK receives a valid heading.
 */
@property (nonatomic, strong, readonly, nullable) CLHeading *heading;

/**
 位置信息是否已过期。仅当 `location` 不为 `nil` 时有意义。

 Whether the location is stale. Meaningful only when `location` is not `nil`.
 */
@property (nonatomic, readonly, getter=isLocationStale) BOOL locationStale;

@end

NS_ASSUME_NONNULL_END
