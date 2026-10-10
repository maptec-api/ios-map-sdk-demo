//
//  MTCPlace+MTCPrettyFork.h
//  MaptecMapsExample
//
//  Created by ZHOUPanpan+ on 2026/8/4.
//  Copyright © 2026 ZHOUPanpan+. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <MaptecSearchKit/MaptecSearchKit.h>

NS_ASSUME_NONNULL_BEGIN

#pragma mark - MTCPlace

@interface MTCPlace (MTCPrettyFork)

/// 地点标识，优先 placeID / name，否则使用 fallbackIndex
- (nullable NSString *)mtc_identifierWithFallbackIndex:(NSUInteger)index;

/// 地点展示标题
- (NSString *)mtc_displayTitleWithFallbackIndex:(NSUInteger)index;

/// 地点列表预览文本
- (NSString *)mtc_previewText;

/// 地点详情展示文本（字段名与 API 一致）
- (NSString *)mtc_detailText;

@end

#pragma mark - MTCSuggestion

@interface MTCSuggestion (MTCPrettyFork)

/// 建议项标识
- (nullable NSString *)mtc_identifierWithFallbackIndex:(NSUInteger)index;

/// 建议项展示标题
- (NSString *)mtc_displayTitleWithFallbackIndex:(NSUInteger)index;

/// 建议项列表预览文本
- (NSString *)mtc_previewText;

/// 建议项详情展示文本
- (NSString *)mtc_detailText;

@end

#pragma mark - MTCGeocodeResult

@interface MTCGeocodeResult (MTCPrettyFork)

/// 地理编码结果标识
- (nullable NSString *)mtc_identifierWithFallbackIndex:(NSUInteger)index;

/// 地理编码结果展示标题
- (NSString *)mtc_displayTitleWithFallbackIndex:(NSUInteger)index;

/// 地理编码结果列表预览文本
- (NSString *)mtc_previewText;

/// 地理编码结果详情展示文本
- (NSString *)mtc_detailText;

@end

NS_ASSUME_NONNULL_END
