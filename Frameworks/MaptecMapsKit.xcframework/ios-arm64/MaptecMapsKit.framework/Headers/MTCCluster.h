#import <CoreGraphics/CoreGraphics.h>
#import <Foundation/Foundation.h>
#import <MaptecMapsKit/MTCClusterPoint.h>
#import <MaptecMapsKit/MTCClusterPointStyle.h>
#import <MaptecMapsKit/MTCClusterStyle.h>
#import <MaptecMapsKit/MTCClusterStyleRule.h>
#import <MaptecMapsKit/MTCOverlay.h>

NS_ASSUME_NONNULL_BEGIN

FOUNDATION_EXPORT NSErrorDomain const MTCClusterErrorDomain;

/**
 聚合错误码。

 Cluster error code.
 */
typedef NS_ERROR_ENUM(MTCClusterErrorDomain, MTCClusterErrorCode) {
    /**
     非法点对象。

     Invalid point object.
     */
    MTCClusterErrorInvalidPoint = 1,

    /**
     非法坐标。

     Invalid coordinate.
     */
    MTCClusterErrorInvalidCoordinate,

    /**
     重复点标识。

     Duplicate point identifier.
     */
    MTCClusterErrorDuplicatePointIdentifier,

    /**
     数据量超过限制。

     Data limit exceeded.
     */
    MTCClusterErrorDataLimitExceeded,

    /**
     非法样式。

     Invalid style.
     */
    MTCClusterErrorInvalidStyle,

    /**
     样式规则范围重叠。

     Style rule ranges overlap.
     */
    MTCClusterErrorStyleRuleOverlap,

    /**
     图片资源不可用。

     Image resource is unavailable.
     */
    MTCClusterErrorImageNotFound,

    /**
     聚合覆盖物尚未就绪。

     Cluster overlay is not ready.
     */
    MTCClusterErrorNotReady,

    /**
     操作已取消。

     Operation cancelled.
     */
    MTCClusterErrorOperationCancelled,

    /**
     内部错误。

     Internal error.
     */
    MTCClusterErrorInternal = 999,
};

/**
 聚合覆盖物生命周期状态。

 Cluster overlay lifecycle state.
 */
typedef NS_ENUM(NSInteger, MTCClusterLifecycleState) {
    /**
     尚未添加到地图。

     Not attached to a map.
     */
    MTCClusterLifecycleStateDetached = 0,

    /**
     数据或配置正在下发。

     Data or configuration is being submitted.
     */
    MTCClusterLifecycleStateLoading,

    /**
     已接受下发且点集非空。

     Submitted successfully with a non-empty point set.
     */
    MTCClusterLifecycleStateReady,

    /**
     已接受下发但点集为空。

     Submitted successfully with an empty point set.
     */
    MTCClusterLifecycleStateEmpty,

    /**
     最近一次数据或渲染生命周期失败。

     The latest data or render lifecycle operation failed.
     */
    MTCClusterLifecycleStateError,
};

/**
 聚合簇点击行为。

 Cluster tap behavior.
 */
typedef NS_ENUM(NSInteger, MTCClusterClickBehavior) {
    /**
     只分发回调，不执行内建相机行为。

     Dispatch callbacks only and do not run built-in camera behavior.
     */
    MTCClusterClickBehaviorCallbackOnly = 0,

    /**
     点击聚合簇时尝试放大展开。

     Attempts to zoom in and expand when a cluster is tapped.

     当前 SDK 使用 `currentZoom + 1` 作为展开缩放回退，并受 `maximumClusterZoomLevel` 约束。
     The SDK uses `currentZoom + 1` as the expansion zoom fallback, constrained by `maximumClusterZoomLevel`.
     */
    MTCClusterClickBehaviorZoomToExpansion,

    /**
     聚合簇点击静默消费；叶子点仍会回调。

     Silently consumes cluster taps; leaf point taps still dispatch callbacks.
     */
    MTCClusterClickBehaviorNone,
};

/**
 点聚合覆盖物。

 Point cluster overlay.

 `MTCCluster` 是一种可点击覆盖物，用于批量点聚合展示。通过 `MTCMapView addOverlay:` 添加到地图；一个 `MTCCluster` 对应一个底层聚合 overlay。
 `MTCCluster` is a clickable overlay for rendering clustered point data. Add it to the map with `MTCMapView addOverlay:`. One `MTCCluster` corresponds to one underlying cluster overlay.
 */
NS_SWIFT_NAME(MTCCluster)
@interface MTCCluster : NSObject <MTCClickableOverlay>

/**
 使用点集创建聚合覆盖物。

 Creates a cluster overlay with points.

 @param points 聚合点集，可为空。The cluster points, which may be empty.
 */
- (instancetype)initWithPoints:(NSArray<MTCClusterPoint *> *)points NS_DESIGNATED_INITIALIZER;

/**
 使用空点集创建聚合覆盖物。

 Creates a cluster overlay with an empty point set.
 */
- (instancetype)init;

/**
 覆盖物唯一标识。

 The unique overlay identifier.
 */
@property (nonatomic, copy, readonly) NSString *identifier;

/**
 聚合点集。

 The cluster points.

 设置时会复制传入数组。空点集会清空底层绘制并进入 `MTCClusterLifecycleStateEmpty`。
 The assigned array is copied. An empty point set clears underlying rendering and enters `MTCClusterLifecycleStateEmpty`.
 */
@property (nonatomic, copy) NSArray<MTCClusterPoint *> *points;

/**
 是否启用聚合。

 Whether clustering is enabled.

 默认值为 `YES`。为 `NO` 时所有点按叶子点渲染。
 The default value is `YES`. When set to `NO`, all points render as leaf points.
 */
@property (nonatomic, getter=isClusteringEnabled) BOOL clusteringEnabled;

/**
 聚合半径。

 Cluster radius.

 取值范围为 `[0, 512]`，单位为屏幕像素语义。默认值为 `50`。该值控制点之间多近会形成聚合，不控制图标视觉大小。
 The valid range is `[0, 512]`, using screen-pixel semantics. The default value is `50`. This controls how close points must be to form clusters and does not control icon visual size.
 */
@property (nonatomic) NSUInteger clusterRadius;

/**
 最大聚合缩放级别。

 Maximum cluster zoom level.

 取值范围为 `[0, 22]`。默认值为 `16`。高于该缩放级别后不再成簇；默认情况下也作为簇图层最大可见缩放。
 The valid range is `[0, 22]`. The default value is `16`. Above this zoom level points no longer cluster; by default this also acts as the maximum visible zoom for cluster layers.
 */
@property (nonatomic) CGFloat maximumClusterZoomLevel;

/**
 最小聚合簇可见缩放级别。

 Minimum visible zoom level for cluster layers.

 取值范围为 `[0, 24]`。默认值为 `0`。
 The valid range is `[0, 24]`. The default value is `0`.
 */
@property (nonatomic) CGFloat minimumClusterZoomLevel;

/**
 最大聚合簇可见缩放级别。

 Maximum visible zoom level for cluster layers.

 取值范围为 `[0, 24]`。默认值跟随 `maximumClusterZoomLevel`。
 The valid range is `[0, 24]`. The default value follows `maximumClusterZoomLevel`.
 */
@property (nonatomic) CGFloat maximumVisibleClusterZoomLevel;

/**
 最小叶子点可见缩放级别。

 Minimum visible zoom level for leaf point layers.

 取值范围为 `[0, 24]`。默认值为 `0`。
 The valid range is `[0, 24]`. The default value is `0`.
 */
@property (nonatomic) CGFloat minimumPointZoomLevel;

/**
 最大叶子点可见缩放级别。

 Maximum visible zoom level for leaf point layers.

 取值范围为 `[0, 24]`。默认值为 `22`。
 The valid range is `[0, 24]`. The default value is `22`.
 */
@property (nonatomic) CGFloat maximumPointZoomLevel;

/**
 形成聚合最小点数。

 Minimum point count to form a cluster.

 必须大于等于 `2`。默认值为 `2`。该值只控制算法是否成簇，不影响样式规则匹配范围。
 Must be at least `2`. The default value is `2`. This controls only whether the algorithm forms a cluster and does not affect style rule matching ranges.
 */
@property (nonatomic) NSUInteger minimumClusterPointCount;

/**
 是否使用计数缩写。

 Whether count abbreviation is enabled.

 默认值为 `YES`，簇默认文字使用缩写计数字段；为 `NO` 时显示完整数字。仅当命中样式未设置自定义 `text` 时生效。
 The default value is `YES`, using the abbreviated count field for default cluster text. When set to `NO`, the full number is shown. This applies only when the matched style does not set custom `text`.
 */
@property (nonatomic, getter=isCountAbbreviationEnabled) BOOL countAbbreviationEnabled;

/**
 是否允许簇符号参与底图碰撞。

 Whether cluster symbols participate in base-map collision.

 默认值为 `NO`，即簇默认稳定显示。为 `YES` 时参与符号碰撞，可能在重叠时隐藏部分簇。
 The default value is `NO`, so clusters are shown reliably by default. When set to `YES`, clusters participate in symbol collision and some clusters may be hidden when overlapping.
 */
@property (nonatomic, getter=isClusterCollisionEnabled) BOOL clusterCollisionEnabled;

/**
 是否允许叶子点符号参与底图碰撞。

 Whether leaf point symbols participate in base-map collision.

 默认值为 `NO`，即叶子点默认稳定显示。
 The default value is `NO`, meaning leaf points are shown reliably by default.
 */
@property (nonatomic, getter=isPointCollisionEnabled) BOOL pointCollisionEnabled;

/**
 默认簇样式。

 The default cluster style.

 当没有样式规则命中时使用。设置时会复制传入对象；传入 `nil` 时恢复 SDK 默认基础样式。
 Used when no style rule matches. The assigned object is copied; passing `nil` restores the SDK default base style.
 */
@property (nonatomic, copy) MTCClusterStyle *style;

/**
 样式规则。

 Style rules.

 规则区间是闭区间，允许有空档；空档回退到 `style`。重叠区间是非法配置，必须通过 `setStyleRules:error:` 修改。
 Rule ranges are inclusive and may contain gaps; gaps fall back to `style`. Overlapping ranges are invalid configuration and must be changed through `setStyleRules:error:`.
 */
@property (nonatomic, copy, readonly) NSArray<MTCClusterStyleRule *> *styleRules;

/**
 设置样式规则。

 Sets style rules.

 传入 `nil` 或空数组表示恢复 SDK 默认三档规则。若存在非法规则或重叠区间，返回 `NO`，通过 `error` 返回原因，并保留旧规则且不触发渲染更新。
 Passing `nil` or an empty array restores the SDK default three-tier rules. If a rule is invalid or ranges overlap, this returns `NO`, reports the reason through `error`, preserves the previous rules, and does not trigger a render update.
 */
- (BOOL)setStyleRules:(nullable NSArray<MTCClusterStyleRule *> *)styleRules
                error:(NSError * _Nullable * _Nullable)error;

/**
 簇图标视觉半径。

 Cluster icon visual radius.

 默认值为自适应 `1` 到 `1`，参考点数 `1000`。该配置作用于整个聚合覆盖物，不按样式规则单独区分。
 The default value is adaptive from `1` to `1` with reference count `1000`. This applies to the whole cluster overlay and is not per-style-rule.
 */
@property (nonatomic, copy) MTCClusterIconRadius *iconRadius;

/**
 默认叶子点样式。

 Default leaf point style.

 设置时会复制传入对象。逐点 `MTCClusterPoint.style` 为空时使用该样式。
 The assigned object is copied. Used when a point's `MTCClusterPoint.style` is `nil`.
 */
@property (nonatomic, copy) MTCClusterPointStyle *defaultPointStyle;

/**
 聚合簇点击行为。

 Cluster tap behavior.

 默认值为 `MTCClusterClickBehaviorCallbackOnly`。该配置只影响聚合簇命中；叶子点命中始终进入 overlay hit 回调。
 The default value is `MTCClusterClickBehaviorCallbackOnly`. This affects only cluster hits; leaf point hits always enter overlay hit callbacks.
 */
@property (nonatomic) MTCClusterClickBehavior clusterClickBehavior;

/**
 是否响应点击和长按。

 Whether the cluster overlay responds to taps and long presses.

 默认值为 `YES`。为 `NO` 时聚合簇和叶子点都不会触发 overlay 点击或长按回调。
 The default value is `YES`. When set to `NO`, neither clusters nor leaf points trigger overlay tap or long-press callbacks.
 */
@property (nonatomic, getter=isClickable) BOOL clickable;

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

/**
 当前生命周期状态。

 The current lifecycle state.
 */
@property (nonatomic, readonly) MTCClusterLifecycleState lifecycleState;

/**
 最近一次生命周期错误。

 The latest lifecycle error.

 仅异步/渲染生命周期失败会写入该属性；同步参数校验失败通过方法返回值和 `NSError` 表达。
 Only asynchronous or render lifecycle failures are stored here; synchronous validation failures are reported through method return values and `NSError`.
 */
@property (nonatomic, copy, readonly, nullable) NSError *lifecycleError;

@end

NS_ASSUME_NONNULL_END
