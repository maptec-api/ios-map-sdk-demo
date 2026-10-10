#import <CoreLocation/CoreLocation.h>
#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/**
 地图 POI 命中结果。

 A map POI hit result.

 `MTCPOI` 表示用户点击底图 POI 后 SDK 返回的稳定信息。该对象是不可变快照；不同地图样式或数据源可能只提供部分字段。
 `MTCPOI` is an immutable snapshot returned when the user taps a base-map POI. Different map styles or data sources may provide only part of the fields.
 */
NS_SWIFT_NAME(MTCPOI)
@interface MTCPOI : NSObject

- (instancetype)init NS_UNAVAILABLE;
+ (instancetype)new NS_UNAVAILABLE;

/**
 创建 POI 命中结果。

 Creates a POI hit result.

 @param identifier POI 标识。The POI identifier.
 @param coordinate POI 锚点坐标。The POI anchor coordinate.
 @param name POI 名称。The POI name.
 */
- (instancetype)initWithIdentifier:(NSString *)identifier
                        coordinate:(CLLocationCoordinate2D)coordinate
                              name:(nullable NSString *)name NS_DESIGNATED_INITIALIZER;

/**
 POI 标识。

 The POI identifier.

 当底图数据没有提供稳定标识时，SDK 返回空字符串。
 The SDK returns an empty string when the map data does not provide a stable identifier.
 */
@property (nonatomic, copy, readonly) NSString *identifier;

/**
 POI 锚点坐标。

 The POI anchor coordinate.
 */
@property (nonatomic, readonly) CLLocationCoordinate2D coordinate;

/**
 POI 名称。

 The POI name.

 当底图数据没有提供名称时为 `nil`。
 This value is `nil` when the map data does not provide a name.
 */
@property (nonatomic, copy, readonly, nullable) NSString *name;

@end

NS_ASSUME_NONNULL_END
