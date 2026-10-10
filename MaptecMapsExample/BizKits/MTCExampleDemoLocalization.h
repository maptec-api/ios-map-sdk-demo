//
//  MTCExampleDemoLocalization.h
//  MaptecMapsExample
//
//  Created by ZHOUPanpan+ on 2026-08-03.
//  Copyright © 2026 ZHOUPanpan+. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/// Example 工程全局演示语言变更通知。
/// userInfo 可选，接收方应通过 `+[MTCExampleDemoLocalization currentLanguage]` 读取最新值。
FOUNDATION_EXPORT NSNotificationName const MTCExampleDemoLanguageDidChangeNotification;

/// Example 工程演示语言（仅中/英）。
typedef NS_ENUM(NSInteger, MTCExampleDemoLanguage) {
    /// 简体中文
    MTCExampleDemoLanguageChinese = 0,
    /// 英语
    MTCExampleDemoLanguageEnglish = 1,
};

/// Example 工程全局演示语言与文案解析（基于 String Catalogs）。
///
/// 语言状态跨页面共享并持久化；切换后会发送 `MTCExampleDemoLanguageDidChangeNotification`，
/// 以便导航栈中已存在的页面同步刷新。
@interface MTCExampleDemoLocalization : NSObject

/// 当前全局演示语言（默认中文）。
+ (MTCExampleDemoLanguage)currentLanguage;

/// 更新全局演示语言；值变化时持久化并发送通知。
+ (void)setCurrentLanguage:(MTCExampleDemoLanguage)language;

/// 返回语言对应的 BCP 47 标签（`zh-Hans` / `en`）。
+ (NSString *)languageTagForLanguage:(MTCExampleDemoLanguage)language;

/// 在中英文之间切换。
+ (MTCExampleDemoLanguage)toggledLanguage:(MTCExampleDemoLanguage)language;

/// 按指定演示语言读取本地化文案；缺失时回退到 key。
+ (NSString *)stringForKey:(NSString *)key language:(MTCExampleDemoLanguage)language;

@end

NS_ASSUME_NONNULL_END
