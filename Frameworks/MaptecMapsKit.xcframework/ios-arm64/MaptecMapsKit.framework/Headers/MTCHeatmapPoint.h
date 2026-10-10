//
//  MTCHeatmapPoint.h
//  MaptecMaps
//
//  Created by ZHOUPanpan on 2026/7/27.
//  Copyright © 2026 ZHOUPanpan. All rights reserved.
//

#import <CoreLocation/CoreLocation.h>
#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/**
 热力图单点。

 A heatmap point.

 `MTCHeatmapPoint` 包含 WGS84 坐标和可选逐点权重。使用 `initWithCoordinate:` 创建时不携带逐点权重，底层会使用热力图样式的全局权重。逐点权重建议位于 `[0, 1]`。
 `MTCHeatmapPoint` contains a WGS84 coordinate and an optional per-point weight. Points created with `initWithCoordinate:` do not carry a per-point weight, so the renderer uses the heatmap style's global weight. The recommended per-point weight range is `[0, 1]`.
 */
NS_SWIFT_NAME(MTCHeatmapPoint)
@interface MTCHeatmapPoint : NSObject <NSCopying>

/**
 使用坐标创建不带逐点权重的热力图点。

 Creates a heatmap point with a coordinate and no per-point weight.

 @param coordinate 点坐标。The point coordinate.
 */
- (instancetype)initWithCoordinate:(CLLocationCoordinate2D)coordinate NS_DESIGNATED_INITIALIZER;

/**
 使用坐标和逐点权重创建热力图点。

 Creates a heatmap point with a coordinate and per-point weight.

 @param coordinate 点坐标。The point coordinate.
 @param weight 逐点权重，建议范围为 `[0, 1]`。The per-point weight, recommended in `[0, 1]`.
 */
- (instancetype)initWithCoordinate:(CLLocationCoordinate2D)coordinate
                            weight:(CGFloat)weight NS_DESIGNATED_INITIALIZER;

/**
 使用默认坐标 `{0, 0}` 创建不带逐点权重的热力图点。

 Creates a heatmap point with default coordinate `{0, 0}` and no per-point weight.
 */
- (instancetype)init;

/**
 点坐标。

 The point coordinate.
 */
@property (nonatomic, readonly) CLLocationCoordinate2D coordinate;

/**
 是否携带逐点权重。

 Whether this point carries a per-point weight.
 */
@property (nonatomic, readonly) BOOL hasWeight;

/**
 逐点权重。

 The per-point weight.

 未携带逐点权重时返回 `1`，请使用 `hasWeight` 判断该权重是否会写入底层点数据。
 Returns `1` when this point does not carry a per-point weight. Use `hasWeight` to determine whether the weight is written to the underlying point data.
 */
@property (nonatomic, readonly) CGFloat weight;

@end

NS_ASSUME_NONNULL_END
