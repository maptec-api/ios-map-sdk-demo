#import <CoreLocation/CoreLocation.h>
#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@class MTCClusterPointStyle;

/**
 聚合覆盖物单点。

 A point in a cluster overlay.

 `MTCClusterPoint` 包含 WGS84 坐标、可选业务标识和可选逐点样式。点的 `identifier` 会在叶子点点击命中时回传。
 `MTCClusterPoint` contains a WGS84 coordinate, an optional business identifier, and an optional per-point style. The point `identifier` is returned for leaf hit events.
 */
NS_SWIFT_NAME(MTCClusterPoint)
@interface MTCClusterPoint : NSObject <NSCopying>

/**
 使用坐标创建聚合单点。

 Creates a cluster point with a coordinate.

 @param coordinate 点坐标。The point coordinate.
 */
- (instancetype)initWithCoordinate:(CLLocationCoordinate2D)coordinate;

/**
 使用坐标和业务标识创建聚合单点。

 Creates a cluster point with a coordinate and business identifier.

 @param coordinate 点坐标。The point coordinate.
 @param identifier 业务标识，可为空。The business identifier, which may be `nil`.
 */
- (instancetype)initWithCoordinate:(CLLocationCoordinate2D)coordinate
                        identifier:(nullable NSString *)identifier NS_DESIGNATED_INITIALIZER;

/**
 使用默认坐标 `{0, 0}` 创建聚合单点。

 Creates a cluster point with default coordinate `{0, 0}`.
 */
- (instancetype)init;

/**
 点坐标。

 The point coordinate.
 */
@property (nonatomic, readonly) CLLocationCoordinate2D coordinate;

/**
 业务标识。

 Business identifier.

 默认值为 `nil`。当叶子点被命中时可通过 `MTCClusterHit.pointIdentifier` 读取。
 The default value is `nil`. When a leaf point is hit, read it from `MTCClusterHit.pointIdentifier`.
 */
@property (nonatomic, copy, readonly, nullable) NSString *identifier;

/**
 单点标题。

 Leaf point title.

 默认值为 `nil`。当逐点样式和默认单点样式没有设置文字时，底层使用该值作为叶子点文字。
 The default value is `nil`. The renderer uses this value as the leaf text when neither the per-point style nor the default point style provides text.
 */
@property (nonatomic, copy, nullable) NSString *title;

/**
 逐点样式。

 Per-point style.

 设置时会复制传入对象。默认值为 `nil`，表示使用 `MTCCluster.defaultPointStyle`。
 The assigned object is copied. The default value is `nil`, which means using `MTCCluster.defaultPointStyle`.
 */
@property (nonatomic, copy, nullable) MTCClusterPointStyle *style;

@end

NS_ASSUME_NONNULL_END
