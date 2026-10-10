//
//  MTCSearchKitRoutePlanningService.m
//  MaptecMapsExample
//
//  Created by ZHOUPanpan+ on 2026/8/3.
//  Copyright © 2026 ZHOUPanpan+. All rights reserved.
//

#import "MTCSearchKitRoutePlanningService.h"
#import "MTCExampleDemoLocalization.h"
#import "MTCRoutePlanModels+Internal.h"

#import <MaptecSearchKit/MaptecSearchKit.h>

static NSString * const MTCRoutePlanErrorDomain = @"com.maptec.example.route-plan";

typedef NS_ENUM(NSInteger, MTCRoutePlanErrorCode) {
    MTCRoutePlanErrorCodeInvalidConfiguration = 1,
    MTCRoutePlanErrorCodeEmptyResult,
    MTCRoutePlanErrorCodeInvalidGeometry,
    MTCRoutePlanErrorCodeUnderlyingService,
};

@interface MTCSearchKitRoutePlanningTask : NSObject <MTCRoutePlanningTask>

@property (atomic, assign, getter=isCancelled) BOOL cancelled;

@end

@implementation MTCSearchKitRoutePlanningTask

- (void)dealloc {
}

#pragma mark - Public

- (void)cancel {
    self.cancelled = YES;
}

#pragma mark - Life Cycle

#pragma mark - Protocol

#pragma mark - Delegate

#pragma mark - Event

#pragma mark - Private

#pragma mark - Getter & Setter

@end

@implementation MTCSearchKitRoutePlanningService

- (void)dealloc {
}

#pragma mark - Public

- (id<MTCRoutePlanningTask>)calculateRouteWithConfiguration:(MTCRoutePlanConfiguration *)configuration
                                                  completion:(void (^)(NSArray<MTCRouteCandidate *> * _Nullable,
                                                                       NSError * _Nullable))completion {
    MTCSearchKitRoutePlanningTask *task = [[MTCSearchKitRoutePlanningTask alloc] init];
    NSError *validationError = [self validationErrorForConfiguration:configuration];
    if (validationError) {
        dispatch_async(dispatch_get_main_queue(), ^{
            if (!task.isCancelled) {
                completion(nil, validationError);
            }
        });
        return task;
    }

    MTCRouteRequest *request = [self requestFromConfiguration:configuration];
    [MTCRouteService.sharedService calculateRouteWithRequest:request completion:^(MTCRouteResponse * _Nullable response,
                                                                                  NSError * _Nullable error) {
        if (task.isCancelled) {
            return;
        }
        if (error) {
            completion(nil, error);
            return;
        }
        if (response.error ||
            [response.status caseInsensitiveCompare:@"ERROR"] == NSOrderedSame) {
            NSError *serviceError =
                [self errorWithCode:MTCRoutePlanErrorCodeUnderlyingService
                       description:response.error.message ?: [MTCExampleDemoLocalization stringForKey:@"web_route_service_returned_a_business_error" language:[MTCExampleDemoLocalization currentLanguage]]];
            completion(nil, serviceError);
            return;
        }

        NSError *conversionError = nil;
        NSArray<MTCRouteCandidate *> *candidates = [self candidatesFromResponse:response
                                                                          error:&conversionError];
        completion(candidates, conversionError);
    }];
    return task;
}

#pragma mark - Life Cycle

#pragma mark - Protocol

#pragma mark - Delegate

#pragma mark - Event

#pragma mark - Private

- (NSError *)validationErrorForConfiguration:(MTCRoutePlanConfiguration *)configuration {
    if (!configuration || !CLLocationCoordinate2DIsValid(configuration.origin.coordinate)) {
        return [self errorWithCode:MTCRoutePlanErrorCodeInvalidConfiguration
                      description:[MTCExampleDemoLocalization stringForKey:@"web_invalid_route_origin" language:[MTCExampleDemoLocalization currentLanguage]]];
    }
    if (!CLLocationCoordinate2DIsValid(configuration.destination.coordinate)) {
        return [self errorWithCode:MTCRoutePlanErrorCodeInvalidConfiguration
                      description:[MTCExampleDemoLocalization stringForKey:@"web_invalid_route_destination" language:[MTCExampleDemoLocalization currentLanguage]]];
    }
    for (MTCRouteWaypoint *waypoint in configuration.waypoints) {
        if (!CLLocationCoordinate2DIsValid(waypoint.coordinate)) {
            return [self errorWithCode:MTCRoutePlanErrorCodeInvalidConfiguration
                          description:[MTCExampleDemoLocalization stringForKey:@"web_route_contains_invalid_waypoints" language:[MTCExampleDemoLocalization currentLanguage]]];
        }
    }
    return nil;
}

- (MTCRouteRequest *)requestFromConfiguration:(MTCRoutePlanConfiguration *)configuration {
    MTCRouteLocationPoint *origin =
        [[MTCRouteLocationPoint alloc] initWithCoordinate:configuration.origin.coordinate];
    MTCRouteLocationPoint *destination =
        [[MTCRouteLocationPoint alloc] initWithCoordinate:configuration.destination.coordinate];
    MTCRouteRequest *request = [[MTCRouteRequest alloc] initWithOrigin:origin
                                                           destination:destination];
    NSMutableArray<MTCRouteLocationPoint *> *waypoints =
        [NSMutableArray arrayWithCapacity:configuration.waypoints.count];
    for (MTCRouteWaypoint *waypoint in configuration.waypoints) {
        [waypoints addObject:[[MTCRouteLocationPoint alloc] initWithCoordinate:waypoint.coordinate]];
    }
    request.waypoints = [waypoints copy];
    request.mode = MTCRouteModeDriving;
    request.strategy = [self strategyForRouteStrategy:configuration.strategy];
    request.alternatives = configuration.requestsAlternativeRoutes;
    if (configuration.avoidsHighways) {
        MTCRouteAvoid *avoid = [[MTCRouteAvoid alloc] init];
        avoid.criteria = @[MTCRouteAvoidCriteriaHighways];
        request.avoid = avoid;
    }
    return request;
}

- (NSString *)strategyForRouteStrategy:(MTCMapRouteStrategy)strategy {
    switch (strategy) {
        case MTCMapRouteStrategyShortest: {
            return MTCRouteStrategyShortest;
        }
        break;
        case MTCMapRouteStrategyBalanced: {
            return MTCRouteStrategyBalanced;
        }
        break;
        case MTCMapRouteStrategyFastest: {
            return MTCRouteStrategyFastest;
        }
        break;
    }
    return MTCRouteStrategyFastest;
}

- (NSArray<MTCRouteCandidate *> *)candidatesFromResponse:(MTCRouteResponse *)response
                                                    error:(NSError * _Nullable __autoreleasing *)error {
    if (response.routes.count == 0) {
        if (error) {
            *error = [self errorWithCode:MTCRoutePlanErrorCodeEmptyResult
                             description:response.error.message ?: [MTCExampleDemoLocalization stringForKey:@"web_no_available_routes_returned" language:[MTCExampleDemoLocalization currentLanguage]]];
        }
        return nil;
    }

    NSString *resultIdentifier = NSUUID.UUID.UUIDString;
    NSMutableArray<MTCRouteCandidate *> *candidates = [NSMutableArray array];
    [response.routes enumerateObjectsUsingBlock:^(MTCRoute *route, NSUInteger index, BOOL *stop) {
        (void)stop;
        NSArray<NSValue *> *coordinates = [route coordinatesFromPolyline];
        if (coordinates.count < 2) {
            return;
        }
        NSUInteger candidateIndex = candidates.count;
        MTCRouteSummary *summary = route.summary;
        MTCRouteCandidate *candidate =
            [[MTCRouteCandidate alloc] initWithIdentifier:[NSString stringWithFormat:@"%@-%lu",
                                                                                     resultIdentifier,
                                                                                     (unsigned long)index]
                                                   index:candidateIndex
                                                distance:MAX(0.0, summary.distanceMeters.doubleValue)
                                                duration:MAX(0.0, summary.durationSeconds.doubleValue)
                                         trafficDuration:MAX(0.0, summary.trafficDurationSeconds.doubleValue)
                                             coordinates:coordinates];
        [candidates addObject:candidate];
    }];
    if (candidates.count == 0 && error) {
        *error = [self errorWithCode:MTCRoutePlanErrorCodeInvalidGeometry
                         description:[MTCExampleDemoLocalization stringForKey:@"web_failed_to_parse_route_geometry" language:[MTCExampleDemoLocalization currentLanguage]]];
    }
    return candidates.count > 0 ? [candidates copy] : nil;
}

- (NSError *)errorWithCode:(MTCRoutePlanErrorCode)code description:(NSString *)description {
    return [NSError errorWithDomain:MTCRoutePlanErrorDomain
                               code:code
                           userInfo:@{NSLocalizedDescriptionKey: description}];
}

#pragma mark - Getter & Setter

@end
