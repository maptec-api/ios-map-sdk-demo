#import <CoreLocation/CoreLocation.h>
#import <Foundation/Foundation.h>

#import <MaptecMapsKit/MTCPath.h>

NS_ASSUME_NONNULL_BEGIN

/**
 几何工具函数。

 Geometry utility functions.

 这一组函数负责球面距离、面积、方位角、偏移和路径命中等纯几何计算。
 These functions handle pure geometry operations such as spherical distance, area, heading, offsets, and path hit testing.
 */

/**
 几何计算使用的球体半径，单位为米。

 The spherical radius used by geometry calculations, in meters.

 该值对标 Google Maps 几何工具的公开常量，适合距离、面积、偏移等球面算法。
 This value matches the public radius used by Google Maps geometry helpers and is used by spherical distance, area, and offset calculations.
 */
FOUNDATION_EXPORT const CLLocationDistance MTCGeometryEarthRadius;

/**
 默认路径容差，单位为米。

 The default path tolerance in meters.

 适合 `isLocationOnEdge`、`isLocationOnPath`、`locationIndexOnPath` 等默认容差参数。
 Suitable as the default tolerance for `isLocationOnEdge`, `isLocationOnPath`, and `locationIndexOnPath`.
 */
FOUNDATION_EXPORT const CLLocationDistance MTCGeometryDefaultTolerance;

/**
 计算两点在单位球面上的中心角，单位为弧度。

 Computes the central angle between two coordinates on the unit sphere, in radians.

 输入必须是有效经纬度坐标。两个点相同返回 `0`。
 Both inputs must be valid coordinates. Identical points return `0`.
 */
FOUNDATION_EXPORT double MTCGeometryComputeAngleBetween(CLLocationCoordinate2D from,
                                                        CLLocationCoordinate2D to);

/**
 计算两点球面最短距离，单位为米。

 Computes the shortest spherical distance between two coordinates, in meters.

 该结果基于 `MTCGeometryEarthRadius` 计算，不保证与 `CLLocation` 的距离函数完全一致。
 The result is based on `MTCGeometryEarthRadius` and is not guaranteed to exactly match `CLLocation` distance functions.
 */
FOUNDATION_EXPORT CLLocationDistance MTCGeometryComputeDistanceBetween(CLLocationCoordinate2D from,
                                                                       CLLocationCoordinate2D to);

/**
 计算路径长度，单位为米。

 Computes the path length, in meters.

 只累加相邻点之间的距离，不会自动把首尾闭合。空路径或单点路径返回 `0`。
 This sums only adjacent segments and does not implicitly close the path. Empty or single-point paths return `0`.
 */
FOUNDATION_EXPORT CLLocationDistance MTCGeometryComputeLength(MTCPath *path);

/**
 计算多边形球面面积的绝对值，单位为平方米。

 Computes the absolute spherical area of a polygon, in square meters.

 `polygon` 这里是语义名，实际类型仍为 `MTCPath`。路径少于 3 个点时返回 `0`。
 `polygon` is a semantic name; the actual type is still `MTCPath`. Paths with fewer than 3 points return `0`.
 */
FOUNDATION_EXPORT double MTCGeometryComputeArea(MTCPath *polygon);

/**
 计算多边形球面有符号面积，单位为平方米。

 Computes the signed spherical area of a polygon, in square meters.

 点的顺序决定符号，counter-clockwise 为正、反向为负。路径少于 3 个点时返回 `0`。
 Point order determines the sign, with counter-clockwise positive and reversed order negative. Paths with fewer than 3 points return `0`.
 */
FOUNDATION_EXPORT double MTCGeometryComputeSignedArea(MTCPath *polygon);

/**
 计算从起点到终点的初始方位角，单位为度。

 Computes the initial heading from the source coordinate to the destination coordinate, in degrees.

 结果范围为 `[-180, 180)`，正北为 `0`，顺时针为正。相同点返回 `0`。
 The result is in `[-180, 180)`, with north as `0` and clockwise positive. Identical points return `0`.
 */
FOUNDATION_EXPORT CLLocationDirection MTCGeometryComputeHeading(CLLocationCoordinate2D from,
                                                                CLLocationCoordinate2D to);

/**
 从起点沿给定距离和方位角计算目标点。

 Computes the destination coordinate from a source, distance, and heading.

 距离必须大于或等于 `0`，heading 为角度值。输入非法时返回 `kCLLocationCoordinate2DInvalid`。
 Distance must be greater than or equal to `0`, and heading is in degrees. Invalid input returns `kCLLocationCoordinate2DInvalid`.
 */
FOUNDATION_EXPORT CLLocationCoordinate2D MTCGeometryComputeOffset(CLLocationCoordinate2D from,
                                                                  CLLocationDistance distanceMeters,
                                                                  CLLocationDirection heading);

/**
 反推可能的起点坐标。

 Computes a possible origin coordinate from a destination, distance, and heading.

 无有效解时返回 `kCLLocationCoordinate2DInvalid`。这类情况常见于参数组合无法形成唯一球面解。
 When no valid solution exists, returns `kCLLocationCoordinate2DInvalid`. This typically happens when the parameter combination cannot form a unique spherical solution.
 */
FOUNDATION_EXPORT CLLocationCoordinate2D MTCGeometryComputeOffsetOrigin(CLLocationCoordinate2D to,
                                                                        CLLocationDistance distanceMeters,
                                                                        CLLocationDirection heading);

/**
 按球面短弧在两点之间插值。

 Interpolates between two coordinates along the spherical great-circle arc.

 `fraction` 必须在 `0...1`。`0` 返回起点，`1` 返回终点，越界输入返回无效坐标。
 `fraction` must be in `0...1`. `0` returns the start coordinate, `1` returns the end coordinate, and out-of-range input returns an invalid coordinate.
 */
FOUNDATION_EXPORT CLLocationCoordinate2D MTCGeometryInterpolate(CLLocationCoordinate2D from,
                                                               CLLocationCoordinate2D to,
                                                               double fraction);

/**
 判断点是否位于多边形内部。

 Tests whether a point lies inside a polygon.

 `polygon` 语义上表示多边形外环，路径会按闭合区域解释。`geodesic` 决定边是按球面弧还是屏幕近似路径处理。
 `polygon` semantically represents the outer ring of a polygon. The path is interpreted as a closed region. `geodesic` controls whether edges are treated as spherical arcs or screen-like approximate segments.
 */
FOUNDATION_EXPORT BOOL MTCGeometryContainsLocation(CLLocationCoordinate2D point,
                                                   MTCPath *polygon,
                                                   BOOL geodesic);

/**
 判断点是否落在多边形边缘上。

 Tests whether a point lies on the edge of a polygon.

 `toleranceMeters` 为判定容差，必须大于或等于 `0`。返回值只表达是否命中，不返回命中的边索引。
 `toleranceMeters` is the hit tolerance and must be greater than or equal to `0`. The return value only indicates whether the point hit an edge; it does not return the edge index.
 */
FOUNDATION_EXPORT BOOL MTCGeometryIsLocationOnEdge(CLLocationCoordinate2D point,
                                                   MTCPath *polygon,
                                                   BOOL geodesic,
                                                   CLLocationDistance toleranceMeters);

/**
 判断点是否落在路径上。

 Tests whether a point lies on a path.

 这里的路径可以是折线、路线或任意有序坐标序列。`geodesic` 和 `toleranceMeters` 的含义与边命中一致。
 The path may be a polyline, route, or any ordered coordinate sequence. The meaning of `geodesic` and `toleranceMeters` matches edge hit testing.
 */
FOUNDATION_EXPORT BOOL MTCGeometryIsLocationOnPath(CLLocationCoordinate2D point,
                                                   MTCPath *path,
                                                   BOOL geodesic,
                                                   CLLocationDistance toleranceMeters);

/**
 返回点命中的路径段索引。

 Returns the index of the path segment that contains the point.

 未命中时返回 `-1`。当点落在闭合路径的最后闭合段时，返回最后一个元素索引。
 Returns `-1` when there is no hit. When the point lands on the closing segment of a closed path, the last element index is returned.
 */
FOUNDATION_EXPORT NSInteger MTCGeometryLocationIndexOnPath(CLLocationCoordinate2D point,
                                                           MTCPath *path,
                                                           BOOL geodesic,
                                                           CLLocationDistance toleranceMeters);

/**
 返回点命中的边或路径段索引。

 Returns the index of the edge or path segment that contains the point.

 `closed` 决定是否把末尾和开头之间的闭合段纳入判断。
 `closed` controls whether the closing segment between the last and first coordinate is included in the hit test.
 */
FOUNDATION_EXPORT NSInteger MTCGeometryLocationIndexOnEdgeOrPath(CLLocationCoordinate2D point,
                                                                 MTCPath *path,
                                                                 BOOL closed,
                                                                 BOOL geodesic,
                                                                 CLLocationDistance toleranceMeters);

/**
 计算点到有限线段的最短球面距离，单位为米。

 Computes the shortest spherical distance from a point to a finite line segment, in meters.

 如果投影落在线段外，则取最近端点距离；若起点和终点相同，则返回点到该端点的距离。
 If the projection falls outside the segment, the nearest endpoint distance is used. If start and end are the same point, the distance to that endpoint is returned.
 */
FOUNDATION_EXPORT CLLocationDistance MTCGeometryDistanceToLine(CLLocationCoordinate2D point,
                                                               CLLocationCoordinate2D start,
                                                               CLLocationCoordinate2D end);

/**
 按 Douglas-Peucker 思路简化路径。

 Simplifies a path using a Douglas-Peucker style algorithm.

 `toleranceMeters` 必须大于 `0`。输入无效或无法处理时返回 `nil`。
 `toleranceMeters` must be greater than `0`. Invalid input or unsupported cases return `nil`.
 */
FOUNDATION_EXPORT MTCPath * _Nullable MTCGeometrySimplify(MTCPath *path,
                                                         CLLocationDistance toleranceMeters);

/**
 判断路径是否已经闭合。

 Tests whether a path is already closed.

 当首尾坐标完全相等时返回 `YES`。少于 2 个点时返回 `NO`。
 Returns `YES` when the first and last coordinates are exactly equal. Paths with fewer than 2 points return `NO`.
 */
FOUNDATION_EXPORT BOOL MTCGeometryIsClosedPolygon(MTCPath *path);

NS_ASSUME_NONNULL_END
