//
//  MTCExampleLanguageToggleControl.m
//  MaptecMapsExample
//
//  Created by ZHOUPanpan+ on 2026-08-03.
//  Copyright © 2026 ZHOUPanpan+. All rights reserved.
//

#import "MTCExampleLanguageToggleControl.h"

#import "MTCExampleDemoLocalization.h"
#import "MTCExampleTestAccessibility.h"

@interface MTCExampleLanguageToggleControl ()

@property (nonatomic, strong) UIImageView *iconView;
@property (nonatomic, strong) UILabel *chineseLabel;
@property (nonatomic, strong) UILabel *separatorLabel;
@property (nonatomic, strong) UILabel *englishLabel;
@property (nonatomic, strong) UIStackView *labelsStackView;
@property (nonatomic, strong) UIStackView *contentStackView;

@end

@implementation MTCExampleLanguageToggleControl

#pragma mark - Life Cycle

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        _selectedLanguage = MTCExampleDemoLanguageChinese;
        [self configureViews];
        [self refreshAppearance];
        [self refreshAccessibility];
    }
    return self;
}

- (CGSize)intrinsicContentSize {
    // 导航栏 ItemWrapperView 高度是 36，不要用 required 的 height >= 44 去顶它。
    // 宽度仍按 44 给出可点区域；高度交给导航栏。
    return CGSizeMake(44.0, UIViewNoIntrinsicMetric);
}

- (void)tintColorDidChange {
    [super tintColorDidChange];
    [self refreshAppearance];
}

#pragma mark - Public

- (void)setSelectedLanguage:(MTCExampleDemoLanguage)selectedLanguage {
    if (_selectedLanguage == selectedLanguage) {
        return;
    }
    _selectedLanguage = selectedLanguage;
    [self refreshAppearance];
    [self refreshAccessibility];
}

#pragma mark - Private

- (void)configureViews {
    self.backgroundColor = UIColor.clearColor;
    // 子视图关闭无障碍，避免 CN/EN Label 抢占焦点导致控件 identifier 不可见。
    self.isAccessibilityElement = YES;
    self.accessibilityTraits = UIAccessibilityTraitButton;

    UIImageSymbolConfiguration *symbolConfig =
        [UIImageSymbolConfiguration configurationWithPointSize:16.0 weight:UIImageSymbolWeightMedium];
    UIImage *globeImage = [UIImage systemImageNamed:@"globe" withConfiguration:symbolConfig];
    self.iconView = [[UIImageView alloc] initWithImage:globeImage];
    self.iconView.contentMode = UIViewContentModeScaleAspectFit;
    self.iconView.isAccessibilityElement = NO;
    self.iconView.translatesAutoresizingMaskIntoConstraints = NO;
    [self.iconView.widthAnchor constraintEqualToConstant:20.0].active = YES;
    [self.iconView.heightAnchor constraintEqualToConstant:20.0].active = YES;

    self.chineseLabel = [self makeIndicatorLabelWithText:@"CN"];
    self.separatorLabel = [self makeIndicatorLabelWithText:@"/"];
    self.englishLabel = [self makeIndicatorLabelWithText:@"EN"];

    self.labelsStackView = [[UIStackView alloc] initWithArrangedSubviews:@[
        self.chineseLabel,
        self.separatorLabel,
        self.englishLabel,
    ]];
    self.labelsStackView.axis = UILayoutConstraintAxisHorizontal;
    self.labelsStackView.alignment = UIStackViewAlignmentCenter;
    self.labelsStackView.spacing = 2.0;
    self.labelsStackView.isAccessibilityElement = NO;

    self.contentStackView = [[UIStackView alloc] initWithArrangedSubviews:@[
        self.iconView,
        self.labelsStackView,
    ]];
    self.contentStackView.axis = UILayoutConstraintAxisVertical;
    self.contentStackView.alignment = UIStackViewAlignmentCenter;
    self.contentStackView.spacing = 1.0;
    self.contentStackView.translatesAutoresizingMaskIntoConstraints = NO;
    self.contentStackView.userInteractionEnabled = NO;
    self.contentStackView.isAccessibilityElement = NO;
    [self addSubview:self.contentStackView];

    NSLayoutConstraint *minLeading =
        [self.contentStackView.leadingAnchor constraintGreaterThanOrEqualToAnchor:self.leadingAnchor];
    NSLayoutConstraint *maxTrailing =
        [self.contentStackView.trailingAnchor constraintLessThanOrEqualToAnchor:self.trailingAnchor];
    NSLayoutConstraint *minTop =
        [self.contentStackView.topAnchor constraintGreaterThanOrEqualToAnchor:self.topAnchor];
    NSLayoutConstraint *maxBottom =
        [self.contentStackView.bottomAnchor constraintLessThanOrEqualToAnchor:self.bottomAnchor];
    minLeading.priority = UILayoutPriorityDefaultHigh;
    maxTrailing.priority = UILayoutPriorityDefaultHigh;
    minTop.priority = UILayoutPriorityDefaultHigh;
    maxBottom.priority = UILayoutPriorityDefaultHigh;

    [NSLayoutConstraint activateConstraints:@[
        [self.contentStackView.centerXAnchor constraintEqualToAnchor:self.centerXAnchor],
        [self.contentStackView.centerYAnchor constraintEqualToAnchor:self.centerYAnchor],
        minLeading,
        maxTrailing,
        minTop,
        maxBottom,
    ]];
}

- (UILabel *)makeIndicatorLabelWithText:(NSString *)text {
    UILabel *label = [[UILabel alloc] init];
    label.text = text;
    label.font = [UIFont systemFontOfSize:9.0 weight:UIFontWeightRegular];
    label.textAlignment = NSTextAlignmentCenter;
    label.isAccessibilityElement = NO;
    return label;
}

- (void)refreshAppearance {
    UIColor *selectedColor = self.tintColor ?: UIColor.systemBlueColor;
    UIColor *unselectedColor = [UIColor.secondaryLabelColor colorWithAlphaComponent:0.55];
    BOOL chineseSelected = (self.selectedLanguage == MTCExampleDemoLanguageChinese);

    self.iconView.tintColor = selectedColor;
    [self applySelected:chineseSelected toLabel:self.chineseLabel selectedColor:selectedColor unselectedColor:unselectedColor];
    [self applySelected:!chineseSelected toLabel:self.englishLabel selectedColor:selectedColor unselectedColor:unselectedColor];
    self.separatorLabel.textColor = unselectedColor;
    self.separatorLabel.font = [UIFont systemFontOfSize:9.0 weight:UIFontWeightRegular];
}

- (void)applySelected:(BOOL)selected
              toLabel:(UILabel *)label
        selectedColor:(UIColor *)selectedColor
      unselectedColor:(UIColor *)unselectedColor {
    label.textColor = selected ? selectedColor : unselectedColor;
    label.font = [UIFont systemFontOfSize:9.0
                                   weight:(selected ? UIFontWeightBold : UIFontWeightRegular)];
}

- (void)refreshAccessibility {
    self.accessibilityIdentifier = MTCExampleTestAccessibilityLanguageToggle;
    self.accessibilityValue = (self.selectedLanguage == MTCExampleDemoLanguageEnglish)
        ? MTCExampleTestAccessibilityLanguageValueEnglish
        : MTCExampleTestAccessibilityLanguageValueChinese;
    NSString *key = (self.selectedLanguage == MTCExampleDemoLanguageEnglish)
        ? @"ui_lang_switch_to_zh"
        : @"ui_lang_switch_to_en";
    self.accessibilityLabel = [MTCExampleDemoLocalization stringForKey:key
                                                              language:self.selectedLanguage];
}

@end
