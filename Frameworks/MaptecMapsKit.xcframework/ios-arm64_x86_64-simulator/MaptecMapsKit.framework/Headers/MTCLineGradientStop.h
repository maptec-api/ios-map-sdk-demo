#import <CoreGraphics/CoreGraphics.h>
#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

/**
 折线沿线渐变颜色停点。

 A line gradient color stop.

 `MTCLineGradientStop` 将沿线累计长度比例映射到颜色。`lineProgress` 表示从折线起点到当前停点的累计长度占整条折线长度的比例，取值范围为 `[0, 1]`。
 `MTCLineGradientStop` maps line progress to a color. `lineProgress` is the ratio of the accumulated distance from the start of the polyline to the total polyline length, in `[0, 1]`.
 */
NS_SWIFT_NAME(MTCLineGradientStop)
@interface MTCLineGradientStop : NSObject <NSCopying>

/**
 使用沿线进度和颜色创建渐变停点。

 Creates a gradient stop with line progress and color.

 @param lineProgress 沿线累计长度比例，范围为 `[0, 1]`。The accumulated line distance ratio in `[0, 1]`.
 @param color 停点颜色。The stop color.
 */
- (instancetype)initWithLineProgress:(CGFloat)lineProgress
                               color:(UIColor *)color NS_DESIGNATED_INITIALIZER;

- (instancetype)init NS_UNAVAILABLE;

/**
 沿线累计长度比例。

 The accumulated line distance ratio.
 */
@property (nonatomic, readonly) CGFloat lineProgress;

/**
 停点颜色。

 The stop color.
 */
@property (nonatomic, strong, readonly) UIColor *color;

@end

NS_ASSUME_NONNULL_END
