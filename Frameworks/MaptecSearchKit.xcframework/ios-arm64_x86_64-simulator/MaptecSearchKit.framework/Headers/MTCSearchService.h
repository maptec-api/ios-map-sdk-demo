//
//  MTCSearchService.h
//  MaptecMaps
//
//  Created by ZHOUPanpan on 2026/7/14.
//

#import <Foundation/Foundation.h>

#import <MaptecSearchKit/MTCSearchTypes.h>

@class MTCTextSearchRequest, MTCNearbySearchRequest, MTCAlongRouteSearchRequest, MTCSuggestRequest;
@class MTCTextSearchResponse, MTCNearbySearchResponse, MTCAlongRouteSearchResponse, MTCSuggestResponse, MTCPlaceDetailResponse, MTCAuthStatusResponse;
@class MTCSearchServiceConfiguration;
NS_ASSUME_NONNULL_BEGIN

/// search 搜索服务：封装文本搜索、附近搜索、输入提示、地点详情、图片获取、鉴权查询等接口
@interface MTCSearchService : NSObject

 /// 当前配置
@property (nonatomic, strong, readonly) MTCSearchServiceConfiguration *configuration;

+ (instancetype)sharedService;
 /// 以指定配置初始化
- (instancetype)initWithConfiguration:(nullable MTCSearchServiceConfiguration *)configuration NS_DESIGNATED_INITIALIZER;

 /// 文本搜索
- (void)textSearchWithRequest:(MTCTextSearchRequest *)request completion:(void (^)(MTCTextSearchResponse * _Nullable response, NSError * _Nullable error))completion NS_SWIFT_NAME(textSearch(request:completion:));
/// 附近搜索
- (void)nearbySearchWithRequest:(MTCNearbySearchRequest *)request completion:(void (^)(MTCNearbySearchResponse * _Nullable response, NSError * _Nullable error))completion NS_SWIFT_NAME(nearbySearch(request:completion:));
/// 沿途搜索
- (void)alongRouteSearchWithRequest:(MTCAlongRouteSearchRequest *)request completion:(void (^)(MTCAlongRouteSearchResponse * _Nullable response, NSError * _Nullable error))completion NS_SWIFT_NAME(alongRouteSearch(request:completion:));
/// 输入提示（自动补全）
- (void)suggestWithRequest:(MTCSuggestRequest *)request completion:(void (^)(MTCSuggestResponse * _Nullable response, NSError * _Nullable error))completion NS_SWIFT_NAME(suggest(request:completion:));
 /// 获取地点详情
- (void)fetchPlaceDetailWithPlaceID:(NSString *)placeID
                            language:(nullable NSString *)language
                              region:(nullable NSString *)region
                         extraFields:(nullable NSArray<NSString *> *)extraFields
                          completion:(void (^)(MTCPlaceDetailResponse * _Nullable response, NSError * _Nullable error))completion NS_SWIFT_NAME(fetchPlaceDetail(placeID:language:region:extraFields:completion:));
 /// 获取地点照片
- (void)fetchPhotoWithName:(NSString *)photoName maxHeightPx:(nullable NSNumber *)maxHeightPx maxWidthPx:(nullable NSNumber *)maxWidthPx completion:(MTCSearchDataCompletion)completion NS_SWIFT_NAME(fetchPhoto(name:maxHeightPx:maxWidthPx:completion:));
 /// 查询鉴权状态（获取 API Key 可用的资源 URL）
- (void)fetchAuthStatusWithCompletion:(void (^)(MTCAuthStatusResponse * _Nullable response, NSError * _Nullable error))completion NS_SWIFT_NAME(fetchAuthStatus(completion:));

- (instancetype)init NS_UNAVAILABLE;
+ (instancetype)new NS_UNAVAILABLE;

@end

NS_ASSUME_NONNULL_END
