#import <CoreGraphics/CoreGraphics.h>
#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

/**
 标记点图标类型。

 Marker icon type.
 */
typedef NS_ENUM(NSInteger, MTCMarkerIconType) {
    /**
     蓝色圆点。

     Blue dot icon.
     */
    MTCMarkerIconTypeBlueDot = 0,

    /**
     红色圆点。

     Red dot icon.
     */
    MTCMarkerIconTypeRedDot,

    /**
     绿色圆点。

     Green dot icon.
     */
    MTCMarkerIconTypeGreenDot,

    /**
     黄色圆点。

     Yellow dot icon.
     */
    MTCMarkerIconTypeYellowDot,

    /**
     自定义图片。

     Custom image icon.

     仅当类型为该值时，`customImage` 会参与渲染。
     `customImage` is used for rendering only when this type is selected.
     */
    MTCMarkerIconTypeCustom,
};

/**
 标记点图标。

 Marker icon.

 `MTCMarkerIcon` 描述 marker 的图片部分，包括内置图标、自定义图片、尺寸、锚点、偏移、旋转与透明度。
 `MTCMarkerIcon` describes the image portion of a marker, including built-in icons, custom images, size, anchor, offset, rotation, and opacity.
 */
NS_SWIFT_NAME(MTCMarkerIcon)
@interface MTCMarkerIcon : NSObject <NSCopying>

/**
 图标类型。

 The icon type.

 默认值为 `MTCMarkerIconTypeBlueDot`。
 The default value is `MTCMarkerIconTypeBlueDot`.
 */
@property (nonatomic) MTCMarkerIconType type;

/**
 自定义图标图片。

 Custom icon image.

 仅当 `type` 为 `MTCMarkerIconTypeCustom` 时生效。默认值为 `nil`。
 Used only when `type` is `MTCMarkerIconTypeCustom`. The default value is `nil`.
 */
@property (nonatomic, strong, nullable) UIImage *customImage;

/**
 图标着色颜色。

 Icon tint color.

 默认值为 `nil`，表示按原图渲染。设置为非空颜色后，SDK 会将该图标作为 SDF 图标资源注册，并使用该颜色渲染图标；内置图标和自定义图片均生效。自定义图片应使用适合 SDF 渲染的单色或距离场图片，否则显示效果取决于图片内容。
 The default value is `nil`, which renders the original image. When set to a non-null color, the SDK registers this icon as an SDF icon resource and renders the icon with that color. This applies to both built-in icons and custom images. Custom images should be monochrome or distance-field images suitable for SDF rendering; otherwise the visual result depends on the image content.
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
 锚点位置。

 The marker anchor.

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

@end

/**
 标记点标题。

 Marker title.

 `MTCMarkerTitle` 描述 marker 的文字部分。默认不显示标题；当 `text` 非空时渲染标题。
 `MTCMarkerTitle` describes the text portion of a marker. The title is hidden by default and renders when `text` is non-empty.
 */
NS_SWIFT_NAME(MTCMarkerTitle)
@interface MTCMarkerTitle : NSObject <NSCopying>

/**
 标题文本。

 The title text.

 默认值为 `nil`。可在默认样式与选中样式中设置不同文本。
 The default value is `nil`. Different text may be configured in the default and selected styles.
 */
@property (nonatomic, copy, nullable) NSString *text;

/**
 标题字号，单位为 point。

 Title font size in points.

 默认值为 `12`。
 The default value is `12`.
 */
@property (nonatomic) CGFloat fontSize;

/**
 标题颜色。

 The title color.

 默认值为黑色。
 The default value is black.
 */
@property (nonatomic, strong) UIColor *color;

/**
 标题描边颜色。

 The title stroke color.

 默认值为白色。
 The default value is white.
 */
@property (nonatomic, strong) UIColor *strokeColor;

/**
 标题描边宽度，单位为 point。

 Title stroke width in points.

 默认值为 `1`。
 The default value is `1`.
 */
@property (nonatomic) CGFloat strokeWidth;

/**
 标题锚点位置。

 The title anchor.

 取值范围通常为 `[0, 1]`，`{0.5, 0.0}` 表示顶部居中对齐坐标点。默认值为 `{0.5, 0.0}`。
 Values are typically in `[0, 1]`; `{0.5, 0.0}` means top-center aligned to the coordinate. The default value is `{0.5, 0.0}`.
 */
@property (nonatomic) CGPoint anchor;

/**
 标题偏移，单位为 point。

 Title offset in points.

 默认值为 `{0, 4}`。
 The default value is `{0, 4}`.
 */
@property (nonatomic) CGPoint offset;

/**
 标题旋转角度，单位为度。

 Title rotation in degrees.

 默认值为 `0`。
 The default value is `0`.
 */
@property (nonatomic) CGFloat rotation;

/**
 标题透明度。

 Title opacity.

 取值范围为 `[0, 1]`。默认值为 `1`。
 The valid range is `[0, 1]`. The default value is `1`.
 */
@property (nonatomic) CGFloat opacity;

@end

/**
 标记点样式。

 Marker style.

 `MTCMarkerStyle` 由图标和标题设置组成。多个 `MTCMarker` 可以共享同一个样式对象。设置到 marker 后 SDK 会复制样式快照，因此后续修改样式对象本身不会影响已设置的 marker，除非重新赋值。
 `MTCMarkerStyle` is composed of icon and title settings. Multiple `MTCMarker` instances may share one style object. The SDK copies the style when assigning it to a marker, so later mutations of the style object do not affect that marker unless the style is assigned again.
 */
NS_SWIFT_NAME(MTCMarkerStyle)
@interface MTCMarkerStyle : NSObject <NSCopying>

/**
 图标设置。

 The icon settings.

 设置时会复制传入对象。默认值为使用蓝色圆点的 `MTCMarkerIcon`。
 The assigned object is copied. The default value is an `MTCMarkerIcon` using the blue dot.
 */
@property (nonatomic, copy) MTCMarkerIcon *icon;

/**
 标题设置。

 The title settings.

 设置时会复制传入对象。默认值为 `text` 为空的 `MTCMarkerTitle`。
 The assigned object is copied. The default value is an `MTCMarkerTitle` with empty `text`.
 */
@property (nonatomic, copy) MTCMarkerTitle *title;

@end

NS_ASSUME_NONNULL_END
