//
//  MTCExampleDemoLocalization.m
//  MaptecMapsExample
//
//  Created by ZHOUPanpan+ on 2026-08-03.
//  Copyright © 2026 ZHOUPanpan+. All rights reserved.
//

#import "MTCExampleDemoLocalization.h"

NSNotificationName const MTCExampleDemoLanguageDidChangeNotification =
    @"MTCExampleDemoLanguageDidChangeNotification";

static NSString * const MTCExampleDemoLanguageDefaultsKey = @"mtc.example.demo_ui_language";

@implementation MTCExampleDemoLocalization

#pragma mark - Public

+ (MTCExampleDemoLanguage)currentLanguage {
    NSInteger raw = [[NSUserDefaults standardUserDefaults] integerForKey:MTCExampleDemoLanguageDefaultsKey];
    if (raw == MTCExampleDemoLanguageEnglish) {
        return MTCExampleDemoLanguageEnglish;
    }
    return MTCExampleDemoLanguageChinese;
}

+ (void)setCurrentLanguage:(MTCExampleDemoLanguage)language {
    MTCExampleDemoLanguage normalized = (language == MTCExampleDemoLanguageEnglish)
        ? MTCExampleDemoLanguageEnglish
        : MTCExampleDemoLanguageChinese;
    if ([self currentLanguage] == normalized) {
        return;
    }

    [[NSUserDefaults standardUserDefaults] setInteger:normalized forKey:MTCExampleDemoLanguageDefaultsKey];
    [[NSNotificationCenter defaultCenter] postNotificationName:MTCExampleDemoLanguageDidChangeNotification
                                                        object:nil];
}

+ (NSString *)languageTagForLanguage:(MTCExampleDemoLanguage)language {
    switch (language) {
        case MTCExampleDemoLanguageEnglish:
            return @"en";
        case MTCExampleDemoLanguageChinese:
        default:
            return @"zh-Hans";
    }
}

+ (MTCExampleDemoLanguage)toggledLanguage:(MTCExampleDemoLanguage)language {
    return language == MTCExampleDemoLanguageEnglish
        ? MTCExampleDemoLanguageChinese
        : MTCExampleDemoLanguageEnglish;
}

+ (NSString *)stringForKey:(NSString *)key language:(MTCExampleDemoLanguage)language {
    if (key.length == 0) {
        return @"";
    }

    NSBundle *bundle = [self bundleForLanguage:language];
    NSString *value = [bundle localizedStringForKey:key value:nil table:nil];
    if (value.length == 0 || [value isEqualToString:key]) {
        value = [[NSBundle mainBundle] localizedStringForKey:key value:key table:nil];
    }
    return value ?: key;
}

#pragma mark - Private

+ (NSBundle *)bundleForLanguage:(MTCExampleDemoLanguage)language {
    NSString *tag = [self languageTagForLanguage:language];
    NSString *path = [[NSBundle mainBundle] pathForResource:tag ofType:@"lproj"];
    if (path.length > 0) {
        NSBundle *bundle = [NSBundle bundleWithPath:path];
        if (bundle) {
            return bundle;
        }
    }
    return [NSBundle mainBundle];
}

@end
