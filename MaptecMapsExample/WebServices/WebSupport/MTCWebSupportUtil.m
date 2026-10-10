//
//  MTCWebSupportUtil.m
//  MaptecMapsExample
//
//  Created by ZHOUPanpan on 2026/7/14.
//

#import "MTCWebSupportUtil.h"

#import "MTCExampleDemoLocalization.h"

#import <math.h>

static void MTCAppendEncodedPolylineValue(NSMutableString *output, long long value) {
    value <<= 1;
    if (value < 0) {
        value = ~value;
    }
    while (value >= 0x20) {
        unichar c = (unichar)((0x20 | (value & 0x1f)) + 63);
        [output appendFormat:@"%C", c];
        value >>= 5;
    }
    [output appendFormat:@"%C", (unichar)(value + 63)];
}

static NSArray<MTCCoordinate *> *MTCDecodePolyline(NSString *encodedPolyline) {
    if (encodedPolyline.length == 0) {
        return @[];
    }
    NSUInteger index = 0;
    NSInteger latitude = 0;
    NSInteger longitude = 0;
    NSMutableArray<MTCCoordinate *> *coordinates = [NSMutableArray array];
    NSUInteger length = encodedPolyline.length;

    while (index < length) {
        NSInteger shift = 0;
        NSInteger result = 0;
        NSInteger byte = 0;
        do {
            if (index >= length) {
                return @[];
            }
            byte = [encodedPolyline characterAtIndex:index++] - 63;
            result |= (byte & 0x1f) << shift;
            shift += 5;
        } while (byte >= 0x20);
        NSInteger deltaLatitude = (result & 1) ? ~(result >> 1) : (result >> 1);

        shift = 0;
        result = 0;
        do {
            if (index >= length) {
                return @[];
            }
            byte = [encodedPolyline characterAtIndex:index++] - 63;
            result |= (byte & 0x1f) << shift;
            shift += 5;
        } while (byte >= 0x20);
        NSInteger deltaLongitude = (result & 1) ? ~(result >> 1) : (result >> 1);

        latitude += deltaLatitude;
        longitude += deltaLongitude;
        [coordinates addObject:[[MTCCoordinate alloc] initWithLatitude:(double)latitude / 1e5
                                                              longitude:(double)longitude / 1e5]];
    }

    return [coordinates copy];
}

static NSArray<MTCCoordinate *> *MTCParsePolylineText(NSString *text) {
    if (text.length == 0) {
        return @[];
    }
    NSCharacterSet *separatorSet = [NSCharacterSet characterSetWithCharactersInString:@";\n\r"];
    NSArray<NSString *> *segments = [text componentsSeparatedByCharactersInSet:separatorSet];
    NSMutableArray<MTCCoordinate *> *coordinates = [NSMutableArray array];
    for (NSString *segment in segments) {
        NSString *trimmed = [segment stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceAndNewlineCharacterSet];
        if (trimmed.length == 0) {
            continue;
        }
        MTCCoordinate *coordinate = [MTCCoordinate mtc_coordinateFromString:trimmed];
        if (!coordinate) {
            return @[];
        }
        [coordinates addObject:coordinate];
    }
    return [coordinates copy];
}

static NSString *MTCEncodePolylineCoordinates(NSArray<MTCCoordinate *> *coordinates) {
    if (coordinates.count == 0) {
        return nil;
    }
    NSMutableString *encodedPolyline = [NSMutableString string];
    long long previousLatitude = 0;
    long long previousLongitude = 0;
    for (MTCCoordinate *coordinate in coordinates) {
        long long latitude = llround(coordinate.latitude * 1e5);
        long long longitude = llround(coordinate.longitude * 1e5);
        long long deltaLatitude = latitude - previousLatitude;
        long long deltaLongitude = longitude - previousLongitude;
        MTCAppendEncodedPolylineValue(encodedPolyline, deltaLatitude);
        MTCAppendEncodedPolylineValue(encodedPolyline, deltaLongitude);
        previousLatitude = latitude;
        previousLongitude = longitude;
    }
    return [encodedPolyline copy];
}

@implementation MTCWebSupportUtil

#pragma mark - Public

+ (NSString *)mtc_prettyJSONStringFromDictionary:(NSDictionary *)dictionary {
    if (dictionary.count == 0) {
        return @"";
    }
    NSData *data = [NSJSONSerialization dataWithJSONObject:dictionary options:NSJSONWritingPrettyPrinted error:nil];
    return data ? [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding] : dictionary.description;
}

+ (NSArray<NSString *> *)mtc_locationModeOptions {
    return @[
        [MTCExampleDemoLocalization stringForKey:@"web_not_set" language:[MTCExampleDemoLocalization currentLanguage]],
        @"locationBias.rectangle",
        @"locationBias.circle",
        @"locationLimit.rectangle",
        @"locationLimit.circle",
    ];
}

+ (NSArray<NSString *> *)mtc_poiTypeOptions {
    static NSArray<NSString *> *options;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        options = @[[MTCExampleDemoLocalization stringForKey:@"web_not_set" language:[MTCExampleDemoLocalization currentLanguage]],
                    @"Chinese_Cuisine", @"Asian_Cuisine", @"Western_Cuisine", @"Fast_Food_Snacks", @"Cafe_Tea_Dessert", @"Bars_Nightlife",
                    @"Shopping_Centers", @"Groceries", @"Fashion_Accessories", @"Electronics", @"Home_Garden", @"Personal_Goods", @"Specialty_Retail",
                    @"Air_Travel", @"Rail_Transport", @"Bus_Coach", @"Water_Transport", @"Parking", @"Energy_Facilities",
                    @"Car_Dealers", @"Repair_Maintenance", @"Car_Rental",
                    @"Hotels", @"Alternative_Lodging", @"Outdoor_Lodging",
                    @"Cinema_Theater", @"Recreation", @"Theme_Parks", @"Wellness",
                    @"Parks_Plazas", @"Landmarks", @"Museums_Galleries", @"Religious_Places",
                    @"Stadiums", @"Fitness", @"Specific_Sports",
                    @"Hospitals", @"Clinics", @"Pharmacy_Care",
                    @"Financial", @"Post_Logistics", @"Telecom", @"Convenience", @"Business",
                    @"Government", @"Education", @"Social_Orgs",
                    @"Offices", @"Industry",
                    @"Housing",
                    @"Water_Bodies", @"Land_Features"];
    });
    return options;
}

+ (NSString *)mtc_poiTypeForIndex:(NSInteger)index {
    NSArray<NSString *> *options = [self mtc_poiTypeOptions];
    if (index <= 0 || index >= (NSInteger)options.count) {
        return @"";
    }
    return options[index];
}

+ (BOOL)mtc_usesRectangleForLocationMode:(MTCWebLocationMode)locationMode {
    return locationMode == MTCWebLocationModeBiasRectangle || locationMode == MTCWebLocationModeLimitRectangle;
}

+ (BOOL)mtc_usesCircleForLocationMode:(MTCWebLocationMode)locationMode {
    return locationMode == MTCWebLocationModeBiasCircle || locationMode == MTCWebLocationModeLimitCircle;
}

+ (NSArray<NSString *> *)mtc_placeExtraFieldOptions {
    return @[
        @"aoi",
        @"summary",
        @"openingHours",
        @"phoneNumbers",
        @"emailAddresses",
        @"websiteUris",
        @"addressComponents",
        @"timeZone",
    ];
}

+ (NSArray<NSString *> *)mtc_textSearchExtraFieldOptions {
    return [self mtc_placeExtraFieldOptions];
}

+ (NSArray<NSString *> *)mtc_extraFieldsFromText:(NSString *)text {
    NSMutableCharacterSet *set = [NSMutableCharacterSet whitespaceAndNewlineCharacterSet];
    NSArray<NSString *> *parts = [[text stringByTrimmingCharactersInSet:set] componentsSeparatedByString:@","];
    NSMutableArray<NSString *> *fields = [NSMutableArray array];
    for (NSString *part in parts) {
        NSString *trimmed = [part stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceAndNewlineCharacterSet];
        if (trimmed.length > 0) {
            [fields addObject:trimmed];
        }
    }
    return fields.count > 0 ? [fields copy] : nil;
}

+ (NSString *)mtc_textFromExtraFields:(NSArray<NSString *> *)extraFields {
    return extraFields.count > 0 ? [extraFields componentsJoinedByString:@","] : @"";
}

+ (NSString *)mtc_encodedPolylineFromPolylineText:(NSString *)text {
    return MTCEncodePolylineCoordinates(MTCParsePolylineText(text));
}

+ (NSString *)mtc_polylineTextFromEncodedPolyline:(NSString *)encodedPolyline {
    NSArray<MTCCoordinate *> *coordinates = MTCDecodePolyline(encodedPolyline);
    if (coordinates.count == 0) {
        return @"";
    }
    NSMutableArray<NSString *> *parts = [NSMutableArray arrayWithCapacity:coordinates.count];
    for (MTCCoordinate *coordinate in coordinates) {
        [parts addObject:[NSString stringWithFormat:@"%.6f,%.6f", coordinate.latitude, coordinate.longitude]];
    }
    return [parts componentsJoinedByString:@"\n"];
}

@end
