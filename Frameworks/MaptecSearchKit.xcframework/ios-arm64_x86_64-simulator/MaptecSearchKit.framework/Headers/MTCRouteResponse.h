//
//  MTCRouteResponse.h
//  MaptecMaps
//
//  Created by ZHOUPanpan on 2026/7/16.
//

#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>

NS_ASSUME_NONNULL_BEGIN

/// 路线错误对象。
@interface MTCRouteError : NSObject
/// 错误码。
@property (nonatomic, assign) NSInteger code;
/// 错误消息。
@property (nonatomic, copy, nullable) NSString *message;
/// 使用错误码与消息初始化。
- (instancetype)initWithCode:(NSInteger)code message:(nullable NSString *)message;
@end

/// 路线概要信息。
@interface MTCRouteSummary : NSObject
/// 距离（米）。
@property (nonatomic, strong, nullable) NSNumber *distanceMeters;
/// 基础通行时间（秒）。
@property (nonatomic, strong, nullable) NSNumber *durationSeconds;
/// 预测通行时间（秒）。
@property (nonatomic, strong, nullable) NSNumber *trafficDurationSeconds;
@end

/// 路线步骤。
@interface MTCRouteStep : NSObject
/// 文本指令。
@property (nonatomic, copy, nullable) NSString *instruction;
/// 转向类型。
@property (nonatomic, copy, nullable) NSString *turnType;
/// 距离（米）。
@property (nonatomic, strong, nullable) NSNumber *distanceMeters;
/// 时长（秒）。
@property (nonatomic, strong, nullable) NSNumber *durationSeconds;
/// 起点坐标。
@property (nonatomic, assign) CLLocationCoordinate2D startLocation;
/// 终点坐标。
@property (nonatomic, assign) CLLocationCoordinate2D endLocation;
/// Polyline 编码。
@property (nonatomic, copy, nullable) NSString *polyline;

/// 该路段最高限速（km/h）
@property (nonatomic, assign) NSInteger speedLimit;

/// 道路等级
@property (nonatomic, copy, nullable) NSString *roadClass;

@end

/// 路线分段。
@interface MTCRouteLeg : NSObject
/// 分段概要。
@property (nonatomic, strong, nullable) MTCRouteSummary *summary;
/// 起点地址。
@property (nonatomic, copy, nullable) NSString *startAddress;
/// 终点地址。
@property (nonatomic, copy, nullable) NSString *endAddress;
/// 步骤列表: Turn-by-Turn (TBT) 导航指令列表
@property (nonatomic, copy) NSArray<MTCRouteStep *> *steps;
@end

/// 单条路线。
@interface MTCRoute : NSObject
/// 路线概要。
@property (nonatomic, strong, nullable) MTCRouteSummary *summary;
/// 路线分段列表。
@property (nonatomic, copy) NSArray<MTCRouteLeg *> *legs;
/// 整条路线的编码折线。
@property (nonatomic, copy, nullable) NSString *overviewPolyline;

/// 导航的警告信息
@property (nonatomic, copy) NSArray<NSString *> *warnings;

/// overviewPolyline → CLLocationCoordinate2D
- (NSArray<NSValue *> *)coordinatesFromPolyline;

@end

/// 路线规划响应。
@interface MTCRouteResponse : NSObject
/// 响应状态。
@property (nonatomic, copy, nullable) NSString *status;
/// 路线方案列表。
@property (nonatomic, copy) NSArray<MTCRoute *> *routes;
/// 错误信息。
@property (nonatomic, strong, nullable) MTCRouteError *error;
@end

NS_ASSUME_NONNULL_END
