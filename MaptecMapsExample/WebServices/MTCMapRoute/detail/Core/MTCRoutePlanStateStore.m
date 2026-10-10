//
//  MTCRoutePlanStateStore.m
//  MaptecMapsExample
//
//  Created by ZHOUPanpan+ on 2026/8/3.
//  Copyright © 2026 ZHOUPanpan+. All rights reserved.
//

#import "MTCRoutePlanStateStore.h"
#import "MTCRoutePlanModels+Internal.h"

@interface MTCRoutePlanStateStore ()

@property (nonatomic, strong, readwrite) MTCRoutePlanState *state;
@property (nonatomic, copy, readwrite) NSArray<MTCRouteCandidate *> *routes;
@property (nonatomic, assign, readwrite) NSInteger selectedRouteIndex;

@end

@implementation MTCRoutePlanStateStore

- (void)dealloc {
}

#pragma mark - Public

- (NSUInteger)beginCalculation {
    NSUInteger generation = self.state.generation + 1;
    self.routes = @[];
    self.selectedRouteIndex = NSNotFound;
    self.state = [[MTCRoutePlanState alloc] initWithPhase:MTCRoutePlanPhaseCalculating
                                               generation:generation
                                                    error:nil];
    return generation;
}

- (void)setReadyWithRoutes:(NSArray<MTCRouteCandidate *> *)routes
                generation:(NSUInteger)generation {
    if (generation != self.state.generation || self.state.phase == MTCRoutePlanPhaseInvalidated) {
        return;
    }
    self.routes = [routes copy];
    self.selectedRouteIndex = routes.count > 0 ? 0 : NSNotFound;
    self.state = [[MTCRoutePlanState alloc] initWithPhase:MTCRoutePlanPhaseReady
                                               generation:generation
                                                    error:nil];
}

- (void)setFailure:(NSError *)error generation:(NSUInteger)generation {
    if (generation != self.state.generation || self.state.phase == MTCRoutePlanPhaseInvalidated) {
        return;
    }
    self.routes = @[];
    self.selectedRouteIndex = NSNotFound;
    self.state = [[MTCRoutePlanState alloc] initWithPhase:MTCRoutePlanPhaseFailed
                                               generation:generation
                                                    error:error];
}

- (BOOL)selectRouteAtIndex:(NSInteger)index {
    if (self.state.phase != MTCRoutePlanPhaseReady ||
        index < 0 ||
        index >= (NSInteger)self.routes.count ||
        index == self.selectedRouteIndex) {
        return NO;
    }
    self.selectedRouteIndex = index;
    return YES;
}

- (void)clear {
    NSUInteger generation = self.state.generation + 1;
    self.routes = @[];
    self.selectedRouteIndex = NSNotFound;
    self.state = [[MTCRoutePlanState alloc] initWithPhase:MTCRoutePlanPhaseIdle
                                               generation:generation
                                                    error:nil];
}

- (void)invalidate {
    NSUInteger generation = self.state.generation + 1;
    self.routes = @[];
    self.selectedRouteIndex = NSNotFound;
    self.state = [[MTCRoutePlanState alloc] initWithPhase:MTCRoutePlanPhaseInvalidated
                                               generation:generation
                                                    error:nil];
}

#pragma mark - Life Cycle

- (instancetype)init {
    self = [super init];
    if (self) {
        _routes = @[];
        _selectedRouteIndex = NSNotFound;
        _state = [[MTCRoutePlanState alloc] initWithPhase:MTCRoutePlanPhaseIdle
                                               generation:0
                                                    error:nil];
    }
    return self;
}

#pragma mark - Protocol

#pragma mark - Delegate

#pragma mark - Event

#pragma mark - Private

#pragma mark - Getter & Setter

@end
