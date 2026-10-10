//
//  MTCSearchError.h
//  MaptecMaps
//
//  Created by ZHOUPanpan on 2026/7/14.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

 
 #pragma mark - 搜索服务错误定义
 
 /// 搜索服务错误域标识符
FOUNDATION_EXPORT NSErrorDomain const MTCSearchServiceErrorDomain;
 /// 错误 UserInfo Key：HTTP 状态码
FOUNDATION_EXPORT NSString * const MTCSearchErrorHTTPStatusCodeKey;
 /// 错误 UserInfo Key：响应体原始字符串
FOUNDATION_EXPORT NSString * const MTCSearchErrorResponseBodyKey;
 /// 错误 UserInfo Key：服务端返回的错误码
FOUNDATION_EXPORT NSString * const MTCSearchErrorServerCodeKey;
 /// 错误 UserInfo Key：服务端返回的错误消息
FOUNDATION_EXPORT NSString * const MTCSearchErrorServerMessageKey;
 /// 错误 UserInfo Key：服务端要求的重试等待秒数
FOUNDATION_EXPORT NSString * const MTCSearchErrorRetryAfterKey;

 /// 搜索服务错误码枚举
typedef NS_ENUM(NSInteger, MTCSearchServiceErrorCode) {
     /// 配置无效（如 URL/APIKey 缺失）
    MTCSearchServiceErrorCodeInvalidConfiguration = 1,
     /// 请求参数非法
    MTCSearchServiceErrorCodeInvalidRequest,
     /// 网络请求失败
    MTCSearchServiceErrorCodeNetwork,
     /// 服务端返回非 2xx 状态码
    MTCSearchServiceErrorCodeHTTPStatus,
     /// 响应数据反序列化失败
    MTCSearchServiceErrorCodeSerialization,
     /// 服务端返回的业务错误
    MTCSearchServiceErrorCodeServerBusiness,
     /// 响应格式不符合预期
    MTCSearchServiceErrorCodeUnexpectedResponse,
};

NS_ASSUME_NONNULL_END
