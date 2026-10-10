#import <CoreGraphics/CoreGraphics.h>
#import <CoreLocation/CoreLocation.h>
#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/**
 地图缩放手势的中心点模式。

 The anchor mode used when zoom gestures change the map zoom level.
 */
typedef NS_ENUM(NSInteger, MTCMapGestureZoomCenterMode) {
    /**
     以手势位置为缩放中心。默认值。

     Uses the gesture location, such as the pinch midpoint or double-tap point, as the zoom anchor. This is the default.
     */
    MTCMapGestureZoomCenterModeGestureCenter = 0,

    /**
     以地图视图屏幕中心为缩放中心。

     Uses the center of the map view bounds as the zoom anchor.
     */
    MTCMapGestureZoomCenterModeScreenCenter,
};

/**
 地图交互手势类型集合。

 Map interaction gesture types.

 可用于描述需要特殊协调规则的一组地图手势。多个值可以按位组合。
 Use these values as a bitmask to describe map gestures that need special coordination rules.
 */
typedef NS_OPTIONS(NSUInteger, MTCMapGestureType) {
    /**
     无手势类型。

     No gesture type.
     */
    MTCMapGestureTypeNone = 0,

    /**
     缩放手势，包含双指捏合缩放。

     Zoom gestures, including pinch zoom.
     */
    MTCMapGestureTypeZoom = 1 << 0,

    /**
     旋转手势。

     Rotation gestures.
     */
    MTCMapGestureTypeRotate = 1 << 1,

    /**
     倾斜手势，当前指双指垂直拖动改变地图俯仰角。

     Pitch gestures, currently the two-finger vertical drag that changes map pitch.
     */
    MTCMapGestureTypePitch = 1 << 2,

    /**
     平移手势。

     Pan or move gestures.
     */
    MTCMapGestureTypeMove = 1 << 3,

    /**
     长按手势。

     Long-press gestures.
     */
    MTCMapGestureTypeLongPress = 1 << 4,
};

/**
 `MTCMapView` 的统一手势配置对象。

 A unified gesture configuration object owned by `MTCMapView`.

 `MTCMapView` 在初始化时创建默认配置对象，并通过只读 `gestureSettings` 属性暴露。直接修改该对象的属性会立即应用到地图视图。
 `MTCMapView` creates a default settings object during initialization and exposes it through its read-only `gestureSettings` property. Mutating these properties applies changes to the map view immediately.

 使用示例 / Example:

 ```objc
 mapView.gestureSettings.pinchZoomEnabled = NO;
 mapView.gestureSettings.rotateEnabled = NO;
 ```

 @note 除特别说明外，所有属性应在主线程访问和修改。
 Unless otherwise documented, access and mutate these properties on the main thread.
 */
@interface MTCMapGestureSettings : NSObject <NSCopying>

/**
 地图所有交互手势的总开关。

 Master switch for all interactive map gestures.

 默认值为 `YES`。设置为 `NO` 时，平移、缩放、旋转、俯仰和双击相关手势都会停止响应，地图表现为静态视图。
 The default is `YES`. When set to `NO`, pan, zoom, rotate, pitch, and double-tap gestures stop responding and the map behaves as a static view.
 */
@property (nonatomic, getter=isEnabled) BOOL enabled;

/**
 是否启用平移后的惯性滚动。

 Whether pan gestures continue with inertial scrolling after the user lifts their finger.

 默认值为 `YES`。仅在 `panEnabled` 和 `enabled` 同时为 `YES` 时生效。
 The default is `YES`. This only takes effect when both `panEnabled` and `enabled` are `YES`.
 */
@property (nonatomic, getter=isInertialScrollEnabled) BOOL inertialScrollEnabled;

/**
 惯性滚动的最大持续时间，单位为秒。

 Maximum duration of inertial scrolling, in seconds.

 默认值为 `1.0`，有效范围为 `0.0...5.0`。设置为 `0.0` 表示不执行惯性滚动；达到该时长时惯性会强制结束。
 The default is `1.0`. Valid range is `0.0...5.0`. Use `0.0` to skip inertial scrolling; inertia is forced to stop when this duration is reached.
 */
@property (nonatomic) NSTimeInterval inertialDuration;

/**
 启动惯性滚动所需的最小松手速度，单位为点/秒。

 Minimum release velocity required to start inertial scrolling, in points per second.

 默认值为 `500.0`，有效范围为 `0.0...5000.0`。平移手势结束时，如果松手速度低于该值，则不会启动惯性滚动，也不会触发快速滑动开始回调。设置为 `0.0` 表示不使用速度门槛。
 The default is `500.0`. Valid range is `0.0...5000.0`. When a pan gesture ends below this release velocity, inertial scrolling does not start and the fling-start callback is not fired. Use `0.0` to disable the velocity gate.
 */
@property (nonatomic) CGFloat inertialScrollMinimumVelocity;

/**
 判定双击手势的最大点击间隔，单位为秒。

 Maximum interval between taps for a double-tap gesture, in seconds.

 默认值为 `0.3`，有效范围为 `0.1...1.0`。
 The default is `0.3`. Valid range is `0.1...1.0`.
 */
@property (nonatomic) NSTimeInterval doubleClickDelay;

/**
 是否允许用户通过拖拽平移地图。

 Whether users can pan the map by dragging.

 默认值为 `YES`。
 The default is `YES`.
 */
@property (nonatomic, getter=isPanEnabled) BOOL panEnabled;

/**
 开始触发平移所需的最小拖动距离，单位为点。

 Minimum drag distance required before pan begins, in points.

 默认值为 `0.0`，有效范围为 `0.0...50.0`。值越大越不容易误触，但开始平移会更费力。
 The default is `0.0`. Valid range is `0.0...50.0`. Larger values reduce accidental pans but require more movement before panning starts.
 */
@property (nonatomic) CGFloat panMinimumResistance;

/**
 是否允许双指捏合缩放地图。

 Whether pinch gestures can zoom the map.

 默认值为 `YES`。
 The default is `YES`.
 */
@property (nonatomic, getter=isPinchZoomEnabled) BOOL pinchZoomEnabled;

/**
 是否允许双击放大地图。

 Whether double-tap gestures can zoom in.

 默认值为 `YES`。开启后，单指双击会直接放大地图，不受 `doubleTapPitchResetEnabled` 影响。
 The default is `YES`. When enabled, a one-finger double tap directly zooms the map in and is not affected by `doubleTapPitchResetEnabled`.
 */
@property (nonatomic, getter=isDoubleTapZoomEnabled) BOOL doubleTapZoomEnabled;

/**
 双击缩放因子。

 Scale factor applied by each double-tap zoom-in operation.

 该值是地图尺度倍率，不是缩放级别增量。正常完成且未触达相机缩放上下限时，缩放级别增量约为 `log2(doubleTapZoomFactor)`。
 例如 `2.0` 通常表示放大一级，`4.0` 通常表示放大两级。实际增量可能因相机缩放约束或动画被打断而小于该换算值。
 此值不改变双指点击缩小的倍率。

 This value is a map scale multiplier, not a zoom-level delta. When the zoom completes normally without hitting camera zoom bounds, the zoom-level delta is approximately `log2(doubleTapZoomFactor)`.
 For example, `2.0` typically zooms in by one level, and `4.0` typically zooms in by two levels. The actual delta may be smaller when capped by camera constraints or interrupted by another camera change.
 This value does not change the two-finger tap zoom-out factor.

 默认值为 `2.0`，有效范围为 `1.1...5.0`。
 The default is `2.0`. Valid range is `1.1...5.0`.
 */
@property (nonatomic) CGFloat doubleTapZoomFactor;

/**
 是否允许双指点击缩回地图。

 Whether the map can zoom out with a two-finger tap.

 由于历史命名原因，属性名中保留 `DoubleTap`；当前行为是双指单击。默认值为 `YES`。开启后，双指点击地图会直接缩小地图，不受 `doubleTapPitchResetEnabled` 影响。
 The property name keeps `DoubleTap` for source compatibility; the current behavior is a two-finger single tap. The default is `YES`. When enabled, a two-finger tap directly zooms the map out and is not affected by `doubleTapPitchResetEnabled`.
 */
@property (nonatomic, getter=isDoubleTapZoomResetEnabled) BOOL doubleTapZoomResetEnabled;

/**
 双击等离散缩放操作的动画时长，单位为秒。

 Animation duration for discrete zoom operations such as double tap, in seconds.

 默认值为 `0.3`，有效范围为 `0.0...2.0`。设置为 `0.0` 表示无动画。
 The default is `0.3`. Valid range is `0.0...2.0`. Use `0.0` for no animation.
 */
@property (nonatomic) NSTimeInterval zoomAnimationDuration;

/**
 缩放手势的中心点模式。

 Anchor mode used by zoom gestures.

 默认值为 `MTCMapGestureZoomCenterModeGestureCenter`。
 The default is `MTCMapGestureZoomCenterModeGestureCenter`.
 */
@property (nonatomic) MTCMapGestureZoomCenterMode zoomCenterMode;

/**
 是否允许双指旋转改变地图朝向。

 Whether two-finger rotation can change the map bearing.

 默认值为 `YES`。
 The default is `YES`.
 */
@property (nonatomic, getter=isRotateEnabled) BOOL rotateEnabled;

/**
 旋转手势阻力系数。

 Resistance factor for rotation gestures.

 默认值为 `1.0`，有效范围为 `0.1...5.0`。值越大，同样角度变化需要更大的手势幅度。
 The default is `1.0`. Valid range is `0.1...5.0`. Larger values require more gesture movement for the same bearing change.
 */
@property (nonatomic) CGFloat rotateResistance;

/**
 是否允许双指垂直拖动改变地图俯仰角。

 Whether two-finger vertical drag can change the map pitch.

 默认值为 `YES`。
 The default is `YES`.
 */
@property (nonatomic, getter=isPitchEnabled) BOOL pitchEnabled;

/**
 俯仰手势阻力系数。

 Resistance factor for pitch gestures.

 默认值为 `1.0`，有效范围为 `0.1...5.0`。值越大，改变俯仰角所需手势幅度越大。
 The default is `1.0`. Valid range is `0.1...5.0`. Larger values require more gesture movement to change pitch.
 */
@property (nonatomic) CGFloat pitchResistance;

/**
 双击地图时是否复位非零俯仰角。

 Whether double tap resets a non-zero pitch angle.

 默认值为 `NO`。仅当 `doubleTapZoomEnabled` 为 `NO` 且当前俯仰角不为 `0` 时，单指双击会将俯仰角复位为 `0`。该属性不影响单指双击放大或双指点击缩回。
 The default is `NO`. Only when `doubleTapZoomEnabled` is `NO` and the current pitch is not `0`, a one-finger double tap resets pitch to `0`. This property does not affect one-finger double-tap zoom-in or two-finger tap zoom-out.
 */
@property (nonatomic, getter=isDoubleTapPitchResetEnabled) BOOL doubleTapPitchResetEnabled;

/**
 是否允许多个地图手势同时识别。

 Whether multiple map gestures may be recognized at the same time.

 默认值为 `YES`。设置为 `NO` 时，同一时间只识别一种手势。
 The default is `YES`. When set to `NO`, only one gesture is recognized at a time.
 */
@property (nonatomic, getter=isSimultaneousRecognitionEnabled) BOOL simultaneousRecognitionEnabled;

/**
 自定义互斥手势分组。

 Custom mutually exclusive gesture group.

 默认值为 `MTCMapGestureTypeNone`，表示不增加自定义互斥规则。设置多个手势类型后，当这些手势互相竞争同时识别时，SDK 会拒绝它们同时生效。
 The default is `MTCMapGestureTypeNone`, which adds no custom exclusivity rule. When multiple gesture types are set, the SDK prevents those gesture types from recognizing simultaneously with each other.

 该属性仅在 `simultaneousRecognitionEnabled` 为 `YES` 时影响同时识别判断；当 `simultaneousRecognitionEnabled` 为 `NO` 时，全局互斥规则优先，所有地图手势仍然不能同时识别。
 This property only affects simultaneous-recognition decisions when `simultaneousRecognitionEnabled` is `YES`; when `simultaneousRecognitionEnabled` is `NO`, the global exclusive rule takes precedence and map gestures still cannot recognize together.

 未选入该集合的手势继续使用 SDK 默认协调规则。未知 bit 会被忽略。
 Gestures not included in this set keep using the SDK default coordination rules. Unknown bits are ignored.
 */
@property (nonatomic) MTCMapGestureType mutuallyExclusiveGestureTypes;

/**
 双指旋转手势触发前每个手指沿旋转弧线需要移动的最小距离，单位为点。

 Minimum arc distance each finger must move before a two-finger rotation gesture begins, in points.

 属性名保留现有命名；该属性当前仅控制旋转触发阈值，不控制俯仰触发阈值。
 The property keeps the existing name; it now only controls the rotation trigger threshold, not the pitch trigger threshold.

 默认值为 `15.0`，有效范围为 `0.0...50.0`。值为 `0.0` 时不增加额外触发阈值。
 The default is `15.0`. Valid range is `0.0...50.0`. Use `0.0` to avoid adding an extra trigger threshold.
 */
@property (nonatomic) CGFloat rotatePitchThreshold;

/**
 双指俯仰手势触发前需要移动的最小距离，单位为点。

 Minimum movement distance required before a two-finger pitch gesture begins, in points.

 默认值为 `15.0`，有效范围为 `0.0...50.0`。值越大，越不容易误触俯仰手势。
 The default is `15.0`. Valid range is `0.0...50.0`. Larger values make accidental pitch gestures less likely.
 */
@property (nonatomic) CGFloat pitchThreshold;

/**
 双指俯仰拖动允许偏离垂直方向的角度，单位为度。

 Maximum angle, in degrees, that a two-finger pitch drag may deviate from the vertical direction.

 默认值为 `20.0`，有效范围为 `0.0...45.0`。值越大，斜向下滑越容易被识别为俯仰；值越小，越接近严格垂直下滑才会触发。
 The default is `20.0`. Valid range is `0.0...45.0`. Larger values allow more diagonal movement to count as pitch; smaller values require movement closer to a vertical drag.
 */
@property (nonatomic) CGFloat pitchVerticalTolerance;

/**
 创建一份默认手势配置。

 Creates a default gesture settings object.

 @return 使用文档默认值初始化的新配置对象。
 A new settings object initialized with documented defaults.
 */
+ (instancetype)defaultSettings;

@end

NS_ASSUME_NONNULL_END
