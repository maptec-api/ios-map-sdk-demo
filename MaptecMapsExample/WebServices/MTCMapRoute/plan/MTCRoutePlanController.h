//
//  MTCRoutePlanController.h
//  MaptecMapsExample
//
//  Created by ZHOUPanpan+ on 2026/8/3.
//  Copyright © 2026 ZHOUPanpan+. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <MaptecMapsKit/MaptecMapsKit.h>

#import "MTCRoutePlanModels.h"

NS_ASSUME_NONNULL_BEGIN

@class MTCRoutePlanController;

/**
 接收路线规划状态与选中路线变化。

 Receives route planning state and selected-route changes.
 */
@protocol MTCRoutePlanControllerDelegate <NSObject>

/**
 路线规划状态变化。

 Called when the route planning state changes.
 */
- (void)routePlanController:(MTCRoutePlanController *)controller
             didChangeState:(MTCRoutePlanState *)state;

/**
 选中路线发生变化。

 Called after the selected candidate route changes.
 */
- (void)routePlanController:(MTCRoutePlanController *)controller
     didSelectRouteAtIndex:(NSInteger)index;

@end

/**
 编排算路、主备路线展示、选线、清理和全览。

 Coordinates route calculation, candidate rendering, selection, cleanup, and overview.

 所有地图操作和代理回调均在主线程执行。
 All map operations and delegate callbacks are performed on the main thread.
 */
@interface MTCRoutePlanController : NSObject

/** 状态代理。The state and selection delegate. */
@property (nonatomic, weak, nullable) id<MTCRoutePlanControllerDelegate> delegate;
/** 当前状态快照。Current state snapshot. */
@property (nonatomic, strong, readonly) MTCRoutePlanState *state;
/** 当前候选路线。Current candidate routes. */
@property (nonatomic, copy, readonly) NSArray<MTCRouteCandidate *> *routes;
/** 当前选中索引；无选中路线时为 `NSNotFound`。Selected index, or `NSNotFound` when unavailable. */
@property (nonatomic, assign, readonly) NSInteger selectedRouteIndex;

/**
 使用地图视图创建路线规划 Controller。

 Creates a route planning controller attached to a map view.
 */
- (instancetype)initWithMapView:(MTCMapView *)mapView;

/** 发起新一轮算路；未完成的旧请求结果会被丢弃。Starts a new calculation and discards stale prior results. */
- (void)calculateRouteWithConfiguration:(MTCRoutePlanConfiguration *)configuration;
/** 选择指定候选路线，不会重新算路。Selects a candidate without recalculating. */
- (void)selectRouteAtIndex:(NSInteger)index;
/** 处理地图 Overlay 点击；返回是否命中当前路线。Handles an overlay tap and returns whether it matched a route. */
- (BOOL)handleTappedOverlay:(id<MTCOverlay>)overlay;
/** 展示路线全览。Shows the route overview. */
- (void)showOverviewWithOptions:(nullable MTCRouteOverviewOptions *)options;
/** 取消当前请求并清除路线，可继续复用 Controller。Cancels the active request and clears routes while keeping the controller reusable. */
- (void)clearRoutes;
/** 永久失效并解除地图关联。Permanently invalidates the controller and detaches it from the map. */
- (void)invalidate;

@end

NS_ASSUME_NONNULL_END
