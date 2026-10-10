#import <CoreGraphics/CoreGraphics.h>
#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@class MTCClusterBadgeStyle;

/**
 聚合簇图标视觉半径模式。

 Cluster icon visual radius mode.
 */
typedef NS_ENUM(NSInteger, MTCClusterIconRadiusMode) {
    /**
     固定视觉半径。

     Fixed visual radius.
     */
    MTCClusterIconRadiusModeFixed = 0,

    /**
     按聚合点数自适应视觉半径。

     Adaptive visual radius based on point count.
     */
    MTCClusterIconRadiusModeAdaptive,
};

/**
 聚合自定义图标渲染模式。

 Cluster custom icon rendering mode.
 */
typedef NS_ENUM(NSInteger, MTCClusterIconRenderingMode) {
    /**
     按图片原始颜色渲染。

     Renders with the image's original colors.
     */
    MTCClusterIconRenderingModeOriginal = 0,

    /**
     按模板图标渲染，可通过样式进行着色和 halo 渲染。

     Renders as a template icon so tint and halo styling can be applied.
     */
    MTCClusterIconRenderingModeTemplate,
};

/**
 聚合簇图标视觉半径配置。

 Cluster icon visual radius configuration.

 `MTCClusterIconRadius` 控制簇图标的视觉缩放比例，不影响聚合距离；聚合距离由 `MTCCluster.clusterRadius` 控制。
 `MTCClusterIconRadius` controls the visual scale for cluster icons and does not affect clustering distance; clustering distance is controlled by `MTCCluster.clusterRadius`.
 */
NS_SWIFT_NAME(MTCClusterIconRadius)
@interface MTCClusterIconRadius : NSObject <NSCopying>

/**
 创建固定视觉半径配置。

 Creates a fixed visual radius configuration.

 @param radius 图标缩放比例，建议范围为 `[0.1, 64]`。The icon scale, recommended in `[0.1, 64]`.
 */
+ (instancetype)fixedRadius:(CGFloat)radius;

/**
 创建自适应视觉半径配置。

 Creates an adaptive visual radius configuration.

 @param minimumRadius 最小图标缩放比例。The minimum icon scale.
 @param maximumRadius 最大图标缩放比例。The maximum icon scale.
 @param maximumReference 最大参考聚合点数，必须大于等于 `1`。The maximum reference point count, which must be at least `1`.
 */
+ (instancetype)adaptiveWithMinimumRadius:(CGFloat)minimumRadius
                            maximumRadius:(CGFloat)maximumRadius
                         maximumReference:(NSUInteger)maximumReference;

- (instancetype)init NS_UNAVAILABLE;
+ (instancetype)new NS_UNAVAILABLE;

/**
 半径模式。

 The radius mode.
 */
@property (nonatomic, readonly) MTCClusterIconRadiusMode mode;

/**
 固定模式图标缩放比例。

 Fixed-mode icon scale.
 */
@property (nonatomic, readonly) CGFloat radius;

/**
 自适应模式最小图标缩放比例。

 Adaptive-mode minimum icon scale.
 */
@property (nonatomic, readonly) CGFloat minimumRadius;

/**
 自适应模式最大图标缩放比例。

 Adaptive-mode maximum icon scale.
 */
@property (nonatomic, readonly) CGFloat maximumRadius;

/**
 自适应模式最大参考聚合点数。

 Adaptive-mode maximum reference point count.
 */
@property (nonatomic, readonly) NSUInteger maximumReference;

@end

/**
 聚合簇样式基类。

 Base cluster style.

 `MTCClusterStyle` 只承载聚合簇图标布局和计数文字等公共样式。具体图标来源由子类表达：使用 SDK 绘制徽标时使用 `MTCClusterBadgeStyle`，使用自定义图片时使用 `MTCClusterCustomIconStyle`。
 `MTCClusterStyle` carries only shared cluster icon layout and count text styling. Concrete icon sources are expressed by subclasses: use `MTCClusterBadgeStyle` for SDK-drawn badges and `MTCClusterCustomIconStyle` for custom images.

 数量范围由 `MTCClusterStyleRule` 表达，避免把匹配条件混入样式对象。
 Count ranges are expressed by `MTCClusterStyleRule` so matching conditions do not leak into the style object.
 */
NS_SWIFT_NAME(MTCClusterStyle)
@interface MTCClusterStyle : NSObject <NSCopying>

/**
 SDK 默认基础簇徽标样式。

 SDK default base cluster badge style.
 */
+ (MTCClusterBadgeStyle *)defaultStyle;

/**
 图标整体透明度。

 Overall icon opacity.

 取值范围为 `[0, 1]`。默认值为 `1`。
 The valid range is `[0, 1]`. The default value is `1`.
 */
@property (nonatomic) CGFloat opacity;

/**
 图标缩放系数。

 Icon scale factor.

 默认值为 `1`。当 `MTCCluster.iconRadius` 已设置时，视觉半径优先生效，该值作为未设置视觉半径时的回退。
 The default value is `1`. When `MTCCluster.iconRadius` is set, the visual radius takes precedence and this value is used only as fallback.
 */
@property (nonatomic) CGFloat scale;

/**
 图标旋转角度，单位为度。

 Icon rotation in degrees.

 默认值为 `0`。
 The default value is `0`.
 */
@property (nonatomic) CGFloat rotation;

/**
 图标偏移，单位为 point。

 Icon offset in points.

 默认值为 `CGPointZero`。
 The default value is `CGPointZero`.
 */
@property (nonatomic) CGPoint offset;

/**
 图标锚点。

 The icon anchor.

 默认值为 `{0.5, 0.5}`。
 The default value is `{0.5, 0.5}`.
 */
@property (nonatomic) CGPoint anchor;

/**
 簇计数文字字号，单位为 point。

 Cluster count text size in points.

 默认值为 `12`。
 The default value is `12`.
 */
@property (nonatomic) CGFloat textFontSize;

/**
 簇计数文字颜色。

 Cluster count text color.

 默认值为白色。
 The default value is white.
 */
@property (nonatomic, strong) UIColor *textColor;

/**
 文字偏移，单位为 point。

 Text offset in points.

 默认值为 `CGPointZero`。
 The default value is `CGPointZero`.
 */
@property (nonatomic) CGPoint textOffset;

/**
 文字旋转角度，单位为度。

 Text rotation in degrees.

 默认值为 `0`。
 The default value is `0`.
 */
@property (nonatomic) CGFloat textRotation;

/**
 文字锚点。

 The text anchor.

 默认值为 `{0.5, 0.5}`。
 The default value is `{0.5, 0.5}`.
 */
@property (nonatomic) CGPoint textAnchor;

/**
 自定义簇文字。

 Custom cluster text.

 默认值为 `nil`，表示显示聚合计数；是否缩写由 `MTCCluster.countAbbreviationEnabled` 决定。设置后该样式命中的簇显示固定文字。
 The default value is `nil`, which displays the cluster count; abbreviation is controlled by `MTCCluster.countAbbreviationEnabled`. When set, clusters matching this style display the fixed text.
 */
@property (nonatomic, copy, nullable) NSString *text;

@end

/**
 SDK 绘制的聚合簇徽标样式。

 SDK-drawn cluster badge style.

 `MTCClusterBadgeStyle` 由 SDK 根据填充色、描边色和描边宽度生成固定尺寸徽标位图。描边向内绘制，增大描边宽度不会扩大徽标整体尺寸。
 `MTCClusterBadgeStyle` lets the SDK generate a fixed-size badge bitmap from fill and stroke styling. The stroke is drawn inward, so increasing stroke width does not expand the badge's overall size.
 */
NS_SWIFT_NAME(MTCClusterBadgeStyle)
@interface MTCClusterBadgeStyle : MTCClusterStyle

/**
 徽标填充颜色。

 Badge fill color.

 默认值为白色。若只需要调整填充透明度，可设置颜色自身的 alpha；`opacity` 会影响整个徽标图标。
 The default value is white. To adjust only fill transparency, set the color's own alpha; `opacity` affects the whole badge icon.
 */
@property (nonatomic, strong) UIColor *fillColor;

/**
 徽标描边颜色。

 Badge stroke color.

 默认值为黑色。
 The default value is black.
 */
@property (nonatomic, strong) UIColor *strokeColor;

/**
 徽标描边宽度，单位为 point。

 Badge stroke width in points.

 默认值为 `0`，SDK 默认徽标样式为 `2`。描边向内绘制，不改变徽标整体尺寸。
 The default value is `0`; SDK default badge styles use `2`. The stroke is drawn inward and does not change the badge's overall size.
 */
@property (nonatomic) CGFloat strokeWidth;

@end

/**
 自定义图片聚合簇样式。

 Custom image cluster style.

 `MTCClusterCustomIconStyle` 使用业务提供的图片作为聚合簇图标。原图渲染适合彩色图片；模板渲染适合单色 mask 图片，并允许通过 `tintColor` 与 halo 属性动态着色。
 `MTCClusterCustomIconStyle` uses an application-provided image as the cluster icon. Original rendering is suitable for colored images; template rendering is suitable for monochrome mask images and allows dynamic styling through `tintColor` and halo properties.
 */
NS_SWIFT_NAME(MTCClusterCustomIconStyle)
@interface MTCClusterCustomIconStyle : MTCClusterStyle

/**
 自定义图标图片。

 Custom icon image.

 默认值为 `nil`。传入 `nil` 时使用透明占位图，实际效果可能不可见。
 The default value is `nil`. Passing `nil` uses a transparent placeholder, which may be invisible.
 */
@property (nonatomic, strong, nullable) UIImage *image;

/**
 自定义图标资源标识。

 Custom icon resource identifier.

 默认值由 SDK 自动生成。相同图片和相同标识可被底层复用；自定义图片建议提供稳定且唯一的标识。
 The default value is generated by the SDK. The renderer may reuse the same image and identifier; custom images should use a stable and unique identifier.
 */
@property (nonatomic, copy, nullable) NSString *imageIdentifier;

/**
 自定义图标渲染模式。

 Custom icon rendering mode.

 默认值为 `MTCClusterIconRenderingModeOriginal`。模板模式适合单色 mask 图标，可通过 `tintColor`、`haloColor` 和 `haloWidth` 进行样式化。
 The default value is `MTCClusterIconRenderingModeOriginal`. Template mode is suitable for monochrome mask icons and can be styled through `tintColor`, `haloColor`, and `haloWidth`.
 */
@property (nonatomic) MTCClusterIconRenderingMode renderingMode;

/**
 模板图标着色颜色。

 Template icon tint color.

 默认值为白色。仅当 `renderingMode` 为 `MTCClusterIconRenderingModeTemplate` 时由底层稳定生效。
 The default value is white. It is reliably applied by the renderer only when `renderingMode` is `MTCClusterIconRenderingModeTemplate`.
 */
@property (nonatomic, strong) UIColor *tintColor;

/**
 模板图标 halo 颜色。

 Template icon halo color.

 默认值为黑色。仅当 `renderingMode` 为 `MTCClusterIconRenderingModeTemplate` 时由底层稳定生效。
 The default value is black. It is reliably applied by the renderer only when `renderingMode` is `MTCClusterIconRenderingModeTemplate`.
 */
@property (nonatomic, strong) UIColor *haloColor;

/**
 模板图标 halo 宽度，单位为 point。

 Template icon halo width in points.

 默认值为 `0`。仅当 `renderingMode` 为 `MTCClusterIconRenderingModeTemplate` 时由底层按 halo 宽度处理。
 The default value is `0`. It is applied as renderer halo width only when `renderingMode` is `MTCClusterIconRenderingModeTemplate`.
 */
@property (nonatomic) CGFloat haloWidth;

@end

NS_ASSUME_NONNULL_END
