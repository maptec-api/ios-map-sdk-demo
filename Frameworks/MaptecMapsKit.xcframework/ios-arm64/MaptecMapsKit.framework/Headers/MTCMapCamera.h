#import <CoreGraphics/CoreGraphics.h>
#import <CoreLocation/CoreLocation.h>
#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/**
 相机过渡类型。

 The camera transition type.
 */
typedef NS_ENUM(NSInteger, MTCCameraTransitionType) {
    /**
     立即跳转到目标相机，无动画。

     Immediately jumps to the target camera without animation.
     */
    MTCCameraTransitionTypeJump = 0,

    /**
     使用缓动动画移动到目标相机。

     Moves to the target camera using an easing animation.
     */
    MTCCameraTransitionTypeEase,

    /**
     使用飞行动画移动到目标相机。

     Moves to the target camera using a flight animation.
     */
    MTCCameraTransitionTypeFly,
};

/**
 相机过渡配置。

 Camera transition configuration.

 `nil` transition 与 `[MTCCameraTransition jump]` 等价。`duration` 小于或等于 `0` 时表示立即完成。
 A `nil` transition is equivalent to `[MTCCameraTransition jump]`. A `duration` less than or equal to `0` means the transition completes immediately.
 */
@interface MTCCameraTransition : NSObject <NSCopying>

/**
 过渡类型。

 The transition type.
 */
@property (nonatomic, readonly) MTCCameraTransitionType type;

/**
 过渡时长，单位为秒。

 The transition duration, in seconds.
 */
@property (nonatomic, readonly) CFTimeInterval duration;

- (instancetype)init NS_UNAVAILABLE;
+ (instancetype)new NS_UNAVAILABLE;

/**
 创建立即跳转过渡。

 Creates an immediate jump transition.
 */
+ (instancetype)jump;

/**
 创建缓动动画过渡。

 Creates an easing animation transition.
 */
+ (instancetype)easeWithDuration:(CFTimeInterval)duration;

/**
 创建飞行动画过渡。

 Creates a flight animation transition.
 */
+ (instancetype)flyWithDuration:(CFTimeInterval)duration;

@end

/**
 地图相机状态。

 Map camera state.

 `MTCMapCamera` 是不可变快照对象。修改地图相机必须调用 `MTCMapView` 的相机设置方法；修改已取得的相机对象不会影响地图。
 `MTCMapCamera` is an immutable snapshot object. To change the map camera, call camera-setting methods on `MTCMapView`; mutating a retrieved camera object does not affect the map.
 */
@interface MTCMapCamera : NSObject <NSCopying>

/**
 地图中心点。

 The map center coordinate.
 */
@property (nonatomic, readonly) CLLocationCoordinate2D centerCoordinate;

/**
 缩放级别。

 The zoom level.
 */
@property (nonatomic, readonly) double zoomLevel;

/**
 朝向角，单位为度。

 The bearing, in degrees.
 */
@property (nonatomic, readonly) CLLocationDirection bearing;

/**
 俯仰角，单位为度。

 The pitch, in degrees.
 */
@property (nonatomic, readonly) CGFloat pitch;

- (instancetype)init NS_UNAVAILABLE;
+ (instancetype)new NS_UNAVAILABLE;

/**
 创建地图相机状态。

 Creates a map camera state.
 */
+ (instancetype)cameraWithCenterCoordinate:(CLLocationCoordinate2D)centerCoordinate
                                 zoomLevel:(double)zoomLevel
                                   bearing:(CLLocationDirection)bearing
                                     pitch:(CGFloat)pitch;

@end

NS_ASSUME_NONNULL_END
