//
//  MTCRoutePlanModels+Internal.h
//  MaptecMapsExample
//
//  Created by ZHOUPanpan+ on 2026/8/3.
//  Copyright © 2026 ZHOUPanpan+. All rights reserved.
//

#import "MTCRoutePlanModels.h"

NS_ASSUME_NONNULL_BEGIN

@interface MTCRouteCandidate ()

@property (nonatomic, copy, readwrite) NSString *identifier;
@property (nonatomic, assign, readwrite) NSUInteger index;
@property (nonatomic, assign, readwrite) CLLocationDistance distance;
@property (nonatomic, assign, readwrite) NSTimeInterval duration;
@property (nonatomic, assign, readwrite) NSTimeInterval trafficDuration;
@property (nonatomic, copy, readwrite) NSArray<NSValue *> *coordinates;

- (instancetype)initWithIdentifier:(NSString *)identifier
                             index:(NSUInteger)index
                          distance:(CLLocationDistance)distance
                          duration:(NSTimeInterval)duration
                   trafficDuration:(NSTimeInterval)trafficDuration
                       coordinates:(NSArray<NSValue *> *)coordinates;

@end

@interface MTCRoutePlanState ()

@property (nonatomic, assign, readwrite) MTCRoutePlanPhase phase;
@property (nonatomic, assign, readwrite) NSUInteger generation;
@property (nonatomic, strong, readwrite, nullable) NSError *error;

- (instancetype)initWithPhase:(MTCRoutePlanPhase)phase
                   generation:(NSUInteger)generation
                        error:(nullable NSError *)error;

@end

NS_ASSUME_NONNULL_END
