//
//  MTCHeatmapStyle.h
//  MaptecMaps
//
//  Created by ZHOUPanpan on 2026/7/27.
//  Copyright © 2026 ZHOUPanpan. All rights reserved.
//

#import <CoreGraphics/CoreGraphics.h>
#import <Foundation/Foundation.h>
#import <MaptecMapsKit/MTCHeatmapGradient.h>

NS_ASSUME_NONNULL_BEGIN

/**
 热力图样式。

 A heatmap style.

 `MTCHeatmapStyle` 对齐 Android 热力图的 radius、weight、intensity、opacity 和 gradient 配置。设置到 `MTCHeatmap` 时 SDK 会复制样式快照。
 `MTCHeatmapStyle` matches Android heatmap radius, weight, intensity, opacity, and gradient configuration. The SDK copies the style when it is assigned to an `MTCHeatmap`.
 */
NS_SWIFT_NAME(MTCHeatmapStyle)
@interface MTCHeatmapStyle : NSObject <NSCopying>

/**
 热力半径，单位为 point。

 The heatmap radius, in points.

 取值范围为 `[1, 50]`。默认值为 `30`。
 The valid range is `[1, 50]`. The default value is `30`.
 */
@property (nonatomic) CGFloat radius;

/**
 全局热力权重。

 The global heatmap weight.

 取值范围为 `[0, 1]`。默认值为 `1`。⚠️当点集包含逐点权重时，底层优先使用逐点权重表达式。
 The valid range is `[0, 1]`. The default value is `1`. When points contain per-point weights, the renderer prefers the per-point weight expression.
 */
@property (nonatomic) CGFloat weight;

/**
 热力强度。

 The heatmap intensity.

 取值范围为 `[0, 10]`。默认值为 `1`。
 The valid range is `[0, 10]`. The default value is `1`.
 */
@property (nonatomic) CGFloat intensity;

/**
 热力透明度。

 The heatmap opacity.

 取值范围为 `[0, 1]`。默认值为 `1`。
 The valid range is `[0, 1]`. The default value is `1`.
 */
@property (nonatomic) CGFloat opacity;

/**
 热力图色带。

 The heatmap gradient.

 默认值为 SDK 内置色带。
 The default value is the SDK default gradient.
 */
@property (nonatomic, copy) MTCHeatmapGradient *gradient;

@end

NS_ASSUME_NONNULL_END
