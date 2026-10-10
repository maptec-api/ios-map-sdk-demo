#import <Foundation/Foundation.h>
#import <MaptecMapsKit/MTCOverlayHit.h>

NS_ASSUME_NONNULL_BEGIN

/**
 聚合覆盖物命中类型。

 Cluster overlay hit type.
 */
typedef NS_ENUM(NSInteger, MTCClusterHitType) {
    /**
     命中聚合簇。

     A cluster was hit.
     */
    MTCClusterHitTypeCluster = 0,

    /**
     命中展开后的单点。

     A leaf point was hit.
     */
    MTCClusterHitTypePoint,
};

/**
 聚合覆盖物命中信息。

 Cluster overlay hit information.

 `MTCClusterHit` 用于在通用覆盖物点击回调中区分当前命中的是聚合簇还是展开后的单点。
 `MTCClusterHit` distinguishes whether a common overlay tap callback hit a cluster or an expanded leaf point.
 */
NS_SWIFT_NAME(MTCClusterHit)
@interface MTCClusterHit : MTCOverlayHit

- (instancetype)init NS_UNAVAILABLE;
+ (instancetype)new NS_UNAVAILABLE;

/**
 创建聚合覆盖物命中信息。

 Creates cluster overlay hit information.
 */
- (instancetype)initWithScreenPoint:(CGPoint)screenPoint
                         coordinate:(CLLocationCoordinate2D)coordinate
                     clusterHitType:(MTCClusterHitType)clusterHitType
                           clusterID:(nullable NSNumber *)clusterID
                          pointCount:(NSUInteger)pointCount
                     pointIdentifier:(nullable NSString *)pointIdentifier
                    expansionLimited:(BOOL)expansionLimited NS_DESIGNATED_INITIALIZER;

/**
 命中类型。

 The hit type.
 */
@property (nonatomic, readonly) MTCClusterHitType clusterHitType;

/**
 是否命中聚合簇。

 Whether a cluster was hit.
 */
@property (nonatomic, readonly, getter=isCluster) BOOL cluster;

/**
 是否命中展开后的单点。

 Whether a leaf point was hit.
 */
@property (nonatomic, readonly, getter=isPoint) BOOL point;

/**
 底层聚合簇 ID。

 The underlying cluster identifier.

 仅命中聚合簇时可能有值。该值只在当前数据版本和当前渲染状态下有效，不应长期持久化。
 This may be non-null only when a cluster is hit. It is valid only for the current data revision and render state and should not be persisted long term.
 */
@property (nonatomic, copy, readonly, nullable) NSNumber *clusterID;

/**
 聚合簇包含的叶子点数量。

 The number of leaf points contained by the cluster.

 仅命中聚合簇时有意义；命中单点时为 `1`。
 Meaningful only when a cluster is hit; it is `1` for a leaf point hit.
 */
@property (nonatomic, readonly) NSUInteger pointCount;

/**
 叶子点业务标识。

 Leaf point business identifier.

 仅命中单点时可能有值，对应 `MTCClusterPoint.identifier`。
 This may be non-null only when a leaf point is hit and corresponds to `MTCClusterPoint.identifier`.
 */
@property (nonatomic, copy, readonly, nullable) NSString *pointIdentifier;

/**
 是否已达到可展开上限。

 Whether expansion has reached its limit.

 当 `MTCCluster.clusterClickBehavior` 为 `MTCClusterClickBehaviorZoomToExpansion` 且当前缩放级别已达到可展开上限时为 `YES`。其它情况下为 `NO`。
 This is `YES` when `MTCCluster.clusterClickBehavior` is `MTCClusterClickBehaviorZoomToExpansion` and the current zoom level has reached the expansion limit. It is `NO` otherwise.
 */
@property (nonatomic, readonly, getter=isExpansionLimited) BOOL expansionLimited;

@end

NS_ASSUME_NONNULL_END
