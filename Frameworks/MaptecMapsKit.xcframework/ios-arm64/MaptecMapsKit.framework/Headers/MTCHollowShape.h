#import <CoreLocation/CoreLocation.h>
#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/**
 中空形状类型。

 The hollow shape type.
 */
typedef NS_ENUM(NSInteger, MTCHollowShapeType) {
    /**
     多边形中空区域。

     A polygon hollow area.
     */
    MTCHollowShapeTypePolygon,

    /**
     圆形中空区域。

     A circular hollow area.
     */
    MTCHollowShapeTypeCircle,
};

/**
 添加中空形状的结果。

 The result of adding a hollow shape.
 */
typedef NS_ENUM(NSInteger, MTCHollowShapeAddResult) {
    /**
     添加成功。

     The hollow shape was added.
     */
    MTCHollowShapeAddResultSuccess,

    /**
     形状无效，例如坐标无效、点数不足、圆心无效或半径不大于 0。

     The shape is invalid, such as invalid coordinates, too few points, an invalid circle center, or a non-positive radius.
     */
    MTCHollowShapeAddResultInvalidShape,

    /**
     形状不在多边形外环内部。

     The shape is not inside the polygon outer ring.
     */
    MTCHollowShapeAddResultOutsidePolygon,

    /**
     形状与多边形外环边界相交。

     The shape intersects the polygon outer boundary.
     */
    MTCHollowShapeAddResultIntersectsPolygonBoundary,

    /**
     形状与已有中空形状相交。

     The shape intersects an existing hollow shape.
     */
    MTCHollowShapeAddResultIntersectsExistingHollow,

    /**
     形状与已有中空形状形成嵌套关系。

     The shape is nested with an existing hollow shape.
     */
    MTCHollowShapeAddResultNestedHollow,

    /**
     形状自身存在边界相交。

     The shape boundary intersects itself.
     */
    MTCHollowShapeAddResultSelfIntersection,
};

/**
 多边形中空区域几何。

 Polygon hollow-area geometry.

 `MTCHollowShape` 是不可变对象。多边形形状会深拷贝传入坐标；圆形形状保存圆心和半径，由 SDK 在渲染时转换为内部环。
 `MTCHollowShape` is immutable. Polygon shapes deep-copy the input coordinates; circle shapes store center and radius and are converted to an internal ring by the SDK when rendered.
 */
NS_SWIFT_NAME(MTCHollowShape)
@interface MTCHollowShape : NSObject <NSCopying>

/**
 使用工厂方法创建中空形状。

 Use the factory methods to create hollow shapes.
 */
- (instancetype)init NS_UNAVAILABLE;

/**
 使用工厂方法创建中空形状。

 Use the factory methods to create hollow shapes.
 */
+ (instancetype)new NS_UNAVAILABLE;

/**
 创建多边形中空形状。

 Creates a polygon hollow shape.

 SDK 会深拷贝传入坐标。有效的多边形中空形状至少需要 3 个有效坐标，且不能自相交；完整校验会在添加到 `MTCPolygon` 时执行。
 The SDK deep-copies the input coordinates. A valid polygon hollow shape needs at least 3 valid coordinates and must not self-intersect; full validation is performed when the shape is added to an `MTCPolygon`.

 @param coordinates 多边形中空区域坐标缓冲区。The polygon hollow coordinate buffer.
 @param count 坐标数量。The number of coordinates.
 */
+ (instancetype)polygonWithCoordinates:(const CLLocationCoordinate2D * _Nullable)coordinates
                                 count:(NSUInteger)count;

/**
 创建圆形中空形状。

 Creates a circular hollow shape.

 圆形中空形状需要有效圆心和大于 0 的半径。完整校验会在添加到 `MTCPolygon` 时执行。
 A circular hollow shape needs a valid center coordinate and a radius greater than 0. Full validation is performed when the shape is added to an `MTCPolygon`.

 @param centerCoordinate 圆心坐标。The center coordinate.
 @param radius 半径，单位为米。The radius in meters.
 */
+ (instancetype)circleWithCenterCoordinate:(CLLocationCoordinate2D)centerCoordinate
                                    radius:(CLLocationDistance)radius;

/**
 中空形状类型。

 The hollow shape type.
 */
@property (nonatomic, readonly) MTCHollowShapeType type;

/**
 多边形中空形状的坐标数量。

 The coordinate count for a polygon hollow shape.

 对圆形中空形状，此值为 0。
 For a circular hollow shape, this value is 0.
 */
@property (nonatomic, readonly) NSUInteger coordinateCount;

/**
 圆形中空形状的圆心坐标。

 The center coordinate for a circular hollow shape.

 对多边形中空形状，此值为 `kCLLocationCoordinate2DInvalid`。
 For a polygon hollow shape, this value is `kCLLocationCoordinate2DInvalid`.
 */
@property (nonatomic, readonly) CLLocationCoordinate2D centerCoordinate;

/**
 圆形中空形状的半径，单位为米。

 The radius of a circular hollow shape, in meters.

 对多边形中空形状，此值为 0。
 For a polygon hollow shape, this value is 0.
 */
@property (nonatomic, readonly) CLLocationDistance radius;

/**
 读取多边形中空形状指定索引处的坐标。

 Returns the coordinate at the specified index for a polygon hollow shape.

 @param index 坐标索引，必须小于 `coordinateCount`。The coordinate index, which must be less than `coordinateCount`.
 */
- (CLLocationCoordinate2D)coordinateAtIndex:(NSUInteger)index;

/**
 批量读取多边形中空形状指定范围内的坐标。

 Reads coordinates in the specified range for a polygon hollow shape.

 @param buffer 接收坐标的缓冲区。The output buffer.
 @param range 要读取的坐标范围。The coordinate range to read.
 */
- (void)getCoordinates:(CLLocationCoordinate2D *)buffer
                 range:(NSRange)range;

@end

NS_ASSUME_NONNULL_END
