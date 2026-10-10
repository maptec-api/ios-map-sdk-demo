//
//  MTCRouteService.h
//  MaptecMaps
//
//  Created by ZHOUPanpan on 2026/7/16.
//

#import <Foundation/Foundation.h>

@class MTCSearchServiceConfiguration;
@class MTCRouteRequest;
@class MTCRouteResponse;
NS_ASSUME_NONNULL_BEGIN

/// 路线规划服务：封装 `routes/v1/directions` 请求
@interface MTCRouteService : NSObject

@property (nonatomic, strong, readonly) MTCSearchServiceConfiguration *configuration;

+ (instancetype)sharedService;

/// 使用指定配置初始化。
- (instancetype)initWithConfiguration:(nullable MTCSearchServiceConfiguration *)configuration NS_DESIGNATED_INITIALIZER;

/// 发起Route请求
- (void)calculateRouteWithRequest:(MTCRouteRequest *)request completion:(void (^)(MTCRouteResponse * _Nullable response, NSError * _Nullable error))completion NS_SWIFT_NAME(calculateRoute(request:completion:));

- (instancetype)init NS_UNAVAILABLE;
+ (instancetype)new NS_UNAVAILABLE;

@end

NS_ASSUME_NONNULL_END
