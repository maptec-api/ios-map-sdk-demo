#import <CoreLocation/CoreLocation.h>
#import <Foundation/Foundation.h>
#import <MaptecMapsKit/MTCUserLocationProvider.h>

NS_ASSUME_NONNULL_BEGIN

@class MTCMockRouteLocationProvider;

typedef void (^MTCMockRouteLocationProviderStatusHandler)(MTCMockRouteLocationProvider *provider);

@interface MTCMockRouteLocationProvider : NSObject <MTCUserLocationProvider>

- (instancetype)initWithRouteID:(NSString *)routeID NS_DESIGNATED_INITIALIZER;
- (instancetype)init NS_UNAVAILABLE;
+ (instancetype)new NS_UNAVAILABLE;

@property (nonatomic, weak, nullable) id<MTCUserLocationProviderDelegate> delegate;
@property (nonatomic, copy, readonly) NSString *routeID;
@property (nonatomic, copy, readonly) NSString *routeName;
@property (nonatomic, readonly) CLLocationCoordinate2D firstCoordinate;
@property (nonatomic, readonly) NSUInteger pointCount;
@property (nonatomic, copy, readonly) NSData *routeCoordinateData;
@property (nonatomic, readonly) NSInteger currentPointIndex;
@property (nonatomic, readonly) NSTimeInterval currentElapsedTime;
@property (nonatomic, readonly) double currentSpeedKmh;
@property (nonatomic, readonly) CLLocationDirection currentHeading;
@property (nonatomic, readonly, getter=isUpdating) BOOL updating;
@property (nonatomic, readonly, getter=isFinished) BOOL finished;
@property (nonatomic, copy, nullable) MTCMockRouteLocationProviderStatusHandler statusDidChangeHandler;

- (void)restart;

@end

NS_ASSUME_NONNULL_END
