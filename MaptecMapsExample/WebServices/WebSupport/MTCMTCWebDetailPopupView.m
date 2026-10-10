//
//  MTCMTCWebDetailPopupView.m
//  MaptecMapsExample
//
//  Created by ZHOUPanpan on 2026/7/15.
//

#import "MTCMTCWebDetailPopupView.h"

@interface MTCMTCWebDetailPopupView()
@property (nonatomic, strong) UIControl *backgroundControl;
@property (nonatomic, strong) UIView *containerView;
@property (nonatomic, strong) UILabel *titleLabel;
@property (nonatomic, strong) UITextView *textView;
@property (nonatomic, strong) UIButton *closeButton;
@end

@implementation MTCMTCWebDetailPopupView

- (void)dealloc {
}
#pragma mark - Public

- (void)presentInView:(UIView *)view
                title:(NSString *)title
                 text:(NSString *)text
       dismissHandler:(dispatch_block_t)dismissHandler {
    self.dismissHandler = dismissHandler;
    _titleLabel.text = title;
    _textView.text = text;
    _textView.contentOffset = CGPointZero;
    [view addSubview:self];
    [NSLayoutConstraint activateConstraints:@[
        [self.topAnchor constraintEqualToAnchor:view.topAnchor],
        [self.leadingAnchor constraintEqualToAnchor:view.leadingAnchor],
        [self.trailingAnchor constraintEqualToAnchor:view.trailingAnchor],
        [self.bottomAnchor constraintEqualToAnchor:view.bottomAnchor],
    ]];
    [UIView animateWithDuration:0.2 animations:^{
        self.alpha = 1.0;
    }];
}

- (void)dismiss {
    dispatch_block_t dismissHandler = self.dismissHandler;
    self.dismissHandler = nil;
    [UIView animateWithDuration:0.2 animations:^{
        self.alpha = 0.0;
    } completion:^(__unused BOOL finished) {
        [self removeFromSuperview];
        if (dismissHandler) {
            dismissHandler();
        }
    }];
}
#pragma mark - Life Cycle
- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.translatesAutoresizingMaskIntoConstraints = NO;
        self.alpha = 0.0;

        
        [self addSubview:self.backgroundControl];
        [self addSubview:self.containerView];
        [self.containerView addSubview:self.titleLabel];
        [self.containerView addSubview:self.closeButton];
        [self.containerView addSubview:self.textView];

        [NSLayoutConstraint activateConstraints:@[
            [self.backgroundControl.topAnchor constraintEqualToAnchor:self.topAnchor],
            [self.backgroundControl.leadingAnchor constraintEqualToAnchor:self.leadingAnchor],
            [self.backgroundControl.trailingAnchor constraintEqualToAnchor:self.trailingAnchor],
            [self.backgroundControl.bottomAnchor constraintEqualToAnchor:self.bottomAnchor],

            [self.containerView.centerXAnchor constraintEqualToAnchor:self.centerXAnchor],
            [self.containerView.centerYAnchor constraintEqualToAnchor:self.centerYAnchor],
            [self.containerView.leadingAnchor constraintGreaterThanOrEqualToAnchor:self.leadingAnchor constant:20.0],
            [self.containerView.trailingAnchor constraintLessThanOrEqualToAnchor:self.trailingAnchor constant:-20.0],
            [self.containerView.widthAnchor constraintEqualToAnchor:self.widthAnchor multiplier:0.88],
            [self.containerView.heightAnchor constraintLessThanOrEqualToAnchor:self.heightAnchor multiplier:0.72],

            [self.titleLabel.topAnchor constraintEqualToAnchor:self.containerView.topAnchor constant:16.0],
            [self.titleLabel.leadingAnchor constraintEqualToAnchor:self.containerView.leadingAnchor constant:16.0],
            [self.titleLabel.trailingAnchor constraintLessThanOrEqualToAnchor:self.closeButton.leadingAnchor constant:-12.0],

            [self.closeButton.centerYAnchor constraintEqualToAnchor:self.titleLabel.centerYAnchor],
            [self.closeButton.trailingAnchor constraintEqualToAnchor:self.containerView.trailingAnchor constant:-16.0],
            [self.closeButton.widthAnchor constraintEqualToConstant:28.0],
            [self.closeButton.heightAnchor constraintEqualToConstant:28.0],

            [self.textView.topAnchor constraintEqualToAnchor:self.titleLabel.bottomAnchor constant:12.0],
            [self.textView.leadingAnchor constraintEqualToAnchor:self.containerView.leadingAnchor constant:16.0],
            [self.textView.trailingAnchor constraintEqualToAnchor:self.containerView.trailingAnchor constant:-16.0],
            [self.textView.bottomAnchor constraintEqualToAnchor:self.containerView.bottomAnchor constant:-16.0],
            [self.textView.heightAnchor constraintGreaterThanOrEqualToConstant:180.0],
        ]];
    }
    return self;
}
#pragma mark - protocol

#pragma mark - Delegate

#pragma mark - Event

#pragma mark - Private

#pragma mark - Getter & Setter
- (UIControl *)backgroundControl {
    if (_backgroundControl) {
        return _backgroundControl;
    }
    _backgroundControl = [[UIControl alloc] init];
    _backgroundControl.translatesAutoresizingMaskIntoConstraints = NO;
    _backgroundControl.backgroundColor = [UIColor.blackColor colorWithAlphaComponent:0.28];
    [_backgroundControl addTarget:self action:@selector(dismiss) forControlEvents:UIControlEventTouchUpInside];
    return _backgroundControl;
}
- (UIView *)containerView {
    if (_containerView) {
        return _containerView;
    }
    _containerView = [[UIView alloc] init];
    _containerView.translatesAutoresizingMaskIntoConstraints = NO;
    _containerView.backgroundColor = UIColor.systemBackgroundColor;
    _containerView.layer.cornerRadius = 18.0;
    _containerView.layer.shadowColor = UIColor.blackColor.CGColor;
    _containerView.layer.shadowOpacity = 0.12;
    _containerView.layer.shadowRadius = 20.0;
    _containerView.layer.shadowOffset = CGSizeMake(0.0, 10.0);
    return _containerView;
}
- (UILabel *)titleLabel {
    if (_titleLabel) {
        return _titleLabel;
    }
    _titleLabel = [[UILabel alloc] init];
    _titleLabel.translatesAutoresizingMaskIntoConstraints = NO;
    _titleLabel.font = [UIFont preferredFontForTextStyle:UIFontTextStyleTitle3];
    _titleLabel.textColor = UIColor.labelColor;
    _titleLabel.numberOfLines = 0;
    return _titleLabel;
}
- (UIButton *)closeButton{
    if (_closeButton) {
        return _closeButton;
    }
    _closeButton = [UIButton buttonWithType:UIButtonTypeCustom];
    _closeButton.translatesAutoresizingMaskIntoConstraints = NO;
    [_closeButton setImage:[UIImage systemImageNamed:@"xmark.circle.fill"] forState:UIControlStateNormal];
    _closeButton.tintColor = UIColor.secondaryLabelColor;
    [_closeButton addTarget:self action:@selector(dismiss) forControlEvents:UIControlEventTouchUpInside];
    return _closeButton;
}
- (UITextView *)textView {
    if (_textView) {
        return _textView;
    }
    _textView = [[UITextView alloc] init];
    _textView.translatesAutoresizingMaskIntoConstraints = NO;
    _textView.backgroundColor = UIColor.secondarySystemBackgroundColor;
    _textView.font = [UIFont monospacedSystemFontOfSize:13.0 weight:UIFontWeightRegular];
    _textView.textColor = UIColor.labelColor;
    _textView.editable = NO;
    _textView.selectable = YES;
    _textView.layer.cornerRadius = 14.0;
    _textView.alwaysBounceVertical = YES;
    _textView.textContainerInset = UIEdgeInsetsMake(12.0, 12.0, 12.0, 12.0);
    return _textView;
}

@end
