#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/**
 地图标签语言。

 Map label language.

 该枚举用于选择底图文字标签读取的矢量瓦片名称字段。实际显示取决于瓦片数据是否包含对应的 `name:xx` 字段；缺失时引擎会回退到英文或默认名称字段。
 This enum selects the vector tile name field used by base-map text labels. The effective display depends on whether the tile data contains the matching `name:xx` field; missing fields fall back to English or the default name field.
 */
typedef NS_ENUM(NSInteger, MTCMapLanguage) {
    /**
     使用矢量瓦片默认 `name` 字段。

     Uses the vector tile default `name` field.
     */
    MTCMapLanguageDefault = 0,

    /**
     英语，BCP 47 标签为 `en`。

     English, with BCP 47 tag `en`.
     */
    MTCMapLanguageEnglish,

    /**
     中文，BCP 47 标签为 `zh`。

     Chinese, with BCP 47 tag `zh`.
     */
    MTCMapLanguageChinese,

    /**
     马来语，BCP 47 标签为 `ms`。

     Malay, with BCP 47 tag `ms`.
     */
    MTCMapLanguageMalay,

    /**
     泰语，BCP 47 标签为 `th`。

     Thai, with BCP 47 tag `th`.
     */
    MTCMapLanguageThai,

    /**
     阿拉伯语，BCP 47 标签为 `ar`。

     Arabic, with BCP 47 tag `ar`.
     */
    MTCMapLanguageArabic,
} NS_SWIFT_NAME(MTCMapLanguage);

/**
 Maptec SDK 级服务配置。

 Service-level configuration for Maptec SDKs.

 该类只依赖 Foundation，可在应用启动时设置全局配置。请在创建 `MTCMapView` 或加载 Maptec 托管资源前设置 API Key。
 This class only depends on Foundation and is intended for global configuration at app startup. Set the API key before creating `MTCMapView` instances or loading Maptec-hosted resources.
 */
NS_SWIFT_NAME(MTCMapServices)
@interface MTCMapServices : NSObject

/**
 获取共享服务配置对象。

 Returns the shared service configuration object.

 返回值在进程内唯一。不要直接创建 `MTCMapServices` 实例。
 The returned object is process-wide. Do not instantiate `MTCMapServices` directly.
 */
+ (instancetype)sharedServices;

- (instancetype)init NS_UNAVAILABLE;
+ (instancetype)new NS_UNAVAILABLE;

/**
 Maptec API Key。

 The Maptec API key used for Maptec-hosted resources.

 默认为 `nil`。应用应在创建地图视图前设置业务自己的 Key；当该值为空时，MaptecMaps 不会为托管资源请求附加 API Key。
 The default is `nil`. Apps should set their own key before creating map views; when this value is empty, MaptecMaps does not attach an API key to hosted resource requests.
 */
@property (nonatomic, copy) NSString *apiKey;

/// SHA1 签名密钥
@property (nonatomic, copy, nullable) NSString *signatureSHA1;

@end

NS_ASSUME_NONNULL_END
