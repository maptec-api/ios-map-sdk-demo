//
//  MTCHeatmap.h
//  MaptecMaps
//
//  Created by ZHOUPanpan on 2026/7/27.
//  Copyright © 2026 ZHOUPanpan. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <MaptecMapsKit/MTCHeatmapPoint.h>
#import <MaptecMapsKit/MTCHeatmapStyle.h>
#import <MaptecMapsKit/MTCOverlay.h>

NS_ASSUME_NONNULL_BEGIN

/**
 地图热力图覆盖物。

 A map heatmap overlay.

 `MTCHeatmap` 用一组带权重点渲染密度热力图。热力图遵循 `MTCOverlay` 通用生命周期语义，并通过通用 overlay 更新链路与私有 heatmap 引擎转换同步到底层引擎。
 `MTCHeatmap` renders a density heatmap from weighted points. It follows common `MTCOverlay` lifecycle semantics and synchronizes to the underlying engine through the common overlay update pipeline with private heatmap engine translation.
 */
NS_SWIFT_NAME(MTCHeatmap)
@interface MTCHeatmap : NSObject <MTCOverlay>

/**
 使用热力图点集创建热力图。

 Creates a heatmap with heatmap points.

 @param points 热力图点集，不能为空。The heatmap points, which must not be empty.
 */
- (instancetype)initWithPoints:(NSArray<MTCHeatmapPoint *> *)points NS_DESIGNATED_INITIALIZER;

/**
 使用空点集创建热力图。

 Creates a heatmap with no points.

 添加到地图前必须设置非空点集，否则添加会被忽略。
 Set non-empty points before adding it to a map; otherwise the add call is ignored.
 */
- (instancetype)init;

/**
 覆盖物唯一标识。

 The unique overlay identifier.
 */
@property (nonatomic, copy, readonly) NSString *identifier;

/**
 热力图点集。

 The heatmap points.

 设置时会复制传入数组。点集为空时，已添加的热力图不会同步到底层渲染。
 The assigned array is copied. Empty points are not synchronized to the renderer for an added heatmap.
 */
@property (nonatomic, copy) NSArray<MTCHeatmapPoint *> *points;

/**
 热力图样式。

 The heatmap style.

 设置时会复制传入对象。默认样式对齐 Android 基础热力图示例。
 The assigned object is copied. The default style matches the Android basic heatmap example.
 */
@property (nonatomic, copy) MTCHeatmapStyle *style;

/**
 最小可见缩放级别。

 The minimum visible zoom level.

 取值范围为 `[0, 24]`。默认值为 `0`。
 The valid range is `[0, 24]`. The default value is `0`.
 */
@property (nonatomic) CGFloat minimumZoomLevel;

/**
 最大可见缩放级别。

 The maximum visible zoom level.

 取值范围为 `[0, 24]`。默认值为 `22`。
 The valid range is `[0, 24]`. The default value is `22`.
 */
@property (nonatomic) CGFloat maximumZoomLevel;

/**
 覆盖物是否可见。

 Whether the overlay is visible.
 */
@property (nonatomic, getter=isVisible) BOOL visible;

/**
 覆盖物绘制层级。

 The overlay drawing order.
 */
@property (nonatomic) NSInteger zIndex;

/**
 业务自定义数据。

 App-specific user data.
 */
@property (nonatomic, strong, nullable) id userInfo;

@end

NS_ASSUME_NONNULL_END
