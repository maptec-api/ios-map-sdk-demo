#import <CoreLocation/CoreLocation.h>
#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

/**
 定位 marker 渲染模式。

 User location marker render mode.
 */
typedef NS_ENUM(NSInteger, MTCUserLocationRenderMode) {
    /**
     圆点模式，只显示前景圆点图片。

     Dot mode. Shows only the foreground dot image.
     */
    MTCUserLocationRenderModeDot = 0,

    /**
     方向模式，显示可旋转方向图片和前景圆点图片。

     Heading mode. Shows a rotating bearing image and the foreground dot image.
     */
    MTCUserLocationRenderModeHeading = 1,

    /**
     自定义模式，使用 `customMarkerImageSet` 中提供的图片；没有有效图片时不显示定位 marker。

     Custom mode. Uses images from `customMarkerImageSet`; the user location marker is hidden when no valid image is provided.
     */
    MTCUserLocationRenderModeCustom = 2,
};

/**
 用户位置跟随模式。

 User location tracking mode.
 */
typedef NS_ENUM(NSInteger, MTCUserLocationTrackingMode) {
    /**
     不跟随用户位置更新。

     Do not follow user location updates.
     */
    MTCUserLocationTrackingModeNone = 0,

    /**
     地图中心跟随用户位置更新。

     Follow user location updates by moving the map center.
     */
    MTCUserLocationTrackingModeFollow = 1,
};

/**
 用户定位朝向跟随模式。

 User location bearing tracking mode.
 */
typedef NS_ENUM(NSInteger, MTCUserBearingTrackingMode) {
    /**
     不自动改变地图 bearing。

     Do not automatically change the map bearing.
     */
    MTCUserBearingTrackingModeNone = 0,

    /**
     自动保持地图北向朝上，bearing 为 0。

     Keep the map north-up with bearing set to 0.
     */
    MTCUserBearingTrackingModeNorthUp = 1,

    /**
     地图 bearing 跟随设备 heading。

     Follow device heading for the map bearing.
     */
    MTCUserBearingTrackingModeHeading = 2,

    /**
     地图 bearing 跟随定位 course/GPS bearing。

     Follow location course/GPS bearing for the map bearing.
     */
    MTCUserBearingTrackingModeCourse = 3,
};

/**
 定位 marker 旋转角度数据源。

 User location marker bearing source.
 */
typedef NS_ENUM(NSInteger, MTCUserLocationMarkerBearingSource) {
    /**
     自动选择 marker 旋转数据源。圆点渲染模式下不旋转；其他渲染模式下优先使用有效且速度足够的定位 course，低速或无有效 course 时使用可用的设备 heading。

     Automatically choose the marker bearing source. Dot render mode does not rotate; other render modes prefer valid location course at sufficient speed and use available device heading at low speed or when course is unavailable.
     */
    MTCUserLocationMarkerBearingSourceAutomatic = 0,

    /**
     使用设备 heading 旋转 marker。

     Rotate the marker using device heading.
     */
    MTCUserLocationMarkerBearingSourceHeading = 1,

    /**
     使用定位 course/GPS bearing 旋转 marker。

     Rotate the marker using location course/GPS bearing.
     */
    MTCUserLocationMarkerBearingSourceCourse = 2,

    /**
     marker 不旋转，即使当前渲染模式包含方向图片。

     Do not rotate the marker, even when the current render mode includes a bearing image.
     */
    MTCUserLocationMarkerBearingSourceNone = 3,
};

/**
 定位 marker 图片集合。

 Image set for the user location marker.

 图片以中心点作为定位点和旋转中心。`bearingImage` 对应可旋转方向层，`foregroundImage` 对应前景层，`shadowImage` 对应阴影层。
 Images use their center as the location point and rotation center. `bearingImage` maps to the rotating bearing layer, `foregroundImage` maps to the foreground layer, and `shadowImage` maps to the shadow layer.
 */
NS_SWIFT_NAME(MTCUserLocationMarkerImageSet)
@interface MTCUserLocationMarkerImageSet : NSObject <NSCopying>

/**
 可旋转方向图片。为 `nil` 时不显示方向层。

 Rotating bearing image. When `nil`, the bearing layer is not shown.
 */
@property (nonatomic, strong, nullable) UIImage *bearingImage;

/**
 前景图片，通常为中心圆点。

 Foreground image, usually the centered dot.
 */
@property (nonatomic, strong, nullable) UIImage *foregroundImage;

/**
 阴影图片。当前 mapengine 阴影渲染支持由底层实现决定。

 Shadow image. Actual shadow rendering depends on the underlying mapengine implementation.
 */
@property (nonatomic, strong, nullable) UIImage *shadowImage;

@end

/**
 用户定位 marker 配置。

 Configuration for the user location marker.

 所有属性应在主线程修改。赋值给 `MTCMapView.userLocationConfig` 时 SDK 会复制该对象。
 Mutate properties on the main thread. The SDK copies this object when assigned to `MTCMapView.userLocationConfig`.
 */
NS_SWIFT_NAME(MTCUserLocationConfig)
@interface MTCUserLocationConfig : NSObject <NSCopying>

/**
 定位 marker 渲染模式。默认值为 `MTCUserLocationRenderModeDot`。

 User location marker render mode. Defaults to `MTCUserLocationRenderModeDot`.
 */
@property (nonatomic) MTCUserLocationRenderMode renderMode;

/**
 用户位置跟随模式。默认值为 `MTCUserLocationTrackingModeNone`。变化时通过 `mapView:didChangeUserLocationTrackingMode:` 通知。

 User location tracking mode. Defaults to `MTCUserLocationTrackingModeNone`. Changes are reported through `mapView:didChangeUserLocationTrackingMode:`.
 */
@property (nonatomic) MTCUserLocationTrackingMode locationTrackingMode;

/**
 用户定位朝向跟随模式。默认值为 `MTCUserBearingTrackingModeNone`。变化时通过 `mapView:didChangeUserBearingTrackingMode:` 通知。

 User location bearing tracking mode. Defaults to `MTCUserBearingTrackingModeNone`. Changes are reported through `mapView:didChangeUserBearingTrackingMode:`.
 */
@property (nonatomic) MTCUserBearingTrackingMode bearingTrackingMode;

/**
 定位 marker 旋转角度数据源。默认值为 `MTCUserLocationMarkerBearingSourceAutomatic`。该属性只影响定位 marker 旋转，不影响地图 camera bearing。

 User location marker bearing source. Defaults to `MTCUserLocationMarkerBearingSourceAutomatic`. This property affects only marker rotation and does not affect map camera bearing.
 */
@property (nonatomic) MTCUserLocationMarkerBearingSource markerBearingSource;

/**
 Heading 最小更新角度，单位为度，有效范围 0 到 360。默认值为 1 度，设置为 0 时不按角度过滤 heading 更新。

 Minimum heading update angle in degrees, from 0 to 360. Defaults to 1 degree. Set to 0 to disable angle-based heading filtering.
 */
@property (nonatomic) CLLocationDirection minimumHeadingUpdateAngle;

/**
 自定义 marker 图片集合，仅在 `renderMode` 为 `MTCUserLocationRenderModeCustom` 时使用。

 Custom marker image set. Used only when `renderMode` is `MTCUserLocationRenderModeCustom`.
 */
@property (nonatomic, copy, nullable) MTCUserLocationMarkerImageSet *customMarkerImageSet;

/**
 是否显示精度圈。默认值为 `YES`。

 Whether to show the accuracy circle. Defaults to `YES`.
 */
@property (nonatomic) BOOL showsAccuracyCircle;

/**
 精度圈填充颜色。默认值为 `#3A5EFB`。

 Accuracy circle fill color. Defaults to `#3A5EFB`.
 */
@property (nonatomic, strong) UIColor *accuracyCircleFillColor;

/**
 精度圈边框颜色。默认值为 `#3A5EFB`。

 Accuracy circle border color. Defaults to `#3A5EFB`.
 */
@property (nonatomic, strong) UIColor *accuracyCircleBorderColor;

/**
 精度圈透明度，取值范围 0 到 1。默认值为 0.2。

 Accuracy circle opacity, from 0 to 1. Defaults to 0.2.
 */
@property (nonatomic) CGFloat accuracyCircleAlpha;

/**
 精度圈半径，单位为米。设置为 0 时优先使用定位数据的 `horizontalAccuracy`。

 Accuracy circle radius in meters. When set to 0, the SDK prefers the location's `horizontalAccuracy`.
 */
@property (nonatomic) CLLocationDistance accuracyCircleRadius;

/**
 是否启用过期态。默认值为 `YES`。

 Whether stale state is enabled. Defaults to `YES`.
 */
@property (nonatomic, getter=isStaleStateEnabled) BOOL staleStateEnabled;

/**
 进入过期态的超时时间，单位为秒。默认值为 30 秒。

 Timeout before entering stale state, in seconds. Defaults to 30 seconds.
 */
@property (nonatomic) NSTimeInterval staleTimeout;

/**
 过期态 marker 颜色。默认值为 `#D1D4D8`。

 Marker tint color used in stale state. Defaults to `#D1D4D8`.
 */
@property (nonatomic, strong) UIColor *staleTintColor;

@end

NS_ASSUME_NONNULL_END
