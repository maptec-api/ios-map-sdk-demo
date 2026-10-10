#import <UIKit/UIKit.h>

@class MTCMapView;

NS_ASSUME_NONNULL_BEGIN

/// 地图 Demo 页共享 UI 测试 hook（对齐 Android `mapRendered` / 状态 label）。
@interface MTCExampleMapTestSupport : NSObject

/// 覆盖物数量读回 key，例如 `marker_count` / `circle_count`。
@property (nonatomic, copy) NSString *overlayCountValueKey;
/// 覆盖物数量 label 的 accessibilityIdentifier（默认 `symbol_layer_map_view`）。
@property (nonatomic, copy) NSString *mapStateIdentifier;
/// 有覆盖物时出现的 indicator identifier（可为 nil）。
@property (nonatomic, copy, nullable) NSString *overlayPresenceIdentifier;

@property (nonatomic, strong, readonly) UIView *mapRenderedTestView;
@property (nonatomic, strong, readonly) UIView *overlayCountTestView;
@property (nonatomic, strong, readonly, nullable) UIView *overlayPresenceTestView;

- (void)installOnHostView:(UIView *)hostView;
- (void)markMapRenderedReady;
- (void)clearMapRenderedReady;
- (void)pauseMapRenderingIfUITesting:(MTCMapView *)mapView;
- (void)syncOverlayCount:(NSUInteger)count;

@end

NS_ASSUME_NONNULL_END
