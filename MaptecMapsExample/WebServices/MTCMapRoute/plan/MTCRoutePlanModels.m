//
//  MTCRoutePlanModels.m
//  MaptecMapsExample
//
//  Created by ZHOUPanpan+ on 2026/8/3.
//  Copyright © 2026 ZHOUPanpan+. All rights reserved.
//

#import "MTCRoutePlanModels+Internal.h"

@implementation MTCRouteWaypoint

- (void)dealloc {
}

#pragma mark - Public

- (instancetype)initWithCoordinate:(CLLocationCoordinate2D)coordinate {
    self = [super init];
    if (self) {
        _coordinate = coordinate;
    }
    return self;
}

#pragma mark - Life Cycle

- (instancetype)init {
    return [self initWithCoordinate:kCLLocationCoordinate2DInvalid];
}

- (id)copyWithZone:(NSZone *)zone {
    MTCRouteWaypoint *waypoint = [[[self class] allocWithZone:zone] initWithCoordinate:self.coordinate];
    waypoint.name = [self.name copy];
    waypoint.representsCurrentLocation = self.representsCurrentLocation;
    return waypoint;
}

#pragma mark - Private

#pragma mark - Getter & Setter

@end

@implementation MTCRoutePlanConfiguration

- (void)dealloc {
}

#pragma mark - Public

- (instancetype)initWithOrigin:(MTCRouteWaypoint *)origin
                   destination:(MTCRouteWaypoint *)destination {
    self = [super init];
    if (self) {
        _origin = [origin copy];
        _destination = [destination copy];
        _waypoints = @[];
        _strategy = MTCMapRouteStrategyFastest;
        _requestsAlternativeRoutes = YES;
    }
    return self;
}

#pragma mark - Life Cycle

- (instancetype)init {
    return [self initWithOrigin:[[MTCRouteWaypoint alloc] init]
                   destination:[[MTCRouteWaypoint alloc] init]];
}

- (id)copyWithZone:(NSZone *)zone {
    MTCRoutePlanConfiguration *configuration =
        [[[self class] allocWithZone:zone] initWithOrigin:self.origin destination:self.destination];
    NSMutableArray<MTCRouteWaypoint *> *waypoints =
        [NSMutableArray arrayWithCapacity:self.waypoints.count];
    for (MTCRouteWaypoint *waypoint in self.waypoints) {
        [waypoints addObject:[waypoint copy]];
    }
    configuration.waypoints = [waypoints copy];
    configuration.strategy = self.strategy;
    configuration.requestsAlternativeRoutes = self.requestsAlternativeRoutes;
    configuration.avoidsHighways = self.avoidsHighways;
    return configuration;
}

#pragma mark - Private

#pragma mark - Getter & Setter

@end

@implementation MTCRouteCandidate

- (void)dealloc {
}

#pragma mark - Public

- (instancetype)initWithIdentifier:(NSString *)identifier
                             index:(NSUInteger)index
                          distance:(CLLocationDistance)distance
                          duration:(NSTimeInterval)duration
                   trafficDuration:(NSTimeInterval)trafficDuration
                       coordinates:(NSArray<NSValue *> *)coordinates {
    self = [super init];
    if (self) {
        _identifier = [identifier copy];
        _index = index;
        _distance = distance;
        _duration = duration;
        _trafficDuration = trafficDuration;
        _coordinates = [coordinates copy];
    }
    return self;
}

#pragma mark - Private

#pragma mark - Getter & Setter

@end

@implementation MTCRoutePlanState

- (void)dealloc {
}

#pragma mark - Public

- (instancetype)initWithPhase:(MTCRoutePlanPhase)phase
                   generation:(NSUInteger)generation
                        error:(NSError *)error {
    self = [super init];
    if (self) {
        _phase = phase;
        _generation = generation;
        _error = error;
    }
    return self;
}

#pragma mark - Private

#pragma mark - Getter & Setter

@end

@implementation MTCRouteDisplayOptions

- (void)dealloc {
}

#pragma mark - Public

#pragma mark - Life Cycle

- (instancetype)init {
    self = [super init];
    if (self) {
        _selectedRouteColor = UIColor.systemBlueColor;
        _alternativeRouteColor = UIColor.systemGrayColor;
        _selectedRouteWidth = 9.0;
        _alternativeRouteWidth = 6.0;
        _showsDirectionalArrows = YES;
        _showsEndpointMarkers = YES;
        _automaticallyShowsOverview = YES;
    }
    return self;
}

- (id)copyWithZone:(NSZone *)zone {
    MTCRouteDisplayOptions *options = [[[self class] allocWithZone:zone] init];
    options.selectedRouteColor = self.selectedRouteColor;
    options.alternativeRouteColor = self.alternativeRouteColor;
    options.selectedRouteWidth = self.selectedRouteWidth;
    options.alternativeRouteWidth = self.alternativeRouteWidth;
    options.showsDirectionalArrows = self.showsDirectionalArrows;
    options.showsEndpointMarkers = self.showsEndpointMarkers;
    options.automaticallyShowsOverview = self.automaticallyShowsOverview;
    return options;
}

#pragma mark - Private

#pragma mark - Getter & Setter

@end

@implementation MTCRouteOverviewOptions

- (void)dealloc {
}

#pragma mark - Public

#pragma mark - Life Cycle

- (instancetype)init {
    self = [super init];
    if (self) {
        _mode = MTCRouteOverviewModeAllRoutes;
        _edgePadding = UIEdgeInsetsMake(100.0, 40.0, 150.0, 40.0);
    }
    return self;
}

- (id)copyWithZone:(NSZone *)zone {
    MTCRouteOverviewOptions *options = [[[self class] allocWithZone:zone] init];
    options.mode = self.mode;
    options.edgePadding = self.edgePadding;
    return options;
}

#pragma mark - Private

#pragma mark - Getter & Setter

@end
