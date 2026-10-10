//
//  MTCRoutePlanningService.h
//  MaptecMapsExample
//
//  Created by ZHOUPanpan+ on 2026/8/3.
//  Copyright © 2026 ZHOUPanpan+. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "MTCRoutePlanModels.h"

NS_ASSUME_NONNULL_BEGIN

/// 可取消或屏蔽回调的路线规划任务。
@protocol MTCRoutePlanningTask <NSObject>

- (void)cancel;

@end

/// 路线规划服务抽象，用于隔离 SearchKit 与 Controller。
@protocol MTCRoutePlanningService <NSObject>

- (id<MTCRoutePlanningTask>)calculateRouteWithConfiguration:(MTCRoutePlanConfiguration *)configuration
                                                  completion:(void (^)(NSArray<MTCRouteCandidate *> * _Nullable routes,
                                                                       NSError * _Nullable error))completion;

@end

NS_ASSUME_NONNULL_END
