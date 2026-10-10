#import <CoreGraphics/CoreGraphics.h>
#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

/**
 多边形填充图案类型。

 Polygon fill pattern type.
 */
typedef NS_ENUM(NSInteger, MTCPolygonFillPatternType) {
    /**
     纯色填充。

     Solid color fill.
     */
    MTCPolygonFillPatternTypeSolid = 0,

    /**
     程序化斜线填充。

     Procedural diagonal hatch fill.
     */
    MTCPolygonFillPatternTypeDiagonal,

    /**
     程序化网格填充。

     Procedural grid fill.
     */
    MTCPolygonFillPatternTypeGrid,

    /**
     程序化点状填充。

     Procedural dot fill.
     */
    MTCPolygonFillPatternTypeDot,

    /**
     图片纹理填充。

     Image texture fill.

     仅当类型为该值时，`fillPatternImage` 会参与渲染。
     `fillPatternImage` is used for rendering only when this type is selected.
     */
    MTCPolygonFillPatternTypeImage,
};

/**
 多边形混合模式。

 Polygon blend mode.
 */
typedef NS_ENUM(NSInteger, MTCPolygonBlendMode) {
    /**
     正常混合。

     Normal blend.
     */
    MTCPolygonBlendModeNormal = 0,

    /**
     正片叠底混合。

     Multiply blend.
     */
    MTCPolygonBlendModeMultiply,

    /**
     滤色混合。

     Screen blend.
     */
    MTCPolygonBlendModeScreen,

    /**
     叠加混合。

     Overlay blend.
     */
    MTCPolygonBlendModeOverlay,
};

/**
 多边形平移锚点。

 Polygon translate anchor.
 */
typedef NS_ENUM(NSInteger, MTCPolygonTranslateAnchor) {
    /**
     相对地图平面解释平移偏移。

     Interprets translation relative to the map plane.
     */
    MTCPolygonTranslateAnchorMap = 0,

    /**
     相对屏幕视口解释平移偏移。

     Interprets translation relative to the screen viewport.
     */
    MTCPolygonTranslateAnchorViewport,
};

/**
 多边形样式。

 Polygon style.

 `MTCPolygonStyle` 描述多边形填充和边框渲染样式。设置到 `MTCPolygon` 时 SDK 会复制样式快照。
 `MTCPolygonStyle` describes polygon fill and stroke rendering. The SDK copies the style when it is assigned to an `MTCPolygon`.
 */
NS_SWIFT_NAME(MTCPolygonStyle)
@interface MTCPolygonStyle : NSObject <NSCopying>

/**
 填充颜色。

 The fill color.

 默认值为蓝色 `#0066FF`。
 The default value is blue `#0066FF`.
 */
@property (nonatomic, strong) UIColor *fillColor;

/**
 填充透明度。

 The fill opacity.

 取值范围为 `[0, 1]`。默认值为 `0.5`。
 The valid range is `[0, 1]`. The default value is `0.5`.
 */
@property (nonatomic) CGFloat fillOpacity;

/**
 填充图案类型。

 The fill pattern type.

 默认值为 `MTCPolygonFillPatternTypeSolid`。斜线、网格和点状图案由 SDK/引擎程序化绘制，不需要图片资源。
 The default value is `MTCPolygonFillPatternTypeSolid`. Diagonal, grid, and dot patterns are procedurally rendered and do not require image resources.
 */
@property (nonatomic) MTCPolygonFillPatternType fillPatternType;

/**
 填充图片纹理。

 The fill pattern image.

 仅当 `fillPatternType` 为 `MTCPolygonFillPatternTypeImage` 时使用。默认值为 `nil`，缺少图片时回退为纯色填充。
 Used only when `fillPatternType` is `MTCPolygonFillPatternTypeImage`. The default value is `nil`; missing images fall back to solid fill.
 */
@property (nonatomic, strong, nullable) UIImage *fillPatternImage;

/**
 是否启用填充抗锯齿。

 Whether fill antialiasing is enabled.

 默认值为 `YES`。该属性控制多边形填充边缘的抗锯齿渲染。
 The default value is `YES`. This property controls antialiasing for polygon fill edges.
 */
@property (nonatomic, getter=isFillAntialias) BOOL fillAntialias;

/**
 边框颜色。

 The stroke color.

 默认值为蓝色 `#0066FF`。
 The default value is blue `#0066FF`.
 */
@property (nonatomic, strong) UIColor *strokeColor;

/**
 边框宽度，单位为 point。

 The stroke width, in points.

 默认值为 `2`。传入 `0` 表示不绘制边框。
 The default value is `2`. Use `0` to hide the stroke.
 */
@property (nonatomic) CGFloat strokeWeight;

/**
 边框透明度。

 The stroke opacity.

 取值范围为 `[0, 1]`。默认值为 `1`。
 The valid range is `[0, 1]`. The default value is `1`.
 */
@property (nonatomic) CGFloat strokeOpacity;

/**
 边框虚线样式。

 The stroke dash pattern.

 数组按绘制长度、间隔长度交替解释。默认值为空数组，表示实线。
 The array is interpreted as alternating drawn and gap lengths. The default is an empty array, which means a solid stroke.
 */
@property (nonatomic, copy) NSArray<NSNumber *> *strokeDashArray;

/**
 多边形整体平移偏移。

 The polygon translation offset.

 该偏移同时作用于填充和描边，单位为 point。默认值为 `{0, 0}`，表示不平移。
 This offset applies to both fill and stroke, in points. The default value is `{0, 0}`, which means no translation.
 */
@property (nonatomic) CGPoint translate;

/**
 多边形平移锚点。

 The polygon translation anchor.

 默认值为 `MTCPolygonTranslateAnchorMap`。
 The default value is `MTCPolygonTranslateAnchorMap`.
 */
@property (nonatomic) MTCPolygonTranslateAnchor translateAnchor;

/**
 混合模式。

 The blend mode.

 默认值为 `MTCPolygonBlendModeNormal`。
 The default value is `MTCPolygonBlendModeNormal`.
 */
@property (nonatomic) MTCPolygonBlendMode blendMode;

@end

NS_ASSUME_NONNULL_END
