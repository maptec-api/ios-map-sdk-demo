//
//  MTCWebSupportUtil.h
//  MaptecMapsExample
//
//  Created by ZHOUPanpan on 2026/7/14.
//

#import <Foundation/Foundation.h>
#import "MTCTextSearchRequestParams+MTCSupportFork.h"
#import "MTCPlace+MTCPrettyFork.h"

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSInteger, MTCWebPopupPurpose) {
    MTCWebPopupPurposeNone = 0,
    MTCWebPopupPurposePlaceDetail,
    MTCWebPopupPurposeSuggestionDetail,
    MTCWebPopupPurposeGeocodeResultDetail,
    MTCWebPopupPurposeResponseRaw,
};

@interface MTCWebSupportUtil : NSObject

+ (NSString *)mtc_prettyJSONStringFromDictionary:(NSDictionary *)dictionary;

+ (NSArray<NSString *> *)mtc_locationModeOptions;

+ (NSArray<NSString *> *)mtc_poiTypeOptions;

+ (NSString *)mtc_poiTypeForIndex:(NSInteger)index;

+ (BOOL)mtc_usesRectangleForLocationMode:(MTCWebLocationMode)locationMode;

+ (BOOL)mtc_usesCircleForLocationMode:(MTCWebLocationMode)locationMode;

/// Place extraFields 可选标签列表
/// Available Place extraFields tags.
+ (NSArray<NSString *> *)mtc_placeExtraFieldOptions;

/// 文本搜索 extraFields 可选标签列表
/// Available extraFields tags for text search.
+ (NSArray<NSString *> *)mtc_textSearchExtraFieldOptions;

+ (NSArray<NSString *> *)mtc_extraFieldsFromText:(NSString *)text;

+ (NSString *)mtc_textFromExtraFields:(NSArray<NSString *> *)extraFields;

/// 将“每行一个 lat,lng”或“分号分隔的 lat,lng”文本编码为 Google Encoded Polyline。
/// Encode newline-separated or semicolon-separated lat,lng text into a Google encoded polyline.
+ (nullable NSString *)mtc_encodedPolylineFromPolylineText:(NSString *)text;

/// 将 Google Encoded Polyline 解码为“每行一个 lat,lng”的展示文本。
/// Decode a Google encoded polyline into newline-separated lat,lng text.
+ (nullable NSString *)mtc_polylineTextFromEncodedPolyline:(NSString *)encodedPolyline;

@end

NS_ASSUME_NONNULL_END
