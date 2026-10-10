//
//  MTCTextSearchRequestParams+MTCSupportFork.m
//  MaptecMapsExample
//
//  Created by ZHOUPanpan on 2026/7/14.
//

#import "MTCTextSearchRequestParams+MTCSupportFork.h"

@implementation MTCCoordinate (MTCSupportFork)

+ (instancetype)mtc_coordinateFromString:(NSString *)string {
    NSArray<NSString *> *parts = [string componentsSeparatedByString:@","];
    if (parts.count != 2) {
        return nil;
    }
    NSString *latitudeString = [parts.firstObject stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceCharacterSet];
    NSString *longitudeString = [parts.lastObject stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceCharacterSet];
    if (latitudeString.length == 0 || longitudeString.length == 0) {
        return nil;
    }
    return [[self alloc] initWithLatitude:latitudeString.doubleValue longitude:longitudeString.doubleValue];
}

@end

@implementation MTCLocationRectangle (MTCSupportFork)

+ (instancetype)mtc_currentRectangleWithNorthEastText:(NSString *)northEastText
                                        southWestText:(NSString *)southWestText {
    MTCCoordinate *northEast = [MTCCoordinate mtc_coordinateFromString:northEastText];
    MTCCoordinate *southWest = [MTCCoordinate mtc_coordinateFromString:southWestText];
    if (!northEast || !southWest) {
        return nil;
    }
    return [[self alloc] initWithNortheast:northEast southwest:southWest];
}

@end

@implementation MTCLocationCircle (MTCSupportFork)

+ (instancetype)mtc_currentCircleWithCenterText:(NSString *)centerText
                                     radiusText:(NSString *)radiusText {
    MTCCoordinate *center = [MTCCoordinate mtc_coordinateFromString:centerText];
    NSString *trimmedRadius = [radiusText stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceAndNewlineCharacterSet];
    if (!center || trimmedRadius.length == 0) {
        return nil;
    }
    NSScanner *scanner = [NSScanner scannerWithString:trimmedRadius];
    NSInteger radius = 0;
    if (![scanner scanInteger:&radius] || !scanner.isAtEnd || radius < 0 || radius > 50000) {
        return nil;
    }
    return [[self alloc] initWithCenter:center radius:radius];
}

@end

@implementation MTCLocationBias (MTCSupportFork)

+ (instancetype)mtc_currentLocationBiasWithMode:(MTCWebLocationMode)locationMode
                                  northEastText:(NSString *)northEastText
                                  southWestText:(NSString *)southWestText
                                     centerText:(NSString *)centerText
                                     radiusText:(NSString *)radiusText {
    switch (locationMode) {
        case MTCWebLocationModeBiasRectangle: {
            MTCLocationRectangle *rectangle = [MTCLocationRectangle mtc_currentRectangleWithNorthEastText:northEastText
                                                                                            southWestText:southWestText];
            return rectangle ? [self biasWithRectangle:rectangle] : nil;
        }
        case MTCWebLocationModeBiasCircle: {
            MTCLocationCircle *circle = [MTCLocationCircle mtc_currentCircleWithCenterText:centerText radiusText:radiusText];
            return circle ? [self biasWithCircle:circle] : nil;
        }
        default:
            return nil;
    }
}

@end

@implementation MTCLocationLimit (MTCSupportFork)

+ (instancetype)mtc_currentLocationLimitWithMode:(MTCWebLocationMode)locationMode
                                   northEastText:(NSString *)northEastText
                                   southWestText:(NSString *)southWestText
                                      centerText:(NSString *)centerText
                                      radiusText:(NSString *)radiusText {
    switch (locationMode) {
        case MTCWebLocationModeLimitRectangle: {
            MTCLocationRectangle *rectangle = [MTCLocationRectangle mtc_currentRectangleWithNorthEastText:northEastText
                                                                                            southWestText:southWestText];
            return rectangle ? [self limitWithRectangle:rectangle] : nil;
        }
        case MTCWebLocationModeLimitCircle: {
            MTCLocationCircle *circle = [MTCLocationCircle mtc_currentCircleWithCenterText:centerText radiusText:radiusText];
            return circle ? [self limitWithCircle:circle] : nil;
        }
        default:
            return nil;
    }
}

@end
