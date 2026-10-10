//
//  MTCExampleLanguageToggleControl.h
//  MaptecMapsExample
//
//  Created by ZHOUPanpan+ on 2026-08-03.
//  Copyright © 2026 ZHOUPanpan+. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "MTCExampleDemoLocalization.h"

NS_ASSUME_NONNULL_BEGIN

/// 中英文切换控件：顶部地球 SF Symbol，下方 `CN / EN` 选中态指示。
///
/// 形态对齐 Android `DemoLanguageToggle`：整块可点，当前语言加粗高亮，非当前语言半透明。
@interface MTCExampleLanguageToggleControl : UIControl

/// 当前选中语言，默认中文。
@property (nonatomic, assign) MTCExampleDemoLanguage selectedLanguage;

@end

NS_ASSUME_NONNULL_END
