//
//  MTCRouteRequest.h
//  MaptecMaps
//
//  Created by ZHOUPanpan on 2026/7/16.
//

#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>

NS_ASSUME_NONNULL_BEGIN

/// 标准驾车模式（driving）。
FOUNDATION_EXPORT NSString * const MTCRouteModeDriving;
/// 货车模式（truck），预留。
FOUNDATION_EXPORT NSString * const MTCRouteModeTruck;
/// 时间最快路线（fastest）。
FOUNDATION_EXPORT NSString * const MTCRouteStrategyFastest;
/// 最短距离路线（shortest）。
FOUNDATION_EXPORT NSString * const MTCRouteStrategyShortest;
/// 环保路线（eco），预留。
FOUNDATION_EXPORT NSString * const MTCRouteStrategyEco;
/// 平衡路线（balanced）。
FOUNDATION_EXPORT NSString * const MTCRouteStrategyBalanced;
/// 避开收费道路（tolls）。
FOUNDATION_EXPORT NSString * const MTCRouteAvoidCriteriaTolls;
/// 避开高速道路（highways）。
FOUNDATION_EXPORT NSString * const MTCRouteAvoidCriteriaHighways;
/// 避开轮渡（ferries）。
FOUNDATION_EXPORT NSString * const MTCRouteAvoidCriteriaFerries;

/// 路线坐标点。
@interface MTCRouteLocationPoint : NSObject <NSCopying>
/// 坐标。
@property (nonatomic, assign) CLLocationCoordinate2D coordinate;

/// 地理编码或搜索接口获取的 placeId （可选）
@property (nonatomic, copy) NSString *placeId;

/// 车辆的行驶航向（可选）
@property (nonatomic, assign) NSInteger bearing;

/// 允许匹配的半径（米）（可选）
@property (nonatomic, assign) NSInteger radius;

/// 使用坐标初始化。
- (instancetype)initWithCoordinate:(CLLocationCoordinate2D)coordinate;
/// 使用经纬度初始化。
- (instancetype)initWithLatitude:(double)latitude longitude:(double)longitude;
@end

/// 避让多边形区域。
@interface MTCRoutePolygonArea : NSObject <NSCopying>
/// 几何类型，固定为 `Polygon`。
@property (nonatomic, copy) NSString *type;
/// 多边形坐标，格式为 `[[[lng, lat], ...]]`。
@property (nonatomic, copy) NSArray<NSArray<NSArray<NSNumber *> *> *> *coordinates;
@end

/// 路线避让信息。
@interface MTCRouteAvoid : NSObject <NSCopying>
/// 规避类型列表，例如 `tolls`、`highways`、`ferries`。
@property (nonatomic, copy, nullable) NSArray<NSString *> *criteria;
/// 自定义规避多边形。
@property (nonatomic, strong, nullable) MTCRoutePolygonArea *polygons;
@end

/// 路线规划请求。
@interface MTCRouteRequest : NSObject <NSCopying>
/// 路线起点。
@property (nonatomic, strong, nullable) MTCRouteLocationPoint *origin;
/// 路线终点。
@property (nonatomic, strong, nullable) MTCRouteLocationPoint *destination;
/// 途经点列表，按顺序访问。
@property (nonatomic, copy) NSArray<MTCRouteLocationPoint *> *waypoints;
/// 交通模式，默认 `driving`。
@property (nonatomic, copy) NSString *mode;

/// 时间戳（可选）
/// 提供此时间： 计算未来该时间的交通状况
/// 不提供此时间： 默认为 now，使用实时路况
@property (nonatomic, copy) NSString *departureTime;

/// 路线策略，默认 `fastest`。
@property (nonatomic, copy) NSString *strategy;
/// 是否返回备选路线，默认 `YES`。
@property (nonatomic, assign) BOOL alternatives;

/// 导航指令(TBT)返回的语言。默认：en-GB
@property (nonatomic, copy) NSString *language;

/// 距离单位 默认：metric
@property (nonatomic, copy) NSString *units;

/// 避让参数。
@property (nonatomic, strong, nullable) MTCRouteAvoid *avoid;
/// 使用起终点初始化。
- (instancetype)initWithOrigin:(MTCRouteLocationPoint *)origin destination:(MTCRouteLocationPoint *)destination;
@end

NS_ASSUME_NONNULL_END
