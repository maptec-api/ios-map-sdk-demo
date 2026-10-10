//
//  MTCRoutePlanModels.h
//  MaptecMapsExample
//
//  Created by ZHOUPanpan+ on 2026/8/3.
//  Copyright © 2026 ZHOUPanpan+. All rights reserved.
//

#import <CoreLocation/CoreLocation.h>
#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

/**
 路线规划策略。

 Route planning strategy.
 */
typedef NS_ENUM(NSInteger, MTCMapRouteStrategy) {
    /** 时间优先。Prefer the fastest route. */
    MTCMapRouteStrategyFastest = 0,
    /** 距离优先。Prefer the shortest route. */
    MTCMapRouteStrategyShortest,
    /** 平衡时间与距离。Balance travel time and distance. */
    MTCMapRouteStrategyBalanced,
};

/**
 路线规划状态。

 Route planning phase.
 */
typedef NS_ENUM(NSInteger, MTCRoutePlanPhase) {
    /** 尚未开始或已清除。Idle or cleared. */
    MTCRoutePlanPhaseIdle = 0,
    /** 正在请求路线。A route request is in progress. */
    MTCRoutePlanPhaseCalculating,
    /** 路线已就绪。Routes are ready. */
    MTCRoutePlanPhaseReady,
    /** 路线规划失败。Route planning failed. */
    MTCRoutePlanPhaseFailed,
    /** Controller 已永久失效。The controller has been permanently invalidated. */
    MTCRoutePlanPhaseInvalidated,
};

/**
 路线全览模式。

 Route overview mode.
 */
typedef NS_ENUM(NSInteger, MTCRouteOverviewMode) {
    /** 全览全部候选路线。Fit all candidate routes. */
    MTCRouteOverviewModeAllRoutes = 0,
    /** 仅全览当前选中路线。Fit only the selected route. */
    MTCRouteOverviewModeSelectedRoute,
};

/**
 路线规划中的起点、终点或途经点。

 An origin, destination, or intermediate waypoint used for route planning.
 */
@interface MTCRouteWaypoint : NSObject <NSCopying>

/** 坐标。The waypoint coordinate. */
@property (nonatomic, assign) CLLocationCoordinate2D coordinate;
/** 展示名称。Optional display name. */
@property (nonatomic, copy, nullable) NSString *name;
/**
 是否代表当前定位点。默认值为 `NO`；设为 `YES` 时默认 Renderer 不绘制起点图标。

 Whether this waypoint represents the current location. Defaults to `NO`; when `YES`, the default renderer omits the origin marker.
 */
@property (nonatomic, assign) BOOL representsCurrentLocation;

/**
 使用坐标创建途经点。

 Creates a waypoint with a coordinate.
 */
- (instancetype)initWithCoordinate:(CLLocationCoordinate2D)coordinate;

@end

/**
 一次路线规划所需的完整配置。

 Complete configuration for one route calculation.
 */
@interface MTCRoutePlanConfiguration : NSObject <NSCopying>

/** 起点。The route origin. */
@property (nonatomic, strong) MTCRouteWaypoint *origin;
/** 终点。The route destination. */
@property (nonatomic, strong) MTCRouteWaypoint *destination;
/** 按访问顺序排列的途经点。Intermediate waypoints in traversal order. */
@property (nonatomic, copy) NSArray<MTCRouteWaypoint *> *waypoints;
/** 路线策略，默认时间优先。Route strategy, defaulting to fastest. */
@property (nonatomic, assign) MTCMapRouteStrategy strategy;
/** 是否请求备选路线，默认 `YES`。Whether to request alternative routes; defaults to `YES`. */
@property (nonatomic, assign) BOOL requestsAlternativeRoutes;
/** 是否避开高速道路，默认 `NO`。Whether to avoid highways; defaults to `NO`. */
@property (nonatomic, assign) BOOL avoidsHighways;

/**
 使用起点和终点创建配置。

 Creates a configuration with an origin and destination.
 */
- (instancetype)initWithOrigin:(MTCRouteWaypoint *)origin
                   destination:(MTCRouteWaypoint *)destination;

@end

/**
 单条候选路线的只读摘要。

 Immutable summary of a candidate route.
 */
@interface MTCRouteCandidate : NSObject

/** 本轮结果中的稳定标识。Stable identifier within the current route result. */
@property (nonatomic, copy, readonly) NSString *identifier;
/** 候选路线索引。Candidate route index. */
@property (nonatomic, assign, readonly) NSUInteger index;
/** 路线距离，单位为米。Route distance in meters. */
@property (nonatomic, assign, readonly) CLLocationDistance distance;
/** 基础通行时间，单位为秒。Base travel duration in seconds. */
@property (nonatomic, assign, readonly) NSTimeInterval duration;
/** 预测交通通行时间，单位为秒；无数据时为 `0`。Traffic-aware duration in seconds, or `0` when unavailable. */
@property (nonatomic, assign, readonly) NSTimeInterval trafficDuration;

- (instancetype)init NS_UNAVAILABLE;
+ (instancetype)new NS_UNAVAILABLE;
@end

/**
 路线规划状态的不可变快照。

 Immutable snapshot of route planning state.
 */
@interface MTCRoutePlanState : NSObject

/** 当前阶段。Current planning phase. */
@property (nonatomic, assign, readonly) MTCRoutePlanPhase phase;
/** 当前请求代次，用于拒绝过期结果。Current request generation used to reject stale results. */
@property (nonatomic, assign, readonly) NSUInteger generation;
/** 失败原因；仅失败状态下有值。Failure reason, available only in the failed phase. */
@property (nonatomic, strong, readonly, nullable) NSError *error;

- (instancetype)init NS_UNAVAILABLE;
+ (instancetype)new NS_UNAVAILABLE;
@end

/**
 主备路线及端点标注的展示配置。

 Display options for selected/alternative routes and endpoint markers.
 */
@interface MTCRouteDisplayOptions : NSObject <NSCopying>

/** 选中路线颜色。Selected route color. */
@property (nonatomic, strong) UIColor *selectedRouteColor;
/** 备选路线颜色。Alternative route color. */
@property (nonatomic, strong) UIColor *alternativeRouteColor;
/** 选中路线宽度，单位为 point。Selected route width in points. */
@property (nonatomic, assign) CGFloat selectedRouteWidth;
/** 备选路线宽度，单位为 point。Alternative route width in points. */
@property (nonatomic, assign) CGFloat alternativeRouteWidth;
/** 是否显示方向箭头，默认 `YES`。Whether to show directional arrows; defaults to `YES`. */
@property (nonatomic, assign) BOOL showsDirectionalArrows;
/** 是否显示起终途经点，默认 `YES`。Whether to show endpoint and waypoint markers; defaults to `YES`. */
@property (nonatomic, assign) BOOL showsEndpointMarkers;
/** 算路成功后是否自动全览，默认 `YES`。Whether to show an overview automatically after success; defaults to `YES`. */
@property (nonatomic, assign) BOOL automaticallyShowsOverview;

@end

/**
 路线全览使用的模式和边距。

 Mode and edge padding used for route overview.
 */
@interface MTCRouteOverviewOptions : NSObject <NSCopying>

/** 全览模式，默认全部路线。Overview mode, defaulting to all routes. */
@property (nonatomic, assign) MTCRouteOverviewMode mode;
/** 地图边缘留白，单位为 point。Map edge padding in points. */
@property (nonatomic, assign) UIEdgeInsets edgePadding;

@end

NS_ASSUME_NONNULL_END
