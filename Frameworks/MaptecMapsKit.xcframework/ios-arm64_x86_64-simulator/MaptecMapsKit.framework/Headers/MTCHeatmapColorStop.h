//
//  MTCHeatmapColorStop.h
//  MaptecMaps
//
//  Created by ZHOUPanpan on 2026/7/27.
//  Copyright © 2026 ZHOUPanpan. All rights reserved.
//

#import <CoreGraphics/CoreGraphics.h>
#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

/**
 热力图色带停点。

 A heatmap gradient color stop.

 `MTCHeatmapColorStop` 将密度值映射到颜色。密度必须位于 `[0, 1]`，颜色 alpha 也会按 `[0, 1]` 参与热力图渲染。
 `MTCHeatmapColorStop` maps a density value to a color. Density must be in `[0, 1]`, and the color alpha is used in heatmap rendering in `[0, 1]`.
 */
NS_SWIFT_NAME(MTCHeatmapColorStop)
@interface MTCHeatmapColorStop : NSObject <NSCopying>

/**
 使用密度和颜色创建色带停点。

 Creates a color stop with a density and color.

 @param density 密度值，范围为 `[0, 1]`。The density value in `[0, 1]`.
 @param color 停点颜色。The stop color.
 */
- (instancetype)initWithDensity:(CGFloat)density
                          color:(UIColor *)color NS_DESIGNATED_INITIALIZER;

/**
 使用默认密度 `0` 和透明色创建色带停点。

 Creates a color stop with density `0` and a transparent color.
 */
- (instancetype)init;

/**
 密度值。

 The density value.
 */
@property (nonatomic, readonly) CGFloat density;

/**
 停点颜色。

 The stop color.
 */
@property (nonatomic, strong, readonly) UIColor *color;

@end

NS_ASSUME_NONNULL_END
