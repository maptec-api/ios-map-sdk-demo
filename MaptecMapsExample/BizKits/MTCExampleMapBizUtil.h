//
//  MTCExampleMapBizUtil.h
//  MaptecMaps
//
//  Created by ZHOUPanpan on 2026/6/25.
//

#import <Foundation/Foundation.h>
#import <MaptecMapsKit/MaptecMapsKit.h>

NS_ASSUME_NONNULL_BEGIN

/// 非通用工具类
@interface MTCExampleMapBizUtil : NSObject
#pragma mark -- 地图控件的位置-文本映射
+ (NSArray<NSString *> *)MTCUIPositionTitles;
+ (MTCUIPosition)MTCUIPositionForIndex:(NSInteger)index;
+ (NSInteger)MTCIndexForUIPosition:(MTCUIPosition)position;

@end

NS_ASSUME_NONNULL_END
