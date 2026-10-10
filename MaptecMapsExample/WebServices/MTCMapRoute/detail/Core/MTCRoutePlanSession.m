//
//  MTCRoutePlanSession.m
//  MaptecMapsExample
//
//  Created by ZHOUPanpan+ on 2026/8/3.
//  Copyright © 2026 ZHOUPanpan+. All rights reserved.
//

#import "MTCRoutePlanSession.h"

@interface MTCRoutePlanSession ()

@property (nonatomic, assign, readwrite) NSUInteger generation;
@property (nonatomic, strong, readwrite, nullable) MTCRoutePlanConfiguration *configuration;
@property (nonatomic, copy, readwrite) NSArray<MTCRouteCandidate *> *routes;
@property (nonatomic, assign, readwrite) NSInteger selectedRouteIndex;

@end

@implementation MTCRoutePlanSession

- (void)dealloc {
}

#pragma mark - Public

- (void)beginWithGeneration:(NSUInteger)generation
              configuration:(MTCRoutePlanConfiguration *)configuration {
    self.generation = generation;
    self.configuration = [configuration copy];
    self.routes = @[];
    self.selectedRouteIndex = NSNotFound;
}

- (void)updateRoutes:(NSArray<MTCRouteCandidate *> *)routes
       selectedIndex:(NSInteger)selectedIndex {
    self.routes = [routes copy];
    self.selectedRouteIndex = selectedIndex;
}

- (void)selectRouteAtIndex:(NSInteger)index {
    if (index >= 0 && index < (NSInteger)self.routes.count) {
        self.selectedRouteIndex = index;
    }
}

- (void)clear {
    self.generation = 0;
    self.configuration = nil;
    self.routes = @[];
    self.selectedRouteIndex = NSNotFound;
}

#pragma mark - Life Cycle

- (instancetype)init {
    self = [super init];
    if (self) {
        _routes = @[];
        _selectedRouteIndex = NSNotFound;
    }
    return self;
}

#pragma mark - Protocol

#pragma mark - Delegate

#pragma mark - Event

#pragma mark - Private

#pragma mark - Getter & Setter

@end
