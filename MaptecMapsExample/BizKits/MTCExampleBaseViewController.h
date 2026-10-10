//
//  MTCExampleBaseViewController.h
//  MaptecMapsExample
//
//  Created by ZHOUPanpan on 2026/8/3.
//

#import <UIKit/UIKit.h>

#import <MaptecFoundationKit/MaptecFoundationKit.h>
#import "MTCExampleDemoLocalization.h"

NS_ASSUME_NONNULL_BEGIN

/// Example 演示页基类：承载全局中英文状态同步与通用导航能力。
@interface MTCExampleBaseViewController : UIViewController

/// 当前页面演示语言；与 `MTCExampleDemoLocalization.currentLanguage` 保持同步。
@property (nonatomic, assign) MTCExampleDemoLanguage demoLanguage;

/// 按当前 `demoLanguage` 读取 String Catalog 文案。
- (NSString *)localizedStringForKey:(NSString *)key;

/// 点击设置按钮时回调；子类按需重写。
- (void)handleExampleSettingsAction;

/// 中英文切换完成后回调；子类在此刷新标题、面板与地图语言。
- (void)demoLanguageDidChange;

@end

/// 导航栏右侧语言切换 + 设置按钮的 UI 绘制。
@interface MTCExampleBaseViewController (NavigationItems)

/// 配置右上角导航按钮。
/// @param onlyLan YES 仅语言切换；NO 语言切换在右、设置按钮在左。
- (void)configureNavigationItems:(BOOL)onlyLan;

- (MTCMapLanguage)mapLanguageForDemoLanguage:(MTCExampleDemoLanguage)language;

- (BOOL)isSettingsSheetVisible:(Class)settingClass;

/// 控件位置选项文案（顺序与 `MTCExampleMapBizUtil.MTCUIPositionTitles` 一致）。
- (NSArray<NSString *> *)localizedUIPositionTitles;

@end

NS_ASSUME_NONNULL_END
