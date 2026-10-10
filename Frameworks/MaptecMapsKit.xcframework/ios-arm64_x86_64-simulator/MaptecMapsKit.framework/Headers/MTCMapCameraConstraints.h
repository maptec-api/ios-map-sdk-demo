#import <CoreGraphics/CoreGraphics.h>
#import <CoreLocation/CoreLocation.h>
#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/**
 地图缩放级别允许范围。

 Allowed map zoom-level range.

 `minimumZoomLevel` 和 `maximumZoomLevel` 表示相机缩放级别的允许范围。赋值给 `MTCMapCameraConstraints.zoomLevelRange` 时，SDK 会将值限制在 `0.0...22.0` 内，并在必要时交换上下限。
 `minimumZoomLevel` and `maximumZoomLevel` define the allowed camera zoom-level range. When assigned to `MTCMapCameraConstraints.zoomLevelRange`, the SDK clamps values to `0.0...22.0` and swaps the bounds when needed.
 */
typedef struct {
    /**
     最小缩放级别。

     The minimum zoom level.
     */
    double minimumZoomLevel;

    /**
     最大缩放级别。

     The maximum zoom level.
     */
    double maximumZoomLevel;
} MTCMapZoomLevelRange;

/**
 创建地图缩放级别允许范围。

 Creates an allowed map zoom-level range.

 @param minimumZoomLevel 最小缩放级别。The minimum zoom level.
 @param maximumZoomLevel 最大缩放级别。The maximum zoom level.
 @return 地图缩放级别范围。A map zoom-level range.
 */
CG_INLINE MTCMapZoomLevelRange MTCMapZoomLevelRangeMake(double minimumZoomLevel,
                                                        double maximumZoomLevel) {
    MTCMapZoomLevelRange range;
    range.minimumZoomLevel = minimumZoomLevel;
    range.maximumZoomLevel = maximumZoomLevel;
    return range;
}

/**
 地图俯仰角允许范围。

 Allowed map pitch-angle range.

 `minimumPitchAngle` 和 `maximumPitchAngle` 表示相机俯仰角的允许范围，单位为度。赋值给 `MTCMapCameraConstraints.pitchAngleRange` 时，SDK 会将值限制在 `0.0...60.0` 内，并在必要时交换上下限。
 `minimumPitchAngle` and `maximumPitchAngle` define the allowed camera pitch-angle range, in degrees. When assigned to `MTCMapCameraConstraints.pitchAngleRange`, the SDK clamps values to `0.0...60.0` and swaps the bounds when needed.
 */
typedef struct {
    /**
     最小俯仰角，单位为度。

     The minimum pitch angle, in degrees.
     */
    CGFloat minimumPitchAngle;

    /**
     最大俯仰角，单位为度。

     The maximum pitch angle, in degrees.
     */
    CGFloat maximumPitchAngle;
} MTCMapPitchAngleRange;

/**
 创建地图俯仰角允许范围。

 Creates an allowed map pitch-angle range.

 @param minimumPitchAngle 最小俯仰角，单位为度。The minimum pitch angle, in degrees.
 @param maximumPitchAngle 最大俯仰角，单位为度。The maximum pitch angle, in degrees.
 @return 地图俯仰角范围。A map pitch-angle range.
 */
CG_INLINE MTCMapPitchAngleRange MTCMapPitchAngleRangeMake(CGFloat minimumPitchAngle,
                                                          CGFloat maximumPitchAngle) {
    MTCMapPitchAngleRange range;
    range.minimumPitchAngle = minimumPitchAngle;
    range.maximumPitchAngle = maximumPitchAngle;
    return range;
}

/**
 地图朝向角允许范围。

 Allowed map bearing range.

 `startBearing` 和 `endBearing` 表示地图朝向角的顺时针允许区间，单位为度。取值范围为 `0.0...360.0`。
 `startBearing` and `endBearing` define the allowed clockwise map bearing interval, in degrees. Valid values are `0.0...360.0`.

 可以跨越正北方向，例如 `MTCMapBearingRangeMake(350, 10)` 表示允许 `350°...360°` 和 `0°...10°`。
 The range may cross north. For example, `MTCMapBearingRangeMake(350, 10)` allows `350°...360°` and `0°...10°`.
 */
typedef struct {
    /**
     起始朝向角，单位为度。

     The start bearing, in degrees.
     */
    CLLocationDirection startBearing;

    /**
     结束朝向角，单位为度。

     The end bearing, in degrees.
     */
    CLLocationDirection endBearing;
} MTCMapBearingRange;

/**
 创建地图朝向角允许范围。

 Creates an allowed map bearing range.

 默认不限制朝向时使用 `MTCMapBearingRangeMake(0, 360)`。赋值给 `bearingRange` 时，SDK 会将两个角度限制在 `0.0...360.0`。
 Use `MTCMapBearingRangeMake(0, 360)` for unrestricted bearing. When assigned to `bearingRange`, the SDK clamps both bearings to `0.0...360.0`.

 @param startBearing 起始朝向角，单位为度。The start bearing, in degrees.
 @param endBearing 结束朝向角，单位为度。The end bearing, in degrees.
 @return 地图朝向角范围。A map bearing range.
 */
CG_INLINE MTCMapBearingRange MTCMapBearingRangeMake(CLLocationDirection startBearing,
                                                    CLLocationDirection endBearing) {
    MTCMapBearingRange range;
    range.startBearing = startBearing;
    range.endBearing = endBearing;
    return range;
}

/**
 地图相机约束配置对象。

 Camera constraint configuration object owned by `MTCMapView`.

 `MTCMapView` 在初始化时创建默认配置对象，并通过只读 `cameraConstraints` 属性暴露。直接修改该对象的属性会立即应用到地图相机。约束会影响手势、程序化相机设置和动画目标；请求超出范围时，SDK 会自动裁剪到最近的合法相机，不作为错误处理。
 `MTCMapView` creates a default constraint object during initialization and exposes it through its read-only `cameraConstraints` property. Mutating these properties applies changes to the map camera immediately. Constraints affect gestures, programmatic camera updates, and animation targets; requests outside the allowed range are automatically clamped to the nearest valid camera and are not treated as errors.

 @note 除特别说明外，所有属性应在主线程访问和修改。
 Unless otherwise documented, access and mutate these properties on the main thread.
 */
@interface MTCMapCameraConstraints : NSObject <NSCopying>

/**
 允许的地图缩放级别范围。

 Allowed map zoom-level range.

 默认值为 `MTCMapZoomLevelRangeMake(0.0, 22.0)`。有效输入范围为 `0.0...22.0`；如果最小值大于最大值，SDK 会自动交换上下限。
 The default is `MTCMapZoomLevelRangeMake(0.0, 22.0)`. Valid input range is `0.0...22.0`; if the minimum is greater than the maximum, the SDK swaps the bounds.
 */
@property (nonatomic) MTCMapZoomLevelRange zoomLevelRange;

/**
 允许的地图俯仰角范围，单位为度。

 Allowed map pitch-angle range, in degrees.

 默认值为 `MTCMapPitchAngleRangeMake(0.0, 60.0)`。有效输入范围为 `0.0...60.0`；如果最小值大于最大值，SDK 会自动交换上下限。
 The default is `MTCMapPitchAngleRangeMake(0.0, 60.0)`. Valid input range is `0.0...60.0`; if the minimum is greater than the maximum, the SDK swaps the bounds.
 */
@property (nonatomic) MTCMapPitchAngleRange pitchAngleRange;

/**
 允许的地图朝向角范围，单位为度。

 Allowed map bearing range, in degrees.

 默认值为 `MTCMapBearingRangeMake(0.0, 360.0)`，表示不限制朝向。可以设置跨越正北方向的范围，例如 `MTCMapBearingRangeMake(350, 10)`。
 The default is `MTCMapBearingRangeMake(0.0, 360.0)`, which means unrestricted bearing. Ranges may cross north, for example `MTCMapBearingRangeMake(350, 10)`.
 */
@property (nonatomic) MTCMapBearingRange bearingRange;

/**
 创建一份默认相机约束配置。

 Creates a default camera constraint object.

 @return 使用文档默认值初始化的新配置对象。
 A new constraint object initialized with documented defaults.
 */
+ (instancetype)defaultConstraints;

@end

NS_ASSUME_NONNULL_END
