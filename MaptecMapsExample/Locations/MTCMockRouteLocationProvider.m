#import "MTCMockRouteLocationProvider.h"

static NSString *const MTCMockRouteLocationProviderErrorDomain = @"com.maptec.maps.example.mock-location";

static NSDictionary<NSString *, NSString *> *MTCMockRouteLocationResourceNamesByID(void) {
    return @{
        @"driving_city_roads" : @"singapore_mock_route_driving_city_roads",
        @"driving_expressway" : @"singapore_mock_route_driving_expressway",
        @"cycling_city_roads" : @"singapore_mock_route_cycling_city_roads",
        @"walking_city_roads" : @"singapore_mock_route_walking_city_roads",
    };
}

@interface MTCMockRouteLocationProvider ()

@property (nonatomic, copy, readwrite) NSString *routeID;
@property (nonatomic, copy, readwrite) NSString *routeName;
@property (nonatomic, readwrite) CLLocationCoordinate2D firstCoordinate;
@property (nonatomic, copy) NSArray<NSDictionary<NSString *, id> *> *points;
@property (nonatomic, copy, readwrite) NSData *routeCoordinateData;
@property (nonatomic, readwrite) NSInteger currentPointIndex;
@property (nonatomic, readwrite) NSTimeInterval currentElapsedTime;
@property (nonatomic, readwrite) double currentSpeedKmh;
@property (nonatomic, readwrite) CLLocationDirection currentHeading;
@property (nonatomic, readwrite, getter=isUpdating) BOOL updating;
@property (nonatomic, readwrite, getter=isFinished) BOOL finished;
@property (nonatomic, strong, nullable) NSTimer *timer;

@end

@implementation MTCMockRouteLocationProvider

- (instancetype)initWithRouteID:(NSString *)routeID {
    self = [super init];
    if (self) {
        NSDictionary<NSString *, id> *route = [self.class routeForID:routeID];
        _routeID = [routeID copy];
        _routeName = [route[@"name_zh"] isKindOfClass:NSString.class] ? [route[@"name_zh"] copy] : [routeID copy];
        _points = [route[@"points"] isKindOfClass:NSArray.class] ? [route[@"points"] copy] : @[];
        _routeCoordinateData = [self coordinateDataForPoints:_points];
        _currentPointIndex = -1;
        _currentHeading = -1.0;
        _firstCoordinate = [self coordinateForPoint:_points.firstObject];
    }
    return self;
}

- (void)dealloc {
    [self stopUpdatingLocation];
}

- (NSUInteger)pointCount {
    return self.points.count;
}

- (void)startUpdatingLocation {
    if (![NSThread isMainThread]) {
        __weak typeof(self) weakSelf = self;
        dispatch_async(dispatch_get_main_queue(), ^{
            [weakSelf startUpdatingLocation];
        });
        return;
    }
    if (self.updating) {
        return;
    }
    if (self.points.count == 0) {
        [self reportErrorWithDescription:@"Mock route data is empty."];
        return;
    }
    if (self.finished) {
        [self resetPlaybackState];
    }

    self.updating = YES;
    [self emitNextPoint];
}

- (void)stopUpdatingLocation {
    if (![NSThread isMainThread]) {
        __weak typeof(self) weakSelf = self;
        dispatch_async(dispatch_get_main_queue(), ^{
            [weakSelf stopUpdatingLocation];
        });
        return;
    }

    [self.timer invalidate];
    self.timer = nil;
    if (self.updating) {
        self.updating = NO;
        [self notifyStatusDidChange];
    }
}

- (void)startUpdatingHeading {
}

- (void)stopUpdatingHeading {
}

- (void)restart {
    if (![NSThread isMainThread]) {
        __weak typeof(self) weakSelf = self;
        dispatch_async(dispatch_get_main_queue(), ^{
            [weakSelf restart];
        });
        return;
    }

    [self stopUpdatingLocation];
    [self resetPlaybackState];
    [self startUpdatingLocation];
}

#pragma mark - Private

+ (NSDictionary<NSString *, id> *)routeForID:(NSString *)routeID {
    NSString *resourceName = MTCMockRouteLocationResourceNamesByID()[routeID];
    NSURL *url = resourceName.length > 0 ? [NSBundle.mainBundle URLForResource:resourceName withExtension:@"json"] : nil;
    NSData *data = url ? [NSData dataWithContentsOfURL:url] : nil;
    NSDictionary *route = data ? [NSJSONSerialization JSONObjectWithData:data options:0 error:nil] : nil;
    return [route isKindOfClass:NSDictionary.class] ? route : @{};
}

- (void)resetPlaybackState {
    self.currentPointIndex = -1;
    self.currentElapsedTime = 0.0;
    self.currentSpeedKmh = 0.0;
    self.currentHeading = -1.0;
    self.finished = NO;
}

- (void)emitNextPoint {
    if (!self.updating) {
        return;
    }

    NSInteger nextIndex = self.currentPointIndex + 1;
    if (nextIndex >= (NSInteger)self.points.count) {
        self.updating = NO;
        self.finished = YES;
        [self notifyStatusDidChange];
        return;
    }

    NSDictionary<NSString *, id> *point = self.points[(NSUInteger)nextIndex];
    self.currentPointIndex = nextIndex;
    self.currentElapsedTime = [self doubleValueForKey:@"elapsed_s" inPoint:point fallback:0.0];
    self.currentSpeedKmh = [self doubleValueForKey:@"speed_kmh" inPoint:point fallback:0.0];
    self.currentHeading = [self doubleValueForKey:@"heading_deg" inPoint:point fallback:-1.0];
    self.finished = nextIndex == (NSInteger)self.points.count - 1;

    CLLocation *location = [self locationForPoint:point];
    id<MTCUserLocationProviderDelegate> delegate = self.delegate;
    if (location) {
        [delegate userLocationProvider:self didUpdateLocation:location];
    }
    if (self.currentHeading >= 0.0 &&
        [delegate respondsToSelector:@selector(userLocationProvider:didUpdateHeading:)]) {
        [delegate userLocationProvider:self didUpdateHeading:self.currentHeading];
    }

    if (self.finished) {
        self.updating = NO;
        [self notifyStatusDidChange];
        return;
    }

    [self notifyStatusDidChange];
    [self scheduleNextPoint];
}

- (void)scheduleNextPoint {
    NSUInteger nextIndex = (NSUInteger)self.currentPointIndex + 1;
    if (nextIndex >= self.points.count) {
        return;
    }

    NSDictionary<NSString *, id> *currentPoint = self.points[(NSUInteger)self.currentPointIndex];
    NSDictionary<NSString *, id> *nextPoint = self.points[nextIndex];
    NSTimeInterval currentElapsed = [self doubleValueForKey:@"elapsed_s" inPoint:currentPoint fallback:0.0];
    NSTimeInterval nextElapsed = [self doubleValueForKey:@"elapsed_s" inPoint:nextPoint fallback:currentElapsed + 1.0];
    NSTimeInterval delay = MAX(0.0, nextElapsed - currentElapsed);

    __weak typeof(self) weakSelf = self;
    NSTimer *timer = [NSTimer timerWithTimeInterval:delay repeats:NO block:^(NSTimer *scheduledTimer) {
        MTCMockRouteLocationProvider *strongSelf = weakSelf;
        if (!strongSelf) {
            return;
        }
        if (strongSelf.timer == scheduledTimer) {
            strongSelf.timer = nil;
        }
        [strongSelf emitNextPoint];
    }];
    [self.timer invalidate];
    self.timer = timer;
    [NSRunLoop.mainRunLoop addTimer:timer forMode:NSRunLoopCommonModes];
}

- (CLLocation *)locationForPoint:(NSDictionary<NSString *, id> *)point {
    CLLocationCoordinate2D coordinate = [self coordinateForPoint:point];
    if (!CLLocationCoordinate2DIsValid(coordinate)) {
        return nil;
    }

    CLLocationSpeed speed = [self doubleValueForKey:@"speed_mps" inPoint:point fallback:-1.0];
    CLLocationDirection course = [self doubleValueForKey:@"heading_deg" inPoint:point fallback:-1.0];
    return [[CLLocation alloc] initWithCoordinate:coordinate
                                        altitude:0.0
                              horizontalAccuracy:8.0
                                verticalAccuracy:-1.0
                                          course:course
                                           speed:speed
                                       timestamp:NSDate.date];
}

- (CLLocationCoordinate2D)coordinateForPoint:(NSDictionary<NSString *, id> *)point {
    if (![point isKindOfClass:NSDictionary.class]) {
        return kCLLocationCoordinate2DInvalid;
    }
    CLLocationDegrees latitude = [self doubleValueForKey:@"lat" inPoint:point fallback:NAN];
    CLLocationDegrees longitude = [self doubleValueForKey:@"lon" inPoint:point fallback:NAN];
    return CLLocationCoordinate2DMake(latitude, longitude);
}

- (NSData *)coordinateDataForPoints:(NSArray<NSDictionary<NSString *, id> *> *)points {
    if (points.count == 0) {
        return [NSData data];
    }

    NSMutableData *data = [NSMutableData dataWithLength:sizeof(CLLocationCoordinate2D) * points.count];
    CLLocationCoordinate2D *coordinates = (CLLocationCoordinate2D *)data.mutableBytes;
    NSUInteger coordinateCount = 0;
    for (NSDictionary<NSString *, id> *point in points) {
        CLLocationCoordinate2D coordinate = [self coordinateForPoint:point];
        if (!CLLocationCoordinate2DIsValid(coordinate)) {
            continue;
        }
        coordinates[coordinateCount] = coordinate;
        coordinateCount += 1;
    }
    data.length = sizeof(CLLocationCoordinate2D) * coordinateCount;
    return [data copy];
}

- (double)doubleValueForKey:(NSString *)key
                    inPoint:(NSDictionary<NSString *, id> *)point
                   fallback:(double)fallback {
    NSNumber *number = [point[key] isKindOfClass:NSNumber.class] ? point[key] : nil;
    return number ? number.doubleValue : fallback;
}

- (void)reportErrorWithDescription:(NSString *)description {
    NSError *error = [NSError errorWithDomain:MTCMockRouteLocationProviderErrorDomain
                                         code:1
                                     userInfo:@{NSLocalizedDescriptionKey : description ?: @""}];
    id<MTCUserLocationProviderDelegate> delegate = self.delegate;
    if ([delegate respondsToSelector:@selector(userLocationProvider:didFailWithError:)]) {
        [delegate userLocationProvider:self didFailWithError:error];
    }
    [self notifyStatusDidChange];
}

- (void)notifyStatusDidChange {
    if (self.statusDidChangeHandler) {
        self.statusDidChangeHandler(self);
    }
}

@end
