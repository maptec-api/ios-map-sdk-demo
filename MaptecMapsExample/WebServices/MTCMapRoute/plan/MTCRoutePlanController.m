//
//  MTCRoutePlanController.m
//  MaptecMapsExample
//
//  Created by ZHOUPanpan+ on 2026/8/3.
//  Copyright © 2026 ZHOUPanpan+. All rights reserved.
//

#import "MTCRoutePlanController.h"

#import "MTCExampleDemoLocalization.h"
#import "MTCMapRouteRendering.h"
#import "MTCPolylineRouteRenderer.h"
#import "MTCRoutePlanController+Internal.h"
#import "MTCRoutePlanSession.h"
#import "MTCRoutePlanStateStore.h"
#import "MTCSearchKitRoutePlanningService.h"

@interface MTCRoutePlanController ()

@property (nonatomic, strong) id<MTCRoutePlanningService> routeService;
@property (nonatomic, strong) id<MTCMapRouteRendering> renderer;
@property (nonatomic, strong) MTCRoutePlanStateStore *stateStore;
@property (nonatomic, strong) MTCRoutePlanSession *session;
@property (nonatomic, strong, nullable) id<MTCRoutePlanningTask> currentTask;
@property (nonatomic, assign) BOOL automaticallyShowsOverview;

@end

@implementation MTCRoutePlanController

- (void)dealloc {
    [self.currentTask cancel];
}

#pragma mark - Public

- (instancetype)initWithMapView:(MTCMapView *)mapView {
    return [self initWithMapView:mapView
                    routeService:[[MTCSearchKitRoutePlanningService alloc] init]
                  displayOptions:nil];
}

- (instancetype)initWithMapView:(MTCMapView *)mapView
                    routeService:(id<MTCRoutePlanningService>)routeService
                  displayOptions:(MTCRouteDisplayOptions *)displayOptions {
    self = [super init];
    if (self) {
        _routeService = routeService;
        _renderer = [[MTCPolylineRouteRenderer alloc] initWithMapView:mapView
                                                       displayOptions:displayOptions];
        _stateStore = [[MTCRoutePlanStateStore alloc] init];
        _session = [[MTCRoutePlanSession alloc] init];
        _automaticallyShowsOverview =
            displayOptions ? displayOptions.automaticallyShowsOverview : YES;
    }
    return self;
}

- (void)calculateRouteWithConfiguration:(MTCRoutePlanConfiguration *)configuration {
    [self performOnMainThread:^{
        if (self.state.phase == MTCRoutePlanPhaseInvalidated) {
            return;
        }
        [self.currentTask cancel];
        self.currentTask = nil;
        [self.renderer clear];

        NSUInteger generation = [self.stateStore beginCalculation];
        [self.session beginWithGeneration:generation configuration:configuration];
        [self notifyStateDidChange];

        __weak typeof(self) weakSelf = self;
        self.currentTask =
            [self.routeService calculateRouteWithConfiguration:[configuration copy]
                                                     completion:^(NSArray<MTCRouteCandidate *> * _Nullable routes,
                                                                  NSError * _Nullable error) {
            __strong typeof(weakSelf) self = weakSelf;
            if (!self) {
                return;
            }
            [self performOnMainThread:^{
                [self handleRoutes:routes error:error generation:generation];
            }];
        }];
    }];
}

- (void)selectRouteAtIndex:(NSInteger)index {
    [self performOnMainThread:^{
        if (![self.stateStore selectRouteAtIndex:index]) {
            return;
        }
        [self.session selectRouteAtIndex:index];
        [self.renderer selectRouteAtIndex:index];
        [self.delegate routePlanController:self didSelectRouteAtIndex:index];
        [self notifyStateDidChange];
    }];
}

- (BOOL)handleTappedOverlay:(id<MTCOverlay>)overlay {
    NSAssert(NSThread.isMainThread, @"Overlay tap handling must run on the main thread.");
    NSNumber *index = [self.renderer routeIndexForOverlay:overlay];
    if (!index) {
        return NO;
    }
    [self selectRouteAtIndex:index.integerValue];
    return YES;
}

- (void)showOverviewWithOptions:(MTCRouteOverviewOptions *)options {
    [self performOnMainThread:^{
        if (self.state.phase == MTCRoutePlanPhaseReady) {
            [self.renderer showOverviewWithOptions:options ?: [[MTCRouteOverviewOptions alloc] init]];
        }
    }];
}

- (void)clearRoutes {
    [self performOnMainThread:^{
        if (self.state.phase == MTCRoutePlanPhaseInvalidated) {
            return;
        }
        [self.currentTask cancel];
        self.currentTask = nil;
        [self.renderer clear];
        [self.session clear];
        [self.stateStore clear];
        [self notifyStateDidChange];
    }];
}

- (void)invalidate {
    [self performOnMainThread:^{
        if (self.state.phase == MTCRoutePlanPhaseInvalidated) {
            return;
        }
        [self.currentTask cancel];
        self.currentTask = nil;
        [self.renderer invalidate];
        [self.session clear];
        [self.stateStore invalidate];
        [self notifyStateDidChange];
        self.delegate = nil;
    }];
}

#pragma mark - Life Cycle

#pragma mark - Protocol

#pragma mark - Delegate

#pragma mark - Event

#pragma mark - Private

- (void)handleRoutes:(NSArray<MTCRouteCandidate *> *)routes
                error:(NSError *)error
           generation:(NSUInteger)generation {
    if (generation != self.state.generation ||
        self.state.phase == MTCRoutePlanPhaseInvalidated) {
        return;
    }
    self.currentTask = nil;
    if (error || routes.count == 0) {
        NSError *resolvedError = error ?: [NSError errorWithDomain:@"com.maptec.example.route-plan"
                                                               code:2
                                                           userInfo:@{
            NSLocalizedDescriptionKey: [MTCExampleDemoLocalization stringForKey:@"web_no_available_routes_returned" language:[MTCExampleDemoLocalization currentLanguage]]
        }];
        [self.session clear];
        [self.stateStore setFailure:resolvedError generation:generation];
        [self.renderer clear];
        [self notifyStateDidChange];
        return;
    }

    [self.stateStore setReadyWithRoutes:routes generation:generation];
    [self.session updateRoutes:routes selectedIndex:0];
    [self.renderer displayRoutes:routes
                   configuration:self.session.configuration
                    selectedIndex:0];
    [self notifyStateDidChange];

    if (self.automaticallyShowsOverview) {
        [self.renderer showOverviewWithOptions:[[MTCRouteOverviewOptions alloc] init]];
    }
}

- (void)notifyStateDidChange {
    [self.delegate routePlanController:self didChangeState:self.state];
}

- (void)performOnMainThread:(dispatch_block_t)block {
    if (NSThread.isMainThread) {
        block();
    } else {
        dispatch_async(dispatch_get_main_queue(), block);
    }
}

#pragma mark - Getter & Setter

- (MTCRoutePlanState *)state {
    return self.stateStore.state;
}

- (NSArray<MTCRouteCandidate *> *)routes {
    return self.stateStore.routes;
}

- (NSInteger)selectedRouteIndex {
    return self.stateStore.selectedRouteIndex;
}

@end
