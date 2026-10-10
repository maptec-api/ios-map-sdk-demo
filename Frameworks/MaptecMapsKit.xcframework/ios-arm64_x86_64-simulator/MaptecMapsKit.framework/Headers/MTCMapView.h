#import <UIKit/UIKit.h>
#import <CoreLocation/CoreLocation.h>
#import <MaptecMapsKit/MTCGeometry.h>
#import <MaptecMapsKit/MTCMapCamera.h>
#import <MaptecMapsKit/MTCMapCameraConstraints.h>
#import <MaptecFoundationKit/MTCMapServices.h>
#import <MaptecMapsKit/MTCMapTypes.h>
#import <MaptecMapsKit/MTCMapGestureSettings.h>
#import <MaptecMapsKit/MTCUISettings.h>
#import <MaptecMapsKit/MTCOverlay.h>
#import <MaptecMapsKit/MTCOverlayHit.h>
#import <MaptecMapsKit/MTCUserLocation.h>
#import <MaptecMapsKit/MTCUserLocationConfig.h>
#import <MaptecMapsKit/MTCSystemUserLocationConfig.h>
#import <MaptecMapsKit/MTCUserLocationProvider.h>

/**
地图相机变化完成回调。

 Map camera change completion.

 `finished` 为 `YES` 表示相机变化自然完成；若该次变化在完成前被新的相机设置或用户交互打断，则为 `NO`。回调在主线程触发。
 `finished` is `YES` when the camera change finishes naturally; if it is interrupted by a newer camera change or user interaction before completion, it is `NO`. The callback is invoked on the main thread.
*/
typedef void (^MTCMapCameraChangeCompletion)(BOOL finished);

/**
 地图截图结果状态。

 Snapshot result state.
 */
typedef NS_ENUM(NSInteger, MTCMapSnapshotState) {
    /// 成功。
    MTCMapSnapshotStateSuccess = 0,

    /// 等待超时。
    MTCMapSnapshotStateTimeout = 1,

    /// 请求被取消，例如地图重置、视图销毁或后续请求覆盖。
    MTCMapSnapshotStateCancelled = 2,

    /// 截图失败，例如区域无效或当前帧不可用。
    MTCMapSnapshotStateFailed = 3,
};

typedef void (^MTCMapSnapshotCompletion)(UIImage * _Nullable resultImage, MTCMapSnapshotState state);

/**
 用户定位平滑模式。User location smoothing mode.
 */
typedef NS_ENUM(NSInteger, MTCUserLocationSmoothingMode) {
    /** 根据相邻定位时间戳平滑移动。Smooth movement using consecutive location timestamps. */
    MTCUserLocationSmoothingModeDefault = 0,
    /** 缓冲定位并按展示时间轴平滑移动，约增加 1.5 秒展示延迟。Buffer samples on a presentation timeline with approximately 1.5 seconds of visual delay. */
    MTCUserLocationSmoothingModeBuffered = 1,
};

@class MTCPOI;

/**
 POI 查询结果回调。

 POI query completion handler.

 回调在主线程触发。结果永不为 `nil`；未命中时返回空数组。
 The callback is invoked on the main thread. The result is never `nil`; an empty array is returned when nothing is hit.
 */
typedef void (^MTCPOIQueryCompletion)(NSArray<MTCPOI *> *pois);

NS_ASSUME_NONNULL_BEGIN

@class MTCMapView;
@class MTCFloatInfoWindow;
@class MTCFloatInfoWindowOptions;
@class MTCCircle;
@class MTCMarker;
@class MTCPolygon;
@class MTCPolyline;
@class MTCPOI;
@class MTCCluster;

/**
 地图视图事件代理。

 Delegate for receiving map view lifecycle events.
 */
@protocol MTCMapViewDelegate <NSObject>

@optional

/**
 地图相机即将变化时调用。

 Called before the map camera begins changing.

 @param mapView 地图视图。The map view.
 @param reason 相机变化来源。The source of the camera change.
 @param animated 是否通过动画变化。Whether the camera change is animated.
 */
- (void)mapView:(MTCMapView *)mapView cameraWillChangeWithReason:(MTCMapCameraChangeReason)reason animated:(BOOL)animated;

/**
 地图相机发生变化时调用。

 Called when the map camera changes.

 @param mapView 地图视图。The map view.
 @param camera 当前相机快照。The current camera snapshot.
 @param reason 相机变化来源。The source of the camera change.
 @param animated 是否通过动画变化。Whether the camera change is animated.
 */
- (void)mapView:(MTCMapView *)mapView cameraDidChange:(MTCMapCamera *)camera reason:(MTCMapCameraChangeReason)reason animated:(BOOL)animated;

/**
 地图相机变化结束并进入空闲状态时调用。

 Called when the map camera change has ended and the map becomes idle.

 @param mapView 地图视图。The map view.
 @param camera 当前相机快照。The current camera snapshot.
 @param reason 相机变化来源。The source of the camera change.
 @param animated 是否通过动画变化。Whether the camera change is animated.
 */
- (void)mapView:(MTCMapView *)mapView cameraDidBecomeIdle:(MTCMapCamera *)camera
         reason:(MTCMapCameraChangeReason)reason
       animated:(BOOL)animated;

/**
 地图快速滑动开始时调用。

 Called when a pan fling starts after the user releases a fast drag.

 该回调只在平移手势松手后进入减速滑动时触发，不会因为双击缩放、双指点击缩回等其它手势动画触发。
 This callback fires only when a pan gesture enters decelerating fling after the user lifts their finger. It is not fired for other gesture animations such as double-tap zoom or two-finger tap zoom-out.

 @param mapView 地图视图。The map view.
 @param velocity 松手时的屏幕速度，单位为点/秒。The screen velocity at release, in points per second.
 */
- (void)mapView:(MTCMapView *)mapView didStartFlingWithVelocity:(CGPoint)velocity;

/**
 地图快速滑动结束时调用。

 Called when a pan fling ends.

 @param mapView 地图视图。The map view.
 */
- (void)mapViewDidEndFling:(MTCMapView *)mapView;

#pragma mark -- map loading event
/**
 地图开始加载时调用。

 Called when the map starts loading.

 首次加载地图和切换地图类型或地图样式导致地图重新加载时都会触发。
 Fired for the initial map load and for map reloads caused by map type or map style changes.

 @param mapView 地图视图。The map view.
 */
- (void)mapViewWillStartLoadingMap:(MTCMapView *)mapView;

/**
 地图加载成功时调用。

 Called when the map finishes loading successfully.

 该回调表示地图完成一次加载周期并完成完整渲染。
 This callback means the map has completed a loading cycle and a full render.

 @param mapView 地图视图。The map view.
 */
- (void)mapViewDidFinishLoadingMap:(MTCMapView *)mapView;

/**
 地图加载失败时调用。

 Called when the map fails to load.

 @param mapView 地图视图。The map view.
 @param error 错误信息。The error.
 */
- (void)mapView:(MTCMapView *)mapView didFailLoadingMapWithError:(NSError *)error;

#pragma mark -- map style event
/**
 地图样式开始加载时调用。

 Called when a map style starts loading.

 该回调只针对正在应用到地图的样式加载；地图样式预加载不会触发该回调。
 This callback is only for map styles being applied to the map; map style preloading does not trigger it.

 @param mapView 地图视图。The map view.
 @param mapStyleID 地图样式 ID。The map style identifier.
 */
- (void)mapView:(MTCMapView *)mapView willStartLoadingMapStyleWithID:(NSString *)mapStyleID;

/**
 地图样式加载成功时调用。

 Called when a map style is loaded successfully.

 @param mapView 地图视图。The map view.
 @param mapStyleID 地图样式 ID。The map style identifier.
 */
- (void)mapView:(MTCMapView *)mapView didLoadMapStyleWithID:(NSString *)mapStyleID;

/**
 地图样式切换完成时调用。

 Called when the active map style switch has completed.

 该回调在地图引擎报告样式已经应用并完成渲染后触发；不同于 `mapView:didLoadMapStyleWithID:`，后者只表示样式资源加载成功。
 This callback fires after the map engine reports that the style has been applied and rendered; unlike `mapView:didLoadMapStyleWithID:`, which only means the style resource loaded successfully.

 地图样式预加载不会触发该回调。
 Map style preloading does not trigger this callback.

 @param mapView 地图视图。The map view.
 @param mapStyleID 地图样式 ID。The map style identifier.
 */
- (void)mapView:(MTCMapView *)mapView didFinishSwitchingMapStyleWithID:(NSString *)mapStyleID;

/**
 地图样式加载失败时调用。

 Called when a map style fails to load.

 @param mapView 地图视图。The map view.
 @param mapStyleID 地图样式 ID。The map style identifier.
 @param message 错误信息。The error message.
 */
- (void)mapView:(MTCMapView *)mapView didFailLoadingMapStyleWithID:(NSString *)mapStyleID message:(NSString *)message;

/**
 地图样式预加载成功时调用。

 Called when a map style is preloaded successfully.

 @param mapView 地图视图。The map view.
 @param mapStyleID 地图样式 ID。The map style identifier.
 */
- (void)mapView:(MTCMapView *)mapView didPreloadMapStyleWithID:(NSString *)mapStyleID;

/**
 地图样式预加载失败时调用。

 Called when a map style fails to preload.

 @param mapView 地图视图。The map view.
 @param mapStyleID 地图样式 ID。The map style identifier.
 @param message 错误信息。The error message.
 */
- (void)mapView:(MTCMapView *)mapView didFailPreloadingMapStyleWithID:(NSString *)mapStyleID message:(NSString *)message;

/**
 点击地图任意位置时调用。

 Called when any map location is tapped.

 在 marker、POI 或 overlay 命中判断之前触发。该回调只暴露点击位置对应的地理坐标；屏幕点仅作为 SDK 内部命中判断使用。
 Fired before marker, POI, or overlay hit testing. This callback exposes only the geographic coordinate; the screen point is used internally by the SDK for hit testing.

 @param mapView 地图视图。The map view.
 @param coordinate 点击位置对应的地理坐标。The geographic coordinate for the tapped location.
 */
- (void)mapView:(MTCMapView *)mapView didTapAtCoordinate:(CLLocationCoordinate2D)coordinate;

/**
 长按地图任意位置时调用。

 Called when any map location is long-pressed.

 在 marker、POI 或 overlay 命中判断之前触发。该回调只暴露长按位置对应的地理坐标；屏幕点仅作为 SDK 内部命中判断使用。
 Fired before marker, POI, or overlay hit testing. This callback exposes only the geographic coordinate; the screen point is used internally by the SDK for hit testing.

 @param mapView 地图视图。The map view.
 @param coordinate 长按位置对应的地理坐标。The geographic coordinate for the long-pressed location.
 */
- (void)mapView:(MTCMapView *)mapView didLongPressAtCoordinate:(CLLocationCoordinate2D)coordinate;

/**
 点击覆盖物时调用。

 Called when an overlay is tapped.

 当前覆盖遵循 `MTCClickableOverlay` 的 `MTCMarker`、`MTCPolyline`、`MTCPolygon`、`MTCCircle` 和 `MTCCluster`。仅当覆盖物可见且 `clickable` 为 `YES` 时触发。
 Currently covers `MTCMarker`, `MTCPolyline`, `MTCPolygon`, `MTCCircle`, and `MTCCluster` when they conform to `MTCClickableOverlay`. Called only when the overlay is visible and `clickable` is `YES`.

 @param mapView 地图视图。The map view.
 @param overlay 被点击的覆盖物。The tapped overlay.
 */
- (void)mapView:(MTCMapView *)mapView didTapOverlay:(id<MTCOverlay>)overlay;

/**
 点击覆盖物时调用，并提供命中信息。

 Called when an overlay is tapped, with hit information.

 若代理实现该方法，SDK 会优先调用该方法而不再调用 `mapView:didTapOverlay:`。普通覆盖物的 `hit` 为 `MTCOverlayHit`；聚合覆盖物的 `hit` 为 `MTCClusterHit`，可区分命中聚合簇还是展开后的单点。
 If the delegate implements this method, the SDK calls this method instead of `mapView:didTapOverlay:`. Regular overlays receive `MTCOverlayHit`; cluster overlays receive `MTCClusterHit`, which distinguishes cluster hits from expanded leaf point hits.

 @param mapView 地图视图。The map view.
 @param overlay 被点击的覆盖物。The tapped overlay.
 @param hit 命中信息。The hit information.
 */
- (void)mapView:(MTCMapView *)mapView
  didTapOverlay:(id<MTCOverlay>)overlay
            hit:(MTCOverlayHit *)hit;

/**
 长按覆盖物时调用。

 Called when an overlay is long-pressed.

 当前覆盖遵循 `MTCClickableOverlay` 的 `MTCMarker`、`MTCPolyline`、`MTCPolygon`、`MTCCircle` 和 `MTCCluster`。仅当覆盖物可见且 `clickable` 为 `YES` 时触发。
 Currently covers `MTCMarker`, `MTCPolyline`, `MTCPolygon`, `MTCCircle`, and `MTCCluster` when they conform to `MTCClickableOverlay`. Called only when the overlay is visible and `clickable` is `YES`.

 @param mapView 地图视图。The map view.
 @param overlay 被长按的覆盖物。The long-pressed overlay.
 */
- (void)mapView:(MTCMapView *)mapView didLongPressOverlay:(id<MTCOverlay>)overlay;

/**
 长按覆盖物时调用，并提供命中信息。

 Called when an overlay is long-pressed, with hit information.

 若代理实现该方法，SDK 会优先调用该方法而不再调用 `mapView:didLongPressOverlay:`。普通覆盖物的 `hit` 为 `MTCOverlayHit`；聚合覆盖物的 `hit` 为 `MTCClusterHit`。
 If the delegate implements this method, the SDK calls this method instead of `mapView:didLongPressOverlay:`. Regular overlays receive `MTCOverlayHit`; cluster overlays receive `MTCClusterHit`.

 @param mapView 地图视图。The map view.
 @param overlay 被长按的覆盖物。The long-pressed overlay.
 @param hit 命中信息。The hit information.
 */
- (void)mapView:(MTCMapView *)mapView
didLongPressOverlay:(id<MTCOverlay>)overlay
            hit:(MTCOverlayHit *)hit;

/**
 开始拖拽覆盖物时调用。

 Called when overlay dragging begins.

 当前覆盖遵循 `MTCDraggableOverlay` 的 `MTCMarker`、`MTCPolyline`、`MTCPolygon` 和 `MTCCircle`。仅当覆盖物可见、`draggable` 为 `YES`，且用户从该覆盖物上开始拖动时触发。该回调触发时覆盖物几何仍为拖拽开始前的位置。
 Currently covers `MTCMarker`, `MTCPolyline`, `MTCPolygon`, and `MTCCircle` when they conform to `MTCDraggableOverlay`. Called only when the overlay is visible, `draggable` is `YES`, and the user starts dragging from that overlay. When this callback fires, the overlay geometry is still at its pre-drag position.

 @param mapView 地图视图。The map view.
 @param overlay 开始被拖拽的覆盖物。The overlay that began dragging.
 */
- (void)mapView:(MTCMapView *)mapView didBeginDraggingOverlay:(id<MTCOverlay>)overlay;

/**
 拖拽覆盖物过程中调用。

 Called while an overlay is being dragged.

 该回调在 SDK 根据当前触点位置更新覆盖物几何后触发，可能在一次拖拽过程中多次触发。
 This callback fires after the SDK updates the overlay geometry from the current touch location, and may be called multiple times during one drag gesture.

 @param mapView 地图视图。The map view.
 @param overlay 正在被拖拽的覆盖物。The overlay being dragged.
 */
- (void)mapView:(MTCMapView *)mapView didDragOverlay:(id<MTCOverlay>)overlay;

/**
 结束拖拽覆盖物时调用。

 Called when overlay dragging ends.

 该回调在 SDK 完成最后一次几何更新后触发；如果手势被取消，覆盖物会停留在最后一次有效拖拽位置。
 This callback fires after the SDK applies the final geometry update. If the gesture is cancelled, the overlay remains at the last valid dragged position.

 @param mapView 地图视图。The map view.
 @param overlay 结束被拖拽的覆盖物。The overlay that ended dragging.
 */
- (void)mapView:(MTCMapView *)mapView didEndDraggingOverlay:(id<MTCOverlay>)overlay;

/**
点击底图 POI 时调用。

 Called when a base-map POI is tapped.

 在地图点击回调之后触发。该回调只针对底图 POI；marker、overlay 等 SDK 对象会触发各自的代理回调。
 Fired after the map tap callback. This callback is only for base-map POIs; SDK objects such as markers and overlays dispatch their own delegate callbacks.

 @param mapView 地图视图。The map view.
 @param poi 被点击的 POI。The tapped POI.
 */
- (void)mapView:(MTCMapView *)mapView didTapPOI:(MTCPOI *)poi;

/**
 标记点进入选中态时调用。

 Called when a marker becomes selected.

 SDK 可能在 marker 被点击后自动将其置为选中态并触发该回调；应用也可在点击、长按或业务逻辑中设置 `marker.selected` 触发该回调。
 The SDK may automatically select a marker after a tap and trigger this callback; apps may also change `marker.selected` from tap, long-press, or business logic.

 @param mapView 地图视图。The map view.
 @param marker 进入选中态的标记点。The selected marker.
 */
- (void)mapView:(MTCMapView *)mapView didSelectMarker:(MTCMarker *)marker;

/**
 标记点退出选中态时调用。

 Called when a marker becomes deselected.

 SDK 可能在已选中 marker 被点击后自动将其置为未选中态并触发该回调；应用也可在点击、长按或业务逻辑中设置 `marker.selected` 触发该回调。
 The SDK may automatically deselect a selected marker after a tap and trigger this callback; apps may also change `marker.selected` from tap, long-press, or business logic.

 @param mapView 地图视图。The map view.
 @param marker 退出选中态的标记点。The deselected marker.
 */
- (void)mapView:(MTCMapView *)mapView didDeselectMarker:(MTCMarker *)marker;

/**
 用户位置跟随模式变化时调用。

 Called when the user location tracking mode changes.

 @param mapView 地图视图。The map view.
 @param mode 变化后的用户位置跟随模式。The updated user location tracking mode.
 */
- (void)mapView:(MTCMapView *)mapView didChangeUserLocationTrackingMode:(MTCUserLocationTrackingMode)mode;

/**
 用户定位朝向跟随模式变化时调用。

 Called when the user location bearing tracking mode changes.

 @param mapView 地图视图。The map view.
 @param mode 变化后的用户定位朝向跟随模式。The updated user location bearing tracking mode.
 */
- (void)mapView:(MTCMapView *)mapView didChangeUserBearingTrackingMode:(MTCUserBearingTrackingMode)mode;

/**
 用户定位进入过期态时调用。

 Called when the user location becomes stale.

 @param mapView 地图视图。The map view.
 */
- (void)mapViewUserLocationDidBecomeStale:(MTCMapView *)mapView;

@end

/**
 MaptecMaps 的 UIKit 地图视图。

 UIKit map view for MaptecMaps.

 `MTCMapView` 是 SDK 的主要入口，用于显示地图、切换地图类型和地图样式、控制相机和配置交互手势。所有渲染和手势相关 API 应在主线程调用。
 `MTCMapView` is the primary SDK entry point for displaying maps, switching map types and map styles, controlling the camera, and configuring gestures. Call rendering and gesture APIs on the main thread.
 */
NS_SWIFT_NAME(MTCMapView)
@interface MTCMapView : UIView

/**
 地图视图代理。

 The map view delegate.

 代理弱引用保存。所有回调在主线程触发。
 The delegate is held weakly. All callbacks are delivered on the main thread.
 */
@property (nonatomic, weak, nullable) id<MTCMapViewDelegate> delegate;

/**
 当前地图类型。

 The current map type.

 默认值为 `MTCMapTypeStandard`。设置该属性会切换地图内容；地图视图初始化后会自动加载标准地图，无需外部显式设置。
 The default is `MTCMapTypeStandard`. Setting this property switches the map content; the map view automatically loads the standard map after initialization without requiring an explicit caller action.
 */
@property (nonatomic, assign) MTCMapType mapType;

/**
 地图标签语言。

 Map label language.

 默认值为 `MTCMapLanguageDefault`，使用矢量瓦片默认 `name` 字段。设置该属性会切换底图文字标签语言；是否显示目标语言取决于瓦片数据是否包含对应的 `name:xx` 字段。
 Defaults to `MTCMapLanguageDefault`, which uses the vector tile default `name` field. Setting this property switches the base-map text label language; the effective language depends on whether tile data contains the matching `name:xx` field.
 */
@property (nonatomic, assign) MTCMapLanguage mapLanguage;

/**
 地图手势配置。

 Gesture configuration for the map.

 `MTCMapView` 初始化时会创建默认配置对象。该属性只读，直接修改返回对象的属性会立即生效，例如 `mapView.gestureSettings.pinchZoomEnabled = NO`。
 `MTCMapView` creates a default settings object during initialization. This property is read-only; mutating the returned object's properties applies immediately, for example `mapView.gestureSettings.pinchZoomEnabled = NO`.
 */
@property (nonatomic, strong, readonly) MTCMapGestureSettings *gestureSettings;

/**
 地图相机约束配置。

 Camera constraint configuration for the map.

 `MTCMapView` 初始化时会创建默认配置对象。该属性只读，直接修改返回对象的属性会立即生效，例如 `mapView.cameraConstraints.zoomLevelRange = MTCMapZoomLevelRangeMake(3, 18)`。
 `MTCMapView` creates a default constraint object during initialization. This property is read-only; mutating the returned object's properties applies immediately, for example `mapView.cameraConstraints.zoomLevelRange = MTCMapZoomLevelRangeMake(3, 18)`.
 */
@property (nonatomic, strong, readonly) MTCMapCameraConstraints *cameraConstraints;

/**
 地图内建 UI 配置。

 Built-in map UI configuration.

 `MTCMapView` 初始化时会创建默认配置对象。该属性只读，直接修改返回对象的属性会立即生效，例如 `mapView.uiSettings.compassEnabled = NO`。
 `MTCMapView` creates a default settings object during initialization. This property is read-only; mutating the returned object's properties applies immediately, for example `mapView.uiSettings.compassEnabled = NO`.
 */
@property (nonatomic, strong, readonly) MTCUISettings *uiSettings;

/**
 是否显示用户定位 marker。

 Whether to show the user location marker.

 默认值为 `NO`。设置为 `YES` 后，使用内置系统定位源时 SDK 会开始定位预热，并在收到用户位置数据时显示定位 marker；没有有效位置或没有有效图片资源时不会显示。
 Defaults to `NO`. When set to `YES`, the SDK starts warming up the built-in system location source when it is active, and shows the user location marker after a valid user location is available; it stays hidden when no valid location or marker image is available.
 */
@property (nonatomic) BOOL showsUserLocation;

/**
 系统定位源配置。

 System user location source configuration.

 默认值为新的 `MTCSystemUserLocationConfig`。设置该属性会复制传入对象；传入 `nil` 时恢复默认配置。该配置仅在使用内置系统定位源时生效。
 Defaults to a new `MTCSystemUserLocationConfig`. The assigned object is copied; passing `nil` restores the default configuration. This configuration only takes effect when the built-in system location source is active.
 */
@property (nonatomic, copy) MTCSystemUserLocationConfig *systemUserLocationConfig;

/**
 用户定位 marker 配置。

 User location marker configuration.

 默认值为新的 `MTCUserLocationConfig`。设置该属性会复制传入对象；传入 `nil` 时恢复默认配置。
 Defaults to a new `MTCUserLocationConfig`. The assigned object is copied; passing `nil` restores the default configuration.
 */
@property (nonatomic, copy) MTCUserLocationConfig *userLocationConfig;

/**
 用户定位数据源。

 User location provider.

 默认值为 `nil`，SDK 使用内置系统定位。设置为非 `nil` 后，SDK 停止内置系统定位、清空当前定位状态并启动外部数据源；外部数据仍会经过 SDK 内部定位 marker、精度圈、过期态和相机跟随逻辑。所有设置应在主线程进行。
 Defaults to `nil`, which uses the built-in system location provider. When set to a non-`nil` provider, the SDK stops the built-in system location source, clears the current user-location state, and starts the external provider while preserving the SDK's user-location marker, accuracy circle, stale state, and camera tracking behavior. Set this property on the main thread.
 */
@property (nonatomic, strong, nullable) id<MTCUserLocationProvider> userLocationProvider;

/**
用户定位平滑模式，默认 `MTCUserLocationSmoothingModeDefault`。在主线程设置；切换时清空旧模式的动画和缓冲状态。

 User location smoothing mode. Defaults to `MTCUserLocationSmoothingModeDefault`. Set on the main thread; changing it clears the previous mode's animation and buffer state.
*/
@property (nonatomic) MTCUserLocationSmoothingMode userLocationSmoothingMode;

/**
当前用户定位状态。

 Current user location state.

 SDK 内部维护该对象。`showsUserLocation` 为 `NO` 或尚未定位成功时，`userLocation.location` 为 `nil`；定位过期状态通过 `userLocation.locationStale` 读取。
 The SDK maintains this object internally. `userLocation.location` is `nil` when `showsUserLocation` is `NO` or no location has been determined; read `userLocation.locationStale` for stale state.
 */
@property (nonatomic, strong, readonly) MTCUserLocation *userLocation;


/**
 按经纬度异步查询底图 POI。

 Asynchronously queries base-map POIs for the specified coordinate.

 SDK 会先将经纬度转换为屏幕坐标，再通过引擎拾取接口查询 POI。结果按命中顺序返回，未命中时返回空数组。回调在主线程触发。
 The SDK first converts the coordinate to a screen point and then queries POIs through the engine pick interface. Results are returned in hit order, and an empty array is returned when nothing is hit. The callback is invoked on the main thread.

 @param coordinate 要查询的经纬度。The coordinate to query.
 @param completion 查询完成回调。The completion handler.
 */
- (void)queryPOIsAtCoordinate:(CLLocationCoordinate2D)coordinate
                   completion:(MTCPOIQueryCompletion)completion;

/**

 当前地图相机快照。

 A snapshot of the current map camera.

 地图尚未初始化且没有已设置的相机时，该属性为 `nil`。返回对象是不可变快照；修改地图相机请调用相机设置方法。
 This property is `nil` when the map is not initialized and no camera has been set. The returned object is an immutable snapshot; use camera-setting methods to change the map camera.
 */
@property (nonatomic, copy, readonly, nullable) MTCMapCamera *camera;

/**
 相机内容内边距。

 The camera content padding.

 该属性设置地图相机的持久逻辑视口内边距，单位为 point。设置后，SDK 会基于当前相机向底层引擎同步一次，后续普通相机设置方法也会携带该内边距。该属性不会自动合并到带有 `edgePadding` 参数的区域适配方法；这些方法仍使用调用时显式传入的边距。
 This property sets the persistent logical viewport padding for camera operations, in points. When set, the SDK synchronizes it to the underlying engine using the current camera, and subsequent regular camera-setting methods carry the padding as well. The value is not automatically merged into region-fitting methods that have an `edgePadding` parameter; those methods continue to use the explicitly supplied padding.

 默认值为 `UIEdgeInsetsZero`。各边取值必须为有限且大于等于 0 的数值；无效值会被忽略。
 The default value is `UIEdgeInsetsZero`. Each edge must be finite and greater than or equal to 0; invalid values are ignored.
 */
@property (nonatomic, assign) UIEdgeInsets cameraPadding;

/**
 按地图样式 ID 加载地图。

 Loads a map by map style identifier.

 @param mapStyleID 地图样式 ID。传入空字符串时使用默认地图样式 ID。
 The map style identifier. Passing an empty string uses the default map style identifier.
 */
- (void)loadMapStyleWithID:(NSString *)mapStyleID;

/**
 预加载一组地图样式资源，但不切换当前地图。

 Preloads map style resources without switching the current map.

 @param mapStyleIDs 地图样式 ID 数组。空字符串或空数组会被忽略。
 The map style identifiers. Empty strings and empty arrays are ignored.
 */
- (void)preloadMapStylesWithIDs:(NSArray<NSString *> *)mapStyleIDs;

/**
 设置地图中心点和缩放级别。

 Sets the map center coordinate and zoom level.

 @param coordinate 地图中心坐标。The map center coordinate.
 @param zoomLevel 缩放级别。The zoom level.
 */
- (void)setCenterCoordinate:(CLLocationCoordinate2D)coordinate zoomLevel:(double)zoomLevel;

/**
 设置地图相机，并在变化结束后回调。

 Sets the map camera and calls completion after the change ends.

 @param camera 地图相机。The map camera.
 @param transition 相机过渡配置。The camera transition configuration.
 @param completion 变化完成回调。The completion callback.
 */
- (void)setCamera:(MTCMapCamera *)camera
       transition:(nullable MTCCameraTransition *)transition
       completion:(nullable MTCMapCameraChangeCompletion)completion;

/**
 设置地图显示区域，并在变化结束后回调。

 Sets the displayed coordinate region and calls completion after the change ends.

 @param region 经纬度区域。The coordinate region.
 @param padding 边缘留白，单位为 point。The edge padding, in points.
 @param transition 相机过渡配置。The camera transition configuration.
 @param completion 变化完成回调。The completion callback.
 */
- (void)setRegion:(MTCCoordinateRegion)region
      edgePadding:(UIEdgeInsets)padding
       transition:(nullable MTCCameraTransition *)transition
       completion:(nullable MTCMapCameraChangeCompletion)completion;

/**
 设置地图显示平面投影矩形，并在变化结束后回调。

 Sets the displayed projected map rectangle and calls completion after the change ends.

 @param mapRect 地图平面投影矩形。The projected map rectangle.
 @param padding 边缘留白，单位为 point。The edge padding, in points.
 @param transition 相机过渡配置。The camera transition configuration.
 @param completion 变化完成回调。The completion callback.
 */
- (void)setVisibleMapRect:(MTCMapRect)mapRect
              edgePadding:(UIEdgeInsets)padding
               transition:(nullable MTCCameraTransition *)transition
               completion:(nullable MTCMapCameraChangeCompletion)completion;

/**
 设置地图显示经纬度边界，并在变化结束后回调。

 Sets the displayed coordinate bounds and calls completion after the change ends.

 @param bounds 经纬度边界。The coordinate bounds.
 @param padding 边缘留白，单位为 point。The edge padding, in points.
 @param transition 相机过渡配置。The camera transition configuration.
 @param completion 变化完成回调。The completion callback.
 */
- (void)setVisibleCoordinateBounds:(MTCCoordinateBounds)bounds
                       edgePadding:(UIEdgeInsets)padding
                        transition:(nullable MTCCameraTransition *)transition
                        completion:(nullable MTCMapCameraChangeCompletion)completion;

/**
 设置持续性相机中心边界限制。

 Sets a persistent camera center bounds limit.

 传入的经纬度边界会持续约束地图相机中心点的活动范围；手势拖动和程序化相机更新都会被限制在边界内。若当前相机中心已经在边界外，SDK 会立即修正到最近的合法中心点。
 The supplied coordinate bounds continuously constrain the map camera center; both gestures and programmatic camera updates are kept inside the bounds. If the current camera center is already outside the bounds, the SDK immediately snaps it to the nearest valid center point.

 传入 `MTCCoordinateBoundsNull` 表示清除限制。
 Passing `MTCCoordinateBoundsNull` clears the limit.

 @param bounds 相机中心允许落入的经纬度边界。The allowed coordinate bounds for the camera center.
 */
- (void)setCameraCenterBoundsLimit:(MTCCoordinateBounds)bounds;

/**
 设置地图中心点，并在变化结束后回调。

 Sets the map center coordinate and calls completion after the change ends.

 @param coordinate 地图中心坐标。The map center coordinate.
 @param transition 相机过渡配置。The camera transition configuration.
 @param completion 变化完成回调。The completion callback.
 */
- (void)setCenterCoordinate:(CLLocationCoordinate2D)coordinate
                transition:(nullable MTCCameraTransition *)transition
                completion:(nullable MTCMapCameraChangeCompletion)completion;

/**
 设置地图缩放级别，并在变化结束后回调。

 Sets the map zoom level and calls completion after the change ends.

 @param zoomLevel 缩放级别。The zoom level.
 @param transition 相机过渡配置。The camera transition configuration.
 @param completion 变化完成回调。The completion callback.
 */
- (void)setZoomLevel:(double)zoomLevel
          transition:(nullable MTCCameraTransition *)transition
          completion:(nullable MTCMapCameraChangeCompletion)completion;

/**
 设置地图朝向角，并在变化结束后回调。

 Sets the map bearing and calls completion after the change ends.

 @param bearing 朝向角。The bearing.
 @param transition 相机过渡配置。The camera transition configuration.
 @param completion 变化完成回调。The completion callback.
 */
- (void)setBearing:(CLLocationDirection)bearing
        transition:(nullable MTCCameraTransition *)transition
        completion:(nullable MTCMapCameraChangeCompletion)completion;

/**
 设置地图俯仰角，并在变化结束后回调。

 Sets the map pitch and calls completion after the change ends.

 @param pitch 俯仰角。The pitch.
 @param transition 相机过渡配置。The camera transition configuration.
 @param completion 变化完成回调。The completion callback.
 */
- (void)setPitch:(CGFloat)pitch
      transition:(nullable MTCCameraTransition *)transition
      completion:(nullable MTCMapCameraChangeCompletion)completion;

/**
 异步截取地图视图指定区域。

 Captures the specified map-view rect asynchronously.

 默认超时时间为 2.5 秒，默认等待下一次渲染完成后再截取。
 The default timeout is 2.5 seconds, and the call waits for the next rendered frame by default.

 @param rect 截图范围。The capture rect.
 @param completion 异步结果回调。The asynchronous completion handler.
 */
- (void)takeSnapshotInRect:(CGRect)rect completion:(MTCMapSnapshotCompletion)completion;

/**
 异步截取地图视图指定区域。

 Captures the specified map-view rect asynchronously.

 @param rect 截图范围。The capture rect.
 @param timeout 超时时间，单位为秒。The timeout in seconds.
 @param completion 异步结果回调。The asynchronous completion handler.
 */
- (void)takeSnapshotInRect:(CGRect)rect
                   timeout:(CFTimeInterval)timeout
                completion:(MTCMapSnapshotCompletion)completion;

/**
 异步截取地图视图指定区域。

 Captures the specified map-view rect asynchronously.

 @param rect 截图范围。The capture rect.
 @param timeout 超时时间，单位为秒。The timeout in seconds.
 @param afterUpdates 是否等待下一次屏幕更新完成。Whether to wait for the next screen update.
 @param completion 异步结果回调。The asynchronous completion handler.
 */
- (void)takeSnapshotInRect:(CGRect)rect
                   timeout:(CFTimeInterval)timeout
      afterScreenUpdates:(BOOL)afterUpdates
                completion:(MTCMapSnapshotCompletion)completion;

/**
 添加一个覆盖物。

 Adds an overlay.

 当前支持 `MTCMarker`、`MTCPolyline`、`MTCPolygon`、`MTCCircle` 和 `MTCHeatmap`。
 The current version supports `MTCMarker`, `MTCPolyline`, `MTCPolygon`, `MTCCircle`, and `MTCHeatmap`.

 @param overlay 要添加的覆盖物。The overlay to add.
 */
- (void)addOverlay:(id<MTCOverlay>)overlay;

/**
 按指定层级添加一个覆盖物。

 Adds an overlay at the specified level.

 `level` 决定该覆盖物进入哪个底层覆盖物组；`zIndex` 只在同一 `level` 内继续排序。
 `level` determines which underlying overlay group the overlay enters; `zIndex` continues to order overlays only within the same `level`.

 如果同一覆盖物已经添加到地图，此方法会更新其层级并重新同步渲染。
 If the same overlay has already been added to the map, this method updates its level and resynchronizes rendering.

 @param overlay 要添加的覆盖物。The overlay to add.
 @param level 覆盖物层级。The overlay level.
 */
- (void)addOverlay:(id<MTCOverlay>)overlay level:(MTCOverlayLevel)level;

/**
 批量添加覆盖物。

 Adds multiple overlays.

 @param overlays 要添加的覆盖物数组。The overlays to add.
 */
- (void)addOverlays:(NSArray<id<MTCOverlay>> *)overlays;

/**
 按指定层级批量添加覆盖物。

 Adds multiple overlays at the specified level.

 如果数组中的覆盖物已经添加到地图，此方法会更新其层级并重新同步渲染。
 If any overlay in the array has already been added to the map, this method updates its level and resynchronizes rendering.

 @param overlays 要添加的覆盖物数组。The overlays to add.
 @param level 覆盖物层级。The overlay level.
 */
- (void)addOverlays:(NSArray<id<MTCOverlay>> *)overlays level:(MTCOverlayLevel)level;

/**
 批量执行覆盖物更新。

 Performs a batch of overlay updates.

 `updates` 会在当前主线程同步执行。块内对已添加 marker、polyline 或 polygon 的坐标、样式、可见性、选中态和 zIndex 等修改会合并为一个逻辑覆盖物更新批次。此方法仅用于批量合并更新；覆盖物的普通属性 setter 不需要包在此方法中也会生效。
 `updates` is executed synchronously on the current main thread. Coordinate, style, visibility, selection, and zIndex changes to added markers, polylines, or polygons inside the block are merged into one logical overlay update batch. This method is only for batching updates; normal overlay property setters take effect without being wrapped in this method.

 此方法必须在主线程调用。Debug 构建会断言；Release 构建会忽略非主线程调用，不会自动切回主线程。
 Call this method on the main thread. Debug builds assert on misuse; Release builds ignore off-main calls and do not dispatch to the main queue automatically.

 @param updates 要执行的覆盖物更新。The overlay updates to perform.
 */
- (void)performOverlayUpdates:(NS_NOESCAPE dispatch_block_t)updates;

/**
 移除一个覆盖物。

 Removes an overlay.

 @param overlay 要移除的覆盖物。The overlay to remove.
 */
- (void)removeOverlay:(id<MTCOverlay>)overlay;

/**
 批量移除覆盖物。

 Removes multiple overlays.

 @param overlays 要移除的覆盖物数组。The overlays to remove.
 */
- (void)removeOverlays:(NSArray<id<MTCOverlay>> *)overlays;

/**
 移除所有覆盖物。

 Removes all overlays.
 */
- (void)removeAllOverlays;

#pragma mark - 信息窗口
/**
 添加一个信息窗口。

 Adds an info window.

 `options.contentView` 必须提供；未绑定 marker 时 `options.coordinate` 也必须为有效坐标。
 `options.contentView` must be provided; `options.coordinate` must also be valid when no marker is attached.

 @param options 信息窗口创建参数。The creation options.
 @return 信息窗口句柄。The info window handle.
 */
- (MTCFloatInfoWindow *)addInfoWindow:(MTCFloatInfoWindowOptions *)options;

/**
 为 marker 添加一个信息窗口。

 Adds an info window attached to a marker.

 若该 marker 已有关联信息窗口，旧窗口会先被移除。
 If the marker already has an attached info window, the previous one is removed first.

 @param options 信息窗口创建参数。The creation options.
 @param marker 要绑定的 marker。The marker to attach.
 @return 信息窗口句柄。The info window handle.
 */
- (MTCFloatInfoWindow *)addInfoWindow:(MTCFloatInfoWindowOptions *)options
                       forMarker:(MTCMarker *)marker;

/**
 移除一个信息窗口。

 Removes an info window.

 @param infoWindow 要移除的信息窗口。The info window to remove.
 */
- (void)removeInfoWindow:(MTCFloatInfoWindow *)infoWindow;

/**
 移除所有信息窗口。

 Removes all info windows.
 */
- (void)removeAllInfoWindows;
@end

NS_ASSUME_NONNULL_END
