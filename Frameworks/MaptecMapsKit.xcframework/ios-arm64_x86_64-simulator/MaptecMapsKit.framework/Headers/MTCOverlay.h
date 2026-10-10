#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/**
 覆盖物层级。

 Overlay level.

 `MTCOverlayLevel` 决定覆盖物所在的底层覆盖物组，`zIndex` 只在同一 level 内继续作为排序值。默认值为 `MTCOverlayLevelDefault`。
 `MTCOverlayLevel` determines the underlying overlay group for an overlay. `zIndex` remains the ordering value only within the same level. The default value is `MTCOverlayLevelDefault`.
 */
typedef NS_ENUM(NSInteger, MTCOverlayLevel) {
    /**
     默认覆盖物层级。

     Default overlay level.
     */
    MTCOverlayLevelDefault = 0,

    /**
     底图图层之后的覆盖物层级。

     Overlay level after a base map layer.
     */
    MTCOverlayLevelLayerAfter = 1,

    /**
     POI 之后的覆盖物层级。

     Overlay level after POI content.
     */
    MTCOverlayLevelPOIAfter = 2,

    /**
     道路之后的覆盖物层级。

     Overlay level after road content.
     */
    MTCOverlayLevelRoadAfter = 3,

    /**
     建筑之后的覆盖物层级。

     Overlay level after building content.
     */
    MTCOverlayLevelBuildingAfter = 4,
};

/**
 地图覆盖物基础协议。

 Base protocol for map overlays.

 `MTCOverlay` 只包含所有覆盖物共有的生命周期和显示属性。具体几何信息由各覆盖物类型自行声明。
 `MTCOverlay` only contains lifecycle and display properties shared by all overlays. Geometry is declared by each concrete overlay type.
 */
NS_SWIFT_NAME(MTCOverlay)
@protocol MTCOverlay <NSObject>

/**
 覆盖物唯一标识。

 The unique overlay identifier.

 SDK 会在初始化时生成默认值。添加到地图后不应修改该值。
 The SDK generates a default value during initialization. Do not change it after adding the overlay to a map.
 */
@property (nonatomic, copy, readonly) NSString *identifier;

/**
 覆盖物是否可见。

 Whether the overlay is visible.

 默认值为 `YES`。修改该属性会同步到底层渲染状态。
 The default value is `YES`. Changing this property updates the underlying render state.
 */
@property (nonatomic, getter=isVisible) BOOL visible;

/**
 覆盖物绘制层级。

 The overlay drawing order.

 值越大在同一覆盖物 level 内越靠上。默认值为 `0`。
 Larger values are rendered above smaller values within the same overlay level. The default value is `0`.
 */
@property (nonatomic) NSInteger zIndex;

/**
 业务自定义数据。

 App-specific user data.

 SDK 不读取或修改该值。
 The SDK does not read or modify this value.
 */
@property (nonatomic, strong, nullable) id userInfo;

@end

/**
 可响应点击和长按的覆盖物协议。

 Protocol for overlays that can respond to tap and long-press interactions.

 仅支持命中拾取的覆盖物会遵循该协议。未遵循该协议的覆盖物不会触发 overlay 点击或长按回调。
 Only overlays that support hit testing conform to this protocol. Overlays that do not conform to this protocol do not trigger overlay tap or long-press callbacks.
 */
NS_SWIFT_NAME(MTCClickableOverlay)
@protocol MTCClickableOverlay <MTCOverlay>

/**
 是否响应点击和长按。

 Whether the overlay responds to taps and long presses.

 默认值由具体覆盖物类型决定。为 `NO` 时，该覆盖物不会触发 overlay 点击或长按回调。
 The default value is defined by each concrete overlay type. When set to `NO`, the overlay does not trigger overlay tap or long-press callbacks.
 */
@property (nonatomic, getter=isClickable) BOOL clickable;

@end

/**
 可拖拽的覆盖物协议。

 Protocol for overlays that can be dragged by the user.

 仅支持拖拽交互的覆盖物会遵循该协议。未遵循该协议的覆盖物不会开始 overlay 拖拽。
 Only overlays that support drag interaction conform to this protocol. Overlays that do not conform to this protocol do not begin overlay dragging.
 */
NS_SWIFT_NAME(MTCDraggableOverlay)
@protocol MTCDraggableOverlay <MTCOverlay>

/**
 是否允许用户拖拽覆盖物。

 Whether the overlay can be dragged by the user.

 默认值由具体覆盖物类型决定。为 `YES` 时，用户按住并拖动覆盖物会由 SDK 自动更新该覆盖物的几何，并触发 overlay 拖拽回调。
 The default value is defined by each concrete overlay type. When set to `YES`, pressing and dragging the overlay causes the SDK to update that overlay's geometry and dispatch overlay drag callbacks.
 */
@property (nonatomic, getter=isDraggable) BOOL draggable;

@end

NS_ASSUME_NONNULL_END
