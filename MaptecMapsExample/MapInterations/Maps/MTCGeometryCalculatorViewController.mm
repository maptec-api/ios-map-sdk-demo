//
//  MTCGeometryCalculatorViewController.mm
//  MaptecMapsExample
//
//  Created by Codex on 2026/8/28.
//

#import "MTCGeometryCalculatorViewController.h"

#import "ExampleSettingsSheetView.h"
#import "MTCExampleToastView.h"

#import <MaptecMapsKit/MaptecMapsKit.h>

#include <float.h>
#include <math.h>

typedef NS_ENUM(NSInteger, MTCGeometryDemoTopSection) {
    MTCGeometryDemoTopSectionSphere = 0,
    MTCGeometryDemoTopSectionPath,
    MTCGeometryDemoTopSectionEncoding,
};

typedef NS_ENUM(NSInteger, MTCGeometryDemoSphereChip) {
    MTCGeometryDemoSphereChipDistance = 0,
    MTCGeometryDemoSphereChipAngle,
    MTCGeometryDemoSphereChipArea,
    MTCGeometryDemoSphereChipSignedArea,
    MTCGeometryDemoSphereChipOffset,
    MTCGeometryDemoSphereChipReverseOrigin,
    MTCGeometryDemoSphereChipInterpolate,
};

typedef NS_ENUM(NSInteger, MTCGeometryDemoPathChip) {
    MTCGeometryDemoPathChipPath = 0,
    MTCGeometryDemoPathChipClosedSegmentIndex,
    MTCGeometryDemoPathChipPointToLine,
    MTCGeometryDemoPathChipIsClosed,
};

static CLLocationDegrees const MTCGeometryDemoInitialLatitude = 1.3521;
static CLLocationDegrees const MTCGeometryDemoInitialLongitude = 103.8198;
static double const MTCGeometryDemoInitialZoomLevel = 13.0;
static CGFloat const MTCGeometryDemoBottomDockHeight = 180.0;
static CGFloat const MTCGeometryDemoChipHeight = 36.0;
static CGFloat const MTCGeometryDemoTabHeight = 52.0;
static CLLocationDistance const MTCGeometryDemoResultPaddingMeters = 72.0;
static CLLocationDistance const MTCGeometryDemoClosedSnapRadiusMeters = 80.0;
static CLLocationDistance const MTCGeometryDemoPathTestToleranceMeters = 20.0;
static CLLocationDistance const MTCGeometryDemoPointToLineToleranceMeters = 20.0;
static CLLocationDistance const MTCGeometryDemoDuplicatePointToleranceMeters = 1.0;
static double const MTCGeometryDemoMinimumPolygonAreaSquareMeters = 1.0;
static CLLocationDistance const MTCGeometryDemoSimplifyOffsetMeters = 500.0;
static CGFloat const MTCGeometryDemoBadgeSide = 36.0;
static CGFloat const MTCGeometryDemoPolygonFocusPadding = 40.0;
static CGFloat const MTCGeometryDemoLineFocusPadding = 40.0;
static CLLocationDegrees const MTCGeometryDemoLineMinimumFocusSpan = 0.001;

static UIColor *MTCGeometryDemoBlueColor(void) {
    return UIColor.systemBlueColor;
}

static UIColor *MTCGeometryDemoGreenColor(void) {
    return UIColor.systemGreenColor;
}

static UIColor *MTCGeometryDemoOrangeColor(void) {
    return UIColor.systemOrangeColor;
}

static UIColor *MTCGeometryDemoPurpleColor(void) {
    return UIColor.systemPurpleColor;
}

static UIColor *MTCGeometryDemoRedColor(void) {
    return UIColor.systemRedColor;
}

static UIColor *MTCGeometryDemoLightBlueColor(void) {
    return UIColor.secondarySystemBackgroundColor;
}

static NSValue *MTCGeometryDemoValueFromCoordinate(CLLocationCoordinate2D coordinate) {
    return [NSValue valueWithBytes:&coordinate objCType:@encode(CLLocationCoordinate2D)];
}

static CLLocationCoordinate2D MTCGeometryDemoCoordinateFromValue(NSValue *value) {
    CLLocationCoordinate2D coordinate = kCLLocationCoordinate2DInvalid;
    if (value) {
        [value getValue:&coordinate];
    }
    return coordinate;
}

static BOOL MTCGeometryDemoCoordinateIsValid(CLLocationCoordinate2D coordinate) {
    return CLLocationCoordinate2DIsValid(coordinate);
}

static CLLocationCoordinate2D MTCGeometryDemoCoordinateMake(double latitude, double longitude) {
    return CLLocationCoordinate2DMake(latitude, longitude);
}

static NSString *MTCGeometryDemoCoordinateText(CLLocationCoordinate2D coordinate) {
    if (!MTCGeometryDemoCoordinateIsValid(coordinate)) {
        return @"无效坐标";
    }
    return [NSString stringWithFormat:@"(%.6f, %.6f)", coordinate.latitude, coordinate.longitude];
}

static NSString *MTCGeometryDemoDistanceText(CLLocationDistance meters) {
    if (fabs(meters) >= 1000.0) {
        return [NSString stringWithFormat:@"%.2f km", meters / 1000.0];
    }
    return [NSString stringWithFormat:@"%.0f m", meters];
}

static NSString *MTCGeometryDemoAreaText(double squareMeters) {
    if (fabs(squareMeters) >= 1000000.0) {
        return [NSString stringWithFormat:@"%.2f km²", squareMeters / 1000000.0];
    }
    return [NSString stringWithFormat:@"%.0f m²", squareMeters];
}

static NSString *MTCGeometryDemoHeadingText(CLLocationDirection heading) {
    return [NSString stringWithFormat:@"%.1f°", heading];
}

static NSString *MTCGeometryDemoAngleText(double radians) {
    return [NSString stringWithFormat:@"%.4f rad / %.1f°", radians, radians * 180.0 / M_PI];
}

static NSString *MTCGeometryDemoFractionText(double fraction) {
    return [NSString stringWithFormat:@"%.0f%%", fraction * 100.0];
}

static double MTCGeometryDemoNormalizeHeading(CLLocationDirection heading) {
    double normalized = fmod(heading, 360.0);
    if (normalized < 0.0) {
        normalized += 360.0;
    }
    return normalized;
}

static NSString *MTCGeometryDemoTruncatedText(NSString *text, NSUInteger limit) {
    if (text.length <= limit) {
        return text;
    }
    if (limit < 12) {
        return [text substringToIndex:limit];
    }
    NSUInteger left = limit / 2;
    NSUInteger right = limit - left - 1;
    return [NSString stringWithFormat:@"%@…%@", [text substringToIndex:left], [text substringFromIndex:text.length - right]];
}

static MTCPath *MTCGeometryDemoPathFromCoordinates(NSArray<NSValue *> *values) {
    if (values.count == 0) {
        return [MTCPath path];
    }
    NSMutableData *coordinateData = [NSMutableData dataWithLength:sizeof(CLLocationCoordinate2D) * values.count];
    CLLocationCoordinate2D *coordinates = (CLLocationCoordinate2D *)coordinateData.mutableBytes;
    for (NSUInteger index = 0; index < values.count; ++index) {
        coordinates[index] = MTCGeometryDemoCoordinateFromValue(values[index]);
    }
    return [[MTCPath alloc] initWithCoordinates:coordinates count:values.count];
}

static NSArray<NSValue *> *MTCGeometryDemoCoordinatesFromPath(MTCPath *path) {
    if (!path || path.count == 0) {
        return @[];
    }
    NSMutableArray<NSValue *> *values = [NSMutableArray arrayWithCapacity:path.count];
    for (NSUInteger index = 0; index < path.count; ++index) {
        [values addObject:MTCGeometryDemoValueFromCoordinate([path coordinateAtIndex:index])];
    }
    return values;
}

static BOOL MTCGeometryDemoCoordinatesEqual(CLLocationCoordinate2D lhs,
                                            CLLocationCoordinate2D rhs,
                                            CLLocationDegrees tolerance) {
    return fabs(lhs.latitude - rhs.latitude) <= tolerance &&
           fabs(lhs.longitude - rhs.longitude) <= tolerance;
}

static BOOL MTCGeometryDemoContainsCoordinateNear(NSArray<NSValue *> *values,
                                                  CLLocationCoordinate2D coordinate,
                                                  CLLocationDistance toleranceMeters) {
    for (NSValue *value in values) {
        CLLocationCoordinate2D existing = MTCGeometryDemoCoordinateFromValue(value);
        if (MTCGeometryComputeDistanceBetween(existing, coordinate) <= toleranceMeters) {
            return YES;
        }
    }
    return NO;
}

static CLLocationCoordinate2D MTCGeometryDemoClosestCoordinateOnSegment(CLLocationCoordinate2D point,
                                                                        CLLocationCoordinate2D start,
                                                                        CLLocationCoordinate2D end,
                                                                        double *ratioOut) {
    double longitudeScale = cos((start.latitude + end.latitude) * 0.5 * M_PI / 180.0);
    double segmentX = (end.longitude - start.longitude) * longitudeScale;
    double segmentY = end.latitude - start.latitude;
    double pointX = (point.longitude - start.longitude) * longitudeScale;
    double pointY = point.latitude - start.latitude;
    double segmentLengthSquared = segmentX * segmentX + segmentY * segmentY;
    if (segmentLengthSquared <= DBL_EPSILON) {
        if (ratioOut) {
            *ratioOut = 0.0;
        }
        return start;
    }

    double ratio = (pointX * segmentX + pointY * segmentY) / segmentLengthSquared;
    if (ratioOut) {
        *ratioOut = ratio;
    }
    ratio = MIN(1.0, MAX(0.0, ratio));
    return CLLocationCoordinate2DMake(start.latitude + (end.latitude - start.latitude) * ratio,
                                      start.longitude + (end.longitude - start.longitude) * ratio);
}

static BOOL MTCGeometryDemoCanFormPolygonArea(NSArray<NSValue *> *values) {
    if (values.count < 3) {
        return NO;
    }
    MTCPath *path = MTCGeometryDemoPathFromCoordinates(values);
    return fabs(MTCGeometryComputeSignedArea(path)) >= MTCGeometryDemoMinimumPolygonAreaSquareMeters;
}

static double MTCGeometryDemoSegmentCross(CLLocationCoordinate2D a,
                                          CLLocationCoordinate2D b,
                                          CLLocationCoordinate2D c) {
    double abX = b.longitude - a.longitude;
    double abY = b.latitude - a.latitude;
    double acX = c.longitude - a.longitude;
    double acY = c.latitude - a.latitude;
    return abX * acY - abY * acX;
}

static BOOL MTCGeometryDemoPointIsOnSegment(CLLocationCoordinate2D point,
                                            CLLocationCoordinate2D start,
                                            CLLocationCoordinate2D end) {
    static double const kEpsilon = 1e-10;
    if (fabs(MTCGeometryDemoSegmentCross(start, end, point)) > kEpsilon) {
        return NO;
    }
    return point.longitude >= MIN(start.longitude, end.longitude) - kEpsilon &&
           point.longitude <= MAX(start.longitude, end.longitude) + kEpsilon &&
           point.latitude >= MIN(start.latitude, end.latitude) - kEpsilon &&
           point.latitude <= MAX(start.latitude, end.latitude) + kEpsilon;
}

static BOOL MTCGeometryDemoSegmentsIntersect(CLLocationCoordinate2D a,
                                             CLLocationCoordinate2D b,
                                             CLLocationCoordinate2D c,
                                             CLLocationCoordinate2D d) {
    double cross1 = MTCGeometryDemoSegmentCross(a, b, c);
    double cross2 = MTCGeometryDemoSegmentCross(a, b, d);
    double cross3 = MTCGeometryDemoSegmentCross(c, d, a);
    double cross4 = MTCGeometryDemoSegmentCross(c, d, b);

    if (((cross1 > 0.0 && cross2 < 0.0) || (cross1 < 0.0 && cross2 > 0.0)) &&
        ((cross3 > 0.0 && cross4 < 0.0) || (cross3 < 0.0 && cross4 > 0.0))) {
        return YES;
    }

    return MTCGeometryDemoPointIsOnSegment(c, a, b) ||
           MTCGeometryDemoPointIsOnSegment(d, a, b) ||
           MTCGeometryDemoPointIsOnSegment(a, c, d) ||
           MTCGeometryDemoPointIsOnSegment(b, c, d);
}

static BOOL MTCGeometryDemoPolygonHasSelfIntersection(NSArray<NSValue *> *values) {
    NSUInteger count = values.count;
    if (count < 4) {
        return NO;
    }

    for (NSUInteger firstIndex = 0; firstIndex < count; ++firstIndex) {
        NSUInteger firstNextIndex = (firstIndex + 1) % count;
        CLLocationCoordinate2D firstStart = MTCGeometryDemoCoordinateFromValue(values[firstIndex]);
        CLLocationCoordinate2D firstEnd = MTCGeometryDemoCoordinateFromValue(values[firstNextIndex]);

        for (NSUInteger secondIndex = firstIndex + 1; secondIndex < count; ++secondIndex) {
            NSUInteger secondNextIndex = (secondIndex + 1) % count;
            BOOL sharesEndpoint = firstIndex == secondIndex ||
                                  firstIndex == secondNextIndex ||
                                  firstNextIndex == secondIndex ||
                                  firstNextIndex == secondNextIndex;
            if (sharesEndpoint) {
                continue;
            }

            CLLocationCoordinate2D secondStart = MTCGeometryDemoCoordinateFromValue(values[secondIndex]);
            CLLocationCoordinate2D secondEnd = MTCGeometryDemoCoordinateFromValue(values[secondNextIndex]);
            if (MTCGeometryDemoSegmentsIntersect(firstStart, firstEnd, secondStart, secondEnd)) {
                return YES;
            }
        }
    }
    return NO;
}

static NSArray<NSValue *> *MTCGeometryDemoPathByOffsettingCoordinates(NSArray<NSValue *> *values,
                                                                      CLLocationDistance meters) {
    if (values.count == 0) {
        return @[];
    }
    if (values.count == 1) {
        CLLocationCoordinate2D coordinate = MTCGeometryDemoCoordinateFromValue(values.firstObject);
        CLLocationCoordinate2D offset = MTCGeometryComputeOffset(coordinate, meters, 0.0);
        return @[MTCGeometryDemoValueFromCoordinate(offset)];
    }

    NSMutableArray<NSValue *> *result = [NSMutableArray arrayWithCapacity:values.count];
    for (NSUInteger index = 0; index < values.count; ++index) {
        CLLocationCoordinate2D coordinate = MTCGeometryDemoCoordinateFromValue(values[index]);
        CLLocationDirection heading = 0.0;
        if (index == 0) {
            CLLocationCoordinate2D next = MTCGeometryDemoCoordinateFromValue(values[index + 1]);
            heading = MTCGeometryComputeHeading(coordinate, next);
        } else if (index == values.count - 1) {
            CLLocationCoordinate2D previous = MTCGeometryDemoCoordinateFromValue(values[index - 1]);
            heading = MTCGeometryComputeHeading(previous, coordinate);
        } else {
            CLLocationCoordinate2D previous = MTCGeometryDemoCoordinateFromValue(values[index - 1]);
            CLLocationCoordinate2D next = MTCGeometryDemoCoordinateFromValue(values[index + 1]);
            double heading1 = MTCGeometryComputeHeading(previous, coordinate) * M_PI / 180.0;
            double heading2 = MTCGeometryComputeHeading(coordinate, next) * M_PI / 180.0;
            double x = cos(heading1) + cos(heading2);
            double y = sin(heading1) + sin(heading2);
            heading = atan2(y, x) * 180.0 / M_PI;
        }
        CLLocationCoordinate2D offset = MTCGeometryComputeOffset(coordinate, meters, MTCGeometryDemoNormalizeHeading(heading + 90.0));
        [result addObject:MTCGeometryDemoValueFromCoordinate(offset)];
    }
    return result;
}

static UIImage *MTCGeometryDemoBadgeImage(NSString *text,
                                          UIColor *fillColor,
                                          UIColor *strokeColor,
                                          CGSize size,
                                          UIFont *font) {
    UIGraphicsImageRendererFormat *format = [UIGraphicsImageRendererFormat defaultFormat];
    format.opaque = NO;
    UIGraphicsImageRenderer *renderer = [[UIGraphicsImageRenderer alloc] initWithSize:size format:format];
    return [renderer imageWithActions:^(UIGraphicsImageRendererContext * _Nonnull context) {
        CGRect rect = CGRectMake(0.0, 0.0, size.width, size.height);
        UIBezierPath *path = [UIBezierPath bezierPathWithOvalInRect:CGRectInset(rect, 1.0, 1.0)];
        [fillColor setFill];
        [path fill];
        [strokeColor setStroke];
        path.lineWidth = 2.0;
        [path stroke];

        NSDictionary<NSAttributedStringKey, id> *attributes = @{
            NSFontAttributeName: font,
            NSForegroundColorAttributeName: UIColor.whiteColor,
        };
        CGSize textSize = [text sizeWithAttributes:attributes];
        CGRect textRect = CGRectMake((size.width - textSize.width) * 0.5,
                                     (size.height - textSize.height) * 0.5 - 0.5,
                                     textSize.width,
                                     textSize.height);
        [text drawInRect:textRect withAttributes:attributes];
    }];
}

static UIView *MTCGeometryDemoBubbleView(NSArray<NSString *> *lines, UIColor *accentColor) {
    (void)accentColor;
    CGFloat maxWidth = 280.0;
    UIFont *titleFont = [UIFont systemFontOfSize:12.0 weight:UIFontWeightSemibold];
    UIFont *bodyFont = [UIFont systemFontOfSize:12.0 weight:UIFontWeightRegular];
    NSMutableArray<UILabel *> *labels = [NSMutableArray arrayWithCapacity:lines.count];
    CGFloat width = 0.0;
    CGFloat height = 0.0;
    for (NSUInteger index = 0; index < lines.count; ++index) {
        UILabel *label = [[UILabel alloc] initWithFrame:CGRectZero];
        label.numberOfLines = 0;
        label.textAlignment = NSTextAlignmentCenter;
        label.textColor = index == 0 ? UIColor.whiteColor : [UIColor colorWithWhite:1.0 alpha:0.92];
        label.font = index == 0 ? titleFont : bodyFont;
        label.text = lines[index];
        CGSize fitting = [label sizeThatFits:CGSizeMake(maxWidth - 20.0, CGFLOAT_MAX)];
        width = MAX(width, fitting.width);
        height += fitting.height;
        [labels addObject:label];
    }
    width = MIN(maxWidth, MAX(width + 20.0, 92.0));
    height = MAX(height + 16.0, 36.0);

    UIView *container = [[UIView alloc] initWithFrame:CGRectMake(0.0, 0.0, ceil(width), ceil(height))];
    container.backgroundColor = [UIColor colorWithRed:0.259 green:0.259 blue:0.259 alpha:1.0];
    container.layer.cornerRadius = 8.0;
    container.layer.borderColor = [UIColor colorWithWhite:0.88 alpha:1.0].CGColor;
    container.layer.borderWidth = 1.0;
    container.layer.shadowColor = UIColor.blackColor.CGColor;
    container.layer.shadowOpacity = 0.14;
    container.layer.shadowRadius = 10.0;
    container.layer.shadowOffset = CGSizeMake(0.0, 4.0);

    CGFloat y = 8.0;
    for (UILabel *label in labels) {
        CGSize fitting = [label sizeThatFits:CGSizeMake(container.bounds.size.width - 20.0, CGFLOAT_MAX)];
        label.frame = CGRectMake(10.0, y, container.bounds.size.width - 20.0, fitting.height);
        y += fitting.height;
        [container addSubview:label];
    }
    return container;
}

static MTCMarker *MTCGeometryDemoBadgeMarker(CLLocationCoordinate2D coordinate,
                                             NSString *text,
                                             UIColor *fillColor,
                                             UIColor *strokeColor,
                                             CGFloat side,
                                             NSInteger zIndex) {
    MTCMarker *marker = [[MTCMarker alloc] initWithCoordinate:coordinate];
    marker.clickable = NO;
    marker.draggable = NO;
    marker.visible = YES;
    marker.zIndex = zIndex;

    MTCMarkerStyle *style = [[MTCMarkerStyle alloc] init];
    style.icon = [[MTCMarkerIcon alloc] init];
    style.title = [[MTCMarkerTitle alloc] init];
    style.icon.type = MTCMarkerIconTypeCustom;
    style.icon.customImage = MTCGeometryDemoBadgeImage(text, fillColor, strokeColor, CGSizeMake(side, side), [UIFont systemFontOfSize:MAX(11.0, side * 0.38) weight:UIFontWeightBold]);
    style.icon.size = CGSizeMake(side, side);
    style.icon.anchor = CGPointMake(0.5, 0.5);
    style.icon.offset = CGPointZero;
    style.icon.opacity = 1.0;
    style.title.text = @"";
    marker.style = style;
    return marker;
}

static MTCPolyline *MTCGeometryDemoPolylineWithDashArray(NSArray<NSValue *> *values,
                                                         UIColor *strokeColor,
                                                         CGFloat width,
                                                         NSInteger zIndex,
                                                         NSArray<NSNumber *> *dashArray) {
    MTCPath *path = MTCGeometryDemoPathFromCoordinates(values);
    NSMutableData *coordinateData = [NSMutableData dataWithLength:sizeof(CLLocationCoordinate2D) * path.count];
    CLLocationCoordinate2D *buffer = (CLLocationCoordinate2D *)coordinateData.mutableBytes;
    for (NSUInteger index = 0; index < path.count; ++index) {
        buffer[index] = [path coordinateAtIndex:index];
    }
    MTCPolyline *polyline = [[MTCPolyline alloc] initWithCoordinates:buffer count:path.count];
    polyline.clickable = NO;
    polyline.draggable = NO;
    polyline.visible = YES;
    polyline.zIndex = zIndex;
    MTCPolylineStyle *style = [[MTCPolylineStyle alloc] init];
    style.strokeColor = strokeColor;
    style.strokeWeight = width;
    style.strokeOpacity = 1.0;
    style.strokeDashArray = dashArray ?: @[];
    polyline.style = style;
    return polyline;
}

static MTCPolyline *MTCGeometryDemoPolyline(NSArray<NSValue *> *values,
                                            UIColor *strokeColor,
                                            CGFloat width,
                                            NSInteger zIndex) {
    return MTCGeometryDemoPolylineWithDashArray(values, strokeColor, width, zIndex, nil);
}

static MTCPolygon *MTCGeometryDemoPolygon(NSArray<NSValue *> *values,
                                          UIColor *fillColor,
                                          CGFloat fillOpacity,
                                          UIColor *strokeColor,
                                          CGFloat width,
                                          NSInteger zIndex) {
    MTCPath *path = MTCGeometryDemoPathFromCoordinates(values);
    NSMutableData *coordinateData = [NSMutableData dataWithLength:sizeof(CLLocationCoordinate2D) * path.count];
    CLLocationCoordinate2D *buffer = (CLLocationCoordinate2D *)coordinateData.mutableBytes;
    for (NSUInteger index = 0; index < path.count; ++index) {
        buffer[index] = [path coordinateAtIndex:index];
    }
    MTCPolygon *polygon = [[MTCPolygon alloc] initWithCoordinates:buffer count:path.count];
    polygon.clickable = NO;
    polygon.draggable = NO;
    polygon.visible = YES;
    polygon.zIndex = zIndex;
    MTCPolygonStyle *style = [[MTCPolygonStyle alloc] init];
    style.fillColor = fillColor;
    style.fillOpacity = fillOpacity;
    style.strokeColor = strokeColor;
    style.strokeWeight = width;
    style.strokeOpacity = 1.0;
    style.strokeDashArray = @[];
    style.fillAntialias = YES;
    polygon.style = style;
    return polygon;
}

static MTCCircle *MTCGeometryDemoCircle(CLLocationCoordinate2D center,
                                        CLLocationDistance radius,
                                        UIColor *fillColor,
                                        UIColor *strokeColor,
                                        NSInteger zIndex) {
    MTCCircle *circle = [[MTCCircle alloc] initWithCenter:center radius:radius];
    circle.renderMode = MTCCircleRenderModeGeographic;
    circle.clickable = NO;
    circle.draggable = NO;
    circle.visible = YES;
    circle.zIndex = zIndex;
    MTCCircleStyle *style = [[MTCCircleStyle alloc] init];
    style.fillColor = fillColor;
    style.fillOpacity = 0.18;
    style.strokeColor = strokeColor;
    style.strokeWeight = 2.0;
    style.strokeOpacity = 1.0;
    circle.style = style;
    return circle;
}

static MTCCoordinateBounds MTCGeometryDemoTightBoundsForCoordinates(NSArray<NSValue *> *values) {
    if (values.count == 0) {
        return MTCCoordinateBoundsMake(kCLLocationCoordinate2DInvalid, kCLLocationCoordinate2DInvalid);
    }

    CLLocationDegrees minLatitude = DBL_MAX;
    CLLocationDegrees maxLatitude = -DBL_MAX;
    CLLocationDegrees minLongitude = DBL_MAX;
    CLLocationDegrees maxLongitude = -DBL_MAX;
    for (NSValue *value in values) {
        CLLocationCoordinate2D coordinate = MTCGeometryDemoCoordinateFromValue(value);
        minLatitude = MIN(minLatitude, coordinate.latitude);
        maxLatitude = MAX(maxLatitude, coordinate.latitude);
        minLongitude = MIN(minLongitude, coordinate.longitude);
        maxLongitude = MAX(maxLongitude, coordinate.longitude);
    }

    if (minLatitude == DBL_MAX || minLongitude == DBL_MAX) {
        return MTCCoordinateBoundsMake(kCLLocationCoordinate2DInvalid, kCLLocationCoordinate2DInvalid);
    }

    CLLocationCoordinate2D southwest = CLLocationCoordinate2DMake(minLatitude, minLongitude);
    CLLocationCoordinate2D northeast = CLLocationCoordinate2DMake(maxLatitude, maxLongitude);
    return MTCCoordinateBoundsMake(southwest, northeast);
}

static MTCCoordinateBounds MTCGeometryDemoBoundsForCoordinates(NSArray<NSValue *> *values) {
    MTCCoordinateBounds bounds = MTCGeometryDemoTightBoundsForCoordinates(values);
    if (MTCMapRectIsNull(MTCMapRectForCoordinateBounds(bounds))) {
        return bounds;
    }

    CLLocationDegrees minLatitude = bounds.southwest.latitude;
    CLLocationDegrees minLongitude = bounds.southwest.longitude;
    CLLocationDegrees maxLatitude = bounds.northeast.latitude;
    CLLocationDegrees maxLongitude = bounds.northeast.longitude;
    CLLocationDegrees latitudePadding = MAX(0.004, (maxLatitude - minLatitude) * 0.35);
    CLLocationDegrees longitudePadding = MAX(0.004, (maxLongitude - minLongitude) * 0.35);

    CLLocationCoordinate2D southwest = CLLocationCoordinate2DMake(MAX(-85.0, minLatitude - latitudePadding),
                                                                  MAX(-180.0, minLongitude - longitudePadding));
    CLLocationCoordinate2D northeast = CLLocationCoordinate2DMake(MIN(85.0, maxLatitude + latitudePadding),
                                                                  MIN(180.0, maxLongitude + longitudePadding));
    return MTCCoordinateBoundsMake(southwest, northeast);
}

static MTCCoordinateBounds MTCGeometryDemoBoundsByEnsuringMinimumSpan(MTCCoordinateBounds bounds,
                                                                      CLLocationDegrees minimumSpan) {
    if (MTCMapRectIsNull(MTCMapRectForCoordinateBounds(bounds))) {
        return bounds;
    }

    CLLocationDegrees minLatitude = bounds.southwest.latitude;
    CLLocationDegrees minLongitude = bounds.southwest.longitude;
    CLLocationDegrees maxLatitude = bounds.northeast.latitude;
    CLLocationDegrees maxLongitude = bounds.northeast.longitude;
    if (maxLatitude - minLatitude < minimumSpan) {
        CLLocationDegrees centerLatitude = (minLatitude + maxLatitude) * 0.5;
        minLatitude = MAX(-85.0, centerLatitude - minimumSpan * 0.5);
        maxLatitude = MIN(85.0, centerLatitude + minimumSpan * 0.5);
    }
    if (maxLongitude - minLongitude < minimumSpan) {
        CLLocationDegrees centerLongitude = (minLongitude + maxLongitude) * 0.5;
        minLongitude = MAX(-180.0, centerLongitude - minimumSpan * 0.5);
        maxLongitude = MIN(180.0, centerLongitude + minimumSpan * 0.5);
    }
    return MTCCoordinateBoundsMake(CLLocationCoordinate2DMake(minLatitude, minLongitude),
                                   CLLocationCoordinate2DMake(maxLatitude, maxLongitude));
}

static CLLocationCoordinate2D MTCGeometryDemoCenterForCoordinates(NSArray<NSValue *> *values) {
    if (values.count == 0) {
        return kCLLocationCoordinate2DInvalid;
    }
    double latitude = 0.0;
    double longitude = 0.0;
    for (NSValue *value in values) {
        CLLocationCoordinate2D coordinate = MTCGeometryDemoCoordinateFromValue(value);
        latitude += coordinate.latitude;
        longitude += coordinate.longitude;
    }
    return CLLocationCoordinate2DMake(latitude / values.count, longitude / values.count);
}

@interface MTCGeometryCalculatorViewController () <MTCMapViewDelegate>

@property (nonatomic, strong) MTCMapView *mapView;
@property (nonatomic, strong) UIView *statusChromeView;
@property (nonatomic, strong) UILabel *statusLabel;
@property (nonatomic, strong) UIView *bottomDockView;
@property (nonatomic, strong) UILabel *hintPillLabel;
@property (nonatomic, strong) UIScrollView *chipScrollView;
@property (nonatomic, strong) UIStackView *chipStackView;
@property (nonatomic, strong) UIStackView *tabStackView;
@property (nonatomic, strong) UILabel *panelTitleLabel;
@property (nonatomic, strong) UILabel *panelModeLabel;
@property (nonatomic, strong) UILabel *panelApiLabel;
@property (nonatomic, strong) UILabel *panelNoteLabel;
@property (nonatomic, strong) UILabel *panelResultLabel;
@property (nonatomic, strong) UILabel *panelDetailLabel;
@property (nonatomic, strong) UILabel *panelEncodedLabel;
@property (nonatomic, strong) UILabel *panelDecodedLabel;
@property (nonatomic, strong) UISlider *offsetDistanceSlider;
@property (nonatomic, strong) UISlider *offsetHeadingSlider;
@property (nonatomic, strong) UISlider *reverseDistanceSlider;
@property (nonatomic, strong) UISlider *reverseHeadingSlider;
@property (nonatomic, strong) UISlider *interpolateSlider;
@property (nonatomic, strong) UISlider *simplifySlider;
@property (nonatomic, strong) UISwitch *areaTestPointSwitch;
@property (nonatomic, strong) UISwitch *pathTestPointSwitch;
@property (nonatomic, strong) UISwitch *closedSegmentTestPointSwitch;
@property (nonatomic, strong) UISwitch *closedSwitch;
@property (nonatomic, strong) UIButton *signedAreaClockwiseButton;
@property (nonatomic, strong) UIButton *signedAreaCounterClockwiseButton;
@property (nonatomic, strong) UIButton *simplifyExampleButton;
@property (nonatomic, strong) UIButton *reversePoleButton;
@property (nonatomic, strong) UIButton *closedCommitButton;
@property (nonatomic, strong) UIButton *closedExampleButton;
@property (nonatomic, strong) NSArray<UIButton *> *sectionButtons;
@property (nonatomic, strong) NSArray<UIButton *> *chipButtons;
@property (nonatomic, assign) MTCGeometryDemoTopSection selectedSection;
@property (nonatomic, assign) NSInteger selectedChipIndex;
@property (nonatomic, strong) NSMutableArray<NSValue *> *geometryPoints;
@property (nonatomic, strong) NSMutableArray<NSValue *> *pathRawPoints;
@property (nonatomic, strong) NSValue *testPointValue;
@property (nonatomic, assign) BOOL hasTestPointValue;
@property (nonatomic, assign) BOOL pendingTestPointOnce;
@property (nonatomic, assign) BOOL closedPolygonCommitted;
@property (nonatomic, assign) BOOL shouldFocusAfterRedraw;
@property (nonatomic, copy) NSString *pendingErrorHint;
@property (nonatomic, weak) ExampleSettingsSheetView *settingsSheet;
@property (nonatomic, strong) MTCMarker *offsetStartMarker;
@property (nonatomic, strong) MTCMarker *offsetEndMarker;
@property (nonatomic, strong) MTCPolyline *offsetLine;
@property (nonatomic, strong) MTCFloatInfoWindow *offsetInfoWindow;
@property (nonatomic, strong) MTCMarker *reverseStartMarker;
@property (nonatomic, strong) MTCMarker *reverseEndMarker;
@property (nonatomic, strong) MTCPolyline *reverseLine;
@property (nonatomic, strong) MTCFloatInfoWindow *reverseInfoWindow;
@property (nonatomic, strong) MTCMarker *interpolateStartMarker;
@property (nonatomic, strong) MTCMarker *interpolateEndMarker;
@property (nonatomic, strong) MTCMarker *interpolatePointMarker;
@property (nonatomic, strong) MTCPolyline *interpolateLine;
@property (nonatomic, strong) MTCFloatInfoWindow *interpolateInfoWindow;

@end

@implementation MTCGeometryCalculatorViewController

#pragma mark - Life Cycle

- (void)viewDidLoad {
    [super viewDidLoad];
    self.edgesForExtendedLayout = UIRectEdgeNone;
    self.view.backgroundColor = UIColor.whiteColor;
    self.selectedSection = MTCGeometryDemoTopSectionSphere;
    self.selectedChipIndex = 0;
    self.geometryPoints = [NSMutableArray array];
    self.pathRawPoints = [NSMutableArray array];
    self.shouldFocusAfterRedraw = NO;

    [self configureNavigationItems:NO];
    [self configureMapView];
    [self configureTopChrome];
    [self configureBottomDock];
    [self configurePanel];
    [self configureConstraints];
    [self applyLocalizedTexts];
    [self selectTopSection:MTCGeometryDemoTopSectionSphere resetGeometry:YES];
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
}

- (void)demoLanguageDidChange {
    [self applyLocalizedTexts];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    self.mapView.mapLanguage = MTCMapLanguageChinese;
}

#pragma mark - Setup

- (void)configureMapView {
    self.mapView = [[MTCMapView alloc] initWithFrame:CGRectZero];
    self.mapView.delegate = self;
    self.mapView.mapLanguage = MTCMapLanguageChinese;
    self.mapView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    self.mapView.uiSettings.zoomLevelVisible = NO;
    [self.view addSubview:self.mapView];

    [self.mapView setCenterCoordinate:MTCGeometryDemoCoordinateMake(MTCGeometryDemoInitialLatitude, MTCGeometryDemoInitialLongitude)
                             zoomLevel:MTCGeometryDemoInitialZoomLevel];
}

- (void)configureTopChrome {
    self.statusChromeView = [[UIView alloc] initWithFrame:CGRectZero];
    self.statusChromeView.backgroundColor = UIColor.systemBackgroundColor;
    self.statusChromeView.layer.cornerRadius = 14.0;
    self.statusChromeView.layer.shadowColor = [UIColor colorWithWhite:0.0 alpha:0.12].CGColor;
    self.statusChromeView.layer.shadowOpacity = 1.0;
    self.statusChromeView.layer.shadowRadius = 8.0;
    self.statusChromeView.layer.shadowOffset = CGSizeMake(0.0, 3.0);
    [self.view addSubview:self.statusChromeView];

    self.statusLabel = [[UILabel alloc] initWithFrame:CGRectZero];
    self.statusLabel.font = [UIFont systemFontOfSize:13.0 weight:UIFontWeightSemibold];
    self.statusLabel.textColor = UIColor.labelColor;
    self.statusLabel.numberOfLines = 2;
    [self.statusChromeView addSubview:self.statusLabel];
}

- (void)configureBottomDock {
    self.bottomDockView = [[UIView alloc] initWithFrame:CGRectZero];
    self.bottomDockView.backgroundColor = UIColor.systemBackgroundColor;
    self.bottomDockView.layer.shadowColor = [UIColor colorWithWhite:0.0 alpha:0.10].CGColor;
    self.bottomDockView.layer.shadowOpacity = 1.0;
    self.bottomDockView.layer.shadowRadius = 10.0;
    self.bottomDockView.layer.shadowOffset = CGSizeMake(0.0, -2.0);
    [self.view addSubview:self.bottomDockView];

    self.hintPillLabel = [[UILabel alloc] initWithFrame:CGRectZero];
    self.hintPillLabel.font = [UIFont systemFontOfSize:12.0 weight:UIFontWeightSemibold];
    self.hintPillLabel.textAlignment = NSTextAlignmentCenter;
    self.hintPillLabel.textColor = UIColor.labelColor;
    self.hintPillLabel.backgroundColor = UIColor.systemBackgroundColor;
    self.hintPillLabel.layer.cornerRadius = 16.0;
    self.hintPillLabel.layer.masksToBounds = NO;
    self.hintPillLabel.layer.shadowColor = [UIColor colorWithWhite:0.0 alpha:0.18].CGColor;
    self.hintPillLabel.layer.shadowOpacity = 1.0;
    self.hintPillLabel.layer.shadowRadius = 6.0;
    self.hintPillLabel.layer.shadowOffset = CGSizeMake(0.0, 2.0);
    [self.bottomDockView addSubview:self.hintPillLabel];

    self.chipScrollView = [[UIScrollView alloc] initWithFrame:CGRectZero];
    self.chipScrollView.showsHorizontalScrollIndicator = NO;
    self.chipScrollView.alwaysBounceHorizontal = YES;
    [self.bottomDockView addSubview:self.chipScrollView];

    self.chipStackView = [[UIStackView alloc] initWithFrame:CGRectZero];
    self.chipStackView.axis = UILayoutConstraintAxisHorizontal;
    self.chipStackView.alignment = UIStackViewAlignmentCenter;
    self.chipStackView.spacing = 8.0;
    [self.chipScrollView addSubview:self.chipStackView];

    self.tabStackView = [[UIStackView alloc] initWithFrame:CGRectZero];
    self.tabStackView.axis = UILayoutConstraintAxisHorizontal;
    self.tabStackView.alignment = UIStackViewAlignmentFill;
    self.tabStackView.distribution = UIStackViewDistributionFillEqually;
    self.tabStackView.spacing = 0.0;
    [self.bottomDockView addSubview:self.tabStackView];

    self.sectionButtons = @[
        [self makeTabButtonWithTitle:@"球面几何" tag:MTCGeometryDemoTopSectionSphere],
        [self makeTabButtonWithTitle:@"路径多边形" tag:MTCGeometryDemoTopSectionPath],
        [self makeTabButtonWithTitle:@"编码" tag:MTCGeometryDemoTopSectionEncoding],
    ];
    for (UIButton *button in self.sectionButtons) {
        [self.tabStackView addArrangedSubview:button];
    }
}

- (void)configurePanel {
    self.panelTitleLabel = [[UILabel alloc] initWithFrame:CGRectZero];
    self.panelModeLabel = [[UILabel alloc] initWithFrame:CGRectZero];
    self.panelApiLabel = [[UILabel alloc] initWithFrame:CGRectZero];
    self.panelNoteLabel = [[UILabel alloc] initWithFrame:CGRectZero];
    self.panelResultLabel = [[UILabel alloc] initWithFrame:CGRectZero];
    self.panelDetailLabel = [[UILabel alloc] initWithFrame:CGRectZero];
    self.panelEncodedLabel = [[UILabel alloc] initWithFrame:CGRectZero];
    self.panelDecodedLabel = [[UILabel alloc] initWithFrame:CGRectZero];

    self.offsetDistanceSlider = [self makeSlider];
    [self.offsetDistanceSlider addTarget:self action:@selector(handleOffsetDistanceSliderChanged:) forControlEvents:UIControlEventValueChanged];
    self.offsetHeadingSlider = [self makeSlider];
    [self.offsetHeadingSlider addTarget:self action:@selector(handleOffsetHeadingSliderChanged:) forControlEvents:UIControlEventValueChanged];
    self.reverseDistanceSlider = [self makeSlider];
    [self.reverseDistanceSlider addTarget:self action:@selector(handleReverseDistanceSliderChanged:) forControlEvents:UIControlEventValueChanged];
    self.reverseHeadingSlider = [self makeSlider];
    [self.reverseHeadingSlider addTarget:self action:@selector(handleReverseHeadingSliderChanged:) forControlEvents:UIControlEventValueChanged];
    self.interpolateSlider = [self makeSlider];
    [self.interpolateSlider addTarget:self action:@selector(handleInterpolateSliderChanged:) forControlEvents:UIControlEventValueChanged];
    self.simplifySlider = [self makeSlider];
    [self.simplifySlider addTarget:self action:@selector(handleSimplifySliderChanged:) forControlEvents:UIControlEventValueChanged];

    self.areaTestPointSwitch = [self makeSwitch];
    [self.areaTestPointSwitch addTarget:self action:@selector(handleAreaTestPointSwitchChanged:) forControlEvents:UIControlEventValueChanged];
    self.pathTestPointSwitch = [self makeSwitch];
    [self.pathTestPointSwitch addTarget:self action:@selector(handlePathTestPointSwitchChanged:) forControlEvents:UIControlEventValueChanged];
    self.closedSegmentTestPointSwitch = [self makeSwitch];
    [self.closedSegmentTestPointSwitch addTarget:self action:@selector(handleClosedSegmentTestPointSwitchChanged:) forControlEvents:UIControlEventValueChanged];
    self.closedSwitch = [self makeSwitch];
    [self.closedSwitch addTarget:self action:@selector(handleClosedSwitchChanged:) forControlEvents:UIControlEventValueChanged];

    self.signedAreaCounterClockwiseButton = [self makeActionButtonWithTitle:@"示例：逆时针（正）" action:@selector(handleSignedAreaCounterClockwiseTapped)];
    self.signedAreaClockwiseButton = [self makeActionButtonWithTitle:@"示例：顺时针（负）" action:@selector(handleSignedAreaClockwiseTapped)];
    self.simplifyExampleButton = [self makeActionButtonWithTitle:@"填充清晰抽稀示例" action:@selector(handleSimplifyExampleTapped)];
    self.reversePoleButton = [self makeActionButtonWithTitle:@"试极点无解" action:@selector(handleReversePoleTapped)];
    self.closedCommitButton = [self makeActionButtonWithTitle:@"闭合（追加首点）" action:@selector(handleClosedCommitTapped)];
    self.closedExampleButton = [self makeActionButtonWithTitle:@"填充已闭合示例" action:@selector(handleClosedExampleTapped)];
    [self seedDefaultPanelValues];
}

- (void)configureConstraints {
    self.statusChromeView.translatesAutoresizingMaskIntoConstraints = NO;
    self.statusLabel.translatesAutoresizingMaskIntoConstraints = NO;
    self.bottomDockView.translatesAutoresizingMaskIntoConstraints = NO;
    self.hintPillLabel.translatesAutoresizingMaskIntoConstraints = NO;
    self.chipScrollView.translatesAutoresizingMaskIntoConstraints = NO;
    self.chipStackView.translatesAutoresizingMaskIntoConstraints = NO;
    self.tabStackView.translatesAutoresizingMaskIntoConstraints = NO;
    self.mapView.translatesAutoresizingMaskIntoConstraints = NO;

    [NSLayoutConstraint activateConstraints:@[
        [self.mapView.topAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.topAnchor],
        [self.mapView.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor],
        [self.mapView.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor],
        [self.mapView.bottomAnchor constraintEqualToAnchor:self.bottomDockView.topAnchor],

        [self.statusChromeView.topAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.topAnchor constant:12.0],
        [self.statusChromeView.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor constant:12.0],
        [self.statusChromeView.trailingAnchor constraintLessThanOrEqualToAnchor:self.view.trailingAnchor constant:-12.0],
        [self.statusChromeView.heightAnchor constraintGreaterThanOrEqualToConstant:40.0],

        [self.statusLabel.topAnchor constraintEqualToAnchor:self.statusChromeView.topAnchor constant:8.0],
        [self.statusLabel.leadingAnchor constraintEqualToAnchor:self.statusChromeView.leadingAnchor constant:12.0],
        [self.statusLabel.trailingAnchor constraintEqualToAnchor:self.statusChromeView.trailingAnchor constant:-12.0],
        [self.statusLabel.bottomAnchor constraintEqualToAnchor:self.statusChromeView.bottomAnchor constant:-8.0],

        [self.bottomDockView.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor],
        [self.bottomDockView.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor],
        [self.bottomDockView.bottomAnchor constraintEqualToAnchor:self.view.bottomAnchor],
        [self.bottomDockView.heightAnchor constraintEqualToConstant:MTCGeometryDemoBottomDockHeight],

        [self.hintPillLabel.topAnchor constraintEqualToAnchor:self.bottomDockView.topAnchor constant:12.0],
        [self.hintPillLabel.centerXAnchor constraintEqualToAnchor:self.bottomDockView.centerXAnchor],
        [self.hintPillLabel.widthAnchor constraintLessThanOrEqualToAnchor:self.bottomDockView.widthAnchor multiplier:0.92],
        [self.hintPillLabel.heightAnchor constraintEqualToConstant:32.0],

        [self.chipScrollView.topAnchor constraintEqualToAnchor:self.hintPillLabel.bottomAnchor constant:8.0],
        [self.chipScrollView.leadingAnchor constraintEqualToAnchor:self.bottomDockView.leadingAnchor constant:12.0],
        [self.chipScrollView.trailingAnchor constraintEqualToAnchor:self.bottomDockView.trailingAnchor constant:-12.0],
        [self.chipScrollView.heightAnchor constraintEqualToConstant:MTCGeometryDemoChipHeight],

        [self.chipStackView.topAnchor constraintEqualToAnchor:self.chipScrollView.contentLayoutGuide.topAnchor],
        [self.chipStackView.leadingAnchor constraintEqualToAnchor:self.chipScrollView.contentLayoutGuide.leadingAnchor],
        [self.chipStackView.trailingAnchor constraintEqualToAnchor:self.chipScrollView.contentLayoutGuide.trailingAnchor],
        [self.chipStackView.bottomAnchor constraintEqualToAnchor:self.chipScrollView.contentLayoutGuide.bottomAnchor],
        [self.chipStackView.heightAnchor constraintEqualToAnchor:self.chipScrollView.frameLayoutGuide.heightAnchor],

        [self.tabStackView.leadingAnchor constraintEqualToAnchor:self.bottomDockView.leadingAnchor],
        [self.tabStackView.trailingAnchor constraintEqualToAnchor:self.bottomDockView.trailingAnchor],
        [self.tabStackView.bottomAnchor constraintEqualToAnchor:self.bottomDockView.safeAreaLayoutGuide.bottomAnchor],
        [self.tabStackView.heightAnchor constraintEqualToConstant:MTCGeometryDemoTabHeight],
    ]];
}

#pragma mark - Actions

- (void)handleClearTapped {
    [self clearGeometryState];
    [self redrawCurrentModeAnimated:NO];
}

- (void)handleOffsetDistanceSliderChanged:(UISlider *)sender {
    (void)sender;
    [self handleOffsetParameterChanged];
}

- (void)handleOffsetHeadingSliderChanged:(UISlider *)sender {
    (void)sender;
    [self handleOffsetParameterChanged];
}

- (void)handleOffsetParameterChanged {
    if ([self updateOffsetModeOverlaysInPlace]) {
        return;
    }
    [self redrawCurrentModeAnimated:NO];
}

- (void)handleReverseDistanceSliderChanged:(UISlider *)sender {
    (void)sender;
    [self handleReverseParameterChanged];
}

- (void)handleReverseHeadingSliderChanged:(UISlider *)sender {
    (void)sender;
    [self handleReverseParameterChanged];
}

- (void)handleReverseParameterChanged {
    if ([self updateReverseOriginModeOverlaysInPlace]) {
        return;
    }
    [self redrawCurrentModeAnimated:NO];
}

- (void)handleInterpolateSliderChanged:(UISlider *)sender {
    (void)sender;
    [self handleInterpolateParameterChanged];
}

- (void)handleInterpolateParameterChanged {
    if ([self updateInterpolateModeOverlaysInPlace]) {
        return;
    }
    [self redrawCurrentModeAnimated:NO];
}

- (void)handleSimplifySliderChanged:(UISlider *)sender {
    (void)sender;
    [self redrawCurrentModeAnimated:NO];
}

- (void)handleAreaTestPointSwitchChanged:(UISwitch *)sender {
    self.pendingTestPointOnce = sender.isOn;
}

- (void)handlePathTestPointSwitchChanged:(UISwitch *)sender {
    self.pendingTestPointOnce = sender.isOn;
}

- (void)handleClosedSegmentTestPointSwitchChanged:(UISwitch *)sender {
    self.pendingTestPointOnce = sender.isOn;
}

- (void)handleClosedSwitchChanged:(UISwitch *)sender {
    (void)sender;
    [self redrawCurrentModeAnimated:NO];
}

- (void)handleSignedAreaCounterClockwiseTapped {
    [self fillSignedAreaExampleCounterClockwise:YES];
    [self redrawCurrentModeAnimated:YES];
}

- (void)handleSignedAreaClockwiseTapped {
    [self fillSignedAreaExampleCounterClockwise:NO];
    [self redrawCurrentModeAnimated:YES];
}

- (void)handleSimplifyExampleTapped {
    [self fillSimplifyExample];
    [self redrawCurrentModeAnimated:YES];
}

- (void)handleReversePoleTapped {
    [self fillReverseOriginPoleExample];
    [self redrawCurrentModeAnimated:YES];
}

- (void)handleClosedCommitTapped {
    [self appendFirstPointToClosePathIfPossible];
    [self redrawCurrentModeAnimated:NO];
}

- (void)handleClosedExampleTapped {
    [self fillClosedPolygonExample];
    [self redrawCurrentModeAnimated:YES];
}

- (void)handleExampleSettingsAction {
    if ([self isSettingsSheetVisible:ExampleSettingsSheetView.class]) {
        return;
    }
    [self showSettingsSheet];
}

- (void)showSettingsSheet {
    ExampleSettingsSheetView *sheet = [[ExampleSettingsSheetView alloc] initWithTitle:@"配置面板"
                                                                             sections:[self settingsSections]];
    self.settingsSheet = sheet;
    [sheet showInView:self.view animated:YES];
}

- (NSArray<ExampleSettingsSection *> *)settingsSections {
    __weak typeof(self) weakSelf = self;
    BOOL (^isSphereChip)(MTCGeometryDemoSphereChip) = ^BOOL(MTCGeometryDemoSphereChip chip) {
        return weakSelf.selectedSection == MTCGeometryDemoTopSectionSphere && weakSelf.selectedChipIndex == chip;
    };
    BOOL (^isPathChip)(MTCGeometryDemoPathChip) = ^BOOL(MTCGeometryDemoPathChip chip) {
        return weakSelf.selectedSection == MTCGeometryDemoTopSectionPath && weakSelf.selectedChipIndex == chip;
    };
    NSString *(^nonEmptyText)(UILabel *) = ^NSString *(UILabel *label) {
        return label.text.length > 0 ? label.text : @"暂无";
    };

    return @[
        [ExampleSettingsSection sectionWithTitle:@"当前能力" items:@[
            [ExampleSettingsItem dynamicInfoItemWithGetter:^NSString *{
                return nonEmptyText(weakSelf.panelModeLabel);
            }],
            [ExampleSettingsItem dynamicInfoItemWithGetter:^NSString *{
                return nonEmptyText(weakSelf.panelApiLabel);
            }],
            [ExampleSettingsItem dynamicInfoItemWithGetter:^NSString *{
                return nonEmptyText(weakSelf.panelNoteLabel);
            }],
        ]],
        [ExampleSettingsSection sectionWithTitle:@"示例结果" items:@[
            [ExampleSettingsItem dynamicInfoItemWithGetter:^NSString *{
                return nonEmptyText(weakSelf.panelResultLabel);
            }],
            [ExampleSettingsItem dynamicInfoItemWithGetter:^NSString *{
                return nonEmptyText(weakSelf.panelDetailLabel);
            }],
            [[ExampleSettingsItem dynamicInfoItemWithGetter:^NSString *{
                return nonEmptyText(weakSelf.panelEncodedLabel);
            }] visibleWhen:^BOOL{
                return weakSelf.selectedSection == MTCGeometryDemoTopSectionEncoding;
            }],
            [[ExampleSettingsItem dynamicInfoItemWithGetter:^NSString *{
                return nonEmptyText(weakSelf.panelDecodedLabel);
            }] visibleWhen:^BOOL{
                return weakSelf.selectedSection == MTCGeometryDemoTopSectionEncoding;
            }],
        ]],
        [ExampleSettingsSection sectionWithTitle:@"参数" items:@[
            [[ExampleSettingsItem sliderItemWithTitle:@"偏移距离"
                                              minimum:50.0
                                              maximum:2000.0
                                                 step:10.0
                                               getter:^double {
                return weakSelf.offsetDistanceSlider.value;
            } setter:^(double value) {
                weakSelf.offsetDistanceSlider.value = value;
                [weakSelf handleOffsetParameterChanged];
            } formatter:^NSString *(double value) {
                return [NSString stringWithFormat:@"%.0f m", value];
            }] visibleWhen:^BOOL{
                return isSphereChip(MTCGeometryDemoSphereChipOffset);
            }],
            [[ExampleSettingsItem sliderItemWithTitle:@"偏移方位"
                                              minimum:0.0
                                              maximum:360.0
                                                 step:1.0
                                               getter:^double {
                return weakSelf.offsetHeadingSlider.value;
            } setter:^(double value) {
                weakSelf.offsetHeadingSlider.value = value;
                [weakSelf handleOffsetParameterChanged];
            } formatter:^NSString *(double value) {
                return [NSString stringWithFormat:@"%.0f°", value];
            }] visibleWhen:^BOOL{
                return isSphereChip(MTCGeometryDemoSphereChipOffset);
            }],
            [[ExampleSettingsItem sliderItemWithTitle:@"反推距离"
                                              minimum:100.0
                                              maximum:20000.0
                                                 step:100.0
                                               getter:^double {
                return weakSelf.reverseDistanceSlider.value;
            } setter:^(double value) {
                weakSelf.reverseDistanceSlider.value = value;
                [weakSelf handleReverseParameterChanged];
            } formatter:^NSString *(double value) {
                return [NSString stringWithFormat:@"%.0f m", value];
            }] visibleWhen:^BOOL{
                return isSphereChip(MTCGeometryDemoSphereChipReverseOrigin);
            }],
            [[ExampleSettingsItem sliderItemWithTitle:@"反推方位"
                                              minimum:0.0
                                              maximum:360.0
                                                 step:1.0
                                               getter:^double {
                return weakSelf.reverseHeadingSlider.value;
            } setter:^(double value) {
                weakSelf.reverseHeadingSlider.value = value;
                [weakSelf handleReverseParameterChanged];
            } formatter:^NSString *(double value) {
                return [NSString stringWithFormat:@"%.0f°", value];
            }] visibleWhen:^BOOL{
                return isSphereChip(MTCGeometryDemoSphereChipReverseOrigin);
            }],
            [[ExampleSettingsItem sliderItemWithTitle:@"插值比例"
                                              minimum:0.0
                                              maximum:1.0
                                                 step:0.01
                                               getter:^double {
                return weakSelf.interpolateSlider.value;
            } setter:^(double value) {
                weakSelf.interpolateSlider.value = value;
                [weakSelf handleInterpolateParameterChanged];
            } formatter:^NSString *(double value) {
                return [NSString stringWithFormat:@"%.0f%%", value * 100.0];
            }] visibleWhen:^BOOL{
                return isSphereChip(MTCGeometryDemoSphereChipInterpolate);
            }],
            [[ExampleSettingsItem sliderItemWithTitle:@"抽稀容差"
                                              minimum:1.0
                                              maximum:120.0
                                                 step:1.0
                                               getter:^double {
                return weakSelf.simplifySlider.value;
            } setter:^(double value) {
                weakSelf.simplifySlider.value = value;
                [weakSelf redrawCurrentModeAnimated:NO];
            } formatter:^NSString *(double value) {
                return [NSString stringWithFormat:@"%.0f m", value];
            }] visibleWhen:^BOOL{
                return isPathChip(MTCGeometryDemoPathChipPath);
            }],
            [[ExampleSettingsItem boolItemWithTitle:@"下一点击 = 测试点"
                                            getter:^BOOL {
                return weakSelf.pendingTestPointOnce && isSphereChip(MTCGeometryDemoSphereChipArea);
            } setter:^(BOOL value) {
                weakSelf.pendingTestPointOnce = value;
                [weakSelf refreshSettingsSheetIfVisible];
            }] visibleWhen:^BOOL{
                return isSphereChip(MTCGeometryDemoSphereChipArea);
            }],
            [[ExampleSettingsItem boolItemWithTitle:@"下一点击 = 测试点"
                                            getter:^BOOL {
                return weakSelf.pendingTestPointOnce && isPathChip(MTCGeometryDemoPathChipPath);
            } setter:^(BOOL value) {
                weakSelf.pendingTestPointOnce = value;
                [weakSelf refreshSettingsSheetIfVisible];
            }] visibleWhen:^BOOL{
                return isPathChip(MTCGeometryDemoPathChipPath);
            }],
            [[ExampleSettingsItem boolItemWithTitle:@"下一点击 = 测试点"
                                            getter:^BOOL {
                return weakSelf.pendingTestPointOnce && isPathChip(MTCGeometryDemoPathChipClosedSegmentIndex);
            } setter:^(BOOL value) {
                weakSelf.pendingTestPointOnce = value;
                [weakSelf refreshSettingsSheetIfVisible];
            }] visibleWhen:^BOOL{
                return isPathChip(MTCGeometryDemoPathChipClosedSegmentIndex);
            }],
            [[ExampleSettingsItem boolItemWithTitle:@"closed（含闭合边）"
                                            getter:^BOOL {
                return weakSelf.closedSwitch.isOn;
            } setter:^(BOOL value) {
                weakSelf.closedSwitch.on = value;
                [weakSelf redrawCurrentModeAnimated:NO];
            }] visibleWhen:^BOOL{
                return isPathChip(MTCGeometryDemoPathChipClosedSegmentIndex);
            }],
        ]],
        [ExampleSettingsSection sectionWithTitle:@"操作" items:@[
            [[ExampleSettingsItem actionItemWithTitle:@"示例：逆时针（正）" handler:^{
                [weakSelf handleSignedAreaCounterClockwiseTapped];
            }] visibleWhen:^BOOL{
                return isSphereChip(MTCGeometryDemoSphereChipSignedArea);
            }],
            [[ExampleSettingsItem actionItemWithTitle:@"示例：顺时针（负）" handler:^{
                [weakSelf handleSignedAreaClockwiseTapped];
            }] visibleWhen:^BOOL{
                return isSphereChip(MTCGeometryDemoSphereChipSignedArea);
            }],
            [[ExampleSettingsItem actionItemWithTitle:@"填充清晰抽稀示例" handler:^{
                [weakSelf handleSimplifyExampleTapped];
            }] visibleWhen:^BOOL{
                return isPathChip(MTCGeometryDemoPathChipPath);
            }],
            [[ExampleSettingsItem actionItemWithTitle:@"试极点无解" handler:^{
                [weakSelf handleReversePoleTapped];
            }] visibleWhen:^BOOL{
                return isSphereChip(MTCGeometryDemoSphereChipReverseOrigin);
            }],
            [[ExampleSettingsItem actionItemWithTitle:@"闭合（追加首点）" handler:^{
                [weakSelf handleClosedCommitTapped];
            }] visibleWhen:^BOOL{
                return isPathChip(MTCGeometryDemoPathChipIsClosed);
            }],
            [[ExampleSettingsItem actionItemWithTitle:@"填充已闭合示例" handler:^{
                [weakSelf handleClosedExampleTapped];
            }] visibleWhen:^BOOL{
                return isPathChip(MTCGeometryDemoPathChipIsClosed);
            }],
            [ExampleSettingsItem actionItemWithTitle:@"清空选点" handler:^{
                [weakSelf handleClearTapped];
            }],
        ]],
    ];
}

- (void)refreshSettingsSheetIfVisible {
    if (![self isSettingsSheetVisible:ExampleSettingsSheetView.class]) {
        return;
    }
    [self.settingsSheet refreshVisibleItems];
}

- (void)reloadSettingsSheetIfVisible {
    if (![self isSettingsSheetVisible:ExampleSettingsSheetView.class]) {
        return;
    }
    [self.settingsSheet reloadData];
}

#pragma mark - Delegate

- (void)mapViewDidFinishLoadingMap:(MTCMapView *)mapView {
    (void)mapView;
}

- (void)mapView:(MTCMapView *)mapView didTapAtCoordinate:(CLLocationCoordinate2D)coordinate {
    (void)mapView;
    [self handleMapTapAtCoordinate:coordinate];
}

#pragma mark - Mode

- (void)selectTopSection:(MTCGeometryDemoTopSection)section resetGeometry:(BOOL)resetGeometry {
    self.selectedSection = section;
    self.selectedChipIndex = 0;
    if (resetGeometry) {
        [self clearGeometryState];
    }
    [self rebuildChipButtons];
    [self updateTopSectionButtons];
    [self applyModeDefaultsIfNeeded];
    [self redrawCurrentModeAnimated:NO];
    [self reloadSettingsSheetIfVisible];
}

- (void)selectChipIndex:(NSInteger)chipIndex {
    self.selectedChipIndex = chipIndex;
    [self updateChipButtons];
    [self clearGeometryState];
    [self applyModeDefaultsIfNeeded];
    [self redrawCurrentModeAnimated:NO];
    [self reloadSettingsSheetIfVisible];
}

- (void)handleSectionButtonTapped:(UIButton *)sender {
    [self selectTopSection:(MTCGeometryDemoTopSection)sender.tag resetGeometry:YES];
}

- (void)handleChipButtonTapped:(UIButton *)sender {
    [self selectChipIndex:sender.tag];
}

#pragma mark - Geometry State

- (void)handleMapTapAtCoordinate:(CLLocationCoordinate2D)coordinate {
    switch (self.selectedSection) {
        case MTCGeometryDemoTopSectionSphere:
            [self handleSphereTapAtCoordinate:coordinate];
            break;
        case MTCGeometryDemoTopSectionPath:
            [self handlePathTapAtCoordinate:coordinate];
            break;
        case MTCGeometryDemoTopSectionEncoding:
            [self handleEncodingTapAtCoordinate:coordinate];
            break;
    }
}

- (void)handleSphereTapAtCoordinate:(CLLocationCoordinate2D)coordinate {
    switch ((MTCGeometryDemoSphereChip)self.selectedChipIndex) {
        case MTCGeometryDemoSphereChipDistance:
        case MTCGeometryDemoSphereChipAngle:
            [self appendPointOrRestart:coordinate maxCount:2];
            break;
        case MTCGeometryDemoSphereChipArea:
        case MTCGeometryDemoSphereChipSignedArea:
            [self handlePolygonLikeTapAtCoordinate:coordinate];
            break;
        case MTCGeometryDemoSphereChipOffset:
            [self.geometryPoints removeAllObjects];
            [self.geometryPoints addObject:MTCGeometryDemoValueFromCoordinate(coordinate)];
            break;
        case MTCGeometryDemoSphereChipReverseOrigin:
            [self.geometryPoints removeAllObjects];
            [self.geometryPoints addObject:MTCGeometryDemoValueFromCoordinate(coordinate)];
            break;
        case MTCGeometryDemoSphereChipInterpolate:
            [self appendPointOrRestart:coordinate maxCount:2];
            break;
    }
    BOOL hasResult = NO;
    switch ((MTCGeometryDemoSphereChip)self.selectedChipIndex) {
        case MTCGeometryDemoSphereChipDistance:
        case MTCGeometryDemoSphereChipAngle:
        case MTCGeometryDemoSphereChipInterpolate:
            hasResult = self.geometryPoints.count == 2;
            break;
        case MTCGeometryDemoSphereChipArea:
        case MTCGeometryDemoSphereChipSignedArea:
            hasResult = self.geometryPoints.count >= 3;
            break;
        case MTCGeometryDemoSphereChipOffset:
        case MTCGeometryDemoSphereChipReverseOrigin:
            hasResult = self.geometryPoints.count == 1;
            break;
    }
    self.shouldFocusAfterRedraw = hasResult;
    [self redrawCurrentModeAnimated:YES];
}

- (void)handlePathTapAtCoordinate:(CLLocationCoordinate2D)coordinate {
    switch ((MTCGeometryDemoPathChip)self.selectedChipIndex) {
        case MTCGeometryDemoPathChipPath:
            if (self.pendingTestPointOnce) {
                self.testPointValue = MTCGeometryDemoValueFromCoordinate(coordinate);
                self.hasTestPointValue = YES;
                self.pendingTestPointOnce = NO;
                self.pathTestPointSwitch.on = NO;
            } else {
                [self.pathRawPoints addObject:MTCGeometryDemoValueFromCoordinate(coordinate)];
            }
            break;
        case MTCGeometryDemoPathChipClosedSegmentIndex:
            if (self.pendingTestPointOnce) {
                self.testPointValue = MTCGeometryDemoValueFromCoordinate(coordinate);
                self.hasTestPointValue = YES;
                self.pendingTestPointOnce = NO;
                self.closedSegmentTestPointSwitch.on = NO;
            } else if (self.closedPolygonCommitted) {
                [self clearGeometryState];
                [self.pathRawPoints addObject:MTCGeometryDemoValueFromCoordinate(coordinate)];
            } else {
                [self.pathRawPoints addObject:MTCGeometryDemoValueFromCoordinate(coordinate)];
            }
            break;
        case MTCGeometryDemoPathChipPointToLine:
            if (self.geometryPoints.count >= 3) {
                [self.geometryPoints removeAllObjects];
            }
            [self.geometryPoints addObject:MTCGeometryDemoValueFromCoordinate(coordinate)];
            self.shouldFocusAfterRedraw = self.geometryPoints.count == 3;
            break;
        case MTCGeometryDemoPathChipIsClosed:
            if (self.closedPolygonCommitted) {
                [self clearGeometryState];
                [self.pathRawPoints addObject:MTCGeometryDemoValueFromCoordinate(coordinate)];
            } else {
                if (self.pathRawPoints.count >= 3) {
                    CLLocationCoordinate2D first = MTCGeometryDemoCoordinateFromValue(self.pathRawPoints.firstObject);
                    CLLocationDistance distanceToStart = MTCGeometryComputeDistanceBetween(first, coordinate);
                    if (distanceToStart <= MTCGeometryDemoClosedSnapRadiusMeters) {
                        [self.pathRawPoints addObject:self.pathRawPoints.firstObject];
                        self.closedPolygonCommitted = YES;
                        self.shouldFocusAfterRedraw = YES;
                    } else {
                        [self.pathRawPoints addObject:MTCGeometryDemoValueFromCoordinate(coordinate)];
                    }
                } else {
                    [self.pathRawPoints addObject:MTCGeometryDemoValueFromCoordinate(coordinate)];
                }
            }
            break;
    }

    if (self.selectedChipIndex == MTCGeometryDemoPathChipPath ||
        self.selectedChipIndex == MTCGeometryDemoPathChipClosedSegmentIndex ||
        self.selectedChipIndex == MTCGeometryDemoPathChipIsClosed) {
        self.shouldFocusAfterRedraw = NO;
    }
    [self redrawCurrentModeAnimated:YES];
}

- (void)handleEncodingTapAtCoordinate:(CLLocationCoordinate2D)coordinate {
    [self.pathRawPoints addObject:MTCGeometryDemoValueFromCoordinate(coordinate)];
    [self redrawCurrentModeAnimated:YES];
}

- (void)appendPointOrRestart:(CLLocationCoordinate2D)coordinate maxCount:(NSUInteger)maxCount {
    if (self.geometryPoints.count >= maxCount) {
        [self.geometryPoints removeAllObjects];
    }
    [self.geometryPoints addObject:MTCGeometryDemoValueFromCoordinate(coordinate)];
}

- (void)handlePolygonLikeTapAtCoordinate:(CLLocationCoordinate2D)coordinate {
    if (self.pendingTestPointOnce) {
        self.testPointValue = MTCGeometryDemoValueFromCoordinate(coordinate);
        self.hasTestPointValue = YES;
        self.pendingTestPointOnce = NO;
        self.areaTestPointSwitch.on = NO;
        return;
    }
    if (MTCGeometryDemoContainsCoordinateNear(self.geometryPoints, coordinate, MTCGeometryDemoDuplicatePointToleranceMeters)) {
        [self showGeometryError:@"当前点与已有点重合，无法形成面"];
        return;
    }
    if (self.geometryPoints.count >= 2 &&
        MTCGeometryIsLocationOnPath(coordinate,
                                    MTCGeometryDemoPathFromCoordinates(self.geometryPoints),
                                    YES,
                                    0)) {
        [self showGeometryError:@"当前点在已有线上，无法形成面"];
        return;
    }
    NSMutableArray<NSValue *> *candidatePoints = [self.geometryPoints mutableCopy];
    [candidatePoints addObject:MTCGeometryDemoValueFromCoordinate(coordinate)];
    if (candidatePoints.count >= 4 && MTCGeometryDemoPolygonHasSelfIntersection(candidatePoints)) {
        [self showGeometryError:@"当前点会导致多边形边相交，无法形成面"];
        return;
    }
    if (candidatePoints.count >= 3 && !MTCGeometryDemoCanFormPolygonArea(candidatePoints)) {
        [self showGeometryError:@"当前点无法与已有点形成面"];
        return;
    }
    [self.geometryPoints addObject:MTCGeometryDemoValueFromCoordinate(coordinate)];
}

- (void)appendFirstPointToClosePathIfPossible {
    if (self.pathRawPoints.count < 3) {
        return;
    }
    [self.pathRawPoints addObject:self.pathRawPoints.firstObject];
    self.closedPolygonCommitted = YES;
}

- (void)clearGeometryState {
    [self.geometryPoints removeAllObjects];
    [self.pathRawPoints removeAllObjects];
    self.hasTestPointValue = NO;
    self.testPointValue = nil;
    self.pendingTestPointOnce = NO;
    self.closedPolygonCommitted = NO;
    self.pendingErrorHint = nil;
    self.areaTestPointSwitch.on = NO;
    self.pathTestPointSwitch.on = NO;
    self.closedSegmentTestPointSwitch.on = NO;
}

- (void)applyModeDefaultsIfNeeded {
    BOOL isClosedSegmentMode = self.selectedSection == MTCGeometryDemoTopSectionPath &&
                               self.selectedChipIndex == MTCGeometryDemoPathChipClosedSegmentIndex;
    self.closedSwitch.on = isClosedSegmentMode;
    if (!isClosedSegmentMode) {
        self.pendingTestPointOnce = NO;
    }
}

#pragma mark - Redraw

- (void)redrawCurrentModeAnimated:(BOOL)animated {
    [self.mapView removeAllOverlays];
    [self.mapView removeAllInfoWindows];
    [self resetOffsetOverlayReferences];
    [self resetReverseOverlayReferences];
    [self resetInterpolateOverlayReferences];
    [self updatePanelVisibility];
    [self syncPanelState];

    NSArray<NSValue *> *focusValues = nil;
    BOOL focusUsesPolygonBounds = NO;
    BOOL focusUsesLineBounds = NO;
    NSString *statusText = @"";

    if (self.selectedSection == MTCGeometryDemoTopSectionSphere) {
        switch ((MTCGeometryDemoSphereChip)self.selectedChipIndex) {
            case MTCGeometryDemoSphereChipDistance:
                statusText = [self drawDistanceMode];
                focusValues = self.geometryPoints.copy;
                break;
            case MTCGeometryDemoSphereChipAngle:
                statusText = [self drawAngleMode];
                focusValues = self.geometryPoints.copy;
                break;
            case MTCGeometryDemoSphereChipArea:
                statusText = [self drawAreaMode];
                focusValues = self.geometryPoints.copy;
                focusUsesPolygonBounds = self.geometryPoints.count >= 3;
                break;
            case MTCGeometryDemoSphereChipSignedArea:
                statusText = [self drawSignedAreaMode];
                focusValues = self.geometryPoints.copy;
                focusUsesPolygonBounds = self.geometryPoints.count >= 3;
                break;
            case MTCGeometryDemoSphereChipOffset:
                statusText = [self drawOffsetMode];
                focusValues = [self offsetLineValuesForCurrentParameters];
                focusUsesLineBounds = focusValues.count == 2;
                break;
            case MTCGeometryDemoSphereChipReverseOrigin:
                statusText = [self drawReverseOriginMode];
                focusValues = [self reverseLineValuesForCurrentParameters];
                focusUsesLineBounds = focusValues.count == 2;
                break;
            case MTCGeometryDemoSphereChipInterpolate:
                statusText = [self drawInterpolateMode];
                focusValues = self.geometryPoints.copy;
                focusUsesLineBounds = self.geometryPoints.count == 2;
                break;
        }
    } else if (self.selectedSection == MTCGeometryDemoTopSectionPath) {
        switch ((MTCGeometryDemoPathChip)self.selectedChipIndex) {
            case MTCGeometryDemoPathChipPath:
                statusText = [self drawPathMode];
                focusValues = self.pathRawPoints.copy;
                break;
            case MTCGeometryDemoPathChipClosedSegmentIndex:
                statusText = [self drawClosedSegmentIndexMode];
                focusValues = self.pathRawPoints.copy;
                break;
            case MTCGeometryDemoPathChipPointToLine:
                statusText = [self drawPointToLineMode];
                focusValues = self.geometryPoints.copy;
                break;
            case MTCGeometryDemoPathChipIsClosed:
                statusText = [self drawIsClosedMode];
                focusValues = self.pathRawPoints.copy;
                break;
        }
    } else {
        statusText = [self drawEncodingMode];
        focusValues = self.pathRawPoints.copy;
    }

    self.statusLabel.text = statusText;
    if (self.pendingErrorHint.length > 0) {
        self.statusLabel.text = self.pendingErrorHint;
        self.hintPillLabel.text = self.pendingErrorHint;
        [self updatePanelResult:@"无法形成面" detail:self.pendingErrorHint];
        self.pendingErrorHint = nil;
    }
    if (self.shouldFocusAfterRedraw && focusValues.count > 0) {
        if (focusUsesPolygonBounds) {
            [self focusOnPolygonCoordinates:focusValues animated:animated];
        } else if (focusUsesLineBounds) {
            [self focusOnResultLineCoordinates:focusValues animated:animated];
        } else {
            [self focusOnCoordinates:focusValues animated:animated];
        }
    }
    self.shouldFocusAfterRedraw = NO;
}

- (NSString *)drawDistanceMode {
    if (self.geometryPoints.count < 2) {
        [self updatePanelResult:@"点击地图选择 A、B 两点" detail:@"满 2 点后再点会清空重选"];
        [self drawPointsWithLabels:@[@"A", @"B"] colors:@[MTCGeometryDemoBlueColor(), MTCGeometryDemoBlueColor()] zIndex:100];
        return @"测距 · 点击地图选择 A、B 两点";
    }

    CLLocationCoordinate2D a = MTCGeometryDemoCoordinateFromValue(self.geometryPoints[0]);
    CLLocationCoordinate2D b = MTCGeometryDemoCoordinateFromValue(self.geometryPoints[1]);
    CLLocationDistance distance = MTCGeometryComputeDistanceBetween(a, b);
    CLLocationDirection heading = MTCGeometryDemoNormalizeHeading(MTCGeometryComputeHeading(a, b));
    [self drawLineFromCoordinates:@[self.geometryPoints[0], self.geometryPoints[1]]
                       strokeColor:MTCGeometryDemoBlueColor()
                             width:10.0];
    [self drawPointsWithLabels:@[@"A", @"B"] colors:@[MTCGeometryDemoBlueColor(), MTCGeometryDemoBlueColor()] zIndex:100];
    CLLocationCoordinate2D center = MTCGeometryDemoCenterForCoordinates(self.geometryPoints);
    [self showBubbleAtCoordinate:center
                          lines:@[[NSString stringWithFormat:@"距离 %@", MTCGeometryDemoDistanceText(distance)],
                                 [NSString stringWithFormat:@"方位角 %@", MTCGeometryDemoHeadingText(heading)]]
                     accentColor:MTCGeometryDemoBlueColor()];
    [self updatePanelResult:[NSString stringWithFormat:@"Distance = %@", MTCGeometryDemoDistanceText(distance)]
                     detail:[NSString stringWithFormat:@"Heading = %@", MTCGeometryDemoHeadingText(heading)]];
    return [NSString stringWithFormat:@"测距 · Distance = %@ · Heading = %@", MTCGeometryDemoDistanceText(distance), MTCGeometryDemoHeadingText(heading)];
}

- (NSString *)drawAngleMode {
    if (self.geometryPoints.count < 2) {
        [self updatePanelResult:@"点击地图选择 A、B 两点" detail:@"中点会显示夹角值"];
        [self drawPointsWithLabels:@[@"A", @"B"] colors:@[MTCGeometryDemoBlueColor(), MTCGeometryDemoBlueColor()] zIndex:100];
        return @"夹角 · 点击地图选择 A、B 两点";
    }

    CLLocationCoordinate2D a = MTCGeometryDemoCoordinateFromValue(self.geometryPoints[0]);
    CLLocationCoordinate2D b = MTCGeometryDemoCoordinateFromValue(self.geometryPoints[1]);
    double radians = MTCGeometryComputeAngleBetween(a, b);
    double degrees = radians * 180.0 / M_PI;
    [self drawLineFromCoordinates:@[self.geometryPoints[0], self.geometryPoints[1]]
                       strokeColor:MTCGeometryDemoPurpleColor()
                             width:8.0];
    [self drawPointsWithLabels:@[@"A", @"B"] colors:@[MTCGeometryDemoBlueColor(), MTCGeometryDemoBlueColor()] zIndex:100];
    CLLocationCoordinate2D center = MTCGeometryDemoCenterForCoordinates(self.geometryPoints);
    [self showBubbleAtCoordinate:center
                          lines:@[[NSString stringWithFormat:@"夹角 %@", MTCGeometryDemoAngleText(radians)],
                                 [NSString stringWithFormat:@"Degrees %.1f°", degrees]]
                     accentColor:MTCGeometryDemoPurpleColor()];
    [self updatePanelResult:[NSString stringWithFormat:@"Radians = %.6f", radians]
                     detail:[NSString stringWithFormat:@"Degrees = %.1f°", degrees]];
    return [NSString stringWithFormat:@"夹角 · Radians = %.6f · Degrees = %.1f°", radians, degrees];
}

- (NSString *)drawAreaMode {
    if (self.geometryPoints.count == 0) {
        [self updatePanelResult:@"连点 ≥3 个顶点围成多边形" detail:@"<3 点时只画点/折线"];
        return @"面积 · 连点 ≥3 个顶点围成多边形";
    }

    if (self.geometryPoints.count < 3) {
        [self drawPathFromCoordinates:self.geometryPoints strokeColor:MTCGeometryDemoBlueColor() width:5.0];
        [self drawPointsWithLabels:nil colors:nil zIndex:100];
        [self updatePanelResult:[NSString stringWithFormat:@"已 %lu 点，还需 ≥%lu", (unsigned long)self.geometryPoints.count, (unsigned long)(3 - self.geometryPoints.count)]
                         detail:@"继续点地图补足顶点"];
        return [NSString stringWithFormat:@"面积 · 已 %lu 点，还需 ≥%lu", (unsigned long)self.geometryPoints.count, (unsigned long)(3 - self.geometryPoints.count)];
    }

    MTCPath *polygonPath = MTCGeometryDemoPathFromCoordinates(self.geometryPoints);
    double area = MTCGeometryComputeArea(polygonPath);
    CLLocationCoordinate2D center = MTCGeometryDemoCenterForCoordinates(self.geometryPoints);
    BOOL onEdge = NO;
    BOOL inside = NO;
    if (self.hasTestPointValue) {
        CLLocationCoordinate2D testPoint = MTCGeometryDemoCoordinateFromValue(self.testPointValue);
        inside = MTCGeometryContainsLocation(testPoint, polygonPath, YES);
        onEdge = MTCGeometryIsLocationOnEdge(testPoint, polygonPath, YES, MTCGeometryDemoPointToLineToleranceMeters);
    }
    [self drawPolygonWithCoordinates:self.geometryPoints fillColor:MTCGeometryDemoRedColor() fillOpacity:0.24 strokeColor:MTCGeometryDemoRedColor() width:2.0];
    [self drawPointsWithLabels:[self numberedLabelsForCount:self.geometryPoints.count] colors:[self repeatedColors:MTCGeometryDemoBlueColor() count:self.geometryPoints.count] zIndex:100];

    if (self.hasTestPointValue) {
        CLLocationCoordinate2D testPoint = MTCGeometryDemoCoordinateFromValue(self.testPointValue);
        UIColor *dotColor = onEdge ? MTCGeometryDemoOrangeColor() : (inside ? MTCGeometryDemoGreenColor() : MTCGeometryDemoOrangeColor());
        [self drawBadgeAtCoordinate:testPoint text:@"测" fillColor:dotColor strokeColor:dotColor side:28.0 zIndex:120];
        [self showBubbleAtCoordinate:testPoint
                              lines:@[[NSString stringWithFormat:@"在多边形内 = %@", inside ? @"true" : @"false"],
                                     onEdge ? @"在边上 = true" : @"在边上 = false"]
                         accentColor:dotColor];
        [self updatePanelResult:[NSString stringWithFormat:@"Area = %@", MTCGeometryDemoAreaText(area)]
                         detail:[NSString stringWithFormat:@"在多边形内 = %@ / 在边上 = %@", inside ? @"true" : @"false", onEdge ? @"true" : @"false"]];
    } else {
        [self showBubbleAtCoordinate:center
                              lines:@[[NSString stringWithFormat:@"区域面积 %@", MTCGeometryDemoAreaText(area)],
                                     @"下一点击 = 测试点"]
                         accentColor:MTCGeometryDemoRedColor()];
        [self updatePanelResult:[NSString stringWithFormat:@"Area = %@", MTCGeometryDemoAreaText(area)]
                         detail:@"下一点击 = 测试点"];
    }
    return [NSString stringWithFormat:@"面积 · Area = %@", MTCGeometryDemoAreaText(area)];
}

- (NSString *)drawSignedAreaMode {
    if (self.geometryPoints.count < 3) {
        [self drawPathFromCoordinates:self.geometryPoints strokeColor:MTCGeometryDemoBlueColor() width:5.0];
        [self drawPointsWithLabels:nil colors:nil zIndex:100];
        if (self.geometryPoints.count == 0) {
            [self updatePanelResult:@"点 ≥3 顶点，顺序决定正负" detail:@"按钮可一键填充正/负示例"];
            return @"带符号面积 · 点 ≥3 顶点，顺序决定正负";
        }
        [self updatePanelResult:[NSString stringWithFormat:@"已 %lu 点，还需 ≥%lu", (unsigned long)self.geometryPoints.count, (unsigned long)(3 - self.geometryPoints.count)]
                         detail:@"继续点地图补足顶点"];
        return [NSString stringWithFormat:@"带符号面积 · 已 %lu 点，还需 ≥%lu", (unsigned long)self.geometryPoints.count, (unsigned long)(3 - self.geometryPoints.count)];
    }

    MTCPath *path = MTCGeometryDemoPathFromCoordinates(self.geometryPoints);
    double signedArea = MTCGeometryComputeSignedArea(path);
    BOOL positive = signedArea >= 0.0;
    UIColor *fillColor = positive ? MTCGeometryDemoGreenColor() : MTCGeometryDemoRedColor();
    [self drawPolygonWithCoordinates:self.geometryPoints fillColor:fillColor fillOpacity:0.25 strokeColor:fillColor width:2.5];
    [self drawPointsWithLabels:[self numberedLabelsForCount:self.geometryPoints.count] colors:[self repeatedColors:MTCGeometryDemoBlueColor() count:self.geometryPoints.count] zIndex:100];
    CLLocationCoordinate2D center = MTCGeometryDemoCenterForCoordinates(self.geometryPoints);
    [self showBubbleAtCoordinate:center
                          lines:@[[NSString stringWithFormat:@"带符号面积 %@", MTCGeometryDemoAreaText(signedArea)],
                                 positive ? @"正（多为逆时针）" : @"负（多为顺时针）"]
                     accentColor:fillColor];
    [self updatePanelResult:[NSString stringWithFormat:@"SignedArea = %@", MTCGeometryDemoAreaText(signedArea)]
                     detail:positive ? @"正（多为逆时针）" : @"负（多为顺时针）"];
    return [NSString stringWithFormat:@"带符号面积 · SignedArea = %@", MTCGeometryDemoAreaText(signedArea)];
}

- (NSString *)drawOffsetMode {
    if (self.geometryPoints.count == 0) {
        [self updatePanelResult:@"点击地图选择起点" detail:@"再在配置面板调距离 / 方位"];
        [self showStatusHint:@"👆 点击地图选择起点，再在配置面板调参数"];
        return @"偏移 · 点击地图选择起点";
    }
    return [self applyOffsetModeOverlayStateCreatingIfNeeded:YES] ?: @"偏移 · 点击地图选择起点";
}

- (BOOL)isOffsetModeSelected {
    return self.selectedSection == MTCGeometryDemoTopSectionSphere &&
           self.selectedChipIndex == MTCGeometryDemoSphereChipOffset;
}

- (void)resetOffsetOverlayReferences {
    self.offsetStartMarker = nil;
    self.offsetEndMarker = nil;
    self.offsetLine = nil;
    self.offsetInfoWindow = nil;
}

- (NSArray<NSValue *> *)offsetLineValuesForCurrentParameters {
    if (self.geometryPoints.count != 1) {
        return @[];
    }
    CLLocationCoordinate2D a = MTCGeometryDemoCoordinateFromValue(self.geometryPoints.firstObject);
    CLLocationCoordinate2D b = MTCGeometryComputeOffset(a, self.offsetDistanceSlider.value, self.offsetHeadingSlider.value);
    return @[self.geometryPoints.firstObject, MTCGeometryDemoValueFromCoordinate(b)];
}

- (BOOL)updateOffsetModeOverlaysInPlace {
    if (![self isOffsetModeSelected] ||
        self.geometryPoints.count != 1 ||
        !self.offsetStartMarker ||
        !self.offsetEndMarker ||
        !self.offsetLine ||
        !self.offsetInfoWindow) {
        return NO;
    }
    NSString *status = [self applyOffsetModeOverlayStateCreatingIfNeeded:NO];
    if (status.length == 0) {
        return NO;
    }
    [self focusOnResultLineCoordinates:[self offsetLineValuesForCurrentParameters] animated:NO];
    return YES;
}

- (NSString *)applyOffsetModeOverlayStateCreatingIfNeeded:(BOOL)createIfNeeded {
    if (self.geometryPoints.count != 1) {
        return nil;
    }

    CLLocationCoordinate2D a = MTCGeometryDemoCoordinateFromValue(self.geometryPoints.firstObject);
    CLLocationDistance distance = self.offsetDistanceSlider.value;
    CLLocationDirection heading = self.offsetHeadingSlider.value;
    CLLocationCoordinate2D b = MTCGeometryComputeOffset(a, distance, heading);
    CLLocationCoordinate2D lineCoordinates[2] = { a, b };

    if (createIfNeeded && !self.offsetLine) {
        self.offsetLine = MTCGeometryDemoPolyline(@[self.geometryPoints.firstObject, MTCGeometryDemoValueFromCoordinate(b)],
                                                  MTCGeometryDemoBlueColor(),
                                                  8.0,
                                                  20);
        [self.mapView addOverlay:self.offsetLine];
    } else {
        [self.offsetLine setCoordinates:lineCoordinates count:2];
    }

    if (createIfNeeded && !self.offsetStartMarker) {
        self.offsetStartMarker = MTCGeometryDemoBadgeMarker(a,
                                                            @"起点",
                                                            MTCGeometryDemoGreenColor(),
                                                            MTCGeometryDemoGreenColor(),
                                                            MTCGeometryDemoBadgeSide,
                                                            100);
        [self.mapView addOverlay:self.offsetStartMarker];
    } else {
        self.offsetStartMarker.coordinate = a;
    }

    if (createIfNeeded && !self.offsetEndMarker) {
        self.offsetEndMarker = MTCGeometryDemoBadgeMarker(b,
                                                          @"终点",
                                                          MTCGeometryDemoRedColor(),
                                                          MTCGeometryDemoRedColor(),
                                                          MTCGeometryDemoBadgeSide,
                                                          100);
        [self.mapView addOverlay:self.offsetEndMarker];
    } else {
        self.offsetEndMarker.coordinate = b;
    }

    CLLocationCoordinate2D center = MTCGeometryDemoCenterForCoordinates(@[self.geometryPoints.firstObject, MTCGeometryDemoValueFromCoordinate(b)]);
    NSArray<NSString *> *bubbleLines = @[
        [NSString stringWithFormat:@"偏移 %@ / %@", MTCGeometryDemoDistanceText(distance), MTCGeometryDemoHeadingText(heading)],
        [NSString stringWithFormat:@"终点 = %@", MTCGeometryDemoCoordinateText(b)],
    ];
    if (createIfNeeded && !self.offsetInfoWindow) {
        self.offsetInfoWindow = [self showBubbleAtCoordinate:center
                                                       lines:bubbleLines
                                                 accentColor:MTCGeometryDemoBlueColor()];
    } else {
        [self.offsetInfoWindow refreshViaOptions:[self bubbleOptionsAtCoordinate:center
                                                                           lines:bubbleLines
                                                                     accentColor:MTCGeometryDemoBlueColor()]];
    }

    NSString *status = [NSString stringWithFormat:@"偏移 · %@ / %@", MTCGeometryDemoDistanceText(distance), MTCGeometryDemoHeadingText(heading)];
    self.statusLabel.text = status;
    [self updatePanelResult:[NSString stringWithFormat:@"Offset = %@ / %@", MTCGeometryDemoDistanceText(distance), MTCGeometryDemoHeadingText(heading)]
                     detail:[NSString stringWithFormat:@"起点沿 %@ 走 %@ → 终点 %@", MTCGeometryDemoHeadingText(heading), MTCGeometryDemoDistanceText(distance), MTCGeometryDemoCoordinateText(b)]];
    return status;
}

- (NSString *)drawReverseOriginMode {
    if (self.geometryPoints.count == 0) {
        [self updatePanelResult:@"点击地图选择终点" detail:@"再在配置面板调距离 / 方位"];
        return @"反推原点 · 点击地图选择终点";
    }
    return [self applyReverseOriginModeOverlayStateCreatingIfNeeded:YES] ?: @"反推原点 · 点击地图选择终点";
}

- (BOOL)isReverseOriginModeSelected {
    return self.selectedSection == MTCGeometryDemoTopSectionSphere &&
           self.selectedChipIndex == MTCGeometryDemoSphereChipReverseOrigin;
}

- (void)resetReverseOverlayReferences {
    self.reverseStartMarker = nil;
    self.reverseEndMarker = nil;
    self.reverseLine = nil;
    self.reverseInfoWindow = nil;
}

- (NSArray<NSValue *> *)reverseLineValuesForCurrentParameters {
    if (self.geometryPoints.count != 1) {
        return @[];
    }
    CLLocationCoordinate2D to = MTCGeometryDemoCoordinateFromValue(self.geometryPoints.firstObject);
    CLLocationCoordinate2D from = MTCGeometryComputeOffsetOrigin(to, self.reverseDistanceSlider.value, self.reverseHeadingSlider.value);
    if (!MTCGeometryDemoCoordinateIsValid(from)) {
        return @[];
    }
    return @[MTCGeometryDemoValueFromCoordinate(from), self.geometryPoints.firstObject];
}

- (BOOL)updateReverseOriginModeOverlaysInPlace {
    if (![self isReverseOriginModeSelected] ||
        self.geometryPoints.count != 1 ||
        (!self.reverseStartMarker && !self.reverseEndMarker && !self.reverseLine && !self.reverseInfoWindow)) {
        return NO;
    }
    NSString *status = [self applyReverseOriginModeOverlayStateCreatingIfNeeded:NO];
    if (status.length == 0) {
        return NO;
    }
    NSArray<NSValue *> *lineValues = [self reverseLineValuesForCurrentParameters];
    if (lineValues.count == 2) {
        [self focusOnResultLineCoordinates:lineValues animated:NO];
    }
    return YES;
}

- (NSString *)applyReverseOriginModeOverlayStateCreatingIfNeeded:(BOOL)createIfNeeded {
    (void)createIfNeeded;
    if (self.geometryPoints.count != 1) {
        return nil;
    }

    CLLocationCoordinate2D to = MTCGeometryDemoCoordinateFromValue(self.geometryPoints.firstObject);
    CLLocationDistance distance = self.reverseDistanceSlider.value;
    CLLocationDirection heading = self.reverseHeadingSlider.value;
    CLLocationCoordinate2D from = MTCGeometryComputeOffsetOrigin(to, distance, heading);
    if (!MTCGeometryDemoCoordinateIsValid(from)) {
        if (self.reverseLine) {
            [self.mapView removeOverlay:self.reverseLine];
            self.reverseLine = nil;
        }
        if (self.reverseStartMarker) {
            [self.mapView removeOverlay:self.reverseStartMarker];
            self.reverseStartMarker = nil;
        }
        if (!self.reverseEndMarker) {
            self.reverseEndMarker = MTCGeometryDemoBadgeMarker(to,
                                                               @"终点",
                                                               MTCGeometryDemoRedColor(),
                                                               MTCGeometryDemoRedColor(),
                                                               MTCGeometryDemoBadgeSide,
                                                               100);
            [self.mapView addOverlay:self.reverseEndMarker];
        } else {
            self.reverseEndMarker.coordinate = to;
        }
        NSArray<NSString *> *bubbleLines = @[@"无解（null）"];
        if (!self.reverseInfoWindow) {
            self.reverseInfoWindow = [self showBubbleAtCoordinate:to
                                                            lines:bubbleLines
                                                      accentColor:MTCGeometryDemoRedColor()];
        } else {
            [self.reverseInfoWindow refreshViaOptions:[self bubbleOptionsAtCoordinate:to
                                                                                lines:bubbleLines
                                                                          accentColor:MTCGeometryDemoRedColor()]];
        }
        self.statusLabel.text = @"反推原点 · 无解（null）";
        [self updatePanelResult:@"From = null" detail:@"极点或参数组合无解"];
        return @"反推原点 · 无解（null）";
    }

    CLLocationCoordinate2D lineCoordinates[2] = { from, to };
    if (!self.reverseLine) {
        self.reverseLine = MTCGeometryDemoPolyline(@[MTCGeometryDemoValueFromCoordinate(from), self.geometryPoints.firstObject],
                                                   MTCGeometryDemoBlueColor(),
                                                   8.0,
                                                   20);
        [self.mapView addOverlay:self.reverseLine];
    } else {
        [self.reverseLine setCoordinates:lineCoordinates count:2];
    }

    if (!self.reverseStartMarker) {
        self.reverseStartMarker = MTCGeometryDemoBadgeMarker(from,
                                                             @"起点",
                                                             MTCGeometryDemoGreenColor(),
                                                             MTCGeometryDemoGreenColor(),
                                                             MTCGeometryDemoBadgeSide,
                                                             100);
        [self.mapView addOverlay:self.reverseStartMarker];
    } else {
        self.reverseStartMarker.coordinate = from;
    }

    if (!self.reverseEndMarker) {
        self.reverseEndMarker = MTCGeometryDemoBadgeMarker(to,
                                                           @"终点",
                                                           MTCGeometryDemoRedColor(),
                                                           MTCGeometryDemoRedColor(),
                                                           MTCGeometryDemoBadgeSide,
                                                           100);
        [self.mapView addOverlay:self.reverseEndMarker];
    } else {
        self.reverseEndMarker.coordinate = to;
    }

    CLLocationCoordinate2D center = MTCGeometryDemoCenterForCoordinates(@[MTCGeometryDemoValueFromCoordinate(from), self.geometryPoints.firstObject]);
    NSArray<NSString *> *bubbleLines = @[
        [NSString stringWithFormat:@"起点 = %@", MTCGeometryDemoCoordinateText(from)],
        [NSString stringWithFormat:@"终点反推 %@ / %@", MTCGeometryDemoDistanceText(distance), MTCGeometryDemoHeadingText(heading)],
    ];
    if (!self.reverseInfoWindow) {
        self.reverseInfoWindow = [self showBubbleAtCoordinate:center
                                                        lines:bubbleLines
                                                  accentColor:MTCGeometryDemoBlueColor()];
    } else {
        [self.reverseInfoWindow refreshViaOptions:[self bubbleOptionsAtCoordinate:center
                                                                            lines:bubbleLines
                                                                      accentColor:MTCGeometryDemoBlueColor()]];
    }

    NSString *status = [NSString stringWithFormat:@"反推原点 · 起点 %@", MTCGeometryDemoCoordinateText(from)];
    self.statusLabel.text = status;
    [self updatePanelResult:[NSString stringWithFormat:@"From = %@", MTCGeometryDemoCoordinateText(from)]
                     detail:[NSString stringWithFormat:@"终点反推 %@ / %@", MTCGeometryDemoDistanceText(distance), MTCGeometryDemoHeadingText(heading)]];
    return status;
}

- (NSString *)drawInterpolateMode {
    if (self.geometryPoints.count < 2) {
        if (self.geometryPoints.count == 1) {
            return [self applyInterpolateModeOverlayStateCreatingIfNeeded:YES] ?: @"插值 · 点击地图选择 B 点";
        }
        [self updatePanelResult:@"点击地图选择 A 点" detail:@"再拖动插值比例滑条"];
        return @"插值 · 点击地图选择 A 点";
    }

    return [self applyInterpolateModeOverlayStateCreatingIfNeeded:YES] ?: @"插值 · 点击地图选择 A 点";
}

- (void)resetInterpolateOverlayReferences {
    self.interpolateStartMarker = nil;
    self.interpolateEndMarker = nil;
    self.interpolatePointMarker = nil;
    self.interpolateLine = nil;
    self.interpolateInfoWindow = nil;
}

- (NSArray<NSValue *> *)interpolateLineValuesForCurrentParameters {
    if (self.geometryPoints.count != 2) {
        return @[];
    }
    CLLocationCoordinate2D a = MTCGeometryDemoCoordinateFromValue(self.geometryPoints[0]);
    CLLocationCoordinate2D b = MTCGeometryDemoCoordinateFromValue(self.geometryPoints[1]);
    return @[self.geometryPoints[0], self.geometryPoints[1], MTCGeometryDemoValueFromCoordinate(MTCGeometryInterpolate(a, b, self.interpolateSlider.value))];
}

- (BOOL)updateInterpolateModeOverlaysInPlace {
    if (![self isInterpolateModeSelected] ||
        self.geometryPoints.count < 1 ||
        (!self.interpolateStartMarker && !self.interpolateEndMarker && !self.interpolatePointMarker && !self.interpolateLine && !self.interpolateInfoWindow)) {
        return NO;
    }
    NSString *status = [self applyInterpolateModeOverlayStateCreatingIfNeeded:NO];
    if (status.length == 0) {
        return NO;
    }
    NSArray<NSValue *> *lineValues = [self interpolateLineValuesForCurrentParameters];
    if (lineValues.count == 3) {
        [self focusOnResultLineCoordinates:@[lineValues[0], lineValues[1]] animated:NO];
    }
    return YES;
}

- (BOOL)isInterpolateModeSelected {
    return self.selectedSection == MTCGeometryDemoTopSectionSphere &&
           self.selectedChipIndex == MTCGeometryDemoSphereChipInterpolate;
}

- (NSString *)applyInterpolateModeOverlayStateCreatingIfNeeded:(BOOL)createIfNeeded {
    if (self.geometryPoints.count == 0) {
        return nil;
    }

    CLLocationCoordinate2D a = MTCGeometryDemoCoordinateFromValue(self.geometryPoints[0]);
    double fraction = self.interpolateSlider.value;
    if (self.geometryPoints.count == 1) {
        if (createIfNeeded && !self.interpolateStartMarker) {
            self.interpolateStartMarker = MTCGeometryDemoBadgeMarker(a,
                                                                     @"A",
                                                                     MTCGeometryDemoBlueColor(),
                                                                     MTCGeometryDemoBlueColor(),
                                                                     MTCGeometryDemoBadgeSide,
                                                                     100);
            [self.mapView addOverlay:self.interpolateStartMarker];
        } else if (self.interpolateStartMarker) {
            self.interpolateStartMarker.coordinate = a;
        }
        self.statusLabel.text = @"插值 · 点击地图选择 B 点";
        [self updatePanelResult:@"点击地图选择 B 点" detail:@"再拖动插值比例滑条"];
        return @"插值 · 点击地图选择 B 点";
    }

    CLLocationCoordinate2D b = MTCGeometryDemoCoordinateFromValue(self.geometryPoints[1]);
    CLLocationCoordinate2D interpolated = MTCGeometryInterpolate(a, b, fraction);
    CLLocationCoordinate2D lineCoordinates[2] = { a, b };

    if (!self.interpolateLine) {
        self.interpolateLine = MTCGeometryDemoPolyline(self.geometryPoints.copy, MTCGeometryDemoBlueColor(), 5.0, 20);
        [self.mapView addOverlay:self.interpolateLine];
    } else {
        [self.interpolateLine setCoordinates:lineCoordinates count:2];
    }

    if (!self.interpolateStartMarker) {
        self.interpolateStartMarker = MTCGeometryDemoBadgeMarker(a, @"A", MTCGeometryDemoBlueColor(), MTCGeometryDemoBlueColor(), MTCGeometryDemoBadgeSide, 100);
        [self.mapView addOverlay:self.interpolateStartMarker];
    } else {
        self.interpolateStartMarker.coordinate = a;
    }

    if (!self.interpolateEndMarker) {
        self.interpolateEndMarker = MTCGeometryDemoBadgeMarker(b, @"B", MTCGeometryDemoBlueColor(), MTCGeometryDemoBlueColor(), MTCGeometryDemoBadgeSide, 100);
        [self.mapView addOverlay:self.interpolateEndMarker];
    } else {
        self.interpolateEndMarker.coordinate = b;
    }

    if (!self.interpolatePointMarker) {
        self.interpolatePointMarker = MTCGeometryDemoBadgeMarker(interpolated, @"分", MTCGeometryDemoOrangeColor(), MTCGeometryDemoOrangeColor(), 30.0, 110);
        [self.mapView addOverlay:self.interpolatePointMarker];
    } else {
        self.interpolatePointMarker.coordinate = interpolated;
    }

    CLLocationCoordinate2D center = MTCGeometryDemoCenterForCoordinates(@[self.geometryPoints[0], self.geometryPoints[1], MTCGeometryDemoValueFromCoordinate(interpolated)]);
    NSArray<NSString *> *bubbleLines = @[
        [NSString stringWithFormat:@"插值 %@", MTCGeometryDemoFractionText(fraction)],
        [NSString stringWithFormat:@"P = %@", MTCGeometryDemoCoordinateText(interpolated)],
    ];
    if (!self.interpolateInfoWindow) {
        self.interpolateInfoWindow = [self showBubbleAtCoordinate:center
                                                            lines:bubbleLines
                                                      accentColor:MTCGeometryDemoOrangeColor()];
    } else {
        [self.interpolateInfoWindow refreshViaOptions:[self bubbleOptionsAtCoordinate:center
                                                                                lines:bubbleLines
                                                                          accentColor:MTCGeometryDemoOrangeColor()]];
    }

    NSString *status = [NSString stringWithFormat:@"插值 · %@", MTCGeometryDemoFractionText(fraction)];
    self.statusLabel.text = status;
    [self updatePanelResult:[NSString stringWithFormat:@"Interpolate = %@", MTCGeometryDemoFractionText(fraction)]
                     detail:[NSString stringWithFormat:@"P = %@", MTCGeometryDemoCoordinateText(interpolated)]];
    return status;
}

- (NSString *)drawPathMode {
    NSArray<NSValue *> *values = self.pathRawPoints.copy;
    if (values.count == 0) {
        [self updatePanelResult:@"点击地图添加路径点" detail:@"蓝细线 = 原路径；绿细线 = 抽稀后"];
        return @"路径 · 点击地图添加路径点";
    }

    [self drawPathFromCoordinates:values strokeColor:MTCGeometryDemoBlueColor() width:5.0];
    NSArray<NSString *> *rawLabels = [self numberedLabelsForCount:values.count];
    for (NSUInteger index = 0; index < values.count; ++index) {
        [self drawBadgeAtCoordinate:MTCGeometryDemoCoordinateFromValue(values[index])
                               text:rawLabels[index]
                         fillColor:MTCGeometryDemoBlueColor()
                        strokeColor:MTCGeometryDemoBlueColor()
                               side:28.0
                             zIndex:100];
    }

    if (values.count == 1) {
        [self showBubbleAtCoordinate:MTCGeometryDemoCoordinateFromValue(values.firstObject)
                              lines:@[@"原始点"]
                         accentColor:MTCGeometryDemoBlueColor()];
        [self updatePanelResult:@"已 1 点" detail:@"继续点更多路径点"];
        return @"路径 · 已 1 点";
    }

    CLLocationDistance tolerance = self.simplifySlider.value;
    MTCPath *rawPath = MTCGeometryDemoPathFromCoordinates(values);
    MTCPath *simplified = MTCGeometrySimplify(rawPath, tolerance);
    NSArray<NSValue *> *simplifiedValues = MTCGeometryDemoCoordinatesFromPath(simplified);
    NSArray<NSValue *> *shifted = MTCGeometryDemoPathByOffsettingCoordinates(simplifiedValues, MTCGeometryDemoSimplifyOffsetMeters);

    if (shifted.count > 0) {
        [self drawPathFromCoordinates:shifted strokeColor:MTCGeometryDemoGreenColor() width:6.0];
        NSMutableArray<NSString *> *simplifiedLabels = [NSMutableArray arrayWithCapacity:simplifiedValues.count];
        NSUInteger rawIndex = 0;
        for (NSUInteger index = 0; index < simplifiedValues.count; ++index) {
            CLLocationCoordinate2D simplifiedCoordinate = MTCGeometryDemoCoordinateFromValue(simplifiedValues[index]);
            while (rawIndex < values.count) {
                CLLocationCoordinate2D raw = MTCGeometryDemoCoordinateFromValue(values[rawIndex]);
                if (MTCGeometryDemoCoordinatesEqual(raw, simplifiedCoordinate, 0.00001)) {
                    [simplifiedLabels addObject:[NSString stringWithFormat:@"%lu", (unsigned long)(rawIndex + 1)]];
                    rawIndex += 1;
                    break;
                }
                rawIndex += 1;
            }
            if (simplifiedLabels.count <= index) {
                [simplifiedLabels addObject:[NSString stringWithFormat:@"%lu", (unsigned long)(index + 1)]];
            }
        }
        for (NSUInteger index = 0; index < shifted.count; ++index) {
            [self drawBadgeAtCoordinate:MTCGeometryDemoCoordinateFromValue(shifted[index])
                                   text:simplifiedLabels.count > index ? simplifiedLabels[index] : [NSString stringWithFormat:@"%lu", (unsigned long)(index + 1)]
                             fillColor:MTCGeometryDemoGreenColor()
                            strokeColor:MTCGeometryDemoGreenColor()
                                   side:28.0
                                 zIndex:110];
        }
        [self showBubbleAtCoordinate:MTCGeometryDemoCoordinateFromValue(values.firstObject)
                              lines:@[@"原始点"]
                         accentColor:MTCGeometryDemoBlueColor()];
        [self showBubbleAtCoordinate:MTCGeometryDemoCoordinateFromValue(shifted.firstObject)
                              lines:@[@"抽稀后"]
                         accentColor:MTCGeometryDemoGreenColor()];
    }

    NSString *rawText = [NSString stringWithFormat:@"蓝圆=原始点 %lu 个（带 index）", (unsigned long)values.count];
    NSString *keepText = [NSString stringWithFormat:@"绿圆=抽稀后 %lu 个（对应原始 index）", (unsigned long)shifted.count];
    [self showBubbleAtCoordinate:MTCGeometryDemoCenterForCoordinates(values)
                          lines:@[rawText, keepText]
                     accentColor:MTCGeometryDemoGreenColor()];

    NSString *testDetail = @"";
    if (self.hasTestPointValue) {
        CLLocationCoordinate2D testPoint = MTCGeometryDemoCoordinateFromValue(self.testPointValue);
        BOOL onPath = MTCGeometryIsLocationOnPath(testPoint, rawPath, YES, MTCGeometryDemoPathTestToleranceMeters);
        NSInteger index = MTCGeometryLocationIndexOnPath(testPoint, rawPath, YES, MTCGeometryDemoPathTestToleranceMeters);
        [self drawBadgeAtCoordinate:testPoint
                               text:@"测"
                         fillColor:MTCGeometryDemoPurpleColor()
                        strokeColor:MTCGeometryDemoPurpleColor()
                               side:28.0
                             zIndex:130];
        [self showBubbleAtCoordinate:testPoint
                              lines:@[[NSString stringWithFormat:@"是否在路径上 = %@", onPath ? @"true" : @"false"],
                                     [NSString stringWithFormat:@"段索引 = %ld", (long)index]]
                         accentColor:MTCGeometryDemoPurpleColor()];
        testDetail = [NSString stringWithFormat:@"；测试点 onPath=%@ index=%ld", onPath ? @"true" : @"false", (long)index];
    }

    CLLocationDistance rawLength = MTCGeometryComputeLength(rawPath);
    NSString *simplifyText = [NSString stringWithFormat:@"%lu → %lu", (unsigned long)values.count, (unsigned long)shifted.count];
    [self updatePanelResult:[NSString stringWithFormat:@"Simplify = %@", simplifyText] detail:[NSString stringWithFormat:@"原路径长度 = %@；容差 = %@%@", MTCGeometryDemoDistanceText(rawLength), MTCGeometryDemoDistanceText(tolerance), testDetail]];
    return [NSString stringWithFormat:@"路径 · Simplify = %@", simplifyText];
}

- (NSString *)drawClosedSegmentIndexMode {
    NSArray<NSValue *> *values = self.pathRawPoints.copy;
    if (values.count == 0) {
        [self updatePanelResult:@"点击地图添加路径点" detail:@"closed 默认开，支持含闭合边"];
        return @"闭合段索引 · 点击地图添加路径点";
    }

    BOOL closed = self.closedSwitch.isOn;
    [self drawPathFromCoordinates:values strokeColor:MTCGeometryDemoBlueColor() width:5.0];
    for (NSUInteger index = 0; index < values.count; ++index) {
        [self drawBadgeAtCoordinate:MTCGeometryDemoCoordinateFromValue(values[index])
                               text:@" "
                         fillColor:MTCGeometryDemoBlueColor()
                        strokeColor:MTCGeometryDemoBlueColor()
                               side:18.0
                             zIndex:100];
    }
    if (closed && values.count >= 2) {
        [self drawLineFromCoordinates:@[values.lastObject, values.firstObject] strokeColor:MTCGeometryDemoOrangeColor() width:6.0];
        [self drawBadgeAtCoordinate:MTCGeometryDemoCoordinateFromValue(values.firstObject) text:@"闭合边" fillColor:MTCGeometryDemoOrangeColor() strokeColor:MTCGeometryDemoOrangeColor() side:60.0 zIndex:120];
    }

    if (self.hasTestPointValue) {
        CLLocationCoordinate2D testPoint = MTCGeometryDemoCoordinateFromValue(self.testPointValue);
        NSInteger index = MTCGeometryLocationIndexOnEdgeOrPath(testPoint, MTCGeometryDemoPathFromCoordinates(values), closed, YES, MTCGeometryDemoPathTestToleranceMeters);
        [self drawBadgeAtCoordinate:testPoint text:@"测" fillColor:MTCGeometryDemoPurpleColor() strokeColor:MTCGeometryDemoPurpleColor() side:28.0 zIndex:120];
        [self showBubbleAtCoordinate:testPoint lines:@[[NSString stringWithFormat:@"段索引 = %ld", (long)index]] accentColor:MTCGeometryDemoPurpleColor()];
        [self updatePanelResult:[NSString stringWithFormat:@"Index = %ld", (long)index] detail:[NSString stringWithFormat:@"closed = %@", closed ? @"YES" : @"NO"]];
        return [NSString stringWithFormat:@"闭合段索引 · Index = %ld", (long)index];
    }

    [self updatePanelResult:@"Index = -1" detail:[NSString stringWithFormat:@"closed = %@", closed ? @"YES" : @"NO"]];
    [self showBubbleAtCoordinate:MTCGeometryDemoCenterForCoordinates(values)
                          lines:@[@"点击地图添加测试点", closed ? @"含闭合边 = true" : @"含闭合边 = false"]
                     accentColor:MTCGeometryDemoBlueColor()];
    return [NSString stringWithFormat:@"闭合段索引 · closed = %@", closed ? @"YES" : @"NO"];
}

- (NSString *)drawPointToLineMode {
    if (self.geometryPoints.count == 0) {
        [self updatePanelResult:@"依次点：S → E → P" detail:@"第三点为待测点，第四点会重来"];
        return @"点到线段 · 依次点：S → E → P";
    }
    if (self.geometryPoints.count >= 2) {
        [self drawLineFromCoordinates:@[self.geometryPoints[0], self.geometryPoints[1]]
                          strokeColor:MTCGeometryDemoBlueColor()
                                width:5.0];
    }
    NSArray<NSString *> *labels = @[@"S", @"E", @"P"];
    NSArray<UIColor *> *colors = @[MTCGeometryDemoBlueColor(), MTCGeometryDemoBlueColor(), MTCGeometryDemoOrangeColor()];
    for (NSUInteger index = 0; index < self.geometryPoints.count && index < 3; ++index) {
        [self drawBadgeAtCoordinate:MTCGeometryDemoCoordinateFromValue(self.geometryPoints[index])
                               text:labels[index]
                         fillColor:colors[index]
                        strokeColor:colors[index]
                               side:index == 2 ? 30.0 : MTCGeometryDemoBadgeSide
                             zIndex:120];
    }
    if (self.geometryPoints.count == 3) {
        CLLocationCoordinate2D point = MTCGeometryDemoCoordinateFromValue(self.geometryPoints[2]);
        CLLocationCoordinate2D start = MTCGeometryDemoCoordinateFromValue(self.geometryPoints[0]);
        CLLocationCoordinate2D end = MTCGeometryDemoCoordinateFromValue(self.geometryPoints[1]);
        double projectionRatio = 0.0;
        (void)MTCGeometryDemoClosestCoordinateOnSegment(point, start, end, &projectionRatio);
        CLLocationCoordinate2D projected = CLLocationCoordinate2DMake(start.latitude + (end.latitude - start.latitude) * projectionRatio,
                                                                       start.longitude + (end.longitude - start.longitude) * projectionRatio);
        BOOL projectionOutsideSegment = projectionRatio < 0.0 || projectionRatio > 1.0;
        CLLocationDistance distance = MTCGeometryDistanceToLine(point, start, end);
        [self drawLineFromCoordinates:@[self.geometryPoints[2], MTCGeometryDemoValueFromCoordinate(projected)]
                          strokeColor:MTCGeometryDemoOrangeColor()
                                width:5.0];
        if (projectionOutsideSegment) {
            CLLocationCoordinate2D extensionStart = projectionRatio < 0.0 ? start : end;
            [self drawLineFromCoordinates:@[MTCGeometryDemoValueFromCoordinate(extensionStart),
                                            MTCGeometryDemoValueFromCoordinate(projected)]
                              strokeColor:MTCGeometryDemoGreenColor()
                                    width:4.0
                                dashArray:@[@8.0, @6.0]];
        }
        [self showBubbleAtCoordinate:point
                              lines:@[[NSString stringWithFormat:@"点到线段垂距 %@", MTCGeometryDemoDistanceText(distance)]]
                         accentColor:MTCGeometryDemoOrangeColor()];
        [self updatePanelResult:[NSString stringWithFormat:@"Distance = %@", MTCGeometryDemoDistanceText(distance)]
                         detail:projectionOutsideSegment ? @"P 的垂足已超出线段，已显示延长虚线" : @"P 到 S-E 的垂距"];
        return [NSString stringWithFormat:@"点到线段 · Distance = %@", MTCGeometryDemoDistanceText(distance)];
    }
    [self updatePanelResult:[NSString stringWithFormat:@"已 %lu 点", (unsigned long)self.geometryPoints.count] detail:@"继续点到 P 完成"];
    return [NSString stringWithFormat:@"点到线段 · 已 %lu 点", (unsigned long)self.geometryPoints.count];
}

- (NSString *)drawIsClosedMode {
    NSArray<NSValue *> *values = self.pathRawPoints.copy;
    if (values.count == 0) {
        [self updatePanelResult:@"点击地图连续加点" detail:@"首尾坐标相等才算闭合"];
        return @"是否闭合 · 点击地图连续加点";
    }

    BOOL isClosed = MTCGeometryIsClosedPolygon(MTCGeometryDemoPathFromCoordinates(values));
    [self drawPathFromCoordinates:values strokeColor:MTCGeometryDemoBlueColor() width:5.0];
    [self drawPointsWithLabels:nil colors:nil zIndex:100];
    if (!isClosed && values.count >= 3) {
        [self drawCircleAtCoordinate:MTCGeometryDemoCoordinateFromValue(values.firstObject)
                              radius:MTCGeometryDemoClosedSnapRadiusMeters
                           fillColor:MTCGeometryDemoGreenColor()
                         strokeColor:MTCGeometryDemoGreenColor()
                              zIndex:90];
    } else if (isClosed) {
        [self drawPolygonWithCoordinates:values fillColor:MTCGeometryDemoGreenColor() fillOpacity:0.24 strokeColor:MTCGeometryDemoGreenColor() width:2.0];
    }

    if (isClosed && values.count >= 2) {
        self.closedPolygonCommitted = YES;
    }

    [self updatePanelResult:[NSString stringWithFormat:@"isClosedPolygon = %@", isClosed ? @"true" : @"false"]
                     detail:[NSString stringWithFormat:@"点数 = %lu", (unsigned long)values.count]];
    [self showBubbleAtCoordinate:MTCGeometryDemoCenterForCoordinates(values)
                          lines:@[[NSString stringWithFormat:@"isClosedPolygon = %@", isClosed ? @"true" : @"false"],
                                 isClosed ? @"首尾坐标相等" : @"继续加点…"]
                     accentColor:isClosed ? MTCGeometryDemoGreenColor() : MTCGeometryDemoRedColor()];
    return [NSString stringWithFormat:@"是否闭合 · isClosedPolygon = %@", isClosed ? @"true" : @"false"];
}

- (NSString *)drawEncodingMode {
    NSArray<NSValue *> *values = self.pathRawPoints.copy;
    MTCPath *path = MTCGeometryDemoPathFromCoordinates(values);
    NSString *encoded = [path encodedPath];
    MTCPath *decoded = [MTCPath pathFromEncodedPath:encoded ?: @""];
    NSUInteger decodedCount = decoded.count;
    [self drawPathFromCoordinates:values strokeColor:MTCGeometryDemoBlueColor() width:5.0];
    [self drawPointsWithLabels:nil colors:nil zIndex:100];
    [self updatePanelResult:[NSString stringWithFormat:@"Encoded = %@", MTCGeometryDemoTruncatedText(encoded ?: @"", 120)]
                     detail:[NSString stringWithFormat:@"Decoded 点数 = %lu", (unsigned long)decodedCount]];
    self.panelEncodedLabel.text = [NSString stringWithFormat:@"Encoded 串：%@", encoded ?: @""];
    self.panelDecodedLabel.text = [NSString stringWithFormat:@"Decoded 点数：%lu", (unsigned long)decodedCount];
    if (values.count > 0) {
        [self showBubbleAtCoordinate:MTCGeometryDemoCenterForCoordinates(values)
                              lines:@[[NSString stringWithFormat:@"Encoded %@", MTCGeometryDemoTruncatedText(encoded ?: @"", 72)],
                                     [NSString stringWithFormat:@"Decoded = %lu", (unsigned long)decodedCount]]
                         accentColor:MTCGeometryDemoBlueColor()];
    }
    return [NSString stringWithFormat:@"编解码 · Decoded = %lu", (unsigned long)decodedCount];
}

#pragma mark - Drawing helpers

- (void)drawPointsWithLabels:(NSArray<NSString *> *)labels colors:(NSArray<UIColor *> *)colors zIndex:(NSInteger)zIndex {
    NSArray<NSValue *> *points = nil;
    if (self.selectedSection == MTCGeometryDemoTopSectionPath ||
        self.selectedSection == MTCGeometryDemoTopSectionEncoding ||
        (self.selectedSection == MTCGeometryDemoTopSectionPath && self.selectedChipIndex == MTCGeometryDemoPathChipPath)) {
        points = self.pathRawPoints.copy;
    } else {
        points = self.geometryPoints.copy;
    }
    for (NSUInteger index = 0; index < points.count; ++index) {
        NSString *label = (labels.count > index) ? labels[index] : @"";
        UIColor *color = (colors.count > index) ? colors[index] : MTCGeometryDemoBlueColor();
        [self drawBadgeAtCoordinate:MTCGeometryDemoCoordinateFromValue(points[index])
                               text:label.length > 0 ? label : @" "
                         fillColor:color
                        strokeColor:color
                               side:label.length > 0 ? 28.0 : 18.0
                             zIndex:zIndex];
    }
}

- (void)drawBadgeAtCoordinate:(CLLocationCoordinate2D)coordinate
                         text:(NSString *)text
                    fillColor:(UIColor *)fillColor
                   strokeColor:(UIColor *)strokeColor
                         side:(CGFloat)side
                       zIndex:(NSInteger)zIndex {
    [self.mapView addOverlay:MTCGeometryDemoBadgeMarker(coordinate, text, fillColor, strokeColor, side, zIndex)];
}

- (void)drawLineFromCoordinates:(NSArray<NSValue *> *)values strokeColor:(UIColor *)strokeColor width:(CGFloat)width {
    [self drawLineFromCoordinates:values strokeColor:strokeColor width:width dashArray:nil];
}

- (void)drawLineFromCoordinates:(NSArray<NSValue *> *)values
                    strokeColor:(UIColor *)strokeColor
                          width:(CGFloat)width
                      dashArray:(NSArray<NSNumber *> *)dashArray {
    if (values.count < 2) {
        return;
    }
    [self.mapView addOverlay:MTCGeometryDemoPolylineWithDashArray(values, strokeColor, width, 20, dashArray)];
}

- (void)drawPathFromCoordinates:(NSArray<NSValue *> *)values strokeColor:(UIColor *)strokeColor width:(CGFloat)width {
    [self drawLineFromCoordinates:values strokeColor:strokeColor width:width];
}

- (void)drawPolygonWithCoordinates:(NSArray<NSValue *> *)values
                          fillColor:(UIColor *)fillColor
                        fillOpacity:(CGFloat)fillOpacity
                        strokeColor:(UIColor *)strokeColor
                              width:(CGFloat)width {
    if (values.count < 3) {
        return;
    }
    MTCPolygon *polygon = MTCGeometryDemoPolygon(values, fillColor, fillOpacity, strokeColor, width, 30);
    [self.mapView addOverlay:polygon];
}

- (void)drawCircleAtCoordinate:(CLLocationCoordinate2D)coordinate
                        radius:(CLLocationDistance)radius
                     fillColor:(UIColor *)fillColor
                   strokeColor:(UIColor *)strokeColor
                        zIndex:(NSInteger)zIndex {
    [self.mapView addOverlay:MTCGeometryDemoCircle(coordinate, radius, fillColor, strokeColor, zIndex)];
}

- (MTCFloatInfoWindowOptions *)bubbleOptionsAtCoordinate:(CLLocationCoordinate2D)coordinate
                                                   lines:(NSArray<NSString *> *)lines
                                             accentColor:(UIColor *)accentColor {
    MTCFloatInfoWindowOptions *options = [[MTCFloatInfoWindowOptions alloc] init];
    options.coordinate = coordinate;
    options.contentView = MTCGeometryDemoBubbleView(lines, accentColor);
    options.visible = YES;
    options.autoCloseOnMapTap = NO;
    options.anchor = MTCFloatInfoWindowAnchorBottom;
    options.contentOffset = CGPointMake(0.0, -10.0);
    return options;
}

- (MTCFloatInfoWindow *)showBubbleAtCoordinate:(CLLocationCoordinate2D)coordinate
                                         lines:(NSArray<NSString *> *)lines
                                   accentColor:(UIColor *)accentColor {
    MTCFloatInfoWindowOptions *options = [self bubbleOptionsAtCoordinate:coordinate
                                                                   lines:lines
                                                             accentColor:accentColor];
    return [self.mapView addInfoWindow:options];
}

- (void)showStatusHint:(NSString *)text {
    self.hintPillLabel.text = text;
}

- (void)showGeometryError:(NSString *)message {
    self.pendingErrorHint = message;
    [MTCExampleToastView showMessage:message inView:self.view];
}

- (NSArray<NSString *> *)numberedLabelsForCount:(NSUInteger)count {
    NSMutableArray<NSString *> *labels = [NSMutableArray arrayWithCapacity:count];
    for (NSUInteger index = 0; index < count; ++index) {
        [labels addObject:[NSString stringWithFormat:@"%lu", (unsigned long)(index + 1)]];
    }
    return labels;
}

- (NSArray<UIColor *> *)repeatedColors:(UIColor *)color count:(NSUInteger)count {
    NSMutableArray<UIColor *> *colors = [NSMutableArray arrayWithCapacity:count];
    for (NSUInteger index = 0; index < count; ++index) {
        [colors addObject:color];
    }
    return colors;
}

#pragma mark - Panel sync

- (void)syncPanelState {
    switch (self.selectedSection) {
        case MTCGeometryDemoTopSectionSphere:
            switch ((MTCGeometryDemoSphereChip)self.selectedChipIndex) {
                case MTCGeometryDemoSphereChipDistance:
                    self.panelModeLabel.text = @"球面几何 · 测距";
                    self.panelApiLabel.text = @"API：MTCGeometryComputeDistanceBetween / MTCGeometryComputeHeading";
                    self.panelNoteLabel.text = @"本模式单独占用地图，不与其他能力叠加。";
                    break;
                case MTCGeometryDemoSphereChipAngle:
                    self.panelModeLabel.text = @"球面几何 · 夹角";
                    self.panelApiLabel.text = @"API：MTCGeometryComputeAngleBetween / MTCGeometryComputeHeading";
                    self.panelNoteLabel.text = @"本模式单独占用地图，不与其他能力叠加。";
                    break;
                case MTCGeometryDemoSphereChipArea:
                    self.panelModeLabel.text = @"球面几何 · 面积";
                    self.panelApiLabel.text = @"API：MTCGeometryComputeArea / MTCGeometryContainsLocation / MTCGeometryIsLocationOnEdge";
                    self.panelNoteLabel.text = @"本模式单独占用地图，不与其他能力叠加。";
                    break;
                case MTCGeometryDemoSphereChipSignedArea:
                    self.panelModeLabel.text = @"球面几何 · 带符号面积";
                    self.panelApiLabel.text = @"API：MTCGeometryComputeSignedArea";
                    self.panelNoteLabel.text = @"本模式单独占用地图，不与其他能力叠加。";
                    break;
                case MTCGeometryDemoSphereChipOffset:
                    self.panelModeLabel.text = @"球面几何 · 偏移";
                    self.panelApiLabel.text = @"API：MTCGeometryComputeOffset";
                    self.panelNoteLabel.text = @"本模式单独占用地图，不与其他能力叠加。";
                    break;
                case MTCGeometryDemoSphereChipReverseOrigin:
                    self.panelModeLabel.text = @"球面几何 · 反推原点";
                    self.panelApiLabel.text = @"API：MTCGeometryComputeOffsetOrigin";
                    self.panelNoteLabel.text = @"本模式单独占用地图，不与其他能力叠加。";
                    break;
                case MTCGeometryDemoSphereChipInterpolate:
                    self.panelModeLabel.text = @"球面几何 · 插值";
                    self.panelApiLabel.text = @"API：MTCGeometryInterpolate";
                    self.panelNoteLabel.text = @"本模式单独占用地图，不与其他能力叠加。";
                    break;
            }
            break;
        case MTCGeometryDemoTopSectionPath:
            switch ((MTCGeometryDemoPathChip)self.selectedChipIndex) {
                case MTCGeometryDemoPathChipPath:
                    self.panelModeLabel.text = @"路径多边形 · 路径";
                    self.panelApiLabel.text = @"API：MTCGeometryComputeLength / MTCGeometrySimplify";
                    self.panelNoteLabel.text = @"本模式单独占用地图，不与其他能力叠加。";
                    break;
                case MTCGeometryDemoPathChipClosedSegmentIndex:
                    self.panelModeLabel.text = @"路径多边形 · 闭合段索引";
                    self.panelApiLabel.text = @"API：MTCGeometryLocationIndexOnEdgeOrPath";
                    self.panelNoteLabel.text = @"本模式单独占用地图，不与其他能力叠加。";
                    break;
                case MTCGeometryDemoPathChipPointToLine:
                    self.panelModeLabel.text = @"路径多边形 · 点到线段";
                    self.panelApiLabel.text = @"API：MTCGeometryDistanceToLine";
                    self.panelNoteLabel.text = @"本模式单独占用地图，不与其他能力叠加。";
                    break;
                case MTCGeometryDemoPathChipIsClosed:
                    self.panelModeLabel.text = @"路径多边形 · 是否闭合";
                    self.panelApiLabel.text = @"API：MTCGeometryIsClosedPolygon";
                    self.panelNoteLabel.text = @"本模式单独占用地图，不与其他能力叠加。";
                    break;
            }
            break;
        case MTCGeometryDemoTopSectionEncoding:
            self.panelModeLabel.text = @"编码 · 编解码";
            self.panelApiLabel.text = @"API：[MTCPath encodedPath] / [MTCPath pathFromEncodedPath:]";
            self.panelNoteLabel.text = @"本模式单独占用地图，不与其他能力叠加。";
            break;
    }
    self.panelTitleLabel.text = @"配置面板";
    self.hintPillLabel.text = [self hintTextForCurrentMode];
    [self updatePanelVisibility];
    [self updatePanelValues];
    [self refreshSettingsSheetIfVisible];
}

- (NSString *)hintTextForCurrentMode {
    switch (self.selectedSection) {
        case MTCGeometryDemoTopSectionSphere:
            switch ((MTCGeometryDemoSphereChip)self.selectedChipIndex) {
                case MTCGeometryDemoSphereChipDistance:
                case MTCGeometryDemoSphereChipAngle:
                    return @"👆 点击地图选择 A、B 两点";
                case MTCGeometryDemoSphereChipArea:
                    return @"👆 连续点 ≥3 个顶点围成多边形";
                case MTCGeometryDemoSphereChipSignedArea:
                    return @"👆 点 ≥3 顶点；顺序决定正负";
                case MTCGeometryDemoSphereChipOffset:
                    return @"👆 点击地图选择起点，再在配置面板调参数";
                case MTCGeometryDemoSphereChipReverseOrigin:
                    return @"👆 点击地图选择终点，再在配置面板调参数";
                case MTCGeometryDemoSphereChipInterpolate:
                    return @"👆 点击地图选择 A、B，再调插值比例";
            }
            break;
        case MTCGeometryDemoTopSectionPath:
            switch ((MTCGeometryDemoPathChip)self.selectedChipIndex) {
                case MTCGeometryDemoPathChipPath:
                    return @"👆 点击地图添加路径点";
                case MTCGeometryDemoPathChipClosedSegmentIndex:
                    return @"👆 点击地图添加路径点";
                case MTCGeometryDemoPathChipPointToLine:
                    return @"👆 依次点：线段起点 → 终点 → 待测点";
                case MTCGeometryDemoPathChipIsClosed:
                    return @"👆 先点 ≥3 顶点，再点起点绿圈或「闭合」";
            }
            break;
        case MTCGeometryDemoTopSectionEncoding:
            return @"👆 连续加点画蓝路径";
    }
    return @"";
}

- (void)updatePanelValues {
    [self updatePanelVisibility];
}

- (void)updatePanelResult:(NSString *)primary detail:(NSString *)detail {
    self.panelResultLabel.text = primary ?: @"";
    self.panelDetailLabel.text = detail ?: @"";
    [self refreshSettingsSheetIfVisible];
}

- (void)updatePanelVisibility {
    BOOL isSphere = self.selectedSection == MTCGeometryDemoTopSectionSphere;
    BOOL isPath = self.selectedSection == MTCGeometryDemoTopSectionPath;
    BOOL isEncoding = self.selectedSection == MTCGeometryDemoTopSectionEncoding;

    self.offsetDistanceSlider.superview.hidden = !(isSphere && self.selectedChipIndex == MTCGeometryDemoSphereChipOffset);
    self.offsetHeadingSlider.superview.hidden = !(isSphere && self.selectedChipIndex == MTCGeometryDemoSphereChipOffset);
    self.reverseDistanceSlider.superview.hidden = !(isSphere && self.selectedChipIndex == MTCGeometryDemoSphereChipReverseOrigin);
    self.reverseHeadingSlider.superview.hidden = !(isSphere && self.selectedChipIndex == MTCGeometryDemoSphereChipReverseOrigin);
    self.interpolateSlider.superview.hidden = !(isSphere && self.selectedChipIndex == MTCGeometryDemoSphereChipInterpolate);
    self.simplifySlider.superview.hidden = !(isPath && self.selectedChipIndex == MTCGeometryDemoPathChipPath);
    self.areaTestPointSwitch.superview.hidden = !(isSphere && self.selectedChipIndex == MTCGeometryDemoSphereChipArea);
    self.pathTestPointSwitch.superview.hidden = !(isPath && self.selectedChipIndex == MTCGeometryDemoPathChipPath);
    self.closedSegmentTestPointSwitch.superview.hidden = !(isPath && self.selectedChipIndex == MTCGeometryDemoPathChipClosedSegmentIndex);
    self.closedSwitch.superview.hidden = !(isPath && self.selectedChipIndex == MTCGeometryDemoPathChipClosedSegmentIndex);
    self.signedAreaCounterClockwiseButton.superview.hidden = !(isSphere && self.selectedChipIndex == MTCGeometryDemoSphereChipSignedArea);
    self.simplifyExampleButton.superview.hidden = !(isPath && self.selectedChipIndex == MTCGeometryDemoPathChipPath);
    self.reversePoleButton.superview.hidden = !(isSphere && self.selectedChipIndex == MTCGeometryDemoSphereChipReverseOrigin);
    self.closedCommitButton.superview.hidden = !(isPath && self.selectedChipIndex == MTCGeometryDemoPathChipIsClosed);
    self.closedExampleButton.superview.hidden = !(isPath && self.selectedChipIndex == MTCGeometryDemoPathChipIsClosed);
    self.panelEncodedLabel.hidden = !isEncoding;
    self.panelDecodedLabel.hidden = !isEncoding;
    self.panelEncodedLabel.text = isEncoding ? self.panelEncodedLabel.text : @"";
    self.panelDecodedLabel.text = isEncoding ? self.panelDecodedLabel.text : @"";
    self.areaTestPointSwitch.on = self.pendingTestPointOnce && isSphere && self.selectedChipIndex == MTCGeometryDemoSphereChipArea;
    self.pathTestPointSwitch.on = self.pendingTestPointOnce && isPath && self.selectedChipIndex == MTCGeometryDemoPathChipPath;
    self.closedSegmentTestPointSwitch.on = self.pendingTestPointOnce && isPath && self.selectedChipIndex == MTCGeometryDemoPathChipClosedSegmentIndex;
    if (!(isPath && self.selectedChipIndex == MTCGeometryDemoPathChipClosedSegmentIndex)) {
        self.closedSwitch.on = NO;
    }
}

#pragma mark - Content builders

- (UIButton *)makeTabButtonWithTitle:(NSString *)title tag:(NSInteger)tag {
    UIButton *button = [UIButton buttonWithType:UIButtonTypeSystem];
    [button setTitle:title forState:UIControlStateNormal];
    button.tag = tag;
    button.titleLabel.font = [UIFont systemFontOfSize:14.0 weight:UIFontWeightSemibold];
    [button setTitleColor:UIColor.secondaryLabelColor forState:UIControlStateNormal];
    button.backgroundColor = UIColor.systemBackgroundColor;
    button.layer.cornerRadius = 8.0;
    [button addTarget:self action:@selector(handleSectionButtonTapped:) forControlEvents:UIControlEventTouchUpInside];
    return button;
}

- (UIButton *)makeChipButtonWithTitle:(NSString *)title tag:(NSInteger)tag {
    UIButton *button = [UIButton buttonWithType:UIButtonTypeSystem];
    [button setTitle:title forState:UIControlStateNormal];
    button.tag = tag;
    button.titleLabel.font = [UIFont systemFontOfSize:13.0 weight:UIFontWeightSemibold];
    button.layer.cornerRadius = 18.0;
    button.contentEdgeInsets = UIEdgeInsetsMake(0.0, 14.0, 0.0, 14.0);
    [button addTarget:self action:@selector(handleChipButtonTapped:) forControlEvents:UIControlEventTouchUpInside];
    return button;
}

- (UISlider *)makeSlider {
    UISlider *slider = [[UISlider alloc] initWithFrame:CGRectZero];
    slider.minimumTrackTintColor = MTCGeometryDemoBlueColor();
    slider.maximumTrackTintColor = UIColor.systemGray4Color;
    return slider;
}

- (UISwitch *)makeSwitch {
    UISwitch *control = [[UISwitch alloc] initWithFrame:CGRectZero];
    control.onTintColor = MTCGeometryDemoBlueColor();
    return control;
}

- (UIButton *)makeActionButtonWithTitle:(NSString *)title action:(SEL)action {
    UIButton *button = [UIButton buttonWithType:UIButtonTypeSystem];
    [button setTitle:title forState:UIControlStateNormal];
    [button setTitleColor:UIColor.whiteColor forState:UIControlStateNormal];
    button.titleLabel.font = [UIFont systemFontOfSize:13.0 weight:UIFontWeightSemibold];
    button.backgroundColor = MTCGeometryDemoBlueColor();
    button.layer.cornerRadius = 8.0;
    button.contentEdgeInsets = UIEdgeInsetsMake(0.0, 12.0, 0.0, 12.0);
    [button addTarget:self action:action forControlEvents:UIControlEventTouchUpInside];
    return button;
}

- (UIView *)makeValueSectionContainer {
    UIView *container = [[UIView alloc] initWithFrame:CGRectZero];
    return container;
}

- (void)setupResultSectionInContainer:(UIView *)container {
    UIStackView *stack = [[UIStackView alloc] initWithFrame:CGRectZero];
    stack.axis = UILayoutConstraintAxisVertical;
    stack.alignment = UIStackViewAlignmentFill;
    stack.spacing = 8.0;
    stack.translatesAutoresizingMaskIntoConstraints = NO;
    [container addSubview:stack];
    [NSLayoutConstraint activateConstraints:@[
        [stack.topAnchor constraintEqualToAnchor:container.topAnchor],
        [stack.leadingAnchor constraintEqualToAnchor:container.leadingAnchor],
        [stack.trailingAnchor constraintEqualToAnchor:container.trailingAnchor],
        [stack.bottomAnchor constraintEqualToAnchor:container.bottomAnchor],
    ]];

    [stack addArrangedSubview:self.panelResultLabel];
    [stack addArrangedSubview:self.panelDetailLabel];
    [stack addArrangedSubview:self.panelEncodedLabel];
    [stack addArrangedSubview:self.panelDecodedLabel];
}

- (UIView *)makeLabelPairRowTitle:(NSString *)title slider:(UISlider *)slider unitLabel:(NSString *)unitLabel {
    UIStackView *stack = [[UIStackView alloc] initWithFrame:CGRectZero];
    stack.axis = UILayoutConstraintAxisVertical;
    stack.alignment = UIStackViewAlignmentFill;
    stack.spacing = 4.0;

    UILabel *label = [[UILabel alloc] initWithFrame:CGRectZero];
    label.font = [UIFont systemFontOfSize:12.0 weight:UIFontWeightSemibold];
    label.textColor = UIColor.secondaryLabelColor;
    label.text = title;
    [stack addArrangedSubview:label];
    [stack addArrangedSubview:slider];

    UILabel *unit = [[UILabel alloc] initWithFrame:CGRectZero];
    unit.font = [UIFont systemFontOfSize:11.0 weight:UIFontWeightRegular];
    unit.textColor = UIColor.secondaryLabelColor;
    unit.text = unitLabel;
    [stack addArrangedSubview:unit];
    return stack;
}

- (UIView *)makeSwitchRowTitle:(NSString *)title switchControl:(UISwitch *)switchControl {
    UIStackView *stack = [[UIStackView alloc] initWithFrame:CGRectZero];
    stack.axis = UILayoutConstraintAxisHorizontal;
    stack.alignment = UIStackViewAlignmentCenter;
    stack.distribution = UIStackViewDistributionEqualSpacing;

    UILabel *label = [[UILabel alloc] initWithFrame:CGRectZero];
    label.font = [UIFont systemFontOfSize:12.0 weight:UIFontWeightSemibold];
    label.textColor = UIColor.secondaryLabelColor;
    label.text = title;
    [stack addArrangedSubview:label];
    [stack addArrangedSubview:switchControl];
    return stack;
}

- (UIView *)makeButtonGroupRow:(NSArray<UIButton *> *)buttons {
    UIStackView *stack = [[UIStackView alloc] initWithFrame:CGRectZero];
    stack.axis = UILayoutConstraintAxisHorizontal;
    stack.alignment = UIStackViewAlignmentFill;
    stack.distribution = UIStackViewDistributionFillEqually;
    stack.spacing = 8.0;
    for (UIButton *button in buttons) {
        [stack addArrangedSubview:button];
        [button.heightAnchor constraintEqualToConstant:36.0].active = YES;
    }
    return stack;
}

- (void)rebuildChipButtons {
    for (UIView *view in self.chipStackView.arrangedSubviews.copy) {
        [self.chipStackView removeArrangedSubview:view];
        [view removeFromSuperview];
    }
    NSMutableArray<UIButton *> *buttons = [NSMutableArray array];
    NSArray<NSString *> *titles = [self chipTitlesForCurrentSection];
    for (NSUInteger index = 0; index < titles.count; ++index) {
        UIButton *button = [self makeChipButtonWithTitle:titles[index] tag:index];
        [buttons addObject:button];
        [self.chipStackView addArrangedSubview:button];
        [button.heightAnchor constraintEqualToConstant:MTCGeometryDemoChipHeight].active = YES;
    }
    self.chipButtons = buttons;
    [self updateChipButtons];
}

- (NSArray<NSString *> *)chipTitlesForCurrentSection {
    switch (self.selectedSection) {
        case MTCGeometryDemoTopSectionSphere:
            return @[@"测距", @"夹角", @"面积", @"带符号面积", @"偏移", @"反推原点", @"插值"];
        case MTCGeometryDemoTopSectionPath:
            return @[@"路径", @"闭合段索引", @"点到线段", @"是否闭合"];
        case MTCGeometryDemoTopSectionEncoding:
            return @[@"编解码"];
    }
}

- (void)updateTopSectionButtons {
    for (UIButton *button in self.sectionButtons) {
        BOOL selected = button.tag == self.selectedSection;
        [button setTitleColor:selected ? MTCGeometryDemoBlueColor() : UIColor.secondaryLabelColor forState:UIControlStateNormal];
        button.backgroundColor = selected ? MTCGeometryDemoLightBlueColor() : UIColor.systemBackgroundColor;
    }
}

- (void)updateChipButtons {
    for (UIButton *button in self.chipButtons) {
        BOOL selected = button.tag == self.selectedChipIndex;
        [button setTitleColor:selected ? UIColor.whiteColor : UIColor.secondaryLabelColor forState:UIControlStateNormal];
        button.backgroundColor = selected ? MTCGeometryDemoBlueColor() : UIColor.secondarySystemBackgroundColor;
    }
}

- (void)applyLocalizedTexts {
    self.title = @"几何计算";
    [self rebuildChipButtons];
    [self updateTopSectionButtons];
    [self syncPanelState];
}

#pragma mark - Focus

- (void)focusOnPolygonCoordinates:(NSArray<NSValue *> *)values animated:(BOOL)animated {
    if (values.count < 3) {
        return;
    }
    MTCCoordinateBounds bounds = MTCGeometryDemoTightBoundsForCoordinates(values);
    if (MTCMapRectIsNull(MTCMapRectForCoordinateBounds(bounds))) {
        [self focusOnCoordinates:values animated:animated];
        return;
    }
    [self.mapView setVisibleCoordinateBounds:bounds
                                 edgePadding:UIEdgeInsetsMake(MTCGeometryDemoPolygonFocusPadding,
                                                              MTCGeometryDemoPolygonFocusPadding,
                                                              MTCGeometryDemoPolygonFocusPadding,
                                                              MTCGeometryDemoPolygonFocusPadding)
                                  transition:animated ? [MTCCameraTransition easeWithDuration:0.25] : nil
                                  completion:nil];
}

- (void)focusOnResultLineCoordinates:(NSArray<NSValue *> *)values animated:(BOOL)animated {
    if (values.count < 2) {
        return;
    }
    MTCCoordinateBounds bounds = MTCGeometryDemoBoundsByEnsuringMinimumSpan(MTCGeometryDemoTightBoundsForCoordinates(values),
                                                                            MTCGeometryDemoLineMinimumFocusSpan);
    if (MTCMapRectIsNull(MTCMapRectForCoordinateBounds(bounds))) {
        [self focusOnCoordinates:values animated:animated];
        return;
    }
    [self.mapView setVisibleCoordinateBounds:bounds
                                 edgePadding:UIEdgeInsetsMake(MTCGeometryDemoLineFocusPadding,
                                                              MTCGeometryDemoLineFocusPadding,
                                                              MTCGeometryDemoLineFocusPadding,
                                                              MTCGeometryDemoLineFocusPadding)
                                  transition:animated ? [MTCCameraTransition easeWithDuration:0.25] : nil
                                  completion:nil];
}

- (void)focusOnCoordinates:(NSArray<NSValue *> *)values animated:(BOOL)animated {
    if (values.count == 0) {
        return;
    }
    MTCCoordinateBounds bounds = MTCGeometryDemoBoundsForCoordinates(values);
    if (!MTCMapRectIsNull(MTCMapRectForCoordinateBounds(bounds))) {
        [self.mapView setVisibleCoordinateBounds:bounds
                                     edgePadding:UIEdgeInsetsMake(MTCGeometryDemoResultPaddingMeters, MTCGeometryDemoResultPaddingMeters, MTCGeometryDemoResultPaddingMeters, MTCGeometryDemoResultPaddingMeters)
                                      transition:animated ? [MTCCameraTransition easeWithDuration:0.25] : nil
                                      completion:nil];
        return;
    }
    CLLocationCoordinate2D center = MTCGeometryDemoCoordinateFromValue(values.firstObject);
    if (animated) {
        [self.mapView setCenterCoordinate:center
                               transition:[MTCCameraTransition easeWithDuration:0.25]
                               completion:nil];
    } else {
        [self.mapView setCenterCoordinate:center zoomLevel:MTCGeometryDemoInitialZoomLevel];
    }
}

#pragma mark - Example fill

- (void)fillSignedAreaExampleCounterClockwise:(BOOL)counterClockwise {
    CLLocationCoordinate2D base = MTCGeometryDemoCoordinateMake(1.3470, 103.8215);
    CLLocationCoordinate2D east = MTCGeometryComputeOffset(base, 300.0, 90.0);
    CLLocationCoordinate2D north = MTCGeometryComputeOffset(base, 300.0, 0.0);
    [self.geometryPoints removeAllObjects];
    if (counterClockwise) {
        [self.geometryPoints addObject:MTCGeometryDemoValueFromCoordinate(base)];
        [self.geometryPoints addObject:MTCGeometryDemoValueFromCoordinate(east)];
        [self.geometryPoints addObject:MTCGeometryDemoValueFromCoordinate(north)];
    } else {
        [self.geometryPoints addObject:MTCGeometryDemoValueFromCoordinate(base)];
        [self.geometryPoints addObject:MTCGeometryDemoValueFromCoordinate(north)];
        [self.geometryPoints addObject:MTCGeometryDemoValueFromCoordinate(east)];
    }
    self.shouldFocusAfterRedraw = YES;
}

- (void)fillSimplifyExample {
    CLLocationCoordinate2D base = MTCGeometryDemoCoordinateMake(1.3435, 103.8175);
    CLLocationCoordinate2D east200 = MTCGeometryComputeOffset(base, 200.0, 90.0);
    CLLocationCoordinate2D east400 = MTCGeometryComputeOffset(base, 400.0, 90.0);
    CLLocationCoordinate2D east600 = MTCGeometryComputeOffset(base, 600.0, 90.0);
    CLLocationCoordinate2D north200 = MTCGeometryComputeOffset(east600, 200.0, 0.0);
    CLLocationCoordinate2D north400 = MTCGeometryComputeOffset(east600, 400.0, 0.0);
    CLLocationCoordinate2D north600 = MTCGeometryComputeOffset(east600, 600.0, 0.0);
    CLLocationCoordinate2D north800 = MTCGeometryComputeOffset(east600, 800.0, 0.0);
    NSArray<NSValue *> *values = @[
        MTCGeometryDemoValueFromCoordinate(base),
        MTCGeometryDemoValueFromCoordinate(MTCGeometryComputeOffset(east200, 12.0, 8.0)),
        MTCGeometryDemoValueFromCoordinate(MTCGeometryComputeOffset(east400, 10.0, 356.0)),
        MTCGeometryDemoValueFromCoordinate(east600),
        MTCGeometryDemoValueFromCoordinate(MTCGeometryComputeOffset(north200, 8.0, 92.0)),
        MTCGeometryDemoValueFromCoordinate(MTCGeometryComputeOffset(north400, 10.0, 2.0)),
        MTCGeometryDemoValueFromCoordinate(MTCGeometryComputeOffset(north600, 12.0, 358.0)),
        MTCGeometryDemoValueFromCoordinate(MTCGeometryComputeOffset(north800, 10.0, 0.0)),
    ];
    [self.pathRawPoints removeAllObjects];
    [self.pathRawPoints addObjectsFromArray:values];
    self.simplifySlider.value = 55.0;
    self.shouldFocusAfterRedraw = YES;
}

- (void)fillReverseOriginPoleExample {
    [self.geometryPoints removeAllObjects];
    [self.geometryPoints addObject:MTCGeometryDemoValueFromCoordinate(MTCGeometryDemoCoordinateMake(90.0, 0.0))];
    self.reverseDistanceSlider.value = 1000.0;
    self.reverseHeadingSlider.value = 90.0;
    self.shouldFocusAfterRedraw = NO;
}

- (void)fillClosedPolygonExample {
    CLLocationCoordinate2D base = MTCGeometryDemoCoordinateMake(1.3490, 103.8250);
    CLLocationCoordinate2D b = MTCGeometryComputeOffset(base, 300.0, 90.0);
    CLLocationCoordinate2D c = MTCGeometryComputeOffset(base, 300.0, 0.0);
    [self.pathRawPoints removeAllObjects];
    [self.pathRawPoints addObject:MTCGeometryDemoValueFromCoordinate(base)];
    [self.pathRawPoints addObject:MTCGeometryDemoValueFromCoordinate(b)];
    [self.pathRawPoints addObject:MTCGeometryDemoValueFromCoordinate(c)];
    [self.pathRawPoints addObject:MTCGeometryDemoValueFromCoordinate(base)];
    self.closedPolygonCommitted = YES;
    self.shouldFocusAfterRedraw = YES;
}

#pragma mark - Default control values

- (void)seedDefaultPanelValues {
    self.offsetDistanceSlider.minimumValue = 50.0;
    self.offsetDistanceSlider.maximumValue = 2000.0;
    self.offsetDistanceSlider.value = 500.0;
    self.offsetHeadingSlider.minimumValue = 0.0;
    self.offsetHeadingSlider.maximumValue = 360.0;
    self.offsetHeadingSlider.value = 45.0;

    self.reverseDistanceSlider.minimumValue = 100.0;
    self.reverseDistanceSlider.maximumValue = 20000.0;
    self.reverseDistanceSlider.value = 5000.0;
    self.reverseHeadingSlider.minimumValue = 0.0;
    self.reverseHeadingSlider.maximumValue = 360.0;
    self.reverseHeadingSlider.value = 45.0;

    self.interpolateSlider.minimumValue = 0.0;
    self.interpolateSlider.maximumValue = 1.0;
    self.interpolateSlider.value = 0.5;

    self.simplifySlider.minimumValue = 1.0;
    self.simplifySlider.maximumValue = 120.0;
    self.simplifySlider.value = 30.0;

    self.closedSwitch.on = YES;
}

@end
