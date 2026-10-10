#import <CoreGraphics/CoreGraphics.h>
#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

/**
 圆覆盖物样式。

 Circle overlay style.

 `MTCCircleStyle` 描述圆的填充、边框、阴影、发光和动画配置。设置到 `MTCCircle` 时 SDK 会复制样式快照。
 `MTCCircleStyle` describes circle fill, stroke, shadow, glow, and animation configuration. The SDK copies the style when it is assigned to an `MTCCircle`.
 */
NS_SWIFT_NAME(MTCCircleStyle)
@interface MTCCircleStyle : NSObject <NSCopying>

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

 取值范围为 `[0, 1]`。默认值为 `1.0`。当 `strokeWeight` 为 `0` 时不会绘制边框。
 The valid range is `[0, 1]`. The default value is `1.0`. No stroke is rendered when `strokeWeight` is `0`.
 */
@property (nonatomic) CGFloat strokeOpacity;

/**
 是否启用内阴影。

 Whether the inner shadow is enabled.

 默认值为 `NO`。当前渲染模式不支持时，设置会被保留但没有视觉效果。
 The default value is `NO`. If the current render mode does not support it, the value is retained but has no visual effect.
 */
@property (nonatomic, getter=isInnerShadowEnabled) BOOL innerShadow;

/**
 内阴影颜色。

 The inner shadow color.

 默认值为黑色 `#000000`。
 The default value is black `#000000`.
 */
@property (nonatomic, strong) UIColor *innerShadowColor;

/**
 内阴影透明度。

 The inner shadow opacity.

 取值范围为 `[0, 1]`。默认值为 `0.5`。
 The valid range is `[0, 1]`. The default value is `0.5`.
 */
@property (nonatomic) CGFloat innerShadowOpacity;

/**
 内阴影模糊宽度，单位为 point。

 The inner shadow blur width, in points.

 默认值为 `10`。
 The default value is `10`.
 */
@property (nonatomic) CGFloat innerShadowBlur;

/**
 是否启用外发光。

 Whether the outer glow is enabled.

 默认值为 `NO`。当前渲染模式不支持时，设置会被保留但没有视觉效果。
 The default value is `NO`. If the current render mode does not support it, the value is retained but has no visual effect.
 */
@property (nonatomic, getter=isOuterGlowEnabled) BOOL outerGlow;

/**
 外发光颜色。

 The outer glow color.

 默认值与 `strokeColor` 相同。
 The default value matches `strokeColor`.
 */
@property (nonatomic, strong) UIColor *outerGlowColor;

/**
 外发光半径，单位为 point。

 The outer glow radius, in points.

 默认值为 `10`。
 The default value is `10`.
 */
@property (nonatomic) CGFloat outerGlowRadius;

/**
 是否启用脉动动画。

 Whether the pulse animation is enabled.

 默认值为 `NO`。脉动动画会让填充透明度周期性变化；仅非等距模式生效。可与 `radiusAnimation` 同时启用。设置为 `YES` 时会关闭 `scanAnimation`。
 The default value is `NO`. The pulse animation periodically changes fill opacity; it only takes effect in screen-sized mode. It can run together with `radiusAnimation`. Setting it to `YES` disables `scanAnimation`.
 */
@property (nonatomic, getter=isPulseAnimationEnabled) BOOL pulseAnimation;

/**
 脉动动画周期，单位为秒。

 The pulse animation duration, in seconds.

 默认值为 `2.0`，建议范围为 `0.5...10.0`。
 The default value is `2.0`. The recommended range is `0.5...10.0`.
 */
@property (nonatomic) NSTimeInterval pulseDuration;

/**
 是否启用半径动画。

 Whether the radius animation is enabled.

 默认值为 `NO`。半径动画会让圆半径在最小值和最大值之间周期性变化，产生呼吸效果；仅非等距模式生效。可与 `pulseAnimation` 同时启用。设置为 `YES` 时会关闭 `scanAnimation`。
 The default value is `NO`. The radius animation periodically changes the circle radius between a minimum and maximum value to create a breathing effect; it only takes effect in screen-sized mode. It can run together with `pulseAnimation`. Setting it to `YES` disables `scanAnimation`.
 */
@property (nonatomic, getter=isRadiusAnimationEnabled) BOOL radiusAnimation;

/**
 半径动画最小半径。

 The minimum radius for the radius animation.

 单位与 `MTCCircle.radius` 在当前渲染模式下的单位一致。默认值为 `0`，表示使用当前半径的 `0.8` 倍。
 The unit matches the current unit of `MTCCircle.radius`. The default value is `0`, which means `0.8` times the current radius is used.
 */
@property (nonatomic) CGFloat radiusAnimationMinimumRadius;

/**
 半径动画最大半径。

 The maximum radius for the radius animation.

 单位与 `MTCCircle.radius` 在当前渲染模式下的单位一致。默认值为 `0`，表示使用当前半径的 `1.2` 倍。
 The unit matches the current unit of `MTCCircle.radius`. The default value is `0`, which means `1.2` times the current radius is used.
 */
@property (nonatomic) CGFloat radiusAnimationMaximumRadius;

/**
 半径动画周期，单位为秒。

 The radius animation duration, in seconds.

 默认值为 `2.0`，建议范围为 `0.5...10.0`。
 The default value is `2.0`. The recommended range is `0.5...10.0`.
 */
@property (nonatomic) NSTimeInterval radiusAnimationDuration;

/**
 是否启用扫描动画。

 Whether the scan animation is enabled.

 默认值为 `NO`。扫描动画会让一条光线从圆心向外缘旋转扫描；仅非等距模式生效。设置为 `YES` 时会关闭 `pulseAnimation` 和 `radiusAnimation`。
 The default value is `NO`. The scan animation rotates a light beam from the center toward the edge; it only takes effect in screen-sized mode. Setting it to `YES` disables `pulseAnimation` and `radiusAnimation`.
 */
@property (nonatomic, getter=isScanAnimationEnabled) BOOL scanAnimation;

/**
 扫描动画周期，单位为秒。

 The scan animation duration, in seconds.

 默认值为 `3.0`，建议范围为 `1.0...10.0`。
 The default value is `3.0`. The recommended range is `1.0...10.0`.
 */
@property (nonatomic) NSTimeInterval scanDuration;

/**
 扫描扇形角度，单位为度。

 The scan sector angle, in degrees.

 默认值为 `60`。
 The default value is `60`.
 */
@property (nonatomic) CGFloat scanAngle;

/**
 扫描扇形颜色。

 The scan sector color.

 默认值与 `fillColor` 相同。
 The default value matches `fillColor`.
 */
@property (nonatomic, strong) UIColor *scanColor;

/**
 扫描起始角度，单位为度。

 The scan start angle, in degrees.

 默认值为 `0`。
 The default value is `0`.
 */
@property (nonatomic) CGFloat scanStartAngle;

/**
 扫描底图资源名称。

 The scan base image resource name.

 默认值为 `nil`。当前版本仅保留配置；缺少对应引擎资源时没有视觉效果。
 The default value is `nil`. The current version retains this configuration; missing engine resources have no visual effect.
 */
@property (nonatomic, copy, nullable) NSString *scanBaseImageName;

@end

NS_ASSUME_NONNULL_END
