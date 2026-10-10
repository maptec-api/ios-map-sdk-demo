//
//  MTCSearchServiceConfiguration.h
//  MaptecMaps
//
//  Created by ZHOUPanpan on 2026/7/14.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

 /// 搜索服务配置项：URL、鉴权、超时、重试策略、自定义 Header 和回调队列等
@interface MTCSearchServiceConfiguration : NSObject <NSCopying>

 /// 单次请求超时（秒），默认 30s
@property (nonatomic, assign) NSTimeInterval timeoutInterval;
 /// 资源级（如图片）超时（秒），默认 30s
@property (nonatomic, assign) NSTimeInterval resourceTimeoutInterval;
 /// 最大重试次数，默认 0，即不重试
@property (nonatomic, assign) NSInteger maxRetryCount;
 /// 重试基础延迟（秒），默认 0.3
@property (nonatomic, assign) NSTimeInterval retryBaseDelay;
 /// 重试延迟倍数，默认 2.0
@property (nonatomic, assign) double retryMultiplier;
 /// 附加请求头
@property (nonatomic, copy) NSDictionary<NSString *, NSString *> *additionalHeaders;
 /// 自定义 NSURLSession 配置，不设置则走默认
@property (nonatomic, strong, nullable) NSURLSessionConfiguration *sessionConfiguration;
 /// 回调队列，不设置则主线程回调
@property (nonatomic, strong, nullable) dispatch_queue_t callbackQueue;

 /// 使用内置默认值创建配置
+ (instancetype)defaultConfiguration;

@end

NS_ASSUME_NONNULL_END
