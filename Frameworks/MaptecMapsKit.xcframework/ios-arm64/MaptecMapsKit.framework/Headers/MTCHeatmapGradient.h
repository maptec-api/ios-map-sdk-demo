//
//  MTCHeatmapGradient.h
//  MaptecMaps
//
//  Created by ZHOUPanpan on 2026/7/27.
//  Copyright © 2026 ZHOUPanpan. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <MaptecMapsKit/MTCHeatmapColorStop.h>

NS_ASSUME_NONNULL_BEGIN

/**
 热力图密度色带。

 A heatmap density gradient.

 `MTCHeatmapGradient` 使用严格递增的色带停点描述 `heatmap-color`。至少需要两个停点。
 `MTCHeatmapGradient` describes `heatmap-color` with strictly increasing color stops. At least two stops are required.
 */
NS_SWIFT_NAME(MTCHeatmapGradient)
@interface MTCHeatmapGradient : NSObject <NSCopying>

/**
 使用色带停点创建热力图色带。

 Creates a heatmap gradient with color stops.

 @param colorStops 色带停点数组，密度必须严格递增。The color stops, whose densities must be strictly increasing.
 */
- (nullable instancetype)initWithColorStops:(NSArray<MTCHeatmapColorStop *> *)colorStops NS_DESIGNATED_INITIALIZER;

/**
 使用 SDK 默认色带创建热力图色带。

 Creates a heatmap gradient with the SDK default color ramp.
 */
- (instancetype)init;

/**
 SDK 默认色带。

 The SDK default heatmap gradient.
 */
+ (instancetype)defaultGradient;

/**
 色带停点。

 The gradient color stops.
 */
@property (nonatomic, copy, readonly) NSArray<MTCHeatmapColorStop *> *colorStops;

@end

NS_ASSUME_NONNULL_END
