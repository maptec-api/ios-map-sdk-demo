#import <CoreLocation/CoreLocation.h>
#import <Foundation/Foundation.h>
#import <MaptecMapsKit/MTCPath.h>

NS_ASSUME_NONNULL_BEGIN

@class MTCMarker;
@class MTCMarkerMovementProgress;
@class MTCMarkerMovementTask;

/**
 Marker 平滑移动错误域。

 The marker movement error domain.
 */
FOUNDATION_EXPORT NSErrorDomain const MTCMarkerMovementErrorDomain;

/**
 Marker 平滑移动错误名称的 `userInfo` key。

 The `userInfo` key for the marker movement error name.

 当前 `MTCMarkerMovementErrorInvalidArgument` 对应的名称为 `INVALID_ARGUMENT`。
 `MTCMarkerMovementErrorInvalidArgument` currently uses `INVALID_ARGUMENT` as the error name.
 */
FOUNDATION_EXPORT NSErrorUserInfoKey const MTCMarkerMovementErrorNameKey;

/**
 Marker 平滑移动错误码。

 Marker movement error code.
 */
typedef NS_ERROR_ENUM(MTCMarkerMovementErrorDomain, MTCMarkerMovementErrorCode) {
    /**
     参数非法。

     Invalid argument.
     */
    MTCMarkerMovementErrorInvalidArgument = 1,

    /**
     当前状态不允许该操作。

     The current state does not allow the operation.
     */
    MTCMarkerMovementErrorInvalidState,

    /**
     Marker 尚未添加到地图。

     The marker has not been added to a map.
     */
    MTCMarkerMovementErrorMarkerNotOnMap,

    /**
     内部错误。

     Internal error.
     */
    MTCMarkerMovementErrorInternal = 999,
};

/**
 Marker 路径移动时序模式。

 Marker path movement timing mode.
 */
typedef NS_ENUM(NSInteger, MTCMarkerMovementTimingMode) {
    /**
     按总时长完成移动。

     Completes the movement within a total duration.
     */
    MTCMarkerMovementTimingModeDuration = 0,

    /**
     按地理速度移动。

     Moves at a geographic speed.
     */
    MTCMarkerMovementTimingModeSpeed,
};

/**
 Marker 平滑移动状态。

 Marker movement state.
 */
typedef NS_ENUM(NSInteger, MTCMarkerMovementState) {
    /**
     正在运行。

     Running.
     */
    MTCMarkerMovementStateRunning = 0,

    /**
     已暂停。

     Paused.
     */
    MTCMarkerMovementStatePaused,

    /**
     已完成。

     Finished.
     */
    MTCMarkerMovementStateFinished,

    /**
     已取消。

     Cancelled.
     */
    MTCMarkerMovementStateCancelled,

    /**
     因错误终止。

     Ended with an error.
     */
    MTCMarkerMovementStateError,
};

/**
 App 进入后台时的移动行为。

 Movement behavior when the app enters the background.
 */
typedef NS_ENUM(NSInteger, MTCMarkerMovementBackgroundBehavior) {
    /**
     进入后台后暂停，回到前台继续。

     Pauses in the background and resumes in the foreground.
     */
    MTCMarkerMovementBackgroundBehaviorPause = 0,

    /**
     进入后台后继续按系统调度运行。

     Continues in the background subject to system scheduling.
     */
    MTCMarkerMovementBackgroundBehaviorContinue,
};

/**
 主动取消后的 Marker 处理方式。

 Marker handling after an explicit cancellation.
 */
typedef NS_ENUM(NSInteger, MTCMarkerMovementCancelBehavior) {
    /**
     保持取消时的当前位置。

     Keeps the marker at its current coordinate.
     */
    MTCMarkerMovementCancelBehaviorKeepCurrent = 0,

    /**
     取消后回到移动起点。

     Resets the marker to the movement start coordinate.
     */
    MTCMarkerMovementCancelBehaviorResetToStart,

    /**
     取消后从地图移除 marker。

     Removes the marker from the map after cancellation.
     */
    MTCMarkerMovementCancelBehaviorRemoveMarker,
};

/**
 移动完成原因。

 Movement finish reason.
 */
typedef NS_ENUM(NSInteger, MTCMarkerMovementFinishReason) {
    /**
     移动自然完成。

     Movement completed naturally.
     */
    MTCMarkerMovementFinishReasonCompleted = 0,

    /**
     业务主动结束移动。

     Movement was finished by app code.
     */
    MTCMarkerMovementFinishReasonFinishedByUser,
};

/**
 移动取消原因。

 Movement cancellation reason.
 */
typedef NS_ENUM(NSInteger, MTCMarkerMovementCancelReason) {
    /**
     业务主动取消移动。

     Movement was cancelled by app code.
     */
    MTCMarkerMovementCancelReasonCancelledByUser = 0,

    /**
     新移动任务替换了当前任务。

     The current task was replaced by a new movement task.
     */
    MTCMarkerMovementCancelReasonReplaced,

    /**
     Marker 被从地图移除。

     The marker was removed from the map.
     */
    MTCMarkerMovementCancelReasonMarkerRemoved,

    /**
     业务直接修改 marker 坐标导致移动取消。

     App code changed the marker coordinate directly and cancelled the movement.
     */
    MTCMarkerMovementCancelReasonExternalCoordinateChange,
};

/**
 Marker 平滑移动输入。

 Marker movement input.
 */
NS_SWIFT_NAME(MTCMarkerMovement)
@protocol MTCMarkerMovement <NSObject, NSCopying>
@end

/**
 Marker 点到点平滑移动。

 Marker point-to-point movement.
 */
NS_SWIFT_NAME(MTCMarkerPointMovement)
@interface MTCMarkerPointMovement : NSObject <MTCMarkerMovement>

- (instancetype)init NS_UNAVAILABLE;
+ (instancetype)new NS_UNAVAILABLE;

/**
 创建点到点移动。

 Creates a point-to-point movement.

 @param targetCoordinate 目标坐标。The target coordinate.
 @param durationMs 移动时长，单位毫秒，必须大于 `0`。The movement duration in milliseconds. Must be greater than `0`.
 */
- (instancetype)initWithTargetCoordinate:(CLLocationCoordinate2D)targetCoordinate
                              durationMs:(NSInteger)durationMs NS_DESIGNATED_INITIALIZER;

/**
 目标坐标。

 The target coordinate.
 */
@property (nonatomic, readonly) CLLocationCoordinate2D targetCoordinate;

/**
 点到点移动时长，单位为毫秒。

 The movement duration in milliseconds.
 */
@property (nonatomic, readonly) NSInteger durationMs;

@end

/**
 Marker 路径平滑移动。

 Marker path movement.
 */
NS_SWIFT_NAME(MTCMarkerPathMovement)
@interface MTCMarkerPathMovement : NSObject <MTCMarkerMovement>

- (instancetype)init NS_UNAVAILABLE;
+ (instancetype)new NS_UNAVAILABLE;

/**
 创建按总时长完成的路径移动。

 Creates a path movement that completes within a total duration.

 @param path 路径。去除相邻重复点后至少需要两个有效坐标。The path. It must contain at least two valid coordinates after adjacent duplicate points are removed.
 @param durationMs 移动总时长，单位毫秒，必须大于 `0`。The total movement duration in milliseconds. Must be greater than `0`.
 */
- (instancetype)initWithPath:(MTCPath *)path
                  durationMs:(NSInteger)durationMs;

/**
 创建按地理速度运行的路径移动。

 Creates a path movement that runs at a geographic speed.

 @param path 路径。去除相邻重复点后至少需要两个有效坐标。The path. It must contain at least two valid coordinates after adjacent duplicate points are removed.
 @param speedMetersPerSecond 沿路径移动的速度，单位米/秒，必须大于 `0`。The path speed in meters per second. Must be greater than `0`.
 */
- (instancetype)initWithPath:(MTCPath *)path
                       speed:(CLLocationSpeed)speedMetersPerSecond;

/**
 Marker 依次经过的有序路径。

 The ordered path that the marker follows.
 */
@property (nonatomic, copy, readonly) MTCPath *path;

/**
 路径移动时序模式。

 The path movement timing mode.
 */
@property (nonatomic, readonly) MTCMarkerMovementTimingMode timingMode;

/**
 按总时长移动时的目标总时长，单位为毫秒。

 The target total duration in milliseconds for duration-based movement.

 仅当 `timingMode` 为 `MTCMarkerMovementTimingModeDuration` 时有效。
 Valid only when `timingMode` is `MTCMarkerMovementTimingModeDuration`.
 */
@property (nonatomic, readonly) NSInteger durationMs;

/**
 按速度移动时的地理速度，单位为米/秒。

 The geographic speed in meters per second for speed-based movement.

 仅当 `timingMode` 为 `MTCMarkerMovementTimingModeSpeed` 时有效。
 Valid only when `timingMode` is `MTCMarkerMovementTimingModeSpeed`.
 */
@property (nonatomic, readonly) CLLocationSpeed speedMetersPerSecond;

@end

/**
 移动进度回调。

 Movement progress callback.
 */
typedef void (^MTCMarkerMovementProgressHandler)(MTCMarkerMovementTask *task,
                                                 MTCMarkerMovementProgress *progress);

/**
 暂停或恢复状态回调。

 Pause or resume state callback.
 */
typedef void (^MTCMarkerMovementStateHandler)(MTCMarkerMovementTask *task,
                                              MTCMarkerMovementProgress *progress);

/**
 移动完成回调。

 Movement finish callback.
 */
typedef void (^MTCMarkerMovementFinishHandler)(MTCMarkerMovementTask *task,
                                               MTCMarkerMovementProgress *progress,
                                               MTCMarkerMovementFinishReason reason);

/**
 移动取消回调。

 Movement cancellation callback.
 */
typedef void (^MTCMarkerMovementCancelHandler)(MTCMarkerMovementTask *task,
                                               MTCMarkerMovementProgress *progress,
                                               MTCMarkerMovementCancelReason reason);

/**
 移动错误回调。

 Movement error callback.
 */
typedef void (^MTCMarkerMovementErrorHandler)(MTCMarkerMovementTask *task,
                                              NSError *error);

/**
 Marker 平滑移动配置。

 Marker movement options.
 */
NS_SWIFT_NAME(MTCMarkerMovementOptions)
@interface MTCMarkerMovementOptions : NSObject <NSCopying>

/**
 是否按移动方向自动旋转 marker 图标。

 Whether the marker icon rotates automatically to follow movement heading.

 默认值为 `YES`。仅在当前采样点能计算方向时生效。
 The default value is `YES`. This only takes effect when the current sampled position has a valid heading.
 */
@property (nonatomic) BOOL autoRotate;

/**
 自动旋转方向偏移量，单位为度。

 Auto-rotation heading offset in degrees.

 默认值为 `0`。
 The default value is `0`.
 */
@property (nonatomic) CLLocationDirection headingOffset;

/**
 方向平滑时长，单位为秒。

 Heading smoothing duration in seconds.

 默认值为 `0.15`。小于等于 `0` 时不做方向平滑。
 The default value is `0.15`. Values less than or equal to `0` disable heading smoothing.
 */
@property (nonatomic) NSTimeInterval orientationSmoothingDuration;

/**
 App 进入后台时的移动行为。

 Movement behavior when the app enters the background.

 默认值为 `MTCMarkerMovementBackgroundBehaviorPause`。
 The default value is `MTCMarkerMovementBackgroundBehaviorPause`.
 */
@property (nonatomic) MTCMarkerMovementBackgroundBehavior backgroundBehavior;

/**
 进度回调最小间隔，单位为秒。

 Minimum progress callback interval in seconds.

 默认值为 `0.1`。小于等于 `0` 时每次进度推进都回调。
 The default value is `0.1`. Values less than or equal to `0` emit callbacks on every progress advance.
 */
@property (nonatomic) NSTimeInterval progressCallbackInterval;

/**
 主动取消后的 marker 处理方式。

 Marker handling after explicit cancellation.

 默认值为 `MTCMarkerMovementCancelBehaviorKeepCurrent`。
 The default value is `MTCMarkerMovementCancelBehaviorKeepCurrent`.
 */
@property (nonatomic) MTCMarkerMovementCancelBehavior cancelBehavior;

/**
 进度回调。

 Progress callback.
 */
@property (nonatomic, copy, nullable) MTCMarkerMovementProgressHandler progressHandler;

/**
 暂停回调。

 Pause callback.
 */
@property (nonatomic, copy, nullable) MTCMarkerMovementStateHandler pauseHandler;

/**
 恢复回调。

 Resume callback.
 */
@property (nonatomic, copy, nullable) MTCMarkerMovementStateHandler resumeHandler;

/**
 完成回调。

 Finish callback.
 */
@property (nonatomic, copy, nullable) MTCMarkerMovementFinishHandler finishHandler;

/**
 取消回调。

 Cancellation callback.
 */
@property (nonatomic, copy, nullable) MTCMarkerMovementCancelHandler cancelHandler;

/**
 错误回调。

 Error callback.
 */
@property (nonatomic, copy, nullable) MTCMarkerMovementErrorHandler errorHandler;

@end

/**
 Marker 平滑移动进度。

 Marker movement progress.
 */
NS_SWIFT_NAME(MTCMarkerMovementProgress)
@interface MTCMarkerMovementProgress : NSObject <NSCopying>

- (instancetype)init NS_UNAVAILABLE;
+ (instancetype)new NS_UNAVAILABLE;

/**
 当前 marker 坐标。

 The current marker coordinate.
 */
@property (nonatomic, readonly) CLLocationCoordinate2D coordinate;

/**
 整体进度，范围为 `[0, 1]`。

 Overall progress in the `[0, 1]` range.
 */
@property (nonatomic, readonly) double progress;

/**
 当前进度是否有可用方向。

 Whether a heading is available at the current progress.
 */
@property (nonatomic, readonly) BOOL headingAvailable;

/**
 当前方向，单位为度。

 The current heading in degrees.

 仅当 `headingAvailable` 为 `YES` 时有效。
 Valid only when `headingAvailable` is `YES`.
 */
@property (nonatomic, readonly) CLLocationDirection heading;

@end

/**
 Marker 平滑移动任务。

 Marker movement task.
 */
NS_SWIFT_NAME(MTCMarkerMovementTask)
@interface MTCMarkerMovementTask : NSObject

- (instancetype)init NS_UNAVAILABLE;
+ (instancetype)new NS_UNAVAILABLE;

/**
 移动任务唯一标识。

 The unique movement task identifier.
 */
@property (nonatomic, copy, readonly) NSString *identifier;

/**
 关联的 marker。

 The associated marker.

 Marker 被移除或释放后可能为 `nil`。
 This may become `nil` after the marker is removed or deallocated.
 */
@property (nonatomic, weak, readonly, nullable) MTCMarker *marker;

/**
 关联 marker 的标识。

 The identifier of the associated marker.
 */
@property (nonatomic, copy, readonly) NSString *markerIdentifier;

/**
 当前移动状态。

 The current movement state.
 */
@property (nonatomic, readonly) MTCMarkerMovementState state;

/**
 最近一次移动进度。

 The latest movement progress.
 */
@property (nonatomic, copy, readonly) MTCMarkerMovementProgress *progress;

/**
 暂停移动。

 Pauses the movement.

 @param error 状态非法时返回错误。The returned error when state is invalid.
 @return 是否成功暂停。Whether the movement was paused.
 */
- (BOOL)pauseWithError:(NSError * _Nullable * _Nullable)error;

/**
 恢复移动。

 Resumes the movement.

 @param error 状态非法时返回错误。The returned error when state is invalid.
 @return 是否成功恢复。Whether the movement was resumed.
 */
- (BOOL)resumeWithError:(NSError * _Nullable * _Nullable)error;

/**
 取消移动。

 Cancels the movement.

 取消后的 marker 处理方式由 `MTCMarkerMovementOptions.cancelBehavior` 决定。
 Marker handling after cancellation is controlled by `MTCMarkerMovementOptions.cancelBehavior`.

 @param error 状态非法时返回错误。The returned error when state is invalid.
 @return 是否成功取消。Whether the movement was cancelled.
 */
- (BOOL)cancelWithError:(NSError * _Nullable * _Nullable)error;

/**
 立即结束移动并移动到终点。

 Finishes the movement immediately and moves the marker to the final coordinate.

 @param error 状态非法时返回错误。The returned error when state is invalid.
 @return 是否成功结束。Whether the movement was finished.
 */
- (BOOL)finishWithError:(NSError * _Nullable * _Nullable)error;

/**
 跳转到指定整体进度。

 Seeks to the specified overall progress.

 @param progress 目标进度，范围为 `[0, 1]`。The target progress in the `[0, 1]` range.
 @param error 参数或状态非法时返回错误。The returned error when arguments or state are invalid.
 @return 是否成功跳转。Whether the seek succeeded.
 */
- (BOOL)seekToProgress:(double)progress error:(NSError * _Nullable * _Nullable)error;

@end

NS_ASSUME_NONNULL_END
