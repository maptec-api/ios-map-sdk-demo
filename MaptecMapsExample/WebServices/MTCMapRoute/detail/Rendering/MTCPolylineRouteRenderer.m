//
//  MTCPolylineRouteRenderer.m
//  MaptecMapsExample
//
//  Created by ZHOUPanpan+ on 2026/8/3.
//  Copyright © 2026 ZHOUPanpan+. All rights reserved.
//

#import "MTCPolylineRouteRenderer.h"
#import "MTCExampleDemoLocalization.h"
#import "MTCRoutePlanModels+Internal.h"

#include <float.h>

@interface MTCPolylineRouteRenderer ()

@property (nonatomic, weak, nullable) MTCMapView *mapView;
@property (nonatomic, strong) MTCRouteDisplayOptions *displayOptions;
@property (nonatomic, copy) NSArray<MTCRouteCandidate *> *routes;
@property (nonatomic, copy) NSArray<MTCPolyline *> *routePolylines;
@property (nonatomic, copy) NSArray<id<MTCOverlay>> *endpointOverlays;
@property (nonatomic, copy) NSDictionary<NSString *, NSNumber *> *routeIndexByOverlayIdentifier;
@property (nonatomic, assign) NSInteger selectedRouteIndex;

@end

@implementation MTCPolylineRouteRenderer

- (void)dealloc {
}

#pragma mark - Public

- (instancetype)initWithMapView:(MTCMapView *)mapView
                 displayOptions:(MTCRouteDisplayOptions *)displayOptions {
    self = [super init];
    if (self) {
        _mapView = mapView;
        _displayOptions = [displayOptions copy] ?: [[MTCRouteDisplayOptions alloc] init];
        _routes = @[];
        _routePolylines = @[];
        _endpointOverlays = @[];
        _routeIndexByOverlayIdentifier = @{};
        _selectedRouteIndex = NSNotFound;
    }
    return self;
}

- (void)displayRoutes:(NSArray<MTCRouteCandidate *> *)routes
        configuration:(MTCRoutePlanConfiguration *)configuration
         selectedIndex:(NSInteger)selectedIndex {
    NSAssert(NSThread.isMainThread, @"Route overlays must be updated on the main thread.");
    [self clear];
    if (!self.mapView || routes.count == 0) {
        return;
    }

    NSMutableArray<MTCPolyline *> *polylines = [NSMutableArray arrayWithCapacity:routes.count];
    NSMutableDictionary<NSString *, NSNumber *> *indices = [NSMutableDictionary dictionary];
    for (MTCRouteCandidate *route in routes) {
        MTCPolyline *polyline = [self polylineForRoute:route selected:NO];
        [polylines addObject:polyline];
        indices[polyline.identifier] = @(route.index);
    }

    self.routes = [routes copy];
    self.routePolylines = [polylines copy];
    self.routeIndexByOverlayIdentifier = [indices copy];
    self.endpointOverlays = self.displayOptions.showsEndpointMarkers
        ? [self endpointOverlaysForConfiguration:configuration]
        : @[];
    self.selectedRouteIndex = selectedIndex;

    NSMutableArray<id<MTCOverlay>> *overlays =
        [NSMutableArray arrayWithArray:self.routePolylines];
    [overlays addObjectsFromArray:self.endpointOverlays];
    [self.mapView addOverlays:overlays];
    [self applySelectionStyles];
}

- (void)selectRouteAtIndex:(NSInteger)index {
    NSAssert(NSThread.isMainThread, @"Route overlays must be updated on the main thread.");
    if (index < 0 || index >= (NSInteger)self.routePolylines.count ||
        index == self.selectedRouteIndex) {
        return;
    }
    self.selectedRouteIndex = index;
    [self applySelectionStyles];
}

- (NSNumber *)routeIndexForOverlay:(id<MTCOverlay>)overlay {
    if (!overlay.identifier) {
        return nil;
    }
    return self.routeIndexByOverlayIdentifier[overlay.identifier];
}

- (void)showOverviewWithOptions:(MTCRouteOverviewOptions *)options {
    NSAssert(NSThread.isMainThread, @"Route camera updates must run on the main thread.");
    if (!self.mapView || self.routes.count == 0) {
        return;
    }

    MTCRouteOverviewOptions *resolvedOptions =
        [options copy] ?: [[MTCRouteOverviewOptions alloc] init];
    NSArray<MTCRouteCandidate *> *routes = self.routes;
    if (resolvedOptions.mode == MTCRouteOverviewModeSelectedRoute &&
        self.selectedRouteIndex >= 0 &&
        self.selectedRouteIndex < (NSInteger)self.routes.count) {
        routes = @[self.routes[(NSUInteger)self.selectedRouteIndex]];
    }

    MTCCoordinateBounds bounds;
    if (![self getBounds:&bounds forRoutes:routes]) {
        return;
    }
    [self.mapView setVisibleCoordinateBounds:bounds
                                 edgePadding:resolvedOptions.edgePadding
                                  transition:nil completion:nil];
}

- (void)clear {
    NSAssert(NSThread.isMainThread, @"Route overlays must be updated on the main thread.");
    NSMutableArray<id<MTCOverlay>> *overlays =
        [NSMutableArray arrayWithArray:self.routePolylines ?: @[]];
    [overlays addObjectsFromArray:self.endpointOverlays ?: @[]];
    if (overlays.count > 0) {
        [self.mapView removeOverlays:overlays];
    }
    self.routes = @[];
    self.routePolylines = @[];
    self.endpointOverlays = @[];
    self.routeIndexByOverlayIdentifier = @{};
    self.selectedRouteIndex = NSNotFound;
}

- (void)invalidate {
    [self clear];
    self.mapView = nil;
}

#pragma mark - Life Cycle

#pragma mark - Protocol

#pragma mark - Delegate

#pragma mark - Event

#pragma mark - Private

- (MTCPolyline *)polylineForRoute:(MTCRouteCandidate *)route selected:(BOOL)selected {
    NSUInteger count = route.coordinates.count;
    CLLocationCoordinate2D *buffer = calloc(count, sizeof(CLLocationCoordinate2D));
    NSUInteger cursor = 0;
    for (NSValue *value in route.coordinates) {
        CLLocationCoordinate2D coordinate = kCLLocationCoordinate2DInvalid;
        [value getValue:&coordinate];
        if (CLLocationCoordinate2DIsValid(coordinate)) {
            buffer[cursor++] = coordinate;
        }
    }
    MTCPolyline *polyline = [[MTCPolyline alloc] initWithCoordinates:buffer count:cursor];
    free(buffer);
    polyline.clickable = YES;
    polyline.userInfo = @{@"routeIdentifier": route.identifier, @"routeIndex": @(route.index)};
    [self applyStyleToPolyline:polyline selected:selected];
    return polyline;
}

- (NSArray<id<MTCOverlay>> *)endpointOverlaysForConfiguration:(MTCRoutePlanConfiguration *)configuration {
    NSMutableArray<id<MTCOverlay>> *overlays = [NSMutableArray array];
    if (!configuration.origin.representsCurrentLocation &&
        CLLocationCoordinate2DIsValid(configuration.origin.coordinate)) {
        [overlays addObject:[self markerAtCoordinate:configuration.origin.coordinate
                                              title:configuration.origin.name ?: [MTCExampleDemoLocalization stringForKey:@"web_origin" language:[MTCExampleDemoLocalization currentLanguage]]
                                           iconType:MTCMarkerIconTypeGreenDot]];
    }
    [configuration.waypoints enumerateObjectsUsingBlock:^(MTCRouteWaypoint *waypoint,
                                                           NSUInteger index,
                                                           BOOL *stop) {
        if (!CLLocationCoordinate2DIsValid(waypoint.coordinate)) {
            return;
        }
        NSString *title = waypoint.name ?: [NSString stringWithFormat:[MTCExampleDemoLocalization stringForKey:@"web_waypoint_lu" language:[MTCExampleDemoLocalization currentLanguage]],
                                                                        (unsigned long)(index + 1)];
        [overlays addObject:[self markerAtCoordinate:waypoint.coordinate
                                              title:title
                                           iconType:MTCMarkerIconTypeBlueDot]];
    }];
    if (CLLocationCoordinate2DIsValid(configuration.destination.coordinate)) {
        [overlays addObject:[self markerAtCoordinate:configuration.destination.coordinate
                                              title:configuration.destination.name ?: [MTCExampleDemoLocalization stringForKey:@"web_destination" language:[MTCExampleDemoLocalization currentLanguage]]
                                           iconType:MTCMarkerIconTypeRedDot]];
    }
    return [overlays copy];
}

- (MTCMarker *)markerAtCoordinate:(CLLocationCoordinate2D)coordinate
                            title:(NSString *)title
                         iconType:(MTCMarkerIconType)iconType {
    MTCMarker *marker = [[MTCMarker alloc] initWithCoordinate:coordinate];
    MTCMarkerStyle *style = [[MTCMarkerStyle alloc] init];
    style.icon.type = iconType;
    style.title.text = title;
    marker.style = style;
    marker.zIndex = 200;
    marker.clickable = NO;
    marker.togglesSelectionOnTap = NO;
    return marker;
}

- (void)applySelectionStyles {
    [self.mapView performOverlayUpdates:^{
        [self.routePolylines enumerateObjectsUsingBlock:^(MTCPolyline *polyline,
                                                           NSUInteger index,
                                                           BOOL *stop) {
            [self applyStyleToPolyline:polyline
                              selected:index == (NSUInteger)self.selectedRouteIndex];
        }];
    }];
}

- (void)applyStyleToPolyline:(MTCPolyline *)polyline selected:(BOOL)selected {
    MTCPolylineStyle *style = [[MTCPolylineStyle alloc] init];
    style.strokeColor = selected
        ? self.displayOptions.selectedRouteColor
        : self.displayOptions.alternativeRouteColor;
    style.strokeWeight = selected
        ? self.displayOptions.selectedRouteWidth
        : self.displayOptions.alternativeRouteWidth;
    style.strokeOpacity = selected ? 1.0 : 0.75;
    style.lineJoinType = MTCLineJoinTypeRound;
    style.startLineCapType = MTCLineCapTypeRound;
    style.endLineCapType = MTCLineCapTypeRound;
    style.directionalArrowStyle.enabled = self.displayOptions.showsDirectionalArrows;
    style.directionalArrowStyle.type = MTCLineDirectionalArrowTypeChevron;
    style.directionalArrowStyle.color = UIColor.whiteColor;
    style.directionalArrowStyle.edgeInset = 1.0;
    polyline.style = style;
    polyline.zIndex = selected ? 100 : 50;
}

- (BOOL)getBounds:(MTCCoordinateBounds *)bounds
        forRoutes:(NSArray<MTCRouteCandidate *> *)routes {
    CLLocationDegrees minLatitude = DBL_MAX;
    CLLocationDegrees maxLatitude = -DBL_MAX;
    CLLocationDegrees minLongitude = DBL_MAX;
    CLLocationDegrees maxLongitude = -DBL_MAX;

    for (MTCRouteCandidate *route in routes) {
        for (NSValue *value in route.coordinates) {
            CLLocationCoordinate2D coordinate = kCLLocationCoordinate2DInvalid;
            [value getValue:&coordinate];
            if (!CLLocationCoordinate2DIsValid(coordinate)) {
                continue;
            }
            minLatitude = MIN(minLatitude, coordinate.latitude);
            maxLatitude = MAX(maxLatitude, coordinate.latitude);
            minLongitude = MIN(minLongitude, coordinate.longitude);
            maxLongitude = MAX(maxLongitude, coordinate.longitude);
        }
    }
    if (minLatitude == DBL_MAX || minLongitude == DBL_MAX) {
        return NO;
    }

    static const CLLocationDegrees MTCRouteMinimumSpan = 0.001;
    if (maxLatitude - minLatitude < MTCRouteMinimumSpan) {
        minLatitude -= MTCRouteMinimumSpan * 0.5;
        maxLatitude += MTCRouteMinimumSpan * 0.5;
    }
    if (maxLongitude - minLongitude < MTCRouteMinimumSpan) {
        minLongitude -= MTCRouteMinimumSpan * 0.5;
        maxLongitude += MTCRouteMinimumSpan * 0.5;
    }
    *bounds = MTCCoordinateBoundsMake(CLLocationCoordinate2DMake(minLatitude, minLongitude),
                                      CLLocationCoordinate2DMake(maxLatitude, maxLongitude));
    return YES;
}

#pragma mark - Getter & Setter

@end
