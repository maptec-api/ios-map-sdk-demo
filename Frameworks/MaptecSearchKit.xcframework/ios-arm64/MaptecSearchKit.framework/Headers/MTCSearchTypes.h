//
//  MTCSearchTypes.h
//  MaptecMaps
//
//  Created by ZHOUPanpan on 2026/7/14.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

 #pragma mark - 通用类型定义
 
 /// 搜索结果排序类型
typedef NS_ENUM(NSInteger, MTCSearchRankType) {
     /// 不指定排序（由服务端决定）
    MTCSearchRankTypeUnspecified = 0,
     /// 按相关性排序
    MTCSearchRankTypeRelevance,
     /// 按距离排序
    MTCSearchRankTypeDistance,
     /// 按热度排序
    MTCSearchRankTypePopularity,
};

/// 沿途搜索路线评估模式。
/// Along-route search evaluation mode.
typedef NS_ENUM(NSInteger, MTCAlongRouteEvaluationMode) {
    /// 基础沿途搜索：仅返回几何关系。
    /// Basic along-route search: returns route geometry relation only.
    MTCAlongRouteEvaluationModeNone = 0,
    /// 标准路线评估：额外返回预计总行程时间与距离。
    /// Standard route evaluation: also returns estimated total duration and distance.
    MTCAlongRouteEvaluationModeStandard,
};

/// 沿途搜索结果排序类型。
/// Along-route search ranking type.
typedef NS_ENUM(NSInteger, MTCAlongRouteRankType) {
    /// 不指定排序（由服务端按模式默认值决定）
    /// Unspecified ranking; the server applies the default for the current mode.
    MTCAlongRouteRankTypeUnspecified = 0,
    /// 按相关性排序
    /// Sort by relevance.
    MTCAlongRouteRankTypeRelevance,
    /// 按路线出现顺序排序
    /// Sort by order along the route.
    MTCAlongRouteRankTypeRouteOrder,
    /// 按到路线的几何距离排序
    /// Sort by geometric distance from the route.
    MTCAlongRouteRankTypeDistanceFromRoute,
    /// 按预计总行程时间排序，仅 STANDARD 支持
    /// Sort by estimated total duration; supported in STANDARD only.
    MTCAlongRouteRankTypeRouteDuration,
    /// 按预计总行程距离排序，仅 STANDARD 支持
    /// Sort by estimated total distance; supported in STANDARD only.
    MTCAlongRouteRankTypeRouteDistance,
};

 /// 通用搜索响应回调：返回解析后的 model 对象或 NSError
typedef void (^MTCSearchResponseCompletion)(id _Nullable response, NSError * _Nullable error);
 /// 二进制数据响应回调（如图片下载）
typedef void (^MTCSearchDataCompletion)(NSData * _Nullable data, NSError * _Nullable error);

NS_ASSUME_NONNULL_END
