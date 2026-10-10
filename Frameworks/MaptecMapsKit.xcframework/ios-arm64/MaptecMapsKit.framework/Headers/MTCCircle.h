#import <CoreLocation/CoreLocation.h>
#import <Foundation/Foundation.h>
#import <MaptecMapsKit/MTCOverlay.h>
#import <MaptecMapsKit/MTCCircleStyle.h>

NS_ASSUME_NONNULL_BEGIN

/**
 圆覆盖物渲染模式。

 Circle overlay render mode.
 */
typedef NS_ENUM(NSInteger, MTCCircleRenderMode) {
    /**
     地理距离圆。 等距模式

     Geographic distance circle.

     `radius` 按米解释，地图缩放时屏幕尺寸会变化，但覆盖的真实地理范围保持不变。默认值。
     `radius` is interpreted in meters. Its on-screen size changes with zoom, while the covered geographic range remains stable. This is the default.
     */
    MTCCircleRenderModeGeographic = 0,

    /**
     屏幕尺寸圆。 非等距模式 

     Screen-sized circle.

     `radius` 按 point 解释，地图缩放时屏幕尺寸保持不变，不代表真实地理距离。
     `radius` is interpreted in points. Its on-screen size remains stable with zoom and does not represent a real geographic distance.
     */
    MTCCircleRenderModeScreen,
};

/**
 地图圆覆盖物。

 A map circle overlay.

 `MTCCircle` 使用圆心和半径表达一个圆形覆盖物。默认使用地理距离模式，半径单位为米；切换为屏幕尺寸模式后，同一个 `radius` 属性按 point 解释。
 `MTCCircle` describes a circular overlay with a center and radius. It uses geographic distance mode by default, where the radius is in meters; when switched to screen-sized mode, the same `radius` property is interpreted in points.
 */
NS_SWIFT_NAME(MTCCircle)
@interface MTCCircle : NSObject <MTCClickableOverlay, MTCDraggableOverlay>

/**
 使用圆心和半径创建圆。

 Creates a circle with a center and radius.

 @param center 圆心坐标。The circle center coordinate.
 @param radius 半径。地理距离模式下单位为米，屏幕尺寸模式下单位为 point。The radius. In geographic mode it is in meters; in screen-sized mode it is in points.
 */
- (instancetype)initWithCenter:(CLLocationCoordinate2D)center
                        radius:(CLLocationDistance)radius NS_DESIGNATED_INITIALIZER;

/**
 使用默认圆心和半径创建圆。

 Creates a circle with the default center and radius.
 */
- (instancetype)init;

/**
 覆盖物唯一标识。

 The unique overlay identifier.
 */
@property (nonatomic, copy, readonly) NSString *identifier;

/**
 圆心坐标。

 The circle center coordinate.

 默认值为 `[39.9, 116.4]`。
 The default value is `[39.9, 116.4]`.
 */
@property (nonatomic) CLLocationCoordinate2D center;

/**
 圆半径。

 The circle radius.

 默认值为 `1000`。`renderMode` 为 `MTCCircleRenderModeGeographic` 时按米解释，建议范围为 `1...2000000`；`renderMode` 为 `MTCCircleRenderModeScreen` 时按 point 解释。
 The default value is `1000`. When `renderMode` is `MTCCircleRenderModeGeographic`, it is interpreted in meters with recommended range `1...2000000`; when `renderMode` is `MTCCircleRenderModeScreen`, it is interpreted in points.
 */
@property (nonatomic) CLLocationDistance radius;

/**
 渲染模式。

 The render mode.

 默认值为 `MTCCircleRenderModeGeographic`。
 The default value is `MTCCircleRenderModeGeographic`.
 */
@property (nonatomic) MTCCircleRenderMode renderMode;

/**
 圆样式。

 The circle style.

 设置时会复制传入对象。默认样式为半透明蓝色填充和蓝色边框。
 The assigned object is copied. The default style is a translucent blue fill with a blue stroke.
 */
@property (nonatomic, copy) MTCCircleStyle *style;

/**
 覆盖物是否可见。

 Whether the overlay is visible.
 */
@property (nonatomic, getter=isVisible) BOOL visible;

/**
 是否响应点击和长按。

 Whether the circle responds to taps and long presses.

 默认值为 `YES`。为 `NO` 时，圆不触发 overlay 点击或长按回调。
 The default value is `YES`. When set to `NO`, the circle does not trigger overlay tap or long-press callbacks.
 */
@property (nonatomic, getter=isClickable) BOOL clickable;

/**
 是否允许用户拖拽圆。

 Whether the circle can be dragged by the user.

 默认值为 `NO`。为 `YES` 时，用户按住并拖动圆会由 SDK 自动平移圆心，并触发 overlay 拖拽回调。该属性与 `clickable` 相互独立。
 The default value is `NO`. When set to `YES`, pressing and dragging the circle causes the SDK to translate its center and dispatch overlay drag callbacks. This property is independent from `clickable`.
 */
@property (nonatomic, getter=isDraggable) BOOL draggable;

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
