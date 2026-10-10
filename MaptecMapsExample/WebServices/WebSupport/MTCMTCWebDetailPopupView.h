//
//  MTCMTCWebDetailPopupView.h
//  MaptecMapsExample
//
//  Created by ZHOUPanpan on 2026/7/15.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

/// 统一的详情弹窗
@interface MTCMTCWebDetailPopupView : UIView

@property (nonatomic, copy, nullable) dispatch_block_t dismissHandler;

- (void)presentInView:(UIView *)view
                title:(NSString *)title
                 text:(NSString *)text
       dismissHandler:(nullable dispatch_block_t)dismissHandler;
- (void)dismiss;

@end

NS_ASSUME_NONNULL_END
