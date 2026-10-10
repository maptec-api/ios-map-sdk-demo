//
//  MTCGeocodeService.h
//  MaptecMaps
//
//  Created by ZHOUPanpan on 2026/7/14.
//

#import <Foundation/Foundation.h>

@class MTCSearchServiceConfiguration;
@class MTCGeocodeRequest,MTCReverseGeocodeRequest;
@class MTCGeocodeResponse;
NS_ASSUME_NONNULL_BEGIN

 /// GEO编码搜索服务：正向地理编码（地址→坐标）和反向地理编码（坐标→地址）
@interface MTCGeocodeService : NSObject

@property (nonatomic, strong, readonly) MTCSearchServiceConfiguration *configuration;

+ (instancetype)sharedService;
 /// 以指定配置初始化
- (instancetype)initWithConfiguration:(nullable MTCSearchServiceConfiguration *)configuration NS_DESIGNATED_INITIALIZER;

 /// 正向地理编码（地址 → 坐标）
- (void)geocodeWithRequest:(MTCGeocodeRequest *)request completion:(void (^)(MTCGeocodeResponse * _Nullable response, NSError * _Nullable error))completion NS_SWIFT_NAME(geocode(request:completion:));
 /// 反向地理编码（坐标 → 地址）
- (void)reverseGeocodeWithRequest:(MTCReverseGeocodeRequest *)request completion:(void (^)(MTCGeocodeResponse * _Nullable response, NSError * _Nullable error))completion NS_SWIFT_NAME(reverseGeocode(request:completion:));

- (instancetype)init NS_UNAVAILABLE;
+ (instancetype)new NS_UNAVAILABLE;
@end

NS_ASSUME_NONNULL_END
