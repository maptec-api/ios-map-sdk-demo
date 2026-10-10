//
//  MTCExampleMapBizUtil.m
//  MaptecMaps
//
//  Created by ZHOUPanpan on 2026/6/25.
//

#import "MTCExampleMapBizUtil.h"

@implementation MTCExampleMapBizUtil
#pragma mark - Public
#pragma mark -- 地图控件的位置-文本映射
+ (NSArray<NSString *> *)MTCUIPositionTitles {
    return @[
        @"右上 (TOP|END)",
        @"左上 (TOP|START)",
        @"顶部居中 (TOP|CENTER)",
        @"左中 (MIDDLE-LEFT)",
        @"居中 (CENTER)",
        @"右中 (MIDDLE-RIGHT)",
        @"右下 (BOTTOM|END)",
        @"左下 (BOTTOM|START)",
        @"底部居中 (BOTTOM|CENTER)",
    ];
}

+ (MTCUIPosition)MTCUIPositionForIndex:(NSInteger)index {
    switch (index) {
        case 1:
            return MTCUIPositionTop | MTCUIPositionLeft;
        case 2:
            return MTCUIPositionTop | MTCUIPositionCenter;
        case 3:
            return MTCUIPositionCenter | MTCUIPositionLeft;
        case 4:
            return MTCUIPositionCenter;
        case 5:
            return MTCUIPositionCenter | MTCUIPositionRight;
        case 6:
            return MTCUIPositionBottom | MTCUIPositionRight;
        case 7:
            return MTCUIPositionBottom | MTCUIPositionLeft;
        case 8:
            return MTCUIPositionBottom | MTCUIPositionCenter;
        case 0:
        default:
            return MTCUIPositionTop | MTCUIPositionRight;
    }
}

+ (NSInteger)MTCIndexForUIPosition:(MTCUIPosition)position {
    NSArray<NSNumber *> *positions = @[
        @(MTCUIPositionTop | MTCUIPositionRight),
        @(MTCUIPositionTop | MTCUIPositionLeft),
        @(MTCUIPositionTop | MTCUIPositionCenter),
        @(MTCUIPositionCenter | MTCUIPositionLeft),
        @(MTCUIPositionCenter),
        @(MTCUIPositionCenter | MTCUIPositionRight),
        @(MTCUIPositionBottom | MTCUIPositionRight),
        @(MTCUIPositionBottom | MTCUIPositionLeft),
        @(MTCUIPositionBottom | MTCUIPositionCenter),
    ];
    NSUInteger index = [positions indexOfObject:@(position)];
    return index == NSNotFound ? 0 : (NSInteger)index;
}

#pragma mark -- 信息窗口映射
- (MTCFloatInfoWindowAnchor)anchorTypeViaIndex:(NSInteger)index {
    MTCFloatInfoWindowAnchor ret = MTCFloatInfoWindowAnchorUnkown;
    switch (index) {
        case 0:{
            ret = MTCFloatInfoWindowAnchorBottom;
        }
            break;
        case 1:{
            ret = MTCFloatInfoWindowAnchorCenter;
        }
            break;
        case 2:{
            ret = MTCFloatInfoWindowAnchorTop;
        }
            break;
        case 3:{
            ret = MTCFloatInfoWindowAnchorLeft;
        }
            break;
        case 4:{
            ret = MTCFloatInfoWindowAnchorRight;
        }
            break;
        case 5:{
            ret = MTCFloatInfoWindowAnchorTopLeft;
        }
            break;
        case 6:{
            ret = MTCFloatInfoWindowAnchorTopRight;
        }
            break;
        case 7:{
            ret = MTCFloatInfoWindowAnchorBottomLeft;
        }
            break;
        case 8:{
            ret = MTCFloatInfoWindowAnchorBottomRight;
        }
            break;
        default:{
            ret = MTCFloatInfoWindowAnchorBottom;
        }
            break;
    }
    return ret;
}
#pragma mark - Private
@end
