#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

/**
 线端点样式。

 Line cap style.
 */
typedef NS_ENUM(NSInteger, MTCLineCapType) {
    /**
     平直端点。

     Butt line cap.
     */
    MTCLineCapTypeButt = 0,

    /**
     圆形端点。

     Round line cap.
     */
    MTCLineCapTypeRound,

    /**
     方形端点。

     Square line cap.
     */
    MTCLineCapTypeSquare,
};

/**
 线段连接样式。

 Line join style.
 */
typedef NS_ENUM(NSInteger, MTCLineJoinType) {
    /**
     尖角连接。

     Miter line join.
     */
    MTCLineJoinTypeMiter = 0,

    /**
     圆角连接。

     Round line join.
     */
    MTCLineJoinTypeRound,

    /**
     斜角连接。

     Bevel line join.
     */
    MTCLineJoinTypeBevel,
};

/**
 沿线方向箭头样式类型。

 Directional arrow type rendered along a line.
 */
typedef NS_ENUM(NSInteger, MTCLineDirectionalArrowType) {
    /**
     经典三角箭头。

     Classic triangular arrow.
     */
    MTCLineDirectionalArrowTypeClassic = 0,

    /**
     V 形箭头。

     Chevron arrow.
     */
    MTCLineDirectionalArrowTypeChevron,

    /**
     实心三角箭头。

     Filled triangle arrow.
     */
    MTCLineDirectionalArrowTypeTriangle,

    /**
     自定义箭头资源。

     Custom arrow resource.
     */
    MTCLineDirectionalArrowTypeCustom,
};

/**
 经典箭头内置资源名称。

 Built-in resource name for the classic directional arrow.

 SDK 期望 bundle 中存在同名 PDF 图片资源：`line_classic`。
 The SDK expects a PDF image resource with this name in the bundle: `line_classic`.
 */
FOUNDATION_EXPORT NSString * const MTCLineDirectionalArrowClassicImageName;

/**
 V 形箭头内置资源名称。

 Built-in resource name for the chevron directional arrow.

 SDK 期望 bundle 中存在同名 PDF 图片资源：`line_chevron`。
 The SDK expects a PDF image resource with this name in the bundle: `line_chevron`.
 */
FOUNDATION_EXPORT NSString * const MTCLineDirectionalArrowChevronImageName;

/**
 实心三角箭头内置资源名称。

 Built-in resource name for the triangle directional arrow.

 SDK 期望 bundle 中存在同名 PDF 图片资源：`line_triangle`。
 The SDK expects a PDF image resource with this name in the bundle: `line_triangle`.
 */
FOUNDATION_EXPORT NSString * const MTCLineDirectionalArrowTriangleImageName;

/**
 沿线方向箭头样式。

 Directional arrow style rendered repeatedly along a line.

 设置到折线样式时 SDK 会复制该对象。内置类型使用 SDK bundle 中的 PDF 图片资源；自定义类型使用 `customImageName` 指定的图片资源名。
 The SDK copies this object when it is assigned to a polyline style. Built-in types use PDF image resources in the SDK bundle; the custom type uses the image resource named by `customImageName`.
 */
NS_SWIFT_NAME(MTCLineDirectionalArrowStyle)
@interface MTCLineDirectionalArrowStyle : NSObject <NSCopying>

/**
 是否启用沿线方向箭头。

 Whether directional arrows are enabled along the line.

 默认值为 `NO`。
 The default value is `NO`.
 */
@property (nonatomic) BOOL enabled;

/**
 箭头类型。

 The arrow type.

 默认值为 `MTCLineDirectionalArrowTypeClassic`。当值为 `MTCLineDirectionalArrowTypeCustom` 时，SDK 使用 `customImageName`。
 The default value is `MTCLineDirectionalArrowTypeClassic`. When the value is `MTCLineDirectionalArrowTypeCustom`, the SDK uses `customImageName`.
 */
@property (nonatomic) MTCLineDirectionalArrowType type;

/**
 箭头颜色。

 The arrow color.

 默认值为 `nil`，表示使用 SDK 默认黑色。使用灰度 PDF 资源时该颜色会作为遮罩颜色。
 The default value is `nil`, which means the SDK default black is used. For grayscale PDF resources, this color is applied as the mask color.
 */
@property (nonatomic, strong, nullable) UIColor *color;

/**
 箭头到线条上下边缘的内边距，单位为 point。

 The inset from the arrow to the upper and lower line edges, in points.

 SDK 会根据线宽和该内边距计算箭头高度：`strokeWeight - 2 * edgeInset`，并按箭头资源宽高比等比例缩放箭头。默认值为 `2`，有效值应大于等于 `0`。
 The SDK computes the arrow height from `strokeWeight - 2 * edgeInset`, then scales the arrow proportionally using the resource aspect ratio. The default value is `2`; valid values should be greater than or equal to `0`.
 */
@property (nonatomic) CGFloat edgeInset;

/**
 箭头间距倍率。

 Arrow spacing multiplier.

 表示两个箭头起点之间的距离相对于箭头绘制宽度的倍率。`1` 表示连续排列，`2` 表示间隔约一个箭头宽度。默认值为 `1`，有效值应大于等于 `1`。
 This is the start-to-start distance between adjacent arrows, expressed as a multiple of the rendered arrow width. `1` means continuous placement; `2` leaves roughly one arrow width between arrows. The default value is `1`; valid values should be greater than or equal to `1`.
 */
@property (nonatomic) CGFloat spacingMultiplier;

/**
 自定义箭头图片资源名。

 The custom arrow image resource name.

 仅当 `type` 为 `MTCLineDirectionalArrowTypeCustom` 时使用。传入 asset 名称，不包含扩展名；资源建议使用 PDF。
 Used only when `type` is `MTCLineDirectionalArrowTypeCustom`. Pass the asset name without an extension; PDF resources are recommended.
 */
@property (nonatomic, copy, nullable) NSString *customImageName;

@end

NS_ASSUME_NONNULL_END
