//
//  MTCGEOFencingSupport.h
//  MaptecMapsExample
//
//  Created by ZHOUPanpan on 2026/7/13.
//

#import <CoreLocation/CoreLocation.h>
#import <MaptecMapsKit/MaptecMapsKit.h>

NS_ASSUME_NONNULL_BEGIN

FOUNDATION_EXTERN CLLocationDegrees const MTCGEOFencingPointFenceLatitude;
FOUNDATION_EXTERN CLLocationDegrees const MTCGEOFencingPointFenceLongitude;
FOUNDATION_EXTERN CLLocationDistance const MTCGEOFencingPointFenceRadius;

FOUNDATION_EXTERN NSUInteger const MTCGEOFencingPolygonFenceCount;
FOUNDATION_EXTERN const CLLocationCoordinate2D MTCGEOFencingPolygonFenceCoords[];

FOUNDATION_EXTERN CLLocationDegrees const MTCGEOFencingCameraLatitude;
FOUNDATION_EXTERN CLLocationDegrees const MTCGEOFencingCameraLongitude;
FOUNDATION_EXTERN double const MTCGEOFencingCameraZoom;

FOUNDATION_EXTERN MTCCircleStyle *MTCGEOFencingMakeCircleStyle(void);
FOUNDATION_EXTERN MTCPolygonStyle *MTCGEOFencingMakePolygonStyle(void);
FOUNDATION_EXTERN BOOL MTCGEOFencingPointInsideCircle(CLLocationCoordinate2D point, MTCCircle *circle);
FOUNDATION_EXTERN BOOL MTCGEOFencingPointInsidePolygon(CLLocationCoordinate2D point, MTCPolygon *polygon);

NS_ASSUME_NONNULL_END
