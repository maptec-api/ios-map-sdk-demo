//
//  MTCExampleToastView.h
//  MaptecMapsExample
//
//  Created by ZHOUPanpan on 2026/6/30.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

/// 示例工程通用 Toast 视图
@interface MTCExampleToastView : UIView

- (instancetype)initWithMessage:(NSString *)message NS_DESIGNATED_INITIALIZER;
+ (void)showMessage:(NSString *)message inView:(UIView *)superview;

- (instancetype)init NS_UNAVAILABLE;
- (instancetype)initWithFrame:(CGRect)frame NS_UNAVAILABLE;
- (nullable instancetype)initWithCoder:(NSCoder *)coder NS_UNAVAILABLE;
+ (instancetype)new NS_UNAVAILABLE;

@end

NS_ASSUME_NONNULL_END
