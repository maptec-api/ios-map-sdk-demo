#import <CoreGraphics/CoreGraphics.h>
#import <CoreLocation/CoreLocation.h>
#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/**
 地图平面投影坐标点。

 A point in the map's projected coordinate space.

 `MTCMapPoint` 使用地图平面投影坐标，不是屏幕 point/pixel，也不是经纬度。完整世界范围由 `MTCMapSizeWorld` 表示，原点位于世界西北角，x 向东增大，y 向南增大。
 `MTCMapPoint` uses projected map coordinates, not screen points/pixels or latitude-longitude values. The full world extent is represented by `MTCMapSizeWorld`; the origin is at the northwest corner of the world, x increases eastward, and y increases southward.
 */
typedef struct {
    /**
     x 坐标。

     The x coordinate.
     */
    double x;

    /**
     y 坐标。

     The y coordinate.
     */
    double y;
} MTCMapPoint;

/**
 地图平面投影尺寸。

 A size in the map's projected coordinate space.
 */
typedef struct {
    /**
     宽度，单位为 map point。

     The width, in map points.
     */
    double width;

    /**
     高度，单位为 map point。

     The height, in map points.
     */
    double height;
} MTCMapSize;

/**
 地图平面投影矩形。

 A rectangle in the map's projected coordinate space.
 */
typedef struct {
    /**
     矩形原点，位于左上角。

     The rectangle origin at the upper-left corner.
     */
    MTCMapPoint origin;

    /**
     矩形尺寸。

     The rectangle size.
     */
    MTCMapSize size;
} MTCMapRect;

/**
 经纬度跨度。

 A latitude-longitude span.
 */
typedef struct {
    /**
     纬度跨度，单位为度。

     The latitude span, in degrees.
     */
    CLLocationDegrees latitudeDelta;

    /**
     经度跨度，单位为度。

     The longitude span, in degrees.
     */
    CLLocationDegrees longitudeDelta;
} MTCCoordinateSpan;

/**
 经纬度区域。

 A latitude-longitude region.
 */
typedef struct {
    /**
     区域中心点。

     The center coordinate of the region.
     */
    CLLocationCoordinate2D center;

    /**
     区域跨度。

     The span of the region.
     */
    MTCCoordinateSpan span;
} MTCCoordinateRegion;

/**
经纬度边界。

A latitude-longitude bounds.
 */
typedef struct {
    /**
     西南角坐标。

     The southwest coordinate.
     */
    CLLocationCoordinate2D southwest;

    /**
     东北角坐标。

     The northeast coordinate.
     */
    CLLocationCoordinate2D northeast;
} MTCCoordinateBounds;

/**
 空经纬度边界。

 A null latitude-longitude bounds.

 `MTCCoordinateBoundsNull` 用作无效或清除限制的哨兵值，不能表示有效的限制区域。
 `MTCCoordinateBoundsNull` is a sentinel value for an invalid or cleared limit and cannot represent a valid limit region.
 */
FOUNDATION_EXPORT const MTCCoordinateBounds MTCCoordinateBoundsNull;

/**
 完整世界的地图平面投影尺寸。

 The projected map size of the full world.
 */
FOUNDATION_EXPORT const MTCMapSize MTCMapSizeWorld;

/**
 完整世界的地图平面投影矩形。

 The projected map rectangle of the full world.
 */
FOUNDATION_EXPORT const MTCMapRect MTCMapRectWorld;

/**
 零矩形。

 The zero map rectangle.
 */
FOUNDATION_EXPORT const MTCMapRect MTCMapRectZero;

/**
 空矩形。

 A null map rectangle.
 */
FOUNDATION_EXPORT const MTCMapRect MTCMapRectNull;

/**
 创建地图平面投影坐标点。

 Creates a map point.
 */
CG_INLINE MTCMapPoint MTCMapPointMake(double x, double y) {
    MTCMapPoint point;
    point.x = x;
    point.y = y;
    return point;
}

/**
 创建地图平面投影尺寸。

 Creates a map size.
 */
CG_INLINE MTCMapSize MTCMapSizeMake(double width, double height) {
    MTCMapSize size;
    size.width = width;
    size.height = height;
    return size;
}

/**
 创建地图平面投影矩形。

 Creates a map rectangle.
 */
CG_INLINE MTCMapRect MTCMapRectMake(double x, double y, double width, double height) {
    MTCMapRect rect;
    rect.origin = MTCMapPointMake(x, y);
    rect.size = MTCMapSizeMake(width, height);
    return rect;
}

/**
 创建经纬度跨度。

 Creates a coordinate span.
 */
CG_INLINE MTCCoordinateSpan MTCCoordinateSpanMake(CLLocationDegrees latitudeDelta,
                                                  CLLocationDegrees longitudeDelta) {
    MTCCoordinateSpan span;
    span.latitudeDelta = latitudeDelta;
    span.longitudeDelta = longitudeDelta;
    return span;
}

/**
 创建经纬度区域。

 Creates a coordinate region.
 */
CG_INLINE MTCCoordinateRegion MTCCoordinateRegionMake(CLLocationCoordinate2D center,
                                                      MTCCoordinateSpan span) {
    MTCCoordinateRegion region;
    region.center = center;
    region.span = span;
    return region;
}

/**
创建经纬度边界。

Creates coordinate bounds.
 */
CG_INLINE MTCCoordinateBounds MTCCoordinateBoundsMake(CLLocationCoordinate2D southwest,
                                                      CLLocationCoordinate2D northeast) {
    MTCCoordinateBounds bounds;
    bounds.southwest = southwest;
    bounds.northeast = northeast;
    return bounds;
}

/**
 判断经纬度边界是否为空。

 Returns whether the coordinate bounds are null.
 */
FOUNDATION_EXPORT BOOL MTCCoordinateBoundsIsNull(MTCCoordinateBounds bounds);

/**
 判断地图矩形是否为空矩形。

 Returns whether the map rectangle is null.
 */
FOUNDATION_EXPORT BOOL MTCMapRectIsNull(MTCMapRect mapRect);

/**
 将经纬度坐标转换为地图平面投影坐标。

 Converts a latitude-longitude coordinate to a projected map point.
 */
FOUNDATION_EXPORT MTCMapPoint MTCMapPointForCoordinate(CLLocationCoordinate2D coordinate);

/**
 将地图平面投影坐标转换为经纬度坐标。

 Converts a projected map point to a latitude-longitude coordinate.
 */
FOUNDATION_EXPORT CLLocationCoordinate2D MTCCoordinateForMapPoint(MTCMapPoint mapPoint);

/**
 将经纬度边界转换为地图平面投影矩形。

 Converts coordinate bounds to a projected map rectangle.
 */
FOUNDATION_EXPORT MTCMapRect MTCMapRectForCoordinateBounds(MTCCoordinateBounds bounds);

/**
 将地图平面投影矩形转换为经纬度边界。

 Converts a projected map rectangle to coordinate bounds.
 */
FOUNDATION_EXPORT MTCCoordinateBounds MTCCoordinateBoundsForMapRect(MTCMapRect mapRect);

/**
 返回指定纬度处每个 map point 对应的米数。

 Returns the number of meters represented by one map point at the specified latitude.
 */
FOUNDATION_EXPORT CLLocationDistance MTCMetersPerMapPointAtLatitude(CLLocationDegrees latitude);

/**
 返回指定纬度处每米对应的 map point 数。

 Returns the number of map points represented by one meter at the specified latitude.
 */
FOUNDATION_EXPORT double MTCMapPointsPerMeterAtLatitude(CLLocationDegrees latitude);

/**
 计算两个地图平面投影坐标点之间的近似距离，单位为米。

 Calculates the approximate distance between two projected map points, in meters.
 */
FOUNDATION_EXPORT CLLocationDistance MTCMetersBetweenMapPoints(MTCMapPoint a, MTCMapPoint b);

#pragma mark - 地理围栏
/**
 判断指定经纬度点是否在给定多边形外环内部（射线法 / Ray-Casting）。

 在 WGS84 二维经纬度平面上计算，适用于跨度数十公里以内的围栏场景。

 @param polygonCoords 多边形外环坐标数组，至少 3 个有效坐标，首尾无需重复闭合
 @param count 坐标数组长度
 @param point 待判定点
 @return YES = 点在多边形内
 */
FOUNDATION_EXPORT BOOL MTCPolygonWGS84ContainsPoint(const CLLocationCoordinate2D *polygonCoords, NSUInteger count, CLLocationCoordinate2D point);

/**
 判断指定经纬度点是否在给定圆内（Haversine 球面距离）。

 使用 Haversine 公式直接计算大圆距离（great-circle distance），
 不经过投影变换。在多数场景精度优于 MapKit 的 Mercator 近似法。

 @param center 圆心
 @param radius 半径（单位 米）
 @param point 待判定点
 @return YES = 点在圆内
 */
FOUNDATION_EXPORT BOOL MTCCircleHaversineContainsPoint(CLLocationCoordinate2D center, CLLocationDistance radius, CLLocationCoordinate2D point);

NS_ASSUME_NONNULL_END
