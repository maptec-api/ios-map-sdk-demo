#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/**
 标记点动画类型。

 Marker animation type.
 */
typedef NS_ENUM(NSInteger, MTCMarkerAnimationType) {
    /**
     淡入动画。

     Fade-in animation.
     */
    MTCMarkerAnimationTypeFadeIn = 0,

    /**
     下落动画。

     Drop animation.
     */
    MTCMarkerAnimationTypeDrop,

    /**
     弹跳动画。

     Bounce animation.
     */
    MTCMarkerAnimationTypeBounce,

    /**
     淡出动画。

     Fade-out animation.
     */
    MTCMarkerAnimationTypeFadeOut = 4,

    /**
     缩小消失动画。

     Scale-down animation.
     */
    MTCMarkerAnimationTypeScaleDown,
};

/**
 标记点运行时动画配置。

 Marker runtime animation options.

 该对象不可变。启动 marker 动画时请创建新的 `MTCMarkerAnimationOptions` 并传入 `MTCMarker` 的动画方法。
 This object is immutable. To start a marker animation, create a new `MTCMarkerAnimationOptions` and pass it to the animation methods on `MTCMarker`.
 */
NS_SWIFT_NAME(MTCMarkerAnimationOptions)
@interface MTCMarkerAnimationOptions : NSObject <NSCopying>

- (instancetype)init NS_UNAVAILABLE;
+ (instancetype)new NS_UNAVAILABLE;

/**
 创建动画配置。

 Creates animation options.

 @param animationType 动画类型。The animation type.
 @param duration 动画时长，单位为秒。小于等于 `0` 时 SDK 不执行动画。The animation duration in seconds. Values less than or equal to `0` disable the animation.
 */
- (instancetype)initWithAnimationType:(MTCMarkerAnimationType)animationType
                             duration:(NSTimeInterval)duration NS_DESIGNATED_INITIALIZER;

/**
 动画类型。

 The animation type.
 */
@property (nonatomic, readonly) MTCMarkerAnimationType animationType;

/**
 动画时长，单位为秒。

 The animation duration in seconds.
 */
@property (nonatomic, readonly) NSTimeInterval duration;

@end

NS_ASSUME_NONNULL_END
