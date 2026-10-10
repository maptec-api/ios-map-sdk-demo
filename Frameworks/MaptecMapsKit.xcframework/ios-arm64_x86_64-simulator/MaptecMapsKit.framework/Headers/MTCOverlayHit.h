#import <CoreGraphics/CoreGraphics.h>
#import <CoreLocation/CoreLocation.h>
#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/**
 覆盖物命中信息。

 Overlay hit information.

 `MTCOverlayHit` 描述一次覆盖物交互命中的屏幕位置和地理坐标。普通覆盖物会收到该基类；需要额外命中详情的覆盖物会使用子类，例如 `MTCClusterHit`。
 `MTCOverlayHit` describes the screen point and geographic coordinate for one overlay interaction. Regular overlays receive this base class; overlays with additional hit details use subclasses, such as `MTCClusterHit`.
 */
NS_SWIFT_NAME(MTCOverlayHit)
@interface MTCOverlayHit : NSObject <NSCopying>

- (instancetype)init NS_UNAVAILABLE;
+ (instancetype)new NS_UNAVAILABLE;

/**
 创建覆盖物命中信息。

 Creates overlay hit information.

 @param screenPoint 命中的屏幕坐标，单位为 point。The hit screen point, in points.
 @param coordinate 命中位置对应的地理坐标。The geographic coordinate for the hit.
 */
- (instancetype)initWithScreenPoint:(CGPoint)screenPoint
                         coordinate:(CLLocationCoordinate2D)coordinate NS_DESIGNATED_INITIALIZER;

/**
 命中的屏幕坐标，单位为 point。

 The hit screen point, in points.
 */
@property (nonatomic, readonly) CGPoint screenPoint;

/**
 命中位置对应的地理坐标。

 The geographic coordinate for the hit.
 */
@property (nonatomic, readonly) CLLocationCoordinate2D coordinate;

@end

NS_ASSUME_NONNULL_END
