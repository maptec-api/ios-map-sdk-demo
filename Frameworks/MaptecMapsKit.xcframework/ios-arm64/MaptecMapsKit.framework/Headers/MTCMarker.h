#import <CoreLocation/CoreLocation.h>
#import <Foundation/Foundation.h>
#import <MaptecMapsKit/MTCFloatInfoWindow.h>
#import <MaptecMapsKit/MTCMarkerAnimationOptions.h>
#import <MaptecMapsKit/MTCMarkerMovement.h>
#import <MaptecMapsKit/MTCMarkerStyle.h>
#import <MaptecMapsKit/MTCOverlay.h>

NS_ASSUME_NONNULL_BEGIN

/**
 标记点碰撞行为。

 Marker collision behavior.
 */
typedef NS_ENUM(NSInteger, MTCMarkerCollisionBehavior) {
    /**
     始终显示，不参与碰撞。

     Always visible and excluded from collision detection.
     */
    MTCMarkerCollisionBehaviorAlwaysVisible = 0,

    /**
     参与碰撞，可被更高优先级的标记点隐藏。

     Participates in collision detection and may be hidden by a higher-priority marker.
     */
    MTCMarkerCollisionBehaviorOptional,

    /**
     始终显示，并隐藏重叠的可选标记点。

     Always visible and hides overlapping optional markers.
     */
    MTCMarkerCollisionBehaviorAlwaysVisibleAndHidesOptional,
};

/**
 地图标记点。

 A map marker overlay.

 `MTCMarker` 是一种 overlay，适合少量或中等数量、需要独立交互的点标记。海量点和聚合点后续会通过图层模型提供。
 `MTCMarker` is an overlay for small to medium numbers of individually interactive point markers. High-volume points and clustered markers will be provided through layer-based APIs.
 */
NS_SWIFT_NAME(MTCMarker)
@interface MTCMarker : NSObject <MTCClickableOverlay, MTCDraggableOverlay>

/**
 使用坐标创建标记点。

 Creates a marker at the specified coordinate.

 @param coordinate 标记点坐标。The marker coordinate.
 */
- (instancetype)initWithCoordinate:(CLLocationCoordinate2D)coordinate NS_DESIGNATED_INITIALIZER;

/**
 使用默认坐标创建标记点。

 Creates a marker with the default coordinate.

 默认坐标为 `{0, 0}`。
 The default coordinate is `{0, 0}`.
 */
- (instancetype)init;

/**
 覆盖物唯一标识。

 The unique overlay identifier.
 */
@property (nonatomic, copy, readonly) NSString *identifier;

/**
 标记点坐标。

 The marker coordinate.
 */
@property (nonatomic) CLLocationCoordinate2D coordinate;

/**
 默认样式。

 The default style.

 设置时会复制传入对象。默认样式使用 SDK 内置 `mtc_marker_blue_dot_normal` 图标。
 The assigned object is copied. The default style uses the SDK built-in `mtc_marker_blue_dot_normal` icon.
 */
@property (nonatomic, copy) MTCMarkerStyle *style;

/**
 选中样式。

 The selected style.

 当 `selected` 为 `YES` 且该属性不为 `nil` 时，SDK 使用该样式渲染 marker。默认值为 `nil`。
 When `selected` is `YES` and this property is not `nil`, the SDK renders the marker with this style. The default value is `nil`.
 */
@property (nonatomic, copy, nullable) MTCMarkerStyle *selectedStyle;

/**
 碰撞行为。

 The collision behavior.

 默认值为 `MTCMarkerCollisionBehaviorAlwaysVisible`。碰撞顺序由 SDK 使用的地图引擎根据覆盖物层级和添加顺序处理。
 The default value is `MTCMarkerCollisionBehaviorAlwaysVisible`. Collision ordering is handled by the map engine used by the SDK based on overlay order and insertion order.
 */
@property (nonatomic) MTCMarkerCollisionBehavior collisionBehavior;

/**
 是否在点击 marker 时切换选中态。

 Whether tapping the marker toggles its selection state.

 默认值为 `YES`。仅当 `clickable` 也为 `YES` 且 marker 被点击时生效。为 `NO` 时，点击 marker 不会自动修改 `selected`；应用仍可在点击、长按或业务逻辑中手动修改 `selected`。
 The default value is `YES`. This takes effect only when `clickable` is also `YES` and the marker is tapped. When set to `NO`, tapping the marker does not automatically change `selected`; apps may still change `selected` from tap, long-press, or business logic.
 */
@property (nonatomic) BOOL togglesSelectionOnTap;

/**
 是否处于选中态。

 Whether the marker is selected.

 默认值为 `NO`。当 `clickable` 和 `togglesSelectionOnTap` 均为 `YES` 且 marker 被点击时，SDK 会自动在选中与未选中之间切换；应用仍可在点击、长按或业务逻辑中设置该值。
 The default value is `NO`. When both `clickable` and `togglesSelectionOnTap` are `YES` and the marker is tapped, the SDK automatically toggles between selected and deselected; apps may still set this value from tap, long-press, or business logic.
 */
@property (nonatomic, getter=isSelected) BOOL selected;

/**
 是否响应点击和长按。

 Whether the marker responds to taps and long presses.

 默认值为 `YES`。为 `NO` 时，marker 不触发 overlay 点击或长按回调，也不会因点击自动切换选中态。
 The default value is `YES`. When set to `NO`, the marker does not trigger overlay tap or long-press callbacks and does not automatically toggle selection from taps.
 */
@property (nonatomic, getter=isClickable) BOOL clickable;

/**
 是否允许用户拖拽 marker。

 Whether the marker can be dragged by the user.

 默认值为 `NO`。为 `YES` 时，用户按住并拖动 marker 会由 SDK 自动更新 `marker.coordinate`，并触发 overlay 拖拽回调。该属性与 `clickable` 相互独立。
 The default value is `NO`. When set to `YES`, pressing and dragging the marker causes the SDK to update `marker.coordinate` automatically and dispatch overlay drag callbacks. This property is independent from `clickable`.
 */
@property (nonatomic, getter=isDraggable) BOOL draggable;

/**
 覆盖物是否可见。

 Whether the overlay is visible.
 */
@property (nonatomic, getter=isVisible) BOOL visible;

/**
 覆盖物绘制层级。

 The overlay drawing order.

 默认值为 `0`。
 The default value is `0`.

 zIndex 越大绘制越靠上；zIndex 相同时，后加入该 zIndex 分组的 marker 绘制在先加入的 marker 之上。修改 zIndex 会使该 marker 重新进入目标分组。
 Higher zIndex values are drawn above lower values. When markers have the same zIndex, the marker that enters that zIndex group later is drawn above earlier markers. Updating zIndex makes the marker re-enter the target group.
 */
@property (nonatomic) NSInteger zIndex;

/**
 业务自定义数据。

 App-specific user data.
 */
@property (nonatomic, strong, nullable) id userInfo;

/**
 当前关联的信息窗口。

 The currently attached info window.

 若通过 `MTCMapView` 绑定 marker 创建信息窗口，则返回该句柄；否则为 `nil`。
 Returns the handle when an info window is created for this marker through `MTCMapView`; otherwise `nil`.
 */
@property (nonatomic, strong, readonly, nullable) MTCFloatInfoWindow *infoWindow;

/**
 启动一个运行时动画。

 Starts a runtime animation.

 动画只影响 marker 当前渲染效果，不修改 marker 样式属性。相同动画类型会用新动画替换旧动画；不同动画类型如果作用在同一底层视觉属性上，也会用新动画替换旧动画。返回的 token 只代表本次启动的动画实例，动画被替换、完成或停止后失效。
 The animation affects only the marker's current rendered effect and does not mutate marker style properties. Starting the same animation type replaces the previous animation. Starting a different animation type that targets the same underlying visual property also replaces the previous animation. The returned token represents only this animation instance and becomes invalid after the animation is replaced, completed, or stopped.

 @param options 动画配置。The animation options.
 @param repeat 是否重复播放。Whether the animation repeats.
 @return 动画 token。配置无效、动画类型不支持或动画时长小于等于 `0` 时返回 `nil`。The animation token. Returns `nil` when the options are invalid, the type is unsupported, or the duration is less than or equal to `0`.
 */
- (nullable NSString *)startAnimation:(MTCMarkerAnimationOptions *)options repeat:(BOOL)repeat;

/**
 停止当前指定类型的运行时动画。

 Stops the current runtime animation of the specified type.

 如果该类型动画不存在，调用不会产生效果。
 Calling this method has no effect when no animation of the specified type is running.

 @param animationType 动画类型。The animation type.
 */
- (void)stopAnimationOfType:(MTCMarkerAnimationType)animationType;

/**
 停止指定 token 对应的运行时动画。

 Stops the runtime animation identified by the specified token.

 token 只匹配创建它的那一次动画实例。若动画已经被替换、完成或停止，该方法不会停止后来启动的新动画。
 A token matches only the animation instance that created it. If that animation has already been replaced, completed, or stopped, this method does not stop a later animation.

 @param token 动画 token。The animation token.
 */
- (void)stopAnimationWithToken:(NSString *)token;

/**
 停止当前 marker 上的所有运行时动画。

 Stops all runtime animations on this marker.
 */
- (void)stopAllAnimations;

/**
 启动一个 Marker 平滑移动任务。

 Starts a marker movement task.

 每个 marker 同一时间只支持一个移动任务。启动新任务会取消旧任务。
 Each marker supports one movement task at a time. Starting a new task cancels the previous task.

 @param movement 移动输入。The movement input.
 @param options 移动配置；传入 `nil` 使用默认配置。The movement options; pass `nil` to use defaults.
 @param error 参数或状态非法时返回错误。The returned error when arguments or state are invalid.
 @return 移动任务；失败时返回 `nil`。The movement task, or `nil` on failure.
 */
- (nullable MTCMarkerMovementTask *)startMovement:(id<MTCMarkerMovement>)movement
                                          options:(nullable MTCMarkerMovementOptions *)options
                                            error:(NSError * _Nullable * _Nullable)error;

@end

NS_ASSUME_NONNULL_END
