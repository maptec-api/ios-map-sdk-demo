#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@class MTCClusterStyle;

/**
 聚合簇样式匹配规则。

 Cluster style matching rule.

 `MTCClusterStyleRule` 使用闭区间 `[minimumPointCount, maximumPointCount]` 匹配聚合簇的 `point_count`。`maximumPointCount` 为 `nil` 时表示无上限。规则只表达匹配条件和命中后的样式，不承载视觉配置本身。
 `MTCClusterStyleRule` matches a cluster's `point_count` using the inclusive range `[minimumPointCount, maximumPointCount]`. A `nil` `maximumPointCount` means no upper bound. The rule expresses matching conditions and the matched style, not visual configuration itself.
 */
NS_SWIFT_NAME(MTCClusterStyleRule)
@interface MTCClusterStyleRule : NSObject <NSCopying>

/**
 创建聚合簇样式规则。

 Creates a cluster style rule.

 @param minimumPointCount 最小聚合点数，必须大于等于 `2`。The minimum point count, which must be at least `2`.
 @param maximumPointCount 最大聚合点数，传入 `nil` 表示无上限；有值时必须大于等于 `minimumPointCount`。The maximum point count. Pass `nil` for no upper bound; when non-null it must be greater than or equal to `minimumPointCount`.
 @param style 命中该规则时使用的样式。The style used when this rule matches.
 */
- (nullable instancetype)initWithMinimumPointCount:(NSUInteger)minimumPointCount
                                maximumPointCount:(nullable NSNumber *)maximumPointCount
                                            style:(MTCClusterStyle *)style NS_DESIGNATED_INITIALIZER;

- (instancetype)init NS_UNAVAILABLE;
+ (instancetype)new NS_UNAVAILABLE;

/**
 最小聚合点数。

 The minimum point count.
 */
@property (nonatomic, readonly) NSUInteger minimumPointCount;

/**
 最大聚合点数。

 The maximum point count.

 `nil` 表示无上限。
 `nil` means no upper bound.
 */
@property (nonatomic, copy, readonly, nullable) NSNumber *maximumPointCount;

/**
 命中该规则时使用的样式。

 The style used when this rule matches.
 */
@property (nonatomic, copy, readonly) MTCClusterStyle *style;

@end

NS_ASSUME_NONNULL_END
