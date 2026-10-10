#import <Foundation/Foundation.h>
#import <MaptecMapsKit/MTCLineGradientStop.h>

NS_ASSUME_NONNULL_BEGIN

/**
 折线沿线颜色渐变。

 A line color gradient.

 `MTCLineGradient` 使用严格递增的颜色停点描述折线主线颜色沿线渐变。至少需要两个停点。
 `MTCLineGradient` describes a polyline stroke color gradient with strictly increasing color stops. At least two stops are required.
 */
NS_SWIFT_NAME(MTCLineGradient)
@interface MTCLineGradient : NSObject <NSCopying>

/**
 使用颜色停点创建折线沿线渐变。

 Creates a line gradient with color stops.

 @param colorStops 颜色停点数组，`lineProgress` 必须严格递增。The color stops, whose `lineProgress` values must be strictly increasing.
 */
- (nullable instancetype)initWithColorStops:(NSArray<MTCLineGradientStop *> *)colorStops NS_DESIGNATED_INITIALIZER;

- (instancetype)init NS_UNAVAILABLE;

/**
 颜色停点。

 The gradient color stops.
 */
@property (nonatomic, copy, readonly) NSArray<MTCLineGradientStop *> *colorStops;

@end

NS_ASSUME_NONNULL_END
