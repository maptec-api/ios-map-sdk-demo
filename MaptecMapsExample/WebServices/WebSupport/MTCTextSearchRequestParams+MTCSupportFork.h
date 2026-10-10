//
//  MTCTextSearchRequestParams+MTCSupportFork.h
//  MaptecMapsExample
//
//  Created by ZHOUPanpan on 2026/7/14.
//

#import <Foundation/Foundation.h>

#import <MaptecMapsKit/MaptecMapsKit.h>
#import <MaptecSearchKit/MaptecSearchKit.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSInteger, MTCWebLocationMode) {
    MTCWebLocationModeNone = 0,
    MTCWebLocationModeBiasRectangle,
    MTCWebLocationModeBiasCircle,
    MTCWebLocationModeLimitRectangle,
    MTCWebLocationModeLimitCircle,
};

@interface MTCCoordinate (MTCSupportFork)

+ (nullable instancetype)mtc_coordinateFromString:(NSString *)string;

@end

@interface MTCLocationRectangle (MTCSupportFork)

+ (nullable instancetype)mtc_currentRectangleWithNorthEastText:(NSString *)northEastText
                                                 southWestText:(NSString *)southWestText;

@end

@interface MTCLocationCircle (MTCSupportFork)

+ (nullable instancetype)mtc_currentCircleWithCenterText:(NSString *)centerText
                                              radiusText:(NSString *)radiusText;

@end

@interface MTCLocationBias (MTCSupportFork)

+ (nullable instancetype)mtc_currentLocationBiasWithMode:(MTCWebLocationMode)locationMode
                                           northEastText:(NSString *)northEastText
                                           southWestText:(NSString *)southWestText
                                              centerText:(NSString *)centerText
                                              radiusText:(NSString *)radiusText;

@end

@interface MTCLocationLimit (MTCSupportFork)

+ (nullable instancetype)mtc_currentLocationLimitWithMode:(MTCWebLocationMode)locationMode
                                            northEastText:(NSString *)northEastText
                                            southWestText:(NSString *)southWestText
                                               centerText:(NSString *)centerText
                                               radiusText:(NSString *)radiusText;

@end


NS_ASSUME_NONNULL_END
