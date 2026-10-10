//
//  MTCMapRouteRendering.h
//  MaptecMapsExample
//
//  Created by ZHOUPanpan+ on 2026/8/3.
//  Copyright © 2026 ZHOUPanpan+. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <MaptecMapsKit/MaptecMapsKit.h>

#import "MTCRoutePlanModels.h"

NS_ASSUME_NONNULL_BEGIN

/// 将候选路线模型转换为 MaptecMaps 覆盖物和相机操作。
@protocol MTCMapRouteRendering <NSObject>

- (void)displayRoutes:(NSArray<MTCRouteCandidate *> *)routes
        configuration:(MTCRoutePlanConfiguration *)configuration
         selectedIndex:(NSInteger)selectedIndex;
- (void)selectRouteAtIndex:(NSInteger)index;
- (nullable NSNumber *)routeIndexForOverlay:(id<MTCOverlay>)overlay;
- (void)showOverviewWithOptions:(MTCRouteOverviewOptions *)options;
- (void)clear;
- (void)invalidate;

@end

NS_ASSUME_NONNULL_END
