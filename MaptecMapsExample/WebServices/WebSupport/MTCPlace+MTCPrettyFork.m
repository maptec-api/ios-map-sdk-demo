//
//  MTCPlace+MTCPrettyFork.m
//  MaptecMapsExample
//
//  Created by ZHOUPanpan+ on 2026/8/4.
//  Copyright © 2026 ZHOUPanpan+. All rights reserved.
//

#import "MTCPlace+MTCPrettyFork.h"

#pragma mark - Private Helpers

static void MTCPrettyAppendSection(NSMutableArray<NSString *> *sections, NSString *title, NSString *value) {
    if (value.length == 0) {
        return;
    }
    [sections addObject:[NSString stringWithFormat:@"%@\n%@", title, value]];
}

static NSString *MTCPrettyJSONStringFromDictionary(NSDictionary *dictionary) {
    if (dictionary.count == 0) {
        return @"";
    }
    NSData *data = [NSJSONSerialization dataWithJSONObject:dictionary options:NSJSONWritingPrettyPrinted error:nil];
    return data ? [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding] : dictionary.description;
}

static NSString *MTCPrettyCoordinateText(MTCCoordinate * _Nullable coordinate) {
    if (!coordinate) {
        return @"";
    }
    return [NSString stringWithFormat:@"(%0.6f, %0.6f)", coordinate.latitude, coordinate.longitude];
}

static NSString *MTCPrettyGeocodeCoordinateText(MTCGeocodeCoordinate * _Nullable coordinate) {
    if (!coordinate) {
        return @"";
    }
    NSMutableArray<NSString *> *parts = [NSMutableArray arrayWithArray:@[
        [NSString stringWithFormat:@"latitude=%@", coordinate.latitude ?: @"-"],
        [NSString stringWithFormat:@"longitude=%@", coordinate.longitude ?: @"-"]
    ]];
    if (coordinate.name.length > 0) {
        [parts addObject:[NSString stringWithFormat:@"name=%@", coordinate.name]];
    }
    return [parts componentsJoinedByString:@", "];
}

static NSString *MTCPrettyOpeningTimePointText(MTCOpeningHoursTimePoint * _Nullable timePoint) {
    if (!timePoint) {
        return @"";
    }
    NSMutableArray<NSString *> *parts = [NSMutableArray array];
    if (timePoint.day) {
        [parts addObject:[NSString stringWithFormat:@"day=%@", timePoint.day]];
    }
    if (timePoint.time.length > 0) {
        [parts addObject:[NSString stringWithFormat:@"time=%@", timePoint.time]];
    }
    return [parts componentsJoinedByString:@", "];
}

@interface MTCPlace (MTCPrettyForkPrivate)

- (NSString *)mtc_aoiText;
- (NSString *)mtc_timeZoneText;
- (NSString *)mtc_openingHoursText;
- (NSString *)mtc_viewportText;
- (NSString *)mtc_addressComponentsText;
- (NSString *)mtc_photosText;

@end

@interface MTCGeocodeResult (MTCPrettyForkPrivate)

- (NSString *)mtc_addressComponentsText;
- (NSString *)mtc_geometryText;
- (NSString *)mtc_matchDetailsText;
- (NSString *)mtc_supplementaryInfoText;

@end

@implementation MTCPlace (MTCPrettyFork)

- (NSString *)mtc_identifierWithFallbackIndex:(NSUInteger)index {
    if (self.placeID.length > 0) {
        return self.placeID;
    }
    if (self.name.length > 0) {
        return self.name;
    }
    if (index != NSNotFound) {
        return [NSString stringWithFormat:@"place-%@", @(index)];
    }
    return nil;
}

- (NSString *)mtc_displayTitleWithFallbackIndex:(NSUInteger)index {
    if (self.displayName.text.length > 0) {
        return self.displayName.text;
    }
    if (self.formattedAddress.length > 0) {
        return self.formattedAddress;
    }
    if (self.name.length > 0) {
        return self.name;
    }
    return [NSString stringWithFormat:@"place-%@", index == NSNotFound ? @(0) : @(index + 1)];
}

- (NSString *)mtc_previewText {
    NSMutableArray<NSString *> *lines = [NSMutableArray array];
    if (self.formattedAddress.length > 0) {
        [lines addObject:self.formattedAddress];
    }
    if (self.types.count > 0) {
        [lines addObject:[self.types componentsJoinedByString:@", "]];
    }
    if (self.latitude && self.longitude) {
        [lines addObject:[NSString stringWithFormat:@"lat:%@ lng:%@", self.latitude, self.longitude]];
    }
    return [lines componentsJoinedByString:@"\n"];
}

- (NSString *)mtc_detailText {
    NSMutableArray<NSString *> *sections = [NSMutableArray array];
    MTCPrettyAppendSection(sections, @"displayName", self.displayName.text ?: @"");
    MTCPrettyAppendSection(sections, @"placeId", self.placeID ?: @"");
    MTCPrettyAppendSection(sections, @"name", self.name ?: @"");
    MTCPrettyAppendSection(sections, @"formattedAddress", self.formattedAddress ?: @"");
    MTCPrettyAppendSection(sections, @"phoneNumbers", self.phoneNumbers.count > 0 ? [self.phoneNumbers componentsJoinedByString:@"\n"] : @"");
    MTCPrettyAppendSection(sections, @"emailAddresses", self.emailAddresses.count > 0 ? [self.emailAddresses componentsJoinedByString:@"\n"] : @"");
    MTCPrettyAppendSection(sections, @"websiteUris", self.websiteUris.count > 0 ? [self.websiteUris componentsJoinedByString:@"\n"] : @"");
    MTCPrettyAppendSection(sections, @"types", self.types.count > 0 ? [self.types componentsJoinedByString:@", "] : @"");
    if (self.latitude && self.longitude) {
        MTCPrettyAppendSection(sections, @"location", [NSString stringWithFormat:@"latitude: %@\nlongitude: %@", self.latitude, self.longitude]);
    }
    MTCPrettyAppendSection(sections, @"summary", self.summary.text ?: @"");
    MTCPrettyAppendSection(sections, @"aoi", [self mtc_aoiText]);
    MTCPrettyAppendSection(sections, @"timeZone", [self mtc_timeZoneText]);
    MTCPrettyAppendSection(sections, @"openingHours", [self mtc_openingHoursText]);
    MTCPrettyAppendSection(sections, @"viewport", [self mtc_viewportText]);
    MTCPrettyAppendSection(sections, @"addressComponents", [self mtc_addressComponentsText]);
    MTCPrettyAppendSection(sections, @"photos", [self mtc_photosText]);
    MTCPrettyAppendSection(sections, @"raw.place", MTCPrettyJSONStringFromDictionary(self.rawDictionary ?: @{}));
    return sections.count > 0 ? [sections componentsJoinedByString:@"\n\n"] : @"No details to show";
}

@end

@implementation MTCPlace (MTCPrettyForkPrivate)

- (NSString *)mtc_aoiText {
    if (!self.aoi) {
        return @"";
    }
    NSMutableArray<NSString *> *parts = [NSMutableArray array];
    if (self.aoi.aoiID.length > 0) {
        [parts addObject:[NSString stringWithFormat:@"id: %@", self.aoi.aoiID]];
    }
    if (self.aoi.name.length > 0) {
        [parts addObject:[NSString stringWithFormat:@"name: %@", self.aoi.name]];
    }
    if (self.aoi.geojson.type.length > 0) {
        [parts addObject:[NSString stringWithFormat:@"geojson.type: %@", self.aoi.geojson.type]];
    }
    if (self.aoi.geojson.coordinates.count > 0) {
        [parts addObject:[NSString stringWithFormat:@"geojson.coordinates: %@", self.aoi.geojson.coordinates]];
    }
    return [parts componentsJoinedByString:@"\n"];
}

- (NSString *)mtc_timeZoneText {
    if (!self.timeZone) {
        return @"";
    }
    NSMutableArray<NSString *> *parts = [NSMutableArray array];
    if (self.timeZone.identifier.length > 0) {
        [parts addObject:[NSString stringWithFormat:@"id: %@", self.timeZone.identifier]];
    }
    if (self.timeZone.version.length > 0) {
        [parts addObject:[NSString stringWithFormat:@"version: %@", self.timeZone.version]];
    }
    return [parts componentsJoinedByString:@"\n"];
}

- (NSString *)mtc_openingHoursText {
    if (!self.openingHours) {
        return @"";
    }
    NSMutableArray<NSString *> *parts = [NSMutableArray array];
    if (self.openingHours.openNow) {
        [parts addObject:[NSString stringWithFormat:@"openNow: %@", self.openingHours.openNow.boolValue ? @"YES" : @"NO"]];
    }
    if (self.openingHours.nextStatusChange.length > 0) {
        [parts addObject:[NSString stringWithFormat:@"nextStatusChange: %@", self.openingHours.nextStatusChange]];
    }
    if (self.openingHours.weekdayText.count > 0) {
        [parts addObject:[NSString stringWithFormat:@"weekdayText:\n%@", [self.openingHours.weekdayText componentsJoinedByString:@"\n"]]];
    }
    if (self.openingHours.periods.count > 0) {
        NSMutableArray<NSString *> *periodText = [NSMutableArray array];
        [self.openingHours.periods enumerateObjectsUsingBlock:^(MTCOpeningHoursPeriod * _Nonnull period, NSUInteger idx, BOOL * _Nonnull stop) {
            (void)stop;
            NSString *openText = MTCPrettyOpeningTimePointText(period.open);
            NSString *closeText = MTCPrettyOpeningTimePointText(period.close);
            [periodText addObject:[NSString stringWithFormat:@"period-%@: open[%@]%@", @(idx + 1), openText ?: @"-",
                                   closeText.length > 0 ? [NSString stringWithFormat:@" close[%@]", closeText] : @""]];
        }];
        [parts addObject:[NSString stringWithFormat:@"periods:\n%@", [periodText componentsJoinedByString:@"\n"]]];
    }
    return [parts componentsJoinedByString:@"\n"];
}

- (NSString *)mtc_viewportText {
    if (!self.viewport) {
        return @"";
    }
    NSMutableArray<NSString *> *parts = [NSMutableArray array];
    if (self.viewport.northeast) {
        [parts addObject:[NSString stringWithFormat:@"northeast: %@", MTCPrettyCoordinateText(self.viewport.northeast)]];
    }
    if (self.viewport.southwest) {
        [parts addObject:[NSString stringWithFormat:@"southwest: %@", MTCPrettyCoordinateText(self.viewport.southwest)]];
    }
    if (self.viewport.low) {
        [parts addObject:[NSString stringWithFormat:@"low: %@", MTCPrettyCoordinateText(self.viewport.low)]];
    }
    if (self.viewport.high) {
        [parts addObject:[NSString stringWithFormat:@"high: %@", MTCPrettyCoordinateText(self.viewport.high)]];
    }
    return [parts componentsJoinedByString:@"\n"];
}

- (NSString *)mtc_addressComponentsText {
    if (self.addressComponents.count == 0) {
        return @"";
    }
    NSMutableArray<NSString *> *lines = [NSMutableArray array];
    [self.addressComponents enumerateObjectsUsingBlock:^(MTCAddressComponent * _Nonnull component, NSUInteger idx, BOOL * _Nonnull stop) {
        (void)stop;
        NSMutableArray<NSString *> *parts = [NSMutableArray array];
        if (component.longName.length > 0) {
            [parts addObject:[NSString stringWithFormat:@"longName=%@", component.longName]];
        }
        if (component.shortName.length > 0) {
            [parts addObject:[NSString stringWithFormat:@"shortName=%@", component.shortName]];
        }
        if (component.languageCode.length > 0) {
            [parts addObject:[NSString stringWithFormat:@"languageCode=%@", component.languageCode]];
        }
        if (component.types.count > 0) {
            [parts addObject:[NSString stringWithFormat:@"types=%@", [component.types componentsJoinedByString:@", "]]];
        }
        [lines addObject:[NSString stringWithFormat:@"component-%@: %@", @(idx + 1), [parts componentsJoinedByString:@" | "]]];
    }];
    return [lines componentsJoinedByString:@"\n"];
}

- (NSString *)mtc_photosText {
    if (self.photos.count == 0) {
        return @"";
    }
    NSMutableArray<NSString *> *lines = [NSMutableArray array];
    [self.photos enumerateObjectsUsingBlock:^(MTCPhotoMetadata * _Nonnull photo, NSUInteger idx, BOOL * _Nonnull stop) {
        (void)stop;
        [lines addObject:[NSString stringWithFormat:@"photo-%@: name=%@ width=%@ height=%@",
                          @(idx + 1),
                          photo.name ?: @"-",
                          photo.widthPx ?: @"-",
                          photo.heightPx ?: @"-"]];
    }];
    return [lines componentsJoinedByString:@"\n"];
}

@end

@implementation MTCSuggestion (MTCPrettyFork)

- (NSString *)mtc_identifierWithFallbackIndex:(NSUInteger)index {
    if (self.placeID.length > 0) {
        return self.placeID;
    }
    if (self.placeName.length > 0) {
        return self.placeName;
    }
    if (self.text.text.length > 0) {
        return self.text.text;
    }
    if (index != NSNotFound) {
        return [NSString stringWithFormat:@"suggestion-%@", @(index)];
    }
    return nil;
}

- (NSString *)mtc_displayTitleWithFallbackIndex:(NSUInteger)index {
    if (self.text.text.length > 0) {
        return self.text.text;
    }
    if (self.placeName.length > 0) {
        return self.placeName;
    }
    if (self.placeID.length > 0) {
        return self.placeID;
    }
    return [NSString stringWithFormat:@"suggestion-%@", index == NSNotFound ? @(0) : @(index + 1)];
}

- (NSString *)mtc_previewText {
    NSMutableArray<NSString *> *lines = [NSMutableArray array];
    if (self.placeName.length > 0) {
        [lines addObject:[NSString stringWithFormat:@"placeName: %@", self.placeName]];
    }
    if (self.placeID.length > 0) {
        [lines addObject:[NSString stringWithFormat:@"placeId: %@", self.placeID]];
    }
    if (self.text.languageCode.length > 0) {
        [lines addObject:[NSString stringWithFormat:@"languageCode: %@", self.text.languageCode]];
    }
    return [lines componentsJoinedByString:@"\n"];
}

- (NSString *)mtc_detailText {
    NSMutableArray<NSString *> *sections = [NSMutableArray array];
    MTCPrettyAppendSection(sections, @"text", self.text.text ?: @"");
    MTCPrettyAppendSection(sections, @"languageCode", self.text.languageCode ?: @"");
    MTCPrettyAppendSection(sections, @"placeId", self.placeID ?: @"");
    MTCPrettyAppendSection(sections, @"placeName", self.placeName ?: @"");
    MTCPrettyAppendSection(sections, @"raw.suggestion", MTCPrettyJSONStringFromDictionary(self.rawDictionary ?: @{}));
    return sections.count > 0 ? [sections componentsJoinedByString:@"\n\n"] : @"No details to show";
}

@end

@implementation MTCGeocodeResult (MTCPrettyFork)

- (NSString *)mtc_identifierWithFallbackIndex:(NSUInteger)index {
    if (self.placeID.length > 0) {
        return self.placeID;
    }
    if (self.formattedAddress.length > 0) {
        return self.formattedAddress;
    }
    if (self.geometry.location.latitude && self.geometry.location.longitude) {
        return [NSString stringWithFormat:@"%@,%@", self.geometry.location.latitude, self.geometry.location.longitude];
    }
    if (index != NSNotFound) {
        return [NSString stringWithFormat:@"geocode-%@", @(index)];
    }
    return nil;
}

- (NSString *)mtc_displayTitleWithFallbackIndex:(NSUInteger)index {
    if (self.formattedAddress.length > 0) {
        return self.formattedAddress;
    }
    if (self.placeID.length > 0) {
        return self.placeID;
    }
    return [NSString stringWithFormat:@"result-%@", index == NSNotFound ? @(0) : @(index + 1)];
}

- (NSString *)mtc_previewText {
    NSMutableArray<NSString *> *lines = [NSMutableArray array];
    if (self.placeID.length > 0) {
        [lines addObject:[NSString stringWithFormat:@"placeId: %@", self.placeID]];
    }
    if (self.types.count > 0) {
        [lines addObject:[self.types componentsJoinedByString:@", "]];
    }
    if (self.geometry.location) {
        [lines addObject:[NSString stringWithFormat:@"lat:%@ lng:%@",
                          self.geometry.location.latitude ?: @"-",
                          self.geometry.location.longitude ?: @"-"]];
    }
    return [lines componentsJoinedByString:@"\n"];
}

- (NSString *)mtc_detailText {
    NSMutableArray<NSString *> *sections = [NSMutableArray array];
    MTCPrettyAppendSection(sections, @"formattedAddress", self.formattedAddress ?: @"");
    MTCPrettyAppendSection(sections, @"placeId", self.placeID ?: @"");
    MTCPrettyAppendSection(sections, @"types", self.types.count > 0 ? [self.types componentsJoinedByString:@", "] : @"");
    MTCPrettyAppendSection(sections, @"languageCode", self.languageCode ?: @"");
    MTCPrettyAppendSection(sections, @"addressComponents", [self mtc_addressComponentsText]);
    MTCPrettyAppendSection(sections, @"geometry", [self mtc_geometryText]);
    MTCPrettyAppendSection(sections, @"matchDetails", [self mtc_matchDetailsText]);
    MTCPrettyAppendSection(sections, @"supplementaryInfo", [self mtc_supplementaryInfoText]);
    MTCPrettyAppendSection(sections, @"raw.result", MTCPrettyJSONStringFromDictionary(self.rawDictionary ?: @{}));
    return sections.count > 0 ? [sections componentsJoinedByString:@"\n\n"] : @"No details to show";
}

@end

@implementation MTCGeocodeResult (MTCPrettyForkPrivate)

- (NSString *)mtc_addressComponentsText {
    if (self.addressComponents.count == 0) {
        return @"";
    }
    NSMutableArray<NSString *> *lines = [NSMutableArray array];
    [self.addressComponents enumerateObjectsUsingBlock:^(MTCGeocodeAddressComponent * _Nonnull component, NSUInteger idx, BOOL * _Nonnull stop) {
        (void)stop;
        NSMutableArray<NSString *> *parts = [NSMutableArray array];
        if (component.type.length > 0) {
            [parts addObject:[NSString stringWithFormat:@"type=%@", component.type]];
        }
        if (component.localType.length > 0) {
            [parts addObject:[NSString stringWithFormat:@"localType=%@", component.localType]];
        }
        if (component.longName.length > 0) {
            [parts addObject:[NSString stringWithFormat:@"longName=%@", component.longName]];
        }
        if (component.shortName.length > 0) {
            [parts addObject:[NSString stringWithFormat:@"shortName=%@", component.shortName]];
        }
        if (component.isoCode.length > 0) {
            [parts addObject:[NSString stringWithFormat:@"isoCode=%@", component.isoCode]];
        }
        [lines addObject:[NSString stringWithFormat:@"component-%@: %@", @(idx + 1), [parts componentsJoinedByString:@" | "]]];
    }];
    return [lines componentsJoinedByString:@"\n"];
}

- (NSString *)mtc_geometryText {
    if (!self.geometry) {
        return @"";
    }
    NSMutableArray<NSString *> *parts = [NSMutableArray array];
    if (self.geometry.location) {
        [parts addObject:[NSString stringWithFormat:@"location: %@", MTCPrettyGeocodeCoordinateText(self.geometry.location)]];
    }
    if (self.geometry.locationType.length > 0) {
        [parts addObject:[NSString stringWithFormat:@"locationType: %@", self.geometry.locationType]];
    }
    if (self.geometry.distance) {
        [parts addObject:[NSString stringWithFormat:@"distance: %@", self.geometry.distance]];
    }
    if (self.geometry.viewport) {
        NSMutableArray<NSString *> *viewportLines = [NSMutableArray array];
        if (self.geometry.viewport.northeast) {
            [viewportLines addObject:[NSString stringWithFormat:@"northeast: %@", MTCPrettyGeocodeCoordinateText(self.geometry.viewport.northeast)]];
        }
        if (self.geometry.viewport.southwest) {
            [viewportLines addObject:[NSString stringWithFormat:@"southwest: %@", MTCPrettyGeocodeCoordinateText(self.geometry.viewport.southwest)]];
        }
        if (self.geometry.viewport.low) {
            [viewportLines addObject:[NSString stringWithFormat:@"low: %@", MTCPrettyGeocodeCoordinateText(self.geometry.viewport.low)]];
        }
        if (self.geometry.viewport.high) {
            [viewportLines addObject:[NSString stringWithFormat:@"high: %@", MTCPrettyGeocodeCoordinateText(self.geometry.viewport.high)]];
        }
        [parts addObject:[NSString stringWithFormat:@"viewport:\n%@", [viewportLines componentsJoinedByString:@"\n"]]];
    }
    return [parts componentsJoinedByString:@"\n"];
}

- (NSString *)mtc_matchDetailsText {
    if (!self.matchDetails) {
        return @"";
    }
    NSMutableArray<NSString *> *parts = [NSMutableArray array];
    if (self.matchDetails.matchScore) {
        [parts addObject:[NSString stringWithFormat:@"matchScore: %@", self.matchDetails.matchScore]];
    }
    if (self.matchDetails.matchLevel.length > 0) {
        [parts addObject:[NSString stringWithFormat:@"matchLevel: %@", self.matchDetails.matchLevel]];
    }
    if (self.matchDetails.degraded) {
        [parts addObject:[NSString stringWithFormat:@"isDegraded: %@", self.matchDetails.degraded.boolValue ? @"YES" : @"NO"]];
    }
    if (self.matchDetails.partial) {
        [parts addObject:[NSString stringWithFormat:@"isPartial: %@", self.matchDetails.partial.boolValue ? @"YES" : @"NO"]];
    }
    if (self.matchDetails.fieldScores.count > 0) {
        NSMutableArray<NSString *> *scoreLines = [NSMutableArray array];
        NSArray<NSString *> *sortedKeys = [[self.matchDetails.fieldScores allKeys] sortedArrayUsingSelector:@selector(compare:)];
        for (NSString *key in sortedKeys) {
            [scoreLines addObject:[NSString stringWithFormat:@"%@=%@", key, self.matchDetails.fieldScores[key]]];
        }
        [parts addObject:[NSString stringWithFormat:@"fieldScores:\n%@", [scoreLines componentsJoinedByString:@"\n"]]];
    }
    return [parts componentsJoinedByString:@"\n"];
}

- (NSString *)mtc_supplementaryInfoText {
    if (!self.supplementaryInfo) {
        return @"";
    }
    NSMutableArray<NSString *> *parts = [NSMutableArray array];
    if (self.supplementaryInfo.externalID.length > 0) {
        [parts addObject:[NSString stringWithFormat:@"externalId: %@", self.supplementaryInfo.externalID]];
    }
    if (self.supplementaryInfo.relativeLocation.length > 0) {
        [parts addObject:[NSString stringWithFormat:@"relativeLocation: %@", self.supplementaryInfo.relativeLocation]];
    }
    return [parts componentsJoinedByString:@"\n"];
}

@end
