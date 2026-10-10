//
//  MTCRoutePlanSession.h
//  MaptecMapsExample
//
//  Created by ZHOUPanpan+ on 2026/8/3.
//  Copyright © 2026 ZHOUPanpan+. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "MTCRoutePlanModels.h"

NS_ASSUME_NONNULL_BEGIN

/// 保存当前一轮算路配置、候选路线和选中路线。
@interface MTCRoutePlanSession : NSObject

@property (nonatomic, assign, readonly) NSUInteger generation;
@property (nonatomic, strong, readonly, nullable) MTCRoutePlanConfiguration *configuration;
@property (nonatomic, copy, readonly) NSArray<MTCRouteCandidate *> *routes;
@property (nonatomic, assign, readonly) NSInteger selectedRouteIndex;

- (void)beginWithGeneration:(NSUInteger)generation
              configuration:(MTCRoutePlanConfiguration *)configuration;
- (void)updateRoutes:(NSArray<MTCRouteCandidate *> *)routes
       selectedIndex:(NSInteger)selectedIndex;
- (void)selectRouteAtIndex:(NSInteger)index;
- (void)clear;

@end

NS_ASSUME_NONNULL_END
