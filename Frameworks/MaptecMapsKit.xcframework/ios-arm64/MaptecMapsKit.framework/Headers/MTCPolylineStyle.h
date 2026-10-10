#import <CoreGraphics/CoreGraphics.h>
#import <Foundation/Foundation.h>
#import <MaptecMapsKit/MTCLineGradient.h>
#import <MaptecMapsKit/MTCLineStyle.h>
#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

/**
 折线样式。

 Polyline style.

 `MTCPolylineStyle` 描述基础折线渲染样式。设置到 `MTCPolyline` 时 SDK 会复制样式快照。
 `MTCPolylineStyle` describes the basic rendering style for a polyline. The SDK copies the style when it is assigned to an `MTCPolyline`.
 */
NS_SWIFT_NAME(MTCPolylineStyle)
@interface MTCPolylineStyle : NSObject <NSCopying>

/**
 线条颜色。

 The stroke color.

 默认值为蓝色 `#0066FF`。
 The default value is blue `#0066FF`.
 */
@property (nonatomic, strong) UIColor *strokeColor;

/**
 折线沿线颜色渐变。

 The line color gradient.

 默认值为 `nil`，表示使用 `strokeColor` 单色绘制。设置有效渐变后，普通线模式下主线颜色按 `lineProgress` 沿线渐变，并覆盖 `strokeColor` 单色填充。
 The default value is `nil`, which draws the line with `strokeColor`. When a valid gradient is set, the main stroke color uses the gradient by `lineProgress` in normal line mode and overrides the solid `strokeColor` fill.
 */
@property (nonatomic, copy, nullable) MTCLineGradient *lineGradient;

/**
 线条宽度，单位为 point。

 The stroke width, in points.

 默认值为 `3`，有效值应大于 `0`。
 The default value is `3`; valid values should be greater than `0`.
 */
@property (nonatomic) CGFloat strokeWeight;

/**
 线条透明度。

 The stroke opacity.

 取值范围为 `[0, 1]`。默认值为 `1`。
 The valid range is `[0, 1]`. The default value is `1`.
 */
@property (nonatomic) CGFloat strokeOpacity;

/**
 虚线样式。

 The dash pattern.

 数组按绘制长度、间隔长度交替解释。默认值为空数组，表示实线。
 The array is interpreted as alternating drawn and gap lengths. The default is an empty array, which means a solid line.

 当前渲染实现不支持虚线与外发光或沿线方向箭头组合使用。启用 `glowEffect` 或 `directionalArrowStyle.enabled` 时，应保持该数组为空；否则渲染结果未定义，可能出现虚线被忽略、外发光不生效或线宽异常。
 The current renderer does not support combining dashed lines with outer glow or directional arrows. Keep this array empty when `glowEffect` or `directionalArrowStyle.enabled` is enabled; otherwise rendering is undefined and may ignore the dash pattern, disable glow, or produce an unexpected line width.
 */
@property (nonatomic, copy) NSArray<NSNumber *> *strokeDashArray;

/**
 起点端点样式。

 The start line cap.
 */
@property (nonatomic) MTCLineCapType startLineCapType;

/**
 终点端点样式。

 The end line cap.
 */
@property (nonatomic) MTCLineCapType endLineCapType;

/**
 线段连接处样式。

 The style used where line segments join.

 默认值为 `MTCLineJoinTypeMiter`。
 The default value is `MTCLineJoinTypeMiter`.
 */
@property (nonatomic) MTCLineJoinType lineJoinType;

/**
 Miter 连接样式的斜接限制值。

 The miter limit used by the miter line join style.

 仅当 `lineJoinType` 为 `MTCLineJoinTypeMiter` 时生效。默认值为 `2.0`，有效值应大于等于 `0`。
 This value only takes effect when `lineJoinType` is `MTCLineJoinTypeMiter`. The default value is `2.0`; valid values should be greater than or equal to `0`.
 */
@property (nonatomic) CGFloat miterLimit;

/**
 是否启用外发光效果。

 Whether the outer glow effect is enabled.

 默认值为 `NO`。外发光当前仅支持实线；启用时请保持 `strokeDashArray` 为空。
 The default value is `NO`. Outer glow currently supports solid lines only; keep `strokeDashArray` empty when this is enabled.
 */
@property (nonatomic) BOOL glowEffect;

/**
 发光颜色。

 The glow color.

 默认值与 `strokeColor` 相同。
 The default value matches `strokeColor`.
 */
@property (nonatomic, strong) UIColor *glowColor;

/**
 发光半径。

 The glow radius.

 默认值为 `10`。
 The default value is `10`.
 */
@property (nonatomic) CGFloat glowRadius;

/**
 沿线方向箭头样式。

 Directional arrow style along the polyline.

 默认值为未启用的 `MTCLineDirectionalArrowStyle`。设置到 `MTCPolyline` 时 SDK 会复制样式及其箭头样式。沿线方向箭头当前仅支持实线；启用时请保持 `strokeDashArray` 为空。
 The default value is a disabled `MTCLineDirectionalArrowStyle`. When assigned to an `MTCPolyline`, the SDK copies the style and its directional arrow style. Directional arrows currently support solid lines only; keep `strokeDashArray` empty when they are enabled.
 */
@property (nonatomic, copy) MTCLineDirectionalArrowStyle *directionalArrowStyle;

@end

NS_ASSUME_NONNULL_END
