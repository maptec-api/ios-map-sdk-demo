#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/**
 地图错误域。

 Error domain for map-level failures.
 */
FOUNDATION_EXPORT NSErrorDomain const MTCMapErrorDomain;

/**
 地图错误码。

 Error codes for map-level failures.
 */
typedef NS_ERROR_ENUM(MTCMapErrorDomain, MTCMapErrorCode) {
    /// 地图资源解析失败。
    /// Map resource parsing failed.
    MTCMapErrorMapResourceParse = 1,

    /// 地图资源加载失败。
    /// Map resource loading failed.
    MTCMapErrorMapResourceLoad = 2,

    /// 资源不存在。
    /// The requested resource was not found.
    MTCMapErrorNotFound = 3,

    /// 未知地图加载错误。
    /// Unknown map loading error.
    MTCMapErrorUnknown = 999,
};

/**
 地图显示模式。

 Map display mode.
 */
typedef NS_ENUM(NSInteger, MTCMapDisplayMode) {
    /// 2D 显示模式。
    /// 2D display mode.
    MTCMapDisplayMode2D = 0,

    /// 3D 显示模式。
    /// 3D display mode.
    MTCMapDisplayMode3D
};

/**
 地图内建 UI 的布局位置。

 Built-in map UI layout position.
 */
typedef NS_OPTIONS(NSUInteger, MTCUIPosition) {
    /// 顶部。
    /// Top edge.
    MTCUIPositionTop      = 1 << 0,

    /// 底部。
    /// Bottom edge.
    MTCUIPositionBottom   = 1 << 1,

    /// 左侧。
    /// Left edge.
    MTCUIPositionLeft     = 1 << 8,

    /// 右侧。
    /// Right edge.
    MTCUIPositionRight    = 1 << 9,

    /// 居中。
    /// Center.
    MTCUIPositionCenter   = 1 << 10,
};

/**
 缩放级别文字在缩放按钮组中的位置。

 Position of the zoom level tile inside the built-in zoom button group.
 */
typedef NS_ENUM(NSInteger, MTCZoomLevelPosition) {
    /**
     缩放级别文字在顶部，即 text + -。

     Zoom level tile on top: text, plus, minus.
     */
    MTCZoomLevelPositionTop = 0,

    /**
     缩放级别文字在中间，即 + text -。

     Zoom level tile in the middle: plus, text, minus.
     */
    MTCZoomLevelPositionMiddle,

    /**
     缩放级别文字在底部，即 + - text。

     Zoom level tile on the bottom: plus, minus, text.
     */
    MTCZoomLevelPositionBottom,
};

/**
 缩放级别文字的小数精度。

 Decimal precision used by the built-in zoom level label.
 */
typedef NS_ENUM(NSInteger, MTCZoomLevelPrecision) {
    /**
     不显示小数，例如 `12`。

     Shows no decimal places, for example `12`.
     */
    MTCZoomLevelPrecisionInteger = 0,

    /**
     显示 1 位小数，例如 `12.1`。

     Shows one decimal place, for example `12.1`.
     */
    MTCZoomLevelPrecisionOneDecimal,

    /**
     显示 2 位小数，例如 `12.12`。

     Shows two decimal places, for example `12.12`.
     */
    MTCZoomLevelPrecisionTwoDecimals,

    /**
     显示 3 位小数，例如 `12.123`。

     Shows three decimal places, for example `12.123`.
     */
    MTCZoomLevelPrecisionThreeDecimals,
};

/**
 地图相机变化来源。

 The source that caused a map camera change.
 */
typedef NS_ENUM(NSInteger, MTCMapCameraChangeReason) {
    /**
     原因未知。

     The reason is unknown.
     */
    MTCMapCameraChangeReasonUnknown = 0,

    /**
     由 API 调用触发。

     Triggered by an API call.
     */
    MTCMapCameraChangeReasonProgrammatic,

    /**
     由用户手势触发。

     Triggered by a user gesture.
     */
    MTCMapCameraChangeReasonGesture,

    /**
     由地图初始相机状态触发。

     Triggered by the initial camera state.
     */
    MTCMapCameraChangeReasonInitial,
};

/**
 地图类型。

 Map type.
 */
typedef NS_ENUM(NSInteger, MTCMapType) {
    /**
     标准地图。

     Standard map.
     */
    MTCMapTypeStandard = 0,

    /**
     夜间地图。

     Night map.
     */
    MTCMapTypeNight,

    /**
     标准路况地图。

     Standard traffic map.
     */
    MTCMapTypeTrafficStandard,

    /**
     夜间路况地图。

     Night traffic map.
     */
    MTCMapTypeTrafficNight,
};

#pragma mark - 信息窗口

///   锚点类型
typedef NS_ENUM(NSInteger, MTCFloatInfoWindowAnchor) {
    MTCFloatInfoWindowAnchorUnkown = 0,
    MTCFloatInfoWindowAnchorBottom,
    MTCFloatInfoWindowAnchorCenter,
    MTCFloatInfoWindowAnchorTop,
    MTCFloatInfoWindowAnchorLeft,
    MTCFloatInfoWindowAnchorRight,
    MTCFloatInfoWindowAnchorTopLeft,
    MTCFloatInfoWindowAnchorTopRight,
    MTCFloatInfoWindowAnchorBottomLeft,
    MTCFloatInfoWindowAnchorBottomRight,
};

NS_ASSUME_NONNULL_END
