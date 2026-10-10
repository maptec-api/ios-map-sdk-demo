//
//  MTCRoutePlanStateStore.h
//  MaptecMapsExample
//
//  Created by ZHOUPanpan+ on 2026/8/3.
//  Copyright © 2026 ZHOUPanpan+. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "MTCRoutePlanModels.h"

NS_ASSUME_NONNULL_BEGIN

/// 维护路线规划状态并生成不可变状态快照。
@interface MTCRoutePlanStateStore : NSObject

@property (nonatomic, strong, readonly) MTCRoutePlanState *state;
@property (nonatomic, copy, readonly) NSArray<MTCRouteCandidate *> *routes;
@property (nonatomic, assign, readonly) NSInteger selectedRouteIndex;

- (NSUInteger)beginCalculation;
- (void)setReadyWithRoutes:(NSArray<MTCRouteCandidate *> *)routes
                generation:(NSUInteger)generation;
- (void)setFailure:(NSError *)error generation:(NSUInteger)generation;
- (BOOL)selectRouteAtIndex:(NSInteger)index;
- (void)clear;
- (void)invalidate;

@end

NS_ASSUME_NONNULL_END
