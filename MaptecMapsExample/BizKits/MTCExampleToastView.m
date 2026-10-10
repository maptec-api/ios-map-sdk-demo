//
//  MTCExampleToastView.m
//  MaptecMapsExample
//
//  Created by ZHOUPanpan on 2026/6/30.
//

#import "MTCExampleToastView.h"

static CGFloat const MTCExampleToastHorizontalInset = 14.0;
static CGFloat const MTCExampleToastVerticalInset = 10.0;
static CGFloat const MTCExampleToastBottomInset = 40.0;
static CGFloat const MTCExampleToastMaxWidth = 320.0;
static CGFloat const MTCExampleToastScreenMargin = 40.0;
static NSTimeInterval const MTCExampleToastFadeInDuration = 0.2;
static NSTimeInterval const MTCExampleToastFadeOutDuration = 0.25;
static NSTimeInterval const MTCExampleToastDisplayDuration = 2.0;

@interface MTCExampleToastView ()

@property (nonatomic, strong) UILabel *textLabel;

@end

@implementation MTCExampleToastView
- (void)dealloc {
}
#pragma mark - Public
- (instancetype)initWithMessage:(NSString *)message {
    self = [super initWithFrame:CGRectZero];
    if (self) {
        self.backgroundColor = [UIColor colorWithWhite:0.0 alpha:0.78];
        self.layer.cornerRadius = 8.0;
        self.layer.masksToBounds = YES;
        self.alpha = 0.0;
        self.translatesAutoresizingMaskIntoConstraints = NO;

        [self addSubview:self.textLabel];
        self.textLabel.text = message;

        [NSLayoutConstraint activateConstraints:@[
            [self.textLabel.topAnchor constraintEqualToAnchor:self.topAnchor constant:MTCExampleToastVerticalInset],
            [self.textLabel.leadingAnchor constraintEqualToAnchor:self.leadingAnchor constant:MTCExampleToastHorizontalInset],
            [self.textLabel.bottomAnchor constraintEqualToAnchor:self.bottomAnchor constant:-MTCExampleToastVerticalInset],
            [self.textLabel.trailingAnchor constraintEqualToAnchor:self.trailingAnchor constant:-MTCExampleToastHorizontalInset],
        ]];
    }
    return self;
}
+ (void)showMessage:(NSString *)message inView:(UIView *)superview {
    if (message.length == 0 || !superview) {
        return;
    }

    MTCExampleToastView *toastView = [[MTCExampleToastView alloc] initWithMessage:message];
    [superview addSubview:toastView];

    CGFloat maxWidth = MIN(CGRectGetWidth(superview.bounds) - MTCExampleToastScreenMargin, MTCExampleToastMaxWidth);
    [NSLayoutConstraint activateConstraints:@[
        [toastView.centerXAnchor constraintEqualToAnchor:superview.centerXAnchor],
        [toastView.bottomAnchor constraintEqualToAnchor:superview.safeAreaLayoutGuide.bottomAnchor
                                               constant:-MTCExampleToastBottomInset],
        [toastView.widthAnchor constraintLessThanOrEqualToConstant:maxWidth],
    ]];

    [UIView animateWithDuration:MTCExampleToastFadeInDuration
                     animations:^{
        toastView.alpha = 1.0;
    } completion:^(__unused BOOL finished) {
        [UIView animateWithDuration:MTCExampleToastFadeOutDuration
                              delay:MTCExampleToastDisplayDuration
                            options:UIViewAnimationOptionCurveEaseInOut
                         animations:^{
            toastView.alpha = 0.0;
        } completion:^(__unused BOOL finished) {
            [toastView removeFromSuperview];
        }];
    }];
}

#pragma mark - Life Cycle

#pragma mark - protocol

#pragma mark - Delegate

#pragma mark - Event

#pragma mark - Private

#pragma mark - Getter & Setter

- (UILabel *)textLabel {
    if (_textLabel) {
        return _textLabel;
    }
    _textLabel = [[UILabel alloc] init];
    _textLabel.translatesAutoresizingMaskIntoConstraints = NO;
    _textLabel.textColor = UIColor.whiteColor;
    _textLabel.font = [UIFont systemFontOfSize:14.0 weight:UIFontWeightMedium];
    _textLabel.textAlignment = NSTextAlignmentCenter;
    _textLabel.numberOfLines = 0;
    return _textLabel;
}

@end
