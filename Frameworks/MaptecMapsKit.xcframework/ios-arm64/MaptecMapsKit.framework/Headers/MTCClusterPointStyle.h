#import <CoreGraphics/CoreGraphics.h>
#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

/**
 聚合单点图标类型。

 Cluster leaf point icon type.
 */
typedef NS_ENUM(NSInteger, MTCClusterPointIconType) {
    /**
     蓝色圆点。

     Blue dot icon.
     */
    MTCClusterPointIconTypeBlueDot = 0,

    /**
     红色圆点。

     Red dot icon.
     */
    MTCClusterPointIconTypeRedDot,

    /**
     绿色圆点。

     Green dot icon.
     */
    MTCClusterPointIconTypeGreenDot,

    /**
     黄色圆点。

     Yellow dot icon.
     */
    MTCClusterPointIconTypeYellowDot,

    /**
     自定义图片。

     Custom image icon.

     仅当类型为该值时，`customImage` 会参与渲染。
     `customImage` is used for rendering only when this type is selected.
     */
    MTCClusterPointIconTypeCustom,
};

/**
 聚合单点样式。

 Cluster leaf point style.

 `MTCClusterPointStyle` 只作用于聚合展开后的叶子点，不与 `MTCMarkerStyle` 耦合。设置到 `MTCClusterPoint` 或 `MTCCluster.defaultPointStyle` 时 SDK 会复制样式快照。
 `MTCClusterPointStyle` affects only leaf points rendered by a cluster and is not coupled to `MTCMarkerStyle`. The SDK copies the style when assigning it to an `MTCClusterPoint` or `MTCCluster.defaultPointStyle`.
 */
NS_SWIFT_NAME(MTCClusterPointStyle)
@interface MTCClusterPointStyle : NSObject <NSCopying>

/**
 图标类型。

 The icon type.

 默认值为 `MTCClusterPointIconTypeBlueDot`。
 The default value is `MTCClusterPointIconTypeBlueDot`.
 */
@property (nonatomic) MTCClusterPointIconType iconType;

/**
 自定义图标图片。

 Custom icon image.

 仅当 `iconType` 为 `MTCClusterPointIconTypeCustom` 时生效。默认值为 `nil`。
 Used only when `iconType` is `MTCClusterPointIconTypeCustom`. The default value is `nil`.
 */
@property (nonatomic, strong, nullable) UIImage *customImage;

/**
 图标着色颜色。

 Icon tint color.

 默认值为 `nil`，表示按原图渲染。设置为非空颜色后，SDK 会生成一份着色后的图标资源用于该聚合点。
 The default value is `nil`, which renders the original image. When set to a non-null color, the SDK generates a tinted icon resource for this cluster point.
 */
@property (nonatomic, strong, nullable) UIColor *tintColor;

/**
 图标尺寸，单位为 point。

 Icon size in points.

 默认值为 `CGSizeZero`，表示使用图片原始尺寸。
 The default value is `CGSizeZero`, which means using the image's intrinsic size.
 */
@property (nonatomic) CGSize size;

/**
 图标锚点。

 The icon anchor.

 取值范围通常为 `[0, 1]`，`{0.5, 1.0}` 表示底部居中对齐坐标点。默认值为 `{0.5, 1.0}`。
 Values are typically in `[0, 1]`; `{0.5, 1.0}` means bottom-center aligned to the coordinate. The default value is `{0.5, 1.0}`.
 */
@property (nonatomic) CGPoint anchor;

/**
 图标偏移，单位为 point。

 Icon offset in points.

 默认值为 `CGPointZero`。
 The default value is `CGPointZero`.
 */
@property (nonatomic) CGPoint offset;

/**
 图标旋转角度，单位为度。

 Icon rotation in degrees.

 默认值为 `0`。
 The default value is `0`.
 */
@property (nonatomic) CGFloat rotation;

/**
 图标透明度。

 Icon opacity.

 取值范围为 `[0, 1]`。默认值为 `1`。
 The valid range is `[0, 1]`. The default value is `1`.
 */
@property (nonatomic) CGFloat opacity;

/**
 单点文字。

 Leaf point text.

 默认值为 `nil`，表示不显示文字。逐点样式文字优先级高于 `MTCClusterPoint.title`。
 The default value is `nil`, which hides text. Per-point style text has higher priority than `MTCClusterPoint.title`.
 */
@property (nonatomic, copy, nullable) NSString *text;

/**
 文字字号，单位为 point。

 Text font size in points.

 默认值为 `12`。
 The default value is `12`.
 */
@property (nonatomic) CGFloat textFontSize;

/**
 文字颜色。

 Text color.

 默认值为黑色。
 The default value is black.
 */
@property (nonatomic, strong) UIColor *textColor;

/**
 文字锚点。

 The text anchor.

 默认值为 `{0.5, 0.0}`。
 The default value is `{0.5, 0.0}`.
 */
@property (nonatomic) CGPoint textAnchor;

/**
 文字偏移，单位为 point。

 Text offset in points.

 默认值为 `{0, 4}`。
 The default value is `{0, 4}`.
 */
@property (nonatomic) CGPoint textOffset;

/**
 文字旋转角度，单位为度。

 Text rotation in degrees.

 默认值为 `0`。
 The default value is `0`.
 */
@property (nonatomic) CGFloat textRotation;

@end

NS_ASSUME_NONNULL_END
