#import <CoreLocation/CoreLocation.h>
#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/**
 有序经纬度路径。

 An ordered geographic path.

 `MTCPath` 表示一串有序经纬度坐标，适合折线、路线和多边形外环等场景。它本身不表示“折线”或“多边形”，只保存坐标顺序。
 `MTCPath` stores an ordered sequence of geographic coordinates and is suitable for polylines, routes, and polygon outer rings. It does not itself mean a polyline or a polygon; it only preserves coordinate order.
 */
NS_SWIFT_NAME(MTCPath)
@interface MTCPath : NSObject <NSCopying, NSMutableCopying>

/**
 使用坐标创建路径。

 Creates a path with coordinates.

 @param coordinates 坐标缓冲区。The coordinate buffer.
 @param count 坐标数量。The number of coordinates.
 @return 路径对象；输入无效时返回 `nil`。The path object, or `nil` for invalid input.
 */
- (nullable instancetype)initWithCoordinates:(const CLLocationCoordinate2D * _Nullable)coordinates
                                       count:(NSUInteger)count NS_DESIGNATED_INITIALIZER;

/**
 使用空路径创建对象。

 Creates an empty path.
 */
- (instancetype)init;

/**
 创建空路径。

 Creates an empty path.
 */
+ (instancetype)path;

/**
 由编码后的 polyline 字符串创建路径。

 Creates a path from an encoded polyline string.

 @param encodedPath Google Encoded Polyline 字符串。The Google Encoded Polyline string.
 @return 路径对象；空字符串返回空路径，非法编码返回 `nil`。The path object; an empty string yields an empty path, and invalid input returns `nil`.
 */
+ (nullable instancetype)pathFromEncodedPath:(NSString *)encodedPath;

/**
 路径中的坐标数量。

 The number of coordinates in the path.
 */
@property (nonatomic, readonly) NSUInteger count;

/**
 返回指定索引处的坐标。

 Returns the coordinate at the specified index.

 @param index 坐标索引，必须小于 `count`。The coordinate index, which must be less than `count`.
 @return 索引越界时返回 `kCLLocationCoordinate2DInvalid`。Returns `kCLLocationCoordinate2DInvalid` when the index is out of bounds.
 */
- (CLLocationCoordinate2D)coordinateAtIndex:(NSUInteger)index;

/**
 读取指定范围内的坐标。

 Reads coordinates in the specified range.

 @param buffer 接收坐标的缓冲区。The output buffer.
 @param range 要读取的坐标范围。The coordinate range to read.
 */
- (void)getCoordinates:(CLLocationCoordinate2D *)buffer
                 range:(NSRange)range;

/**
 将路径编码为 Google Encoded Polyline 字符串。

 Encodes the path as a Google Encoded Polyline string.

 空路径返回空字符串。
 An empty path returns an empty string.
 */
- (NSString *)encodedPath;

/**
 复制所有坐标并按给定偏移生成新路径。

 Copies all coordinates and creates a new path shifted by the given deltas.

 @param deltaLatitude 纬度偏移，单位为度。Latitude delta, in degrees.
 @param deltaLongitude 经度偏移，单位为度。Longitude delta, in degrees.
@return 新路径；偏移后坐标非法时返回 `nil`。The new path, or `nil` if the offset produces invalid coordinates.
 */
- (nullable MTCPath *)pathOffsetByLatitude:(CLLocationDegrees)deltaLatitude
                                 longitude:(CLLocationDegrees)deltaLongitude;

@end

NS_ASSUME_NONNULL_END
