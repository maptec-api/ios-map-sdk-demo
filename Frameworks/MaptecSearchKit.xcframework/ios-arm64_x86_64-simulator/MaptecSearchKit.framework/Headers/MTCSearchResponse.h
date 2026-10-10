//
//  MTCSearchResponse.h
//  MaptecMaps
//
//  Created by ZHOUPanpan on 2026/7/14.
//

#import <Foundation/Foundation.h>

#import <MaptecSearchKit/MTCSearchRequest.h>

NS_ASSUME_NONNULL_BEGIN

#pragma mark - 搜索结果模型

@class MTCPlace;

/// 沿途搜索路线关系。
/// Route relation for along-route search.
@interface MTCAlongRouteRelation : NSObject
/// 距离路线最近的投影点。
/// Nearest projected point on the route.
@property (nonatomic, strong, nullable) MTCCoordinate *nearestRoutePoint;
/// 从路线起点累计到最近点的距离（米）。
/// Route offset from the start point to the nearest point, in meters.
@property (nonatomic, strong, nullable) NSNumber *routeOffsetMeters;
/// 地点到路线的最短几何距离（米）。
/// Minimum geometric distance from the place to the route, in meters.
@property (nonatomic, strong, nullable) NSNumber *distanceFromRouteMeters;
/// 最近点在输入路线中的相对进度，取值 [0, 1]。
/// Relative progress of the nearest point along the input route, in [0, 1].
@property (nonatomic, strong, nullable) NSNumber *routeProgressRatio;
@end

/// 沿途搜索路线评估结果。
/// Route evaluation result for along-route search.
@interface MTCAlongRouteEvaluation : NSObject
/// 经过候选地点后的预计总行程时间（秒）。
/// Estimated total duration after passing the candidate place, in seconds.
@property (nonatomic, strong, nullable) NSNumber *estimatedDurationSeconds;
/// 经过候选地点后的预计总行程距离（米）。
/// Estimated total distance after passing the candidate place, in meters.
@property (nonatomic, strong, nullable) NSNumber *estimatedDistanceMeters;
/// 路线评估 profile。
/// Route evaluation profile.
@property (nonatomic, copy, nullable) NSString *profile;
@end

/// 沿途搜索结果项。
/// Along-route search result item.
@interface MTCAlongRouteResult : NSObject
/// 地点信息。
/// Place information.
@property (nonatomic, strong, nullable) MTCPlace *place;
/// 地点与输入路线的几何关系。
/// Geometric relation between the place and the input route.
@property (nonatomic, strong, nullable) MTCAlongRouteRelation *routeRelation;
/// 经过候选地点后的预计总行程评估。
/// Estimated total trip evaluation after passing the candidate place.
@property (nonatomic, strong, nullable) MTCAlongRouteEvaluation *routeEvaluation;
/// 原始 JSON 字典。
/// Raw JSON dictionary.
@property (nonatomic, copy) NSDictionary *rawDictionary;
@end
 
 /// 本地化文本（含语言代码）
@interface MTCLocalizedText : NSObject
 /// 文本内容
@property (nonatomic, copy, nullable) NSString *text;
 /// IETF 语言代码
@property (nonatomic, copy, nullable) NSString *languageCode;
@end

 /// 地点照片元信息
@interface MTCPhotoMetadata : NSObject
 /// 照片资源名称（用于获取图片）
@property (nonatomic, copy, nullable) NSString *name;
 /// 宽度（像素）
@property (nonatomic, strong, nullable) NSNumber *widthPx;
 /// 高度（像素）
@property (nonatomic, strong, nullable) NSNumber *heightPx;
@end

/// 地址组成部分
/// Address component.
@interface MTCAddressComponent : NSObject
/// 地址组成部分完整名称
/// Full text of the address component.
@property (nonatomic, copy, nullable) NSString *longName;
/// 地址组成部分简称
/// Short text of the address component.
@property (nonatomic, copy, nullable) NSString *shortName;
/// 地址组成部分类型列表
/// Type list of the address component.
@property (nonatomic, copy) NSArray<NSString *> *types;
/// IETF BCP 47 语言标签
/// IETF BCP 47 language tag.
@property (nonatomic, copy, nullable) NSString *languageCode;
@end

/// 营业时间点
/// Opening-hours time point.
@interface MTCOpeningHoursTimePoint : NSObject
/// 星期索引，0 表示周日，6 表示周六
/// Weekday index where 0 is Sunday and 6 is Saturday.
@property (nonatomic, strong, nullable) NSNumber *day;
/// 24 小时制时间字符串，如 0900
/// 24-hour formatted time string such as 0900.
@property (nonatomic, copy, nullable) NSString *time;
@end

/// 营业时间区间
/// Opening-hours period.
@interface MTCOpeningHoursPeriod : NSObject
/// 开门时间点
/// Opening time point.
@property (nonatomic, strong, nullable) MTCOpeningHoursTimePoint *open;
/// 关门时间点
/// Closing time point.
@property (nonatomic, strong, nullable) MTCOpeningHoursTimePoint *close;
@end

/// 营业时间信息
/// Opening-hours information.
@interface MTCOpeningHours : NSObject
/// 当前是否营业中
/// Whether the place is currently open.
@property (nonatomic, strong, nullable) NSNumber *openNow;
/// 周期性营业时间列表
/// Recurring opening-hours periods.
@property (nonatomic, copy) NSArray<MTCOpeningHoursPeriod *> *periods;
/// 已格式化的每周营业时间文本
/// Formatted weekday text descriptions.
@property (nonatomic, copy) NSArray<NSString *> *weekdayText;
/// 下一次状态变化时间，ISO 8601 UTC 字符串
/// Next status change time in ISO 8601 UTC format.
@property (nonatomic, copy, nullable) NSString *nextStatusChange;
@end

/// 推荐视口
/// Recommended viewport.
@interface MTCViewport : NSObject
/// 东北角坐标
/// Northeast coordinate.
@property (nonatomic, strong, nullable) MTCCoordinate *northeast;
/// 西南角坐标
/// Southwest coordinate.
@property (nonatomic, strong, nullable) MTCCoordinate *southwest;
/// 可选低位坐标
/// Optional low coordinate.
@property (nonatomic, strong, nullable) MTCCoordinate *low;
/// 可选高位坐标
/// Optional high coordinate.
@property (nonatomic, strong, nullable) MTCCoordinate *high;
@end

/// 时区信息
/// Time-zone information.
@interface MTCTimeZoneInfo : NSObject
/// IANA 时区 ID
/// IANA time-zone identifier.
@property (nonatomic, copy, nullable) NSString *identifier;
/// IANA 时区数据库版本
/// IANA time-zone database version.
@property (nonatomic, copy, nullable) NSString *version;
@end

/// AOI 空间几何信息（GeoJSON）
/// AOI geometry in GeoJSON form.
@interface MTCGeoJson : NSObject
/// 几何类型，当前支持 Polygon
/// Geometry type; currently Polygon is supported.
@property (nonatomic, copy, nullable) NSString *type;
/// Polygon 坐标：Number[][][]，最内层为 [longitude, latitude]
/// Polygon coordinates as Number[][][], innermost pairs are [longitude, latitude].
@property (nonatomic, copy) NSArray *coordinates;
@end

/// 地点关联的 AOI 区域
/// Area of Interest associated with a place.
@interface MTCAoi : NSObject
/// AOI 唯一标识符
/// AOI identifier.
@property (nonatomic, copy, nullable) NSString *aoiID;
/// AOI 名称
/// AOI name.
@property (nonatomic, copy, nullable) NSString *name;
/// AOI 空间几何信息
/// AOI geometry.
@property (nonatomic, strong, nullable) MTCGeoJson *geojson;
@end

/// 错误对象
/// Error object.
@interface MTCErrorObject : NSObject
/// 错误码
/// Error code.
@property (nonatomic, copy, nullable) NSString *code;
/// 错误描述
/// Error message.
@property (nonatomic, copy, nullable) NSString *message;
@end

/// 输入提示建议项
/// Suggestion item.
@interface MTCSuggestion : NSObject
/// 地点资源名称，格式通常为 places/{id}
/// Place resource name, typically in the form places/{id}.
@property (nonatomic, copy, nullable) NSString *placeName;
/// 地点唯一标识
/// Place identifier.
@property (nonatomic, copy, nullable) NSString *placeID;
/// 输入提示文本
/// Suggestion text.
@property (nonatomic, strong, nullable) MTCLocalizedText *text;
/// 原始 JSON 字典
/// Raw JSON dictionary.
@property (nonatomic, copy) NSDictionary *rawDictionary;
@end

/// 地理编码地址组成部分
/// Geocode address component.
@interface MTCGeocodeAddressComponent : NSObject
/// 地址类型
/// Address component type.
@property (nonatomic, copy, nullable) NSString *type;
/// 本地地址类型
/// Local address type.
@property (nonatomic, copy, nullable) NSString *localType;
/// 完整名称
/// Long name.
@property (nonatomic, copy, nullable) NSString *longName;
/// 简短名称
/// Short name.
@property (nonatomic, copy, nullable) NSString *shortName;
/// ISO 代码
/// ISO code.
@property (nonatomic, copy, nullable) NSString *isoCode;
@end

/// 地理编码坐标点
/// Geocode coordinate point.
@interface MTCGeocodeCoordinate : NSObject
/// 纬度
/// Latitude.
@property (nonatomic, strong, nullable) NSNumber *latitude;
/// 经度
/// Longitude.
@property (nonatomic, strong, nullable) NSNumber *longitude;
/// 可选名称
/// Optional name.
@property (nonatomic, copy, nullable) NSString *name;
@end

/// 地理编码推荐视口
/// Geocode viewport.
@interface MTCGeocodeViewport : NSObject
/// 东北角坐标
/// Northeast coordinate.
@property (nonatomic, strong, nullable) MTCGeocodeCoordinate *northeast;
/// 西南角坐标
/// Southwest coordinate.
@property (nonatomic, strong, nullable) MTCGeocodeCoordinate *southwest;
/// 可选低位坐标
/// Optional low coordinate.
@property (nonatomic, strong, nullable) MTCGeocodeCoordinate *low;
/// 可选高位坐标
/// Optional high coordinate.
@property (nonatomic, strong, nullable) MTCGeocodeCoordinate *high;
@end

/// 地理编码几何信息
/// Geocode geometry.
@interface MTCGeocodeGeometry : NSObject
/// 坐标位置
/// Location coordinate.
@property (nonatomic, strong, nullable) MTCGeocodeCoordinate *location;
/// 位置匹配类型
/// Location type.
@property (nonatomic, copy, nullable) NSString *locationType;
/// 与输入坐标距离
/// Distance from the input coordinate.
@property (nonatomic, strong, nullable) NSNumber *distance;
/// 推荐视口
/// Recommended viewport.
@property (nonatomic, strong, nullable) MTCGeocodeViewport *viewport;
@end

/// 地理编码匹配详情
/// Geocode match details.
@interface MTCGeocodeMatchDetails : NSObject
/// 综合匹配得分
/// Match score.
@property (nonatomic, strong, nullable) NSNumber *matchScore;
/// 最终匹配层级
/// Match level.
@property (nonatomic, copy, nullable) NSString *matchLevel;
/// 是否发生回退
/// Whether degraded matching happened.
@property (nonatomic, strong, nullable) NSNumber *degraded;
/// 是否为部分匹配
/// Whether the match is partial.
@property (nonatomic, strong, nullable) NSNumber *partial;
/// 各字段匹配得分
/// Field score mapping.
@property (nonatomic, copy) NSDictionary<NSString *, NSNumber *> *fieldScores;
@end

/// 地理编码补充信息
/// Geocode supplementary information.
@interface MTCGeocodeSupplementaryInfo : NSObject
/// 外部编码
/// External identifier.
@property (nonatomic, copy, nullable) NSString *externalID;
/// 相对位置描述
/// Relative location description.
@property (nonatomic, copy, nullable) NSString *relativeLocation;
@end

/// 单条地理编码结果
/// Geocode result item.
@interface MTCGeocodeResult : NSObject
/// 地点唯一标识
/// Place identifier.
@property (nonatomic, copy, nullable) NSString *placeID;
/// 格式化地址
/// Formatted address.
@property (nonatomic, copy, nullable) NSString *formattedAddress;
/// 结果类型列表
/// Result type list.
@property (nonatomic, copy) NSArray<NSString *> *types;
/// IETF 语言标签
/// IETF language code.
@property (nonatomic, copy, nullable) NSString *languageCode;
/// 地址组成部分列表
/// Address component list.
@property (nonatomic, copy) NSArray<MTCGeocodeAddressComponent *> *addressComponents;
/// 几何信息
/// Geometry details.
@property (nonatomic, strong, nullable) MTCGeocodeGeometry *geometry;
/// 匹配质量信息
/// Match details.
@property (nonatomic, strong, nullable) MTCGeocodeMatchDetails *matchDetails;
/// 补充信息
/// Supplementary info.
@property (nonatomic, strong, nullable) MTCGeocodeSupplementaryInfo *supplementaryInfo;
/// 原始 JSON 字典
/// Raw JSON dictionary.
@property (nonatomic, copy) NSDictionary *rawDictionary;
@end

/// 地点信息
/// Place information.
@interface MTCPlace : NSObject
/// 地点唯一标识
/// Place identifier.
@property (nonatomic, copy, nullable) NSString *placeID;
/// 地点资源名称，格式通常为 places/{id}
/// Place resource name, typically in the form places/{id}.
@property (nonatomic, copy, nullable) NSString *name;
/// 格式化地址
/// Formatted address.
@property (nonatomic, copy, nullable) NSString *formattedAddress;
/// 展示名称（本地化）
/// Localized display name.
@property (nonatomic, strong, nullable) MTCLocalizedText *displayName;
/// 纬度
/// Latitude.
@property (nonatomic, strong, nullable) NSNumber *latitude;
/// 经度
/// Longitude.
@property (nonatomic, strong, nullable) NSNumber *longitude;
/// 地点类型列表，保留服务端原值（可含 POI / 地址 / 道路类型）
/// Place type list; keeps server raw strings (POI / address / road types).
@property (nonatomic, copy) NSArray<NSString *> *types;
/// 地址组成部分列表；需通过 extraFields 请求
/// Address-component list; request via extraFields.
@property (nonatomic, copy) NSArray<MTCAddressComponent *> *addressComponents;
/// 联系电话列表，按推荐展示优先级排序；需通过 extraFields 请求
/// Phone numbers ordered by display preference; request via extraFields.
@property (nonatomic, copy) NSArray<NSString *> *phoneNumbers;
/// 联系邮箱列表，按推荐展示优先级排序；需通过 extraFields 请求
/// Email addresses ordered by display preference; request via extraFields.
@property (nonatomic, copy) NSArray<NSString *> *emailAddresses;
/// 网址列表，按推荐展示优先级排序；需通过 extraFields 请求
/// Website URIs ordered by display preference; request via extraFields.
@property (nonatomic, copy) NSArray<NSString *> *websiteUris;
/// 营业时间信息；需通过 extraFields 请求
/// Opening-hours information; request via extraFields.
@property (nonatomic, strong, nullable) MTCOpeningHours *openingHours;
/// 推荐视口
/// Recommended viewport.
@property (nonatomic, strong, nullable) MTCViewport *viewport;
/// 时区信息；需通过 extraFields 请求
/// Time-zone information; request via extraFields.
@property (nonatomic, strong, nullable) MTCTimeZoneInfo *timeZone;
/// 照片元信息列表
/// Photo metadata list.
@property (nonatomic, copy) NSArray<MTCPhotoMetadata *> *photos;
/// 地点摘要（本地化）；需通过 extraFields 请求
/// Localized place summary; request via extraFields.
@property (nonatomic, strong, nullable) MTCLocalizedText *summary;
/// 地点关联的 AOI 区域；需通过 extraFields 请求
/// Associated AOI; request via extraFields.
@property (nonatomic, strong, nullable) MTCAoi *aoi;
/// 原始 JSON 字典
/// Raw JSON dictionary.
@property (nonatomic, copy) NSDictionary *rawDictionary;
@end

 /// 搜索服务响应基类
@interface MTCSearchServiceResponse : NSObject
 /// 原始响应字典
@property (nonatomic, copy) NSDictionary *rawDictionary;
/// 响应状态
/// Response status.
@property (nonatomic, copy, nullable) NSString *status;
/// 服务端有效性标记
/// Server validity flag.
@property (nonatomic, strong, nullable) NSNumber *valid;
/// 服务端错误对象
/// Server error object.
@property (nonatomic, strong, nullable) MTCErrorObject *error;
@end

#pragma mark - 文本搜索
 /// 文本搜索响应
@interface MTCTextSearchResponse : MTCSearchServiceResponse
 /// 地点列表
@property (nonatomic, copy) NSArray<MTCPlace *> *places;
 /// 下一页分页令牌
@property (nonatomic, copy, nullable) NSString *nextPageToken;
@end

 /// 附近搜索响应
@interface MTCNearbySearchResponse : MTCSearchServiceResponse
@property (nonatomic, copy) NSArray<MTCPlace *> *places;
/// 下一页分页令牌
/// Next-page token.
@property (nonatomic, copy, nullable) NSString *nextPageToken;
@end

/// 沿途搜索响应。
/// Along-route search response.
@interface MTCAlongRouteSearchResponse : MTCSearchServiceResponse
/// 沿途搜索结果列表。
/// Along-route search result list.
@property (nonatomic, copy) NSArray<MTCAlongRouteResult *> *results;
@end

 /// 输入提示搜索响应
@interface MTCSuggestResponse : MTCSearchServiceResponse
@property (nonatomic, copy) NSArray<MTCSuggestion *> *suggestions;
@end

 /// 地点详情响应
@interface MTCPlaceDetailResponse : MTCSearchServiceResponse
@property (nonatomic, strong, nullable) MTCPlace *place;
@end

 /// 地理编码响应（正向/反向共用）
@interface MTCGeocodeResponse : MTCSearchServiceResponse
 /// 地理编码结果列表
@property (nonatomic, copy) NSArray<MTCGeocodeResult *> *results;
@end

 /// 鉴权状态响应（查询 API Key 可用的资源 URL 列表）
@interface MTCAuthStatusResponse : MTCSearchServiceResponse
 /// 可访问的资源 URL 列表
@property (nonatomic, copy) NSArray<NSString *> *resourceURLs;
@end

NS_ASSUME_NONNULL_END
