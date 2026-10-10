//
//  MTCWebRoutePanel.h
//  MaptecMapsExample
//
//  Created by ZHOUPanpan on 2026/8/3.
//  Copyright © 2026 ZHOUPanpan. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

/// 路线规划结果底部面板：主备路线切换、摘要、全览与清除。
@interface MTCWebRoutePanel : UIView

@property (nonatomic, copy, nullable) void (^onSegmentChanged)(NSInteger index);
@property (nonatomic, copy, nullable) void (^onOverviewTapped)(void);
@property (nonatomic, copy, nullable) void (^onClearTapped)(void);

/// 刷新分段标题与选中项。
- (void)reloadWithTitles:(NSArray<NSString *> *)titles selectedIndex:(NSInteger)selectedIndex;

/// 更新摘要文案。
- (void)updateSummaryText:(NSString *)text;

/// 同步分段选中索引（不触发回调）。
- (void)setSelectedSegmentIndex:(NSInteger)index;

/// 按当前 Example 语言刷新控件文案。
- (void)applyLocalizedTexts;

@end

NS_ASSUME_NONNULL_END
