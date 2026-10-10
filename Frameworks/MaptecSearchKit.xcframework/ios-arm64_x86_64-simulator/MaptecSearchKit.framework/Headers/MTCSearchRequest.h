//
//  MTCSearchRequest.h
//  MaptecMaps
//
//  Created by ZHOUPanpan on 2026/7/14.
//

#import <Foundation/Foundation.h>

#import <MaptecSearchKit/MTCSearchTypes.h>

NS_ASSUME_NONNULL_BEGIN

 #pragma mark - 坐标与地理区域模型
 
 /// 经纬度坐标
@interface MTCCoordinate : NSObject <NSCopying>
 /// 纬度
@property (nonatomic, assign) double latitude;
 /// 经度
@property (nonatomic, assign) double longitude;
 /// 以纬度、经度初始化
- (instancetype)initWithLatitude:(double)latitude longitude:(double)longitude;
@end

 /// 矩形地理区域（东北-西南对角）
@interface MTCLocationRectangle : NSObject <NSCopying>
 /// 东北角坐标
@property (nonatomic, strong) MTCCoordinate *northeast;
 /// 西南角坐标
@property (nonatomic, strong) MTCCoordinate *southwest;
- (instancetype)initWithNortheast:(MTCCoordinate *)northeast southwest:(MTCCoordinate *)southwest;
@end

 /// 圆形地理区域
@interface MTCLocationCircle : NSObject <NSCopying>
 /// 圆心
@property (nonatomic, strong) MTCCoordinate *center;
 /// 半径（米）
@property (nonatomic, assign) NSInteger radius;
- (instancetype)initWithCenter:(MTCCoordinate *)center radius:(NSInteger)radius;
@end

 #pragma mark - 位置约束模型
 
 /// 位置偏向（倾向搜索结果靠近此区域，不严格限定）
@interface MTCLocationBias : NSObject <NSCopying>
@property (nonatomic, strong, nullable) MTCLocationRectangle *rectangle;
@property (nonatomic, strong, nullable) MTCLocationCircle *circle;
+ (instancetype)biasWithRectangle:(MTCLocationRectangle *)rectangle;
+ (instancetype)biasWithCircle:(MTCLocationCircle *)circle;
@end

 /// 位置限定（严格限定结果在此区域内）
@interface MTCLocationLimit : NSObject <NSCopying>
@property (nonatomic, strong, nullable) MTCLocationRectangle *rectangle;
@property (nonatomic, strong, nullable) MTCLocationCircle *circle;
+ (instancetype)limitWithRectangle:(MTCLocationRectangle *)rectangle;
+ (instancetype)limitWithCircle:(MTCLocationCircle *)circle;
@end

#pragma mark - 搜索请求模型

/// 沿途搜索路线几何。
/// Route geometry used by along-route search.
@interface MTCRouteGeometry : NSObject <NSCopying>
/// Google Encoded Polyline（Polyline 5）。
/// Google encoded polyline (Polyline 5).
@property (nonatomic, copy) NSString *encodedPolyline;
@end

/// 沿途搜索请求参数。
/// Along-route search request parameters.
@interface MTCAlongRouteSearchRequest : NSObject <NSCopying>
/// 搜索关键词，地点名称/品牌/类别文本。
/// Search query, such as place name, brand, or category text.
@property (nonatomic, copy, nullable) NSString *query;
/// 允许返回的地点类型，逗号分隔。
/// Allowed place types, comma-separated.
@property (nonatomic, copy, nullable) NSString *types;
/// 本次搜索的路线几何。
/// Route geometry for this request.
@property (nonatomic, strong) MTCRouteGeometry *route;
/// 路线缓冲距离（米）。
/// Search buffer distance around the route, in meters.
@property (nonatomic, strong, nullable) NSNumber *routeBufferMeters;
/// 路线评估模式。
/// Route evaluation mode.
@property (nonatomic, assign) MTCAlongRouteEvaluationMode evaluationMode;
/// 结果排序类型。
/// Result ranking type.
@property (nonatomic, assign) MTCAlongRouteRankType rank;
/// 结果数量上限。
/// Maximum number of returned results.
@property (nonatomic, strong, nullable) NSNumber *resultLimit;
/// IETF 语言标签。
/// IETF language tag.
@property (nonatomic, copy, nullable) NSString *language;
/// ISO 3166-1 alpha-2 国家/地区代码。
/// ISO 3166-1 alpha-2 region code.
@property (nonatomic, copy, nullable) NSString *region;
/// 需要额外返回的 Place 扩展字段列表。
/// Extra Place fields to request.
@property (nonatomic, copy, nullable) NSArray<NSString *> *extraFields;
@end
 
/// 文本搜索请求参数
/// Text search request parameters.
@interface MTCTextSearchRequest : NSObject <NSCopying>
/// 搜索关键词（必填）
/// Search query string (required).
@property (nonatomic, copy) NSString *query;
/// 地点类型过滤
/// Place type filter.
@property (nonatomic, copy, nullable) NSString *type;
/// 位置偏向
/// Location bias.
@property (nonatomic, strong, nullable) MTCLocationBias *locationBias;
/// 位置限定
/// Location restriction.
@property (nonatomic, strong, nullable) MTCLocationLimit *locationLimit;
/// 分页大小，默认20条
/// Page size, default 20.
@property (nonatomic, strong, nullable) NSNumber *pageSize;
/// 分页令牌（从上一页响应获取）
/// Page token from the previous response.
@property (nonatomic, copy, nullable) NSString *pageToken;
/// 排序类型
/// Ranking type.
@property (nonatomic, assign) MTCSearchRankType rankType;
/// IETF 语言标签，如 @"zh"
/// IETF language tag, e.g. @"zh".
@property (nonatomic, copy, nullable) NSString *language;
/// ccTLD 地区代码，如 @"SG"
/// ccTLD region code, e.g. @"SG".
@property (nonatomic, copy, nullable) NSString *region;
/// 需要额外返回的 Place 扩展字段列表
/// Extra Place fields to request in addition to defaults.
///
/// 仅追加扩展字段，不裁剪默认字段；未传入或为 nil 时只返回默认字段。
/// Additive only; nil means defaults only.
/// 取值范围：aoi、summary、openingHours、phoneNumbers、emailAddresses、websiteUris、
/// addressComponents、timeZone。未知字符串由服务端处理，SDK 不本地拦截。
/// Allowed values: aoi, summary, openingHours, phoneNumbers, emailAddresses, websiteUris,
/// addressComponents, timeZone. Unknown strings are handled by the server.
@property (nonatomic, copy, nullable) NSArray<NSString *> *extraFields;
@end

 /// 附近搜索请求参数
@interface MTCNearbySearchRequest : NSObject <NSCopying>
 /// 搜索圆形区域（必填）
@property (nonatomic, strong) MTCLocationCircle *locationLimit;
 /// 地点类型过滤，逗号分隔
@property (nonatomic, copy, nullable) NSString *types;
 /// 结果数量上限
@property (nonatomic, strong, nullable) NSNumber *resultLimit;
 /// 排序类型
@property (nonatomic, assign) MTCSearchRankType rankType;
 /// IETF 语言标签
@property (nonatomic, copy, nullable) NSString *language;
 /// ccTLD 地区代码
@property (nonatomic, copy, nullable) NSString *region;
/// 需要额外返回的 Place 扩展字段列表
@property (nonatomic, copy, nullable) NSArray<NSString *> *extraFields;
@end

 /// 输入提示（自动补全）请求参数
@interface MTCSuggestRequest : NSObject <NSCopying>
 /// 输入关键词（必填）
@property (nonatomic, copy) NSString *query;
 /// 地点类型过滤
@property (nonatomic, copy, nullable) NSString *types;
 /// 位置偏向
@property (nonatomic, strong, nullable) MTCLocationBias *locationBias;
 /// 位置限定
@property (nonatomic, strong, nullable) MTCLocationLimit *locationLimit;
 /// 结果数量上限
@property (nonatomic, strong, nullable) NSNumber *resultLimit;
 /// IETF 语言标签
@property (nonatomic, copy, nullable) NSString *language;
 /// ccTLD 地区代码
@property (nonatomic, copy, nullable) NSString *region;
@end

 /// 正向地理编码请求参数
@interface MTCGeocodeRequest : NSObject <NSCopying>
 /// 地址文本（与 components 二选一）
@property (nonatomic, copy, nullable) NSString *address;
 /// 结构化地址组件，如 @"country:SG|postal_code:238801"
@property (nonatomic, copy, nullable) NSString *components;
 /// 位置偏向
@property (nonatomic, strong, nullable) MTCLocationBias *locationBias;
 /// IETF 语言标签
@property (nonatomic, copy, nullable) NSString *language;
 /// ccTLD 地区代码
@property (nonatomic, copy, nullable) NSString *region;
@end

 /// 反向地理编码请求参数
@interface MTCReverseGeocodeRequest : NSObject <NSCopying>
 /// 待解析的坐标（必填）
@property (nonatomic, strong) MTCCoordinate *location;
 /// 结果类型（必填），如 @"LOCALITY" | @"ADMINISTRATIVE_AREA_LEVEL_1"
@property (nonatomic, copy) NSString *resultType;
 /// 坐标精确度过滤
@property (nonatomic, copy, nullable) NSString *locationType;
 /// IETF 语言标签
@property (nonatomic, copy, nullable) NSString *language;
 /// ccTLD 地区代码
@property (nonatomic, copy, nullable) NSString *region;
@end

NS_ASSUME_NONNULL_END
