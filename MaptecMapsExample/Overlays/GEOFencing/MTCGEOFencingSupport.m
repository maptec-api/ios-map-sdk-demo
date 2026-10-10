//
//  MTCGEOFencingSupport.m
//  MaptecMapsExample
//
//  Created by ZHOUPanpan on 2026/7/13.
//

#import "MTCGEOFencingSupport.h"

CLLocationDegrees const MTCGEOFencingPointFenceLatitude = 39.9087;
CLLocationDegrees const MTCGEOFencingPointFenceLongitude = 116.3975;
CLLocationDistance const MTCGEOFencingPointFenceRadius = 200.0;

NSUInteger const MTCGEOFencingPolygonFenceCount = 5;// + 3;
const CLLocationCoordinate2D MTCGEOFencingPolygonFenceCoords[] = {
    {39.905, 116.390},
    //{39.908, 116.392},
    {39.905, 116.395},
    //{39.908, 116.395},
    //{39.909, 116.393},
    {39.910, 116.395},
    {39.910, 116.390},
    {39.905, 116.390},
};

CLLocationDegrees const MTCGEOFencingCameraLatitude = 39.908;
CLLocationDegrees const MTCGEOFencingCameraLongitude = 116.394;
double const MTCGEOFencingCameraZoom = 15.0;

MTCCircleStyle *MTCGEOFencingMakeCircleStyle(void) {
    MTCCircleStyle *style = [[MTCCircleStyle alloc] init];
    style.fillColor = [UIColor colorWithRed:0.227 green:0.369 blue:0.984 alpha:1.0];
    style.fillOpacity = 0.25;
    style.strokeColor = [UIColor colorWithRed:0.227 green:0.369 blue:0.984 alpha:1.0];
    style.strokeWeight = 3.0;
    return style;
}

MTCPolygonStyle *MTCGEOFencingMakePolygonStyle(void) {
    MTCPolygonStyle *style = [[MTCPolygonStyle alloc] init];
    style.fillColor = [UIColor colorWithRed:0.227 green:0.369 blue:0.984 alpha:1.0];
    style.fillOpacity = 0.25;
    style.strokeColor = [UIColor colorWithRed:0.227 green:0.369 blue:0.984 alpha:1.0];
    style.strokeWeight = 3.0;
    style.strokeOpacity = 1.0;
    return style;
}

BOOL MTCGEOFencingPointInsideCircle(CLLocationCoordinate2D point, MTCCircle *circle) {
    return MTCCircleHaversineContainsPoint(circle.center, circle.radius, point);
}

BOOL MTCGEOFencingPointInsidePolygon(CLLocationCoordinate2D point, MTCPolygon *polygon) {
    NSUInteger count = polygon.outerRingCoordinateCount;
    if (count == 0) {
        return NO;
    }
    CLLocationCoordinate2D coords[count];
    [polygon getOuterRingCoordinates:coords range:NSMakeRange(0, count)];
    return MTCPolygonWGS84ContainsPoint(coords, count, point);
}
